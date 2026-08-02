import asyncio
import json
import re
import time as time_module
from datetime import date, time
from pathlib import Path
from typing import Any
from urllib.parse import parse_qs, urlencode, urlparse
from urllib.request import Request, urlopen

from bs4 import BeautifulSoup, Tag
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import Select, WebDriverWait

from worker.config import settings
from worker.sources.base import BaseballDataSource


TEAM_CODES = {
    "LG": "LG",
    "두산": "OB",
    "SSG": "SSG",
    "키움": "WO",
    "KT": "KT",
    "KIA": "KIA",
    "롯데": "LT",
    "삼성": "SS",
    "한화": "HH",
    "NC": "NC",
}

KBO_GAME_TEAM_CODES = {
    "LG": "LG",
    "OB": "OB",
    "SK": "SSG",
    "WO": "WO",
    "KT": "KT",
    "HT": "KIA",
    "LT": "LT",
    "SS": "SS",
    "HH": "HH",
    "NC": "NC",
}

KBO_EXTERNAL_TEAM_CODES = {
    "LG": "LG",
    "OB": "OB",
    "SSG": "SK",
    "WO": "WO",
    "KT": "KT",
    "KIA": "HT",
    "LT": "LT",
    "SS": "SS",
    "HH": "HH",
    "NC": "NC",
}


def _game_id_parts(external_game_id: str) -> tuple[str, str, str]:
    """Return date, away code and home code for official or fallback IDs."""
    if len(external_game_id) < 8 or not external_game_id[:8].isdigit():
        raise ValueError(f"Invalid KBO game id: {external_game_id}")
    game_date = external_game_id[:8]
    compact = external_game_id[8:]
    if len(compact) >= 5 and compact[-1].isdigit():
        away_key, home_key = compact[:2], compact[2:4]
        if away_key in KBO_GAME_TEAM_CODES and home_key in KBO_GAME_TEAM_CODES:
            return game_date, KBO_GAME_TEAM_CODES[away_key], KBO_GAME_TEAM_CODES[home_key]

    parts = external_game_id.split("-")
    if len(parts) >= 4:
        away_code, home_code = parts[1], parts[2]
        if away_code in KBO_GAME_TEAM_CODES.values() and home_code in KBO_GAME_TEAM_CODES.values():
            return game_date, away_code, home_code
    raise ValueError(f"Unsupported KBO game id format: {external_game_id}")

STADIUM_NAMES = {
    "잠실": "잠실야구장",
    "고척": "고척스카이돔",
    "문학": "인천SSG랜더스필드",
    "수원": "수원KT위즈파크",
    "광주": "광주기아챔피언스필드",
    "사직": "사직야구장",
    "대구": "대구삼성라이온즈파크",
    "대전": "대전한화생명볼파크",
    "창원": "창원NC파크",
    "울산": "울산문수야구장",
    "포항": "포항야구장",
    "청주": "청주야구장",
}

_DAY_PATTERN = re.compile(r"(?P<month>\d{2})\.(?P<day>\d{2})")
_TIME_PATTERN = re.compile(r"(?P<hour>\d{1,2}):(?P<minute>\d{2})")
_CANCEL_KEYWORDS = ("취소", "그라운드사정", "미세먼지")


def _cell_text(cell: Tag | None) -> str:
    return cell.get_text(" ", strip=True) if cell else ""


def _parse_score(play_cell: Tag) -> tuple[int | None, int | None]:
    score_box = play_cell.find("em")
    if not score_box:
        return None, None
    values = [span.get_text(strip=True) for span in score_box.find_all("span")]
    scores = [int(value) for value in values if value.isdigit()]
    if len(scores) != 2:
        # KBO has used more than one score markup over time.  Keep the
        # parser tolerant when the score is rendered as plain text.
        scores = [
            int(value)
            for value in re.findall(r"(?<!\d)\d+(?!\d)", score_box.get_text(" ", strip=True))
        ]
    if len(scores) != 2:
        return None, None
    return scores[0], scores[1]


def _external_game_id(row: Tag, game_date: date, away_code: str, home_code: str) -> str:
    for link in row.find_all("a", href=True):
        game_ids = parse_qs(urlparse(link["href"]).query).get("gameId")
        if game_ids:
            return game_ids[0]
    away_external = KBO_EXTERNAL_TEAM_CODES[away_code]
    home_external = KBO_EXTERNAL_TEAM_CODES[home_code]
    return f"{game_date:%Y%m%d}{away_external}{home_external}0"


def _status(
    note: str,
    relay: str,
    scores: tuple[int | None, int | None],
    game_date: date,
) -> str:
    if any(keyword in note for keyword in _CANCEL_KEYWORDS):
        return "cancelled"
    has_scores = scores[0] is not None and scores[1] is not None
    if not has_scores:
        return "scheduled"

    # A completed game from a past date must never remain in_progress just
    # because the KBO relay label changed or was not rendered in the HTML.
    if game_date < date.today():
        return "completed"
    if "리뷰" in relay and "프리뷰" not in relay:
        return "completed"
    if any(
        keyword in relay
        for keyword in ("문자중계", "중계", "LIVE", "라이브", "경기중")
    ) and "프리뷰" not in relay:
        return "in_progress"
    return "scheduled"


def parse_schedule_html(html: str, year: int, month: int) -> list[dict[str, Any]]:
    soup = BeautifulSoup(html, "html.parser")
    rows = soup.select("table.tbl tbody tr")
    games: list[dict[str, Any]] = []
    current_date: date | None = None

    for row in rows:
        day_cell = row.select_one("td.day")
        if day_cell:
            day_match = _DAY_PATTERN.search(_cell_text(day_cell))
            if not day_match:
                current_date = None
                continue
            row_month = int(day_match.group("month"))
            row_day = int(day_match.group("day"))
            current_date = date(year, row_month, row_day)

        play_cell = row.select_one("td.play")
        time_cell = row.select_one("td.time")
        if current_date is None or play_cell is None or time_cell is None:
            continue
        if current_date.month != month:
            continue

        teams = [span.get_text(strip=True) for span in play_cell.find_all("span", recursive=False)]
        if len(teams) < 2 or teams[0] not in TEAM_CODES or teams[-1] not in TEAM_CODES:
            continue

        time_match = _TIME_PATTERN.search(_cell_text(time_cell))
        game_time = (
            time(int(time_match.group("hour")), int(time_match.group("minute")))
            if time_match
            else None
        )
        cells = row.find_all("td", recursive=False)
        play_index = cells.index(play_cell)
        relay = _cell_text(cells[play_index + 1] if len(cells) > play_index + 1 else None)
        stadium_short = _cell_text(cells[play_index + 5] if len(cells) > play_index + 5 else None)
        note = _cell_text(cells[play_index + 6] if len(cells) > play_index + 6 else None)
        away_name, home_name = teams[0], teams[-1]
        away_code, home_code = TEAM_CODES[away_name], TEAM_CODES[home_name]
        away_score, home_score = _parse_score(play_cell)
        status = _status(note, relay, (away_score, home_score), current_date)

        if status == "cancelled":
            away_score, home_score = None, None

        games.append(
            {
                "external_source": "kbo",
                "external_game_id": _external_game_id(
                    row, current_date, away_code, home_code
                ),
                "season_year": year,
                "game_date": current_date,
                "game_time": game_time,
                "home_team_code": home_code,
                "home_team_name": home_name,
                "away_team_code": away_code,
                "away_team_name": away_name,
                "stadium_name": STADIUM_NAMES.get(stadium_short, stadium_short),
                "status": status,
                "home_score": home_score,
                "away_score": away_score,
                "note": note or None,
            }
        )

    return games


def _number(value: str, *, decimal: bool = False) -> int | float | None:
    value = value.strip()
    if not value or value == "-":
        return None
    try:
        return float(value) if decimal else int(value)
    except ValueError:
        return None


def _innings(value: str) -> float | None:
    value = value.strip()
    if not value:
        return None
    if "/" not in value:
        return float(value)
    parts = value.split()
    whole = int(parts[0]) if len(parts) == 2 else 0
    fraction = parts[-1]
    outs = 1 if fraction == "1/3" else 2 if fraction == "2/3" else 0
    return float(f"{whole}.{outs}")


def _parse_hitters(soup: BeautifulSoup, side: str, team_code: str) -> list[dict[str, Any]]:
    info_rows = soup.select(f"#tbl{side}Hitter1 tbody tr")
    outcome_rows = soup.select(f"#tbl{side}Hitter2 tbody tr")
    stat_rows = soup.select(f"#tbl{side}Hitter3 tbody tr")
    hitters: list[dict[str, Any]] = []
    for index, (info_row, stat_row) in enumerate(zip(info_rows, stat_rows, strict=False)):
        info = [_cell_text(cell) for cell in info_row.find_all(["th", "td"], recursive=False)]
        stats = [_cell_text(cell) for cell in stat_row.find_all("td", recursive=False)]
        if len(info) < 3 or len(stats) < 5 or not info[2] or info[2] == "TOTAL":
            continue
        outcomes = []
        if index < len(outcome_rows):
            for cell in outcome_rows[index].find_all("td", recursive=False):
                text = cell.get_text("/", strip=True)
                outcomes.extend(part.strip() for part in text.split("/") if part.strip())
        home_runs = sum("홈" in outcome for outcome in outcomes)
        doubles = sum(
            any(marker in outcome for marker in ("좌2", "중2", "우2", "좌중2", "우중2"))
            for outcome in outcomes
        )
        triples = sum(
            any(marker in outcome for marker in ("좌3", "중3", "우3", "좌중3", "우중3"))
            for outcome in outcomes
        )
        hitters.append(
            {
                "team_code": team_code,
                "player_name": info[2],
                "external_player_id": f"kbo:{team_code}:{info[2]}",
                "batting_order": _number(info[0]),
                "position": info[1] or None,
                "ab": _number(stats[0]) or 0,
                "h": _number(stats[1]) or 0,
                "rbi": _number(stats[2]) or 0,
                "r": _number(stats[3]) or 0,
                "avg_after_game": _number(stats[4], decimal=True),
                "hr": home_runs,
                "doubles": doubles,
                "triples": triples,
                "bb": sum("4구" in outcome or "고4" in outcome for outcome in outcomes),
                "hbp": sum("사구" in outcome for outcome in outcomes),
                "sf": sum("희비" in outcome for outcome in outcomes),
                "sh": sum("희번" in outcome for outcome in outcomes),
                "ci": sum("타격방해" in outcome for outcome in outcomes),
                "so": sum("삼진" in outcome for outcome in outcomes),
                "sb": sum(
                    "도루" in outcome and "실패" not in outcome
                    for outcome in outcomes
                ),
            }
        )
    return hitters


def _parse_stolen_bases(soup: BeautifulSoup) -> dict[str, int]:
    """Return successful steals by player from KBO's game-detail summary.

    KBO does not expose steals in the per-at-bat hitter table. They are listed
    in ``#tblEtc`` as entries such as ``김주원(6회) 채현우(7회)`` or
    ``선수명2(1회 3회)`` when the same player steals more than once.
    """
    steals: dict[str, int] = {}
    for heading in soup.select("#tblEtc th"):
        if _cell_text(heading) != "도루":
            continue
        value_cell = heading.find_next_sibling("td")
        if value_cell is None:
            continue
        value = value_cell.get_text(" ", strip=True)
        for match in re.finditer(r"([^\s()]+?)(\d+)?\(([^)]*)\)", value):
            player_name = match.group(1).strip()
            explicit_count = int(match.group(2)) if match.group(2) else 1
            if player_name:
                steals[player_name] = steals.get(player_name, 0) + explicit_count
    return steals


def _parse_pitchers(soup: BeautifulSoup, side: str, team_code: str) -> list[dict[str, Any]]:
    pitchers: list[dict[str, Any]] = []
    for row in soup.select(f"#tbl{side}Pitcher tbody tr"):
        values = [_cell_text(cell) for cell in row.find_all("td", recursive=False)]
        if len(values) < 17 or values[0] == "TOTAL":
            continue
        pitchers.append(
            {
                "team_code": team_code,
                "player_name": values[0],
                "external_player_id": f"kbo:{team_code}:{values[0]}",
                "decision": values[2] or None,
                "innings_pitched": _innings(values[6]),
                "batters_faced": _number(values[7]) or 0,
                "pitches": _number(values[8]),
                "hits": _number(values[10]) or 0,
                "home_runs": _number(values[11]) or 0,
                "walks": _number(values[12]) or 0,
                "strikeouts": _number(values[13]) or 0,
                "runs": _number(values[14]) or 0,
                "earned_runs": _number(values[15]) or 0,
                "era_after_game": _number(values[16], decimal=True),
            }
        )
    return pitchers


def _event_number(element: Tag, name: str, default: int = 0) -> int:
    value = element.get(f"data-{name}")
    if value is None:
        return default
    try:
        return int(value)
    except (TypeError, ValueError):
        return default


def _event_type(description: str) -> str:
    lowered = description.lower()
    if any(token in description for token in ("홈런", "홈런타자")) or "home run" in lowered:
        return "home_run"
    if "삼진" in description or "strikeout" in lowered:
        return "strikeout"
    if "볼넷" in description or "walk" in lowered:
        return "walk"
    if "안타" in description or "hit" in lowered:
        return "hit"
    if "실책" in description or "error" in lowered:
        return "error"
    return "plate_appearance"


def parse_game_events_html(html: str) -> list[dict[str, Any]]:
    """Parse KBO relay markup into normalized event records.

    KBO has changed the relay markup more than once. The parser intentionally
    reads data-* attributes first and supports the common relay list/table
    containers as fallbacks, so a markup change does not create fabricated WPA.
    """
    soup = BeautifulSoup(html, "html.parser")
    selectors = (
        "[data-inning][data-half]",
        ".relay-list li",
        ".relay_list li",
        ".game-relay li",
        ".game_relay li",
        "table.tblEvent tbody tr",
        "table.tbl_event tbody tr",
    )
    elements: list[Tag] = []
    seen: set[int] = set()
    for selector in selectors:
        for element in soup.select(selector):
            identity = id(element)
            if identity not in seen:
                seen.add(identity)
                elements.append(element)

    events: list[dict[str, Any]] = []
    for sequence_no, element in enumerate(elements, start=1):
        text = _cell_text(element)
        if not text:
            continue
        inning = _event_number(element, "inning")
        if not inning:
            match = re.search(r"(\d+)\s*회", text)
            if not match:
                continue
            inning = int(match.group(1))
        half = element.get("data-half") or (
            "bottom" if any(token in text for token in ("말", "말초", "bottom")) else "top"
        )
        events.append(
            {
                "sequence_no": sequence_no,
                "inning": inning,
                "inning_half": half,
                "outs_before": _event_number(element, "outs-before"),
                "base_state_before": element.get("data-base-before", "000"),
                "score_diff_before": _event_number(element, "score-diff-before"),
                "event_type": element.get("data-event-type") or _event_type(text),
                "description": text,
                "runs_scored": _event_number(element, "runs"),
                "outs_after": _event_number(element, "outs-after"),
                "base_state_after": element.get("data-base-after", "000"),
                "score_diff_after": _event_number(element, "score-diff-after"),
                "batter_name": element.get("data-batter"),
                "pitcher_name": element.get("data-pitcher"),
                "batting_team_code": element.get("data-batting-team"),
                "fielding_team_code": element.get("data-fielding-team"),
            }
        )
    return events


def _grid_texts(table_json: str | None) -> list[list[str]]:
    if not table_json:
        return []
    table = json.loads(table_json)
    return [
        [str(cell.get("Text") or "").strip() for cell in row.get("row", [])]
        for row in table.get("rows", [])
    ]


def _base_state_from_description(description: str) -> str:
    if "만루" in description:
        return "111"
    occupied = {int(base) for base in re.findall(r"([123])루", description)}
    return "".join("1" if base in occupied else "0" for base in (1, 2, 3))


def parse_game_events_payload(
    payload: dict[str, Any], *, away_team_code: str, home_team_code: str
) -> list[dict[str, Any]]:
    """Normalize the official KBO review summary into a decisive-hit event.

    Completed game pages populate their event summary through
    GetBoxScoreScroll rather than rendering play-by-play markup in the HTML.
    The first summary row is KBO's official winning-hit record and includes the
    batter, inning, outs and base situation.
    """
    decisive_description: str | None = None
    for cells in _grid_texts(payload.get("tableEtc")):
        if len(cells) >= 2 and cells[0] == "결승타":
            decisive_description = cells[1]
            break
    if not decisive_description or decisive_description in {"없음", "-"}:
        return []

    name_match = re.match(r"\s*(.+?)\s*\(", decisive_description)
    inning_match = re.search(r"(\d+)회", decisive_description)
    if not name_match or not inning_match:
        return []
    batter_name = name_match.group(1).strip()

    batting_team_code: str | None = None
    hitter_groups = payload.get("arrHitter") or []
    for index, group in enumerate(hitter_groups[:2]):
        for cells in _grid_texts(group.get("table1")):
            if batter_name in cells:
                batting_team_code = away_team_code if index == 0 else home_team_code
                break
        if batting_team_code:
            break
    if batting_team_code is None:
        return []

    is_home = batting_team_code == home_team_code
    outs_match = re.search(r"([012])사", decisive_description)
    outs_before = int(outs_match.group(1)) if outs_match else 0
    return [
        {
            "sequence_no": 1,
            "inning": int(inning_match.group(1)),
            "inning_half": "bottom" if is_home else "top",
            "outs_before": outs_before,
            "base_state_before": _base_state_from_description(decisive_description),
            "score_diff_before": 0,
            "event_type": "decisive_hit",
            "description": decisive_description,
            "runs_scored": 1,
            "outs_after": min(2, outs_before + (1 if "희생" in decisive_description else 0)),
            "base_state_after": "000",
            "score_diff_after": 1 if is_home else -1,
            "batter_name": batter_name,
            "pitcher_name": None,
            "batting_team_code": batting_team_code,
            "fielding_team_code": away_team_code if is_home else home_team_code,
        }
    ]


def parse_boxscore_html(
    html: str, external_game_id: str, away_team_code: str, home_team_code: str
) -> dict[str, Any]:
    soup = BeautifulSoup(html, "html.parser")
    batting = [
        *_parse_hitters(soup, "Away", away_team_code),
        *_parse_hitters(soup, "Home", home_team_code),
    ]
    stolen_bases = _parse_stolen_bases(soup)
    for hitter in batting:
        hitter["sb"] = max(hitter["sb"], stolen_bases.get(hitter["player_name"], 0))

    return {
        "external_game_id": external_game_id,
        "batting": batting,
        "pitching": [
            *_parse_pitchers(soup, "Away", away_team_code),
            *_parse_pitchers(soup, "Home", home_team_code),
        ],
    }


class KboSource(BaseballDataSource):
    """Collect KBO data with a locally installed Google Chrome."""

    def __init__(self, *, keep_open: bool | None = None) -> None:
        self._driver: webdriver.Chrome | None = None
        self._month_cache: dict[tuple[int, int], tuple[float, list[dict[str, Any]]]] = {}
        self._keep_open = settings.chrome_keep_open if keep_open is None else keep_open

    def _create_driver(self) -> webdriver.Chrome:
        options = webdriver.ChromeOptions()
        if settings.chrome_headless:
            options.add_argument("--headless=new")
            options.add_argument("--window-size=1920,1080")
            options.add_argument("--disable-gpu")
            options.add_argument("--no-sandbox")
            options.add_argument("--disable-dev-shm-usage")
        else:
            options.add_argument("--start-maximized")
        options.add_experimental_option("excludeSwitches", ["enable-automation"])
        options.add_experimental_option("useAutomationExtension", False)
        if settings.chrome_binary:
            options.binary_location = settings.chrome_binary
        elif Path(r"C:\Program Files\Google\Chrome\Application\chrome.exe").exists():
            options.binary_location = r"C:\Program Files\Google\Chrome\Application\chrome.exe"
        if settings.chrome_user_data_dir:
            options.add_argument(f"--user-data-dir={settings.chrome_user_data_dir}")
        if self._keep_open:
            options.add_experimental_option("detach", True)
        return webdriver.Chrome(options=options)

    def _load_month(self, year: int, month: int) -> list[dict[str, Any]]:
        cache_key = (year, month)
        cached = self._month_cache.get(cache_key)
        if cached and time_module.monotonic() - cached[0] < settings.chrome_cache_ttl_seconds:
            return cached[1]

        if self._driver is None:
            self._driver = self._create_driver()
            self._driver.get(f"{settings.kbo_base_url}/Schedule/Schedule.aspx")

        wait = WebDriverWait(self._driver, settings.chrome_page_timeout_seconds)
        wait.until(lambda driver: driver.find_elements(By.CSS_SELECTOR, "table.tbl"))

        Select(self._driver.find_element(By.ID, "ddlYear")).select_by_value(str(year))
        Select(self._driver.find_element(By.ID, "ddlMonth")).select_by_value(f"{month:02d}")
        wait.until(
            lambda driver: Select(driver.find_element(By.ID, "ddlYear"))
            .first_selected_option.get_attribute("value")
            == str(year)
            and Select(driver.find_element(By.ID, "ddlMonth"))
            .first_selected_option.get_attribute("value")
            == f"{month:02d}"
        )
        time_module.sleep(settings.chrome_page_settle_seconds)

        games = parse_schedule_html(self._driver.page_source, year, month)
        self._month_cache[cache_key] = (time_module.monotonic(), games)
        return games

    async def fetch_schedule(self, target_date: date) -> list[dict[str, Any]]:
        games = await asyncio.to_thread(self._load_month, target_date.year, target_date.month)
        return [game for game in games if game["game_date"] == target_date]

    async def fetch_live_games(self, target_date: date) -> list[dict[str, Any]]:
        # Live polling must bypass the monthly schedule cache. Otherwise a
        # 10-second scheduler still returns the same page for the cache TTL.
        self._month_cache.pop((target_date.year, target_date.month), None)
        games = await self.fetch_schedule(target_date)
        return [game for game in games if game["status"] in {"in_progress", "completed"}]

    async def fetch_boxscore(self, external_game_id: str) -> dict[str, Any]:
        return await asyncio.to_thread(self._fetch_boxscore, external_game_id)

    async def fetch_game_events(self, external_game_id: str) -> list[dict[str, Any]]:
        return await asyncio.to_thread(self._fetch_game_events, external_game_id)

    def _fetch_boxscore(self, external_game_id: str) -> dict[str, Any]:
        if self._driver is None:
            self._driver = self._create_driver()
        game_date, away_code, home_code = _game_id_parts(external_game_id)
        url = (
            f"{settings.kbo_base_url}/Schedule/GameCenter/Main.aspx"
            f"?gameDate={game_date}&gameId={external_game_id}&section=REVIEW"
        )
        self._driver.get(url)
        wait = WebDriverWait(self._driver, settings.chrome_page_timeout_seconds)
        wait.until(lambda driver: driver.find_elements(By.ID, "tblAwayPitcher"))
        time_module.sleep(settings.chrome_boxscore_settle_seconds)
        return parse_boxscore_html(
            self._driver.page_source, external_game_id, away_code, home_code
        )

    def _fetch_game_events(self, external_game_id: str) -> list[dict[str, Any]]:
        _, away_code, home_code = _game_id_parts(external_game_id)
        body = urlencode(
            {
                "leId": "1",
                "srId": "0",
                "seasonId": external_game_id[:4],
                "gameId": external_game_id,
            }
        ).encode("utf-8")
        request = Request(
            f"{settings.kbo_base_url.rstrip('/')}/ws/Schedule.asmx/GetBoxScoreScroll",
            data=body,
            headers={
                "Content-Type": "application/x-www-form-urlencoded; charset=UTF-8",
                "Referer": settings.kbo_event_url_template.format(
                    base_url=settings.kbo_base_url.rstrip("/"),
                    game_date=external_game_id[:8],
                    game_id=external_game_id,
                ),
                "X-Requested-With": "XMLHttpRequest",
                "User-Agent": "Mozilla/5.0",
            },
        )
        with urlopen(request, timeout=settings.chrome_page_timeout_seconds) as response:
            payload = json.loads(response.read().decode("utf-8"))
        if str(payload.get("code")) != "100":
            raise ValueError(
                f"KBO review summary failed for game={external_game_id}: "
                f"{payload.get('msg') or payload.get('code')}"
            )
        return parse_game_events_payload(
            payload, away_team_code=away_code, home_team_code=home_code
        )

    async def aclose(self) -> None:
        if self._driver is not None and not self._keep_open:
            await asyncio.to_thread(self._driver.quit)
        self._driver = None
