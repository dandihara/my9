import logging
from typing import Any

from worker.db import get_conn
from worker.sources.base import BaseballDataSource
from worker.jobs.refresh_season_metrics import refresh_season_metrics


logger = logging.getLogger("seungyo.worker.boxscore")


def _ensure_player(conn: Any, item: dict[str, Any]) -> int:
    row = conn.execute(
        "SELECT id FROM players WHERE external_player_id = %s",
        (item["external_player_id"],),
    ).fetchone()
    if row:
        return row[0]
    return conn.execute(
        """
        INSERT INTO players (name, external_player_id)
        VALUES (%s, %s)
        RETURNING id
        """,
        (item["player_name"], item["external_player_id"]),
    ).fetchone()[0]


def _event_player_payload(
    event: dict[str, Any], name_key: str, team_code_key: str
) -> dict[str, Any] | None:
    player_name = event.get(name_key)
    team_code = event.get(team_code_key)
    if not player_name or not team_code:
        return None
    return {
        "player_name": player_name,
        "external_player_id": f"kbo:{team_code}:{player_name}",
    }


def _normalize_event_scores(
    events: list[dict[str, Any]],
    *,
    away_team_id: int,
    home_team_id: int,
) -> list[dict[str, Any]]:
    normalized: list[dict[str, Any]] = []
    score_diff = 0
    for event in events:
        item = dict(event)
        runs = int(item.get("runs_scored") or 0)
        batting_team_id = item.get("batting_team_id")
        if batting_team_id == away_team_id:
            expected_delta = -runs
        elif batting_team_id == home_team_id:
            expected_delta = runs
        else:
            expected_delta = 0
        calculated_after = score_diff + expected_delta

        parsed_before = int(item.get("score_diff_before") or 0)
        parsed_after = int(item.get("score_diff_after") or 0)
        parsed_delta = parsed_after - parsed_before
        has_parsed_score = (
            parsed_before == score_diff and parsed_delta == expected_delta
        )
        has_inferable_parsed_score = (
            runs == 0 and parsed_before == score_diff and parsed_delta != 0
        )

        if has_parsed_score or has_inferable_parsed_score:
            if has_inferable_parsed_score:
                item["runs_scored"] = abs(parsed_delta)
            item["score_diff_before"] = parsed_before
            item["score_diff_after"] = parsed_after
            score_diff = parsed_after
        else:
            item["score_diff_before"] = score_diff
            item["score_diff_after"] = calculated_after
            score_diff = calculated_after
        normalized.append(item)
    return normalized


def _sync_game_events(
    conn: Any,
    *,
    game_id: int,
    away_team_id: int,
    home_team_id: int,
    team_ids: dict[str, int],
    events: list[dict[str, Any]],
) -> int:
    conn.execute(
        """
        DELETE FROM wpa_events w
        USING game_events e
        WHERE w.game_event_id = e.id AND e.game_id = %s
        """,
        (game_id,),
    )
    conn.execute("DELETE FROM player_game_wpa WHERE game_id = %s", (game_id,))
    conn.execute("DELETE FROM game_events WHERE game_id = %s", (game_id,))
    prepared_events = []
    for event in events:
        batting_team_id = team_ids.get(event.get("batting_team_code"))
        fielding_team_id = team_ids.get(event.get("fielding_team_code"))
        if batting_team_id is None:
            batting_team_id = (
                away_team_id if event.get("inning_half") == "top" else home_team_id
            )
        if fielding_team_id is None:
            fielding_team_id = (
                home_team_id if batting_team_id == away_team_id else away_team_id
            )

        item = {
            **event,
            "batting_team_id": batting_team_id,
            "fielding_team_id": fielding_team_id,
        }
        batter = _event_player_payload(item, "batter_name", "batting_team_code")
        pitcher = _event_player_payload(item, "pitcher_name", "fielding_team_code")
        item["batter_id"] = _ensure_player(conn, batter) if batter else None
        item["pitcher_id"] = _ensure_player(conn, pitcher) if pitcher else None
        prepared_events.append(item)

    normalized_events = _normalize_event_scores(
        prepared_events,
        away_team_id=away_team_id,
        home_team_id=home_team_id,
    )
    for event in normalized_events:
        conn.execute(
            """
            INSERT INTO game_events (
                game_id, sequence_no, inning, inning_half, batting_team_id,
                fielding_team_id, batter_id, pitcher_id, outs_before,
                base_state_before, score_diff_before, event_type, description,
                runs_scored, outs_after, base_state_after, score_diff_after
            ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
            """,
            (
                game_id,
                event["sequence_no"],
                event["inning"],
                event["inning_half"],
                event["batting_team_id"],
                event["fielding_team_id"],
                event["batter_id"],
                event["pitcher_id"],
                event["outs_before"],
                event["base_state_before"],
                event["score_diff_before"],
                event["event_type"],
                event["description"],
                event["runs_scored"],
                event["outs_after"],
                event["base_state_after"],
                event["score_diff_after"],
            ),
        )
    _sync_game_wpa(conn, game_id=game_id, home_team_id=home_team_id)
    return len(normalized_events)


def _lookup_win_expectancy(
    conn: Any,
    *,
    season_year: int,
    inning: int,
    inning_half: str,
    outs: int,
    base_state: str,
    score_diff: int,
) -> float | None:
    row = conn.execute(
        """
        SELECT win_expectancy
        FROM win_expectancy_table
        WHERE season_year = %s
          AND inning = %s
          AND inning_half = %s
          AND outs = %s
          AND base_state = %s
        ORDER BY ABS(score_diff - %s)
        LIMIT 1
        """,
        (season_year, inning, inning_half, outs, base_state, score_diff),
    ).fetchone()
    if row:
        return float(row[0])
    return _estimate_win_expectancy(
        inning=inning,
        inning_half=inning_half,
        outs=outs,
        base_state=base_state,
        score_diff=score_diff,
    )


def _estimate_win_expectancy(
    *,
    inning: int,
    inning_half: str,
    outs: int,
    base_state: str,
    score_diff: int,
) -> float:
    score_component = score_diff * 0.08
    inning_component = min(inning, 12) * 0.01
    out_component = min(outs, 2) * -0.015
    base_component = base_state.count("1") * 0.02
    home_half_bonus = 0.015 if inning_half == "bottom" else 0.0
    raw = (
        0.5
        + score_component
        + inning_component
        + out_component
        + base_component
        + home_half_bonus
    )
    return max(0.01, min(0.99, raw))


def _terminal_win_expectancy(score_diff: int) -> float:
    if score_diff > 0:
        return 1.0
    if score_diff < 0:
        return 0.0
    return 0.5


def _is_terminal_after(
    *,
    inning: int,
    inning_half: str,
    outs_after: int,
    score_diff_after: int,
) -> bool:
    if inning < 9:
        return False
    if inning_half == "bottom" and score_diff_after > 0:
        return True
    if outs_after < 3:
        return False
    if inning_half == "top":
        return score_diff_after > 0
    return score_diff_after != 0


def _next_state_after_half_inning(
    *,
    inning: int,
    inning_half: str,
    outs_after: int,
    base_state_after: str,
) -> tuple[int, str, int, str]:
    if outs_after < 3:
        return inning, inning_half, outs_after, base_state_after
    if inning_half == "top":
        return inning, "bottom", 0, "000"
    return inning + 1, "top", 0, "000"


def _sync_game_wpa(conn: Any, *, game_id: int, home_team_id: int) -> int:
    game = conn.execute(
        "SELECT season_year FROM games WHERE id = %s",
        (game_id,),
    ).fetchone()
    if not game:
        return 0
    season_year = game[0]
    events = conn.execute(
        """
        SELECT id, inning, inning_half, batting_team_id, fielding_team_id,
               batter_id, pitcher_id, outs_before, base_state_before,
               score_diff_before, outs_after, base_state_after, score_diff_after
        FROM game_events
        WHERE game_id = %s
        ORDER BY sequence_no
        """,
        (game_id,),
    ).fetchall()
    totals: dict[tuple[int, int | None], dict[str, float]] = {}
    inserted = 0
    for event in events:
        (
            event_id,
            inning,
            inning_half,
            batting_team_id,
            fielding_team_id,
            batter_id,
            pitcher_id,
            outs_before,
            base_state_before,
            score_diff_before,
            outs_after,
            base_state_after,
            score_diff_after,
        ) = event
        we_before = _lookup_win_expectancy(
            conn,
            season_year=season_year,
            inning=inning,
            inning_half=inning_half,
            outs=outs_before,
            base_state=base_state_before,
            score_diff=score_diff_before,
        )
        if _is_terminal_after(
            inning=inning,
            inning_half=inning_half,
            outs_after=outs_after,
            score_diff_after=score_diff_after,
        ):
            we_after = _terminal_win_expectancy(score_diff_after)
        else:
            after_inning, after_half, after_outs, after_bases = (
                _next_state_after_half_inning(
                    inning=inning,
                    inning_half=inning_half,
                    outs_after=outs_after,
                    base_state_after=base_state_after,
                )
            )
            we_after = _lookup_win_expectancy(
                conn,
                season_year=season_year,
                inning=after_inning,
                inning_half=after_half,
                outs=after_outs,
                base_state=after_bases,
                score_diff=score_diff_after,
            )
        if we_before is None or we_after is None:
            continue
        batting_wpa = we_after - we_before
        if batting_team_id != home_team_id:
            batting_wpa = -batting_wpa
        pitching_wpa = -batting_wpa
        conn.execute(
            """
            INSERT INTO wpa_events (
                game_event_id, batter_id, pitcher_id, we_before, we_after, wpa
            ) VALUES (%s, %s, %s, %s, %s, %s)
            """,
            (
                event_id,
                batter_id,
                pitcher_id,
                round(we_before, 5),
                round(we_after, 5),
                round(batting_wpa, 5),
            ),
        )
        inserted += 1
        if batter_id is not None:
            batter_key = (batter_id, batting_team_id)
            batter_total = totals.setdefault(
                batter_key, {"batting": 0.0, "pitching": 0.0}
            )
            batter_total["batting"] += batting_wpa
        if pitcher_id is not None:
            pitcher_key = (pitcher_id, fielding_team_id)
            pitcher_total = totals.setdefault(
                pitcher_key, {"batting": 0.0, "pitching": 0.0}
            )
            pitcher_total["pitching"] += pitching_wpa
    for (player_id, team_id), values in totals.items():
        batting = values["batting"]
        pitching = values["pitching"]
        conn.execute(
            """
            INSERT INTO player_game_wpa (
                game_id, player_id, team_id, batting_wpa, pitching_wpa, total_wpa
            ) VALUES (%s, %s, %s, %s, %s, %s)
            """,
            (
                game_id,
                player_id,
                team_id,
                round(batting, 5),
                round(pitching, 5),
                round(batting + pitching, 5),
            ),
        )
    return inserted


def sync_boxscore(
    boxscore: dict[str, Any],
    *,
    game_events: list[dict[str, Any]] | None = None,
    finalize: bool = False,
) -> tuple[int, int]:
    with get_conn() as conn:
        game = conn.execute(
            """
            SELECT id, away_team_id, home_team_id
            FROM games
            WHERE external_source = 'kbo' AND external_game_id = %s
            """,
            (boxscore["external_game_id"],),
        ).fetchone()
        if not game:
            raise ValueError(f"Game not found: {boxscore['external_game_id']}")
        game_id, away_team_id, home_team_id = game
        team_ids = dict(conn.execute("SELECT code, id FROM teams").fetchall())

        conn.execute("DELETE FROM batting_game_stats WHERE game_id = %s", (game_id,))
        conn.execute("DELETE FROM pitching_game_stats WHERE game_id = %s", (game_id,))
        if game_events is not None:
            _sync_game_events(
                conn,
                game_id=game_id,
                away_team_id=away_team_id,
                home_team_id=home_team_id,
                team_ids=team_ids,
                events=game_events,
            )

        for item in boxscore["batting"]:
            player_id = _ensure_player(conn, item)
            conn.execute(
                """
                INSERT INTO batting_game_stats (
                    game_id, player_id, team_id, batting_order, position,
                    ab, r, h, doubles, triples, hr, rbi, bb, hbp, sf, so,
                    sb, avg_after_game
                ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                """,
                (
                    game_id,
                    player_id,
                    team_ids[item["team_code"]],
                    item["batting_order"],
                    item["position"],
                    item["ab"],
                    item["r"],
                    item["h"],
                    item["doubles"],
                    item["triples"],
                    item["hr"],
                    item["rbi"],
                    item["bb"],
                    item["hbp"],
                    item["sf"],
                    item["so"],
                    item["sb"],
                    item["avg_after_game"],
                ),
            )

        for item in boxscore["pitching"]:
            player_id = _ensure_player(conn, item)
            conn.execute(
                """
                INSERT INTO pitching_game_stats (
                    game_id, player_id, team_id, innings_pitched, hits, runs,
                    earned_runs, walks, strikeouts, pitches, era_after_game,
                    home_runs, batters_faced, decision
                ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                """,
                (
                    game_id,
                    player_id,
                    team_ids[item["team_code"]],
                    item["innings_pitched"],
                    item["hits"],
                    item["runs"],
                    item["earned_runs"],
                    item["walks"],
                    item["strikeouts"],
                    item["pitches"],
                    item["era_after_game"],
                    item["home_runs"],
                    item["batters_faced"],
                    item["decision"],
                ),
            )

        if finalize:
            conn.execute(
                "UPDATE games SET boxscore_finalized_at = now() WHERE id = %s",
                (game_id,),
            )

    return len(boxscore["batting"]), len(boxscore["pitching"])


async def _fetch_game_events_or_none(
    source: BaseballDataSource, external_game_id: str
) -> list[dict[str, Any]] | None:
    try:
        return await source.fetch_game_events(external_game_id)
    except Exception:
        logger.exception("game event sync failed game_id=%s", external_game_id)
        return None


def _completed_game_ids(target_date) -> list[str]:
    with get_conn() as conn:
        rows = conn.execute(
            """
            SELECT external_game_id
            FROM games
            WHERE external_source = 'kbo'
              AND status = 'completed'
              AND game_date = %s
              AND boxscore_finalized_at IS NULL
            ORDER BY game_time, external_game_id
            """,
            (target_date,),
        ).fetchall()
    return [row[0] for row in rows]


async def sync_completed_boxscores(
    source: BaseballDataSource, target_date
) -> tuple[int, int, int]:
    game_ids = _completed_game_ids(target_date)
    batting_total = pitching_total = 0
    for game_id in game_ids:
        boxscore = await source.fetch_boxscore(game_id)
        game_events = await _fetch_game_events_or_none(source, game_id)
        batting_count, pitching_count = sync_boxscore(
            boxscore, game_events=game_events, finalize=True
        )
        batting_total += batting_count
        pitching_total += pitching_count
    refresh_season_metrics(target_date.year)
    return len(game_ids), batting_total, pitching_total


def _started_games(target_date, current_time) -> list[tuple[str, str]]:
    with get_conn() as conn:
        rows = conn.execute(
            """
            SELECT external_game_id, status
            FROM games
            WHERE external_source = 'kbo'
              AND game_date = %s
              AND game_time IS NOT NULL
              AND game_time <= %s
              AND status IN ('in_progress', 'completed')
              AND external_game_id IS NOT NULL
              AND (status <> 'completed' OR boxscore_finalized_at IS NULL)
            ORDER BY game_time, external_game_id
            """,
            (target_date, current_time),
        ).fetchall()
    return [(row[0], row[1]) for row in rows]


async def sync_started_boxscores(
    source: BaseballDataSource, target_date, current_time
) -> tuple[int, int, int, int]:
    games = _started_games(target_date, current_time)
    synced = batting_total = pitching_total = 0
    for game_id, status in games:
        try:
            boxscore = await source.fetch_boxscore(game_id)
            game_events = await _fetch_game_events_or_none(source, game_id)
            batting_count, pitching_count = sync_boxscore(
                boxscore, game_events=game_events, finalize=status == "completed"
            )
            synced += 1
            batting_total += batting_count
            pitching_total += pitching_count
        except Exception:
            logger.exception("boxscore sync failed game_id=%s status=%s", game_id, status)
    if synced:
        refresh_season_metrics(target_date.year)
    return len(games), synced, batting_total, pitching_total
