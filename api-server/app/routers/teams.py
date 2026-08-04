from datetime import datetime, timedelta, timezone
from zoneinfo import ZoneInfo

from fastapi import APIRouter, Depends
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.session import get_db
from app.models.game import Game
from app.models.stadium import Stadium
from app.models.stat import BattingGameStat, PitchingGameStat
from app.models.team import Team
from app.schemas.team import (
    TeamDashboardGameRead,
    TeamDashboardRead,
    TeamRead,
    TeamSeasonSummaryRead,
    TeamStandingsRead,
)
from app.services.weather import fetch_stadium_weather

router = APIRouter()
KST = ZoneInfo("Asia/Seoul")
STANDINGS_CACHE_TTL = timedelta(seconds=60)
_standings_cache: dict[int, tuple[datetime, TeamStandingsRead]] = {}


def _outs(innings: float | None) -> int:
    value = float(innings or 0)
    whole = int(value)
    return whole * 3 + int(round((value - whole) * 10))


def _record(games: list[Game], team_id: int) -> tuple[int, int, int, int, int]:
    wins = losses = draws = scored = allowed = 0
    for game in games:
        if team_id not in (game.home_team_id, game.away_team_id):
            continue
        mine, opponent = (
            (game.home_score, game.away_score)
            if game.home_team_id == team_id
            else (game.away_score, game.home_score)
        )
        scored += int(mine or 0)
        allowed += int(opponent or 0)
        if mine > opponent:
            wins += 1
        elif mine < opponent:
            losses += 1
        else:
            draws += 1
    return wins, losses, draws, scored, allowed


async def _standings(db: AsyncSession, season_year: int | None) -> TeamStandingsRead:
    if season_year is None:
        season_year = await db.scalar(select(func.max(Game.season_year)))
    if season_year is None:
        season_year = datetime.now(KST).year
    cached = _standings_cache.get(season_year)
    now = datetime.now(timezone.utc)
    if cached is not None and now - cached[0] < STANDINGS_CACHE_TTL:
        return cached[1]
    teams = list((await db.execute(select(Team).order_by(Team.name))).scalars().all())
    games = list(
        (
            await db.execute(
                select(Game).where(
                    Game.season_year == season_year,
                    Game.status == "completed",
                    Game.home_score.is_not(None),
                    Game.away_score.is_not(None),
                )
            )
        ).scalars().all()
    )
    game_ids = [game.id for game in games]
    batting_by_team: dict[int, dict[str, int]] = {}
    pitching_by_team: dict[int, dict[str, int]] = {}
    if game_ids:
        batting_stats = list(
            (
                await db.execute(
                    select(BattingGameStat).where(
                        BattingGameStat.game_id.in_(game_ids)
                    )
                )
            ).scalars().all()
        )
        for stat in batting_stats:
            totals = batting_by_team.setdefault(
                stat.team_id,
                {
                    "ab": 0,
                    "h": 0,
                    "hr": 0,
                    "bb": 0,
                    "hbp": 0,
                    "sf": 0,
                    "doubles": 0,
                    "triples": 0,
                },
            )
            for field in totals:
                totals[field] += int(getattr(stat, field) or 0)

        pitching_stats = list(
            (
                await db.execute(
                    select(PitchingGameStat).where(
                        PitchingGameStat.game_id.in_(game_ids)
                    )
                )
            ).scalars().all()
        )
        for stat in pitching_stats:
            totals = pitching_by_team.setdefault(
                stat.team_id,
                {"outs": 0, "hits": 0, "walks": 0, "earned_runs": 0, "strikeouts": 0},
            )
            totals["outs"] += _outs(stat.innings_pitched)
            for field in ("hits", "walks", "earned_runs", "strikeouts"):
                totals[field] += int(getattr(stat, field) or 0)

    rows = []
    for team in teams:
        wins, losses, draws, scored, allowed = _record(games, team.id)
        batting = batting_by_team.get(team.id, {})
        pitching = pitching_by_team.get(team.id, {})
        ab = batting.get("ab", 0)
        hits = batting.get("h", 0)
        walks = batting.get("bb", 0)
        hbp = batting.get("hbp", 0)
        sf = batting.get("sf", 0)
        total_bases = (
            hits
            + batting.get("doubles", 0)
            + batting.get("triples", 0) * 2
            + batting.get("hr", 0) * 3
        )
        obp_denominator = ab + walks + hbp + sf
        innings = pitching.get("outs", 0) / 3
        recent_games = sorted(
            [game for game in games if team.id in (game.home_team_id, game.away_team_id)],
            key=lambda game: (
                game.game_date,
                game.game_time or datetime.min.time(),
                game.id,
            ),
            reverse=True,
        )[:10]
        recent_wins, recent_losses, recent_draws, _, _ = _record(
            recent_games, team.id
        )
        decisions = wins + losses
        rows.append(
            {
                "team": team,
                "games": wins + losses + draws,
                "wins": wins,
                "losses": losses,
                "draws": draws,
                "scored": scored,
                "allowed": allowed,
                "rate": wins / decisions if decisions else 0,
                "recent_wins": recent_wins,
                "recent_losses": recent_losses,
                "recent_draws": recent_draws,
                "team_batting_average": round(hits / ab, 3) if ab else 0,
                "team_on_base_percentage": (
                    round((hits + walks + hbp) / obp_denominator, 3)
                    if obp_denominator
                    else 0
                ),
                "team_slugging_percentage": (
                    round(total_bases / ab, 3) if ab else 0
                ),
                "team_hits": hits,
                "team_home_runs": batting.get("hr", 0),
                "team_era": (
                    round(pitching.get("earned_runs", 0) * 9 / innings, 2)
                    if innings
                    else 0
                ),
                "team_whip": (
                    round(
                        (pitching.get("hits", 0) + pitching.get("walks", 0))
                        / innings,
                        2,
                    )
                    if innings
                    else 0
                ),
                "team_strikeouts": pitching.get("strikeouts", 0),
            }
        )
    rows.sort(
        key=lambda row: (
            row["rate"], row["wins"], row["scored"] - row["allowed"]
        ),
        reverse=True,
    )
    result = TeamStandingsRead(
        season_year=season_year,
        as_of_date=max((game.game_date for game in games), default=None),
        standings=[
            TeamSeasonSummaryRead(
                season_year=season_year,
                team_id=row["team"].id,
                team_name=row["team"].name,
                rank=rank,
                games=row["games"],
                wins=row["wins"],
                losses=row["losses"],
                draws=row["draws"],
                win_rate=round(row["rate"] * 100, 1),
                runs_scored=row["scored"],
                runs_allowed=row["allowed"],
                run_difference=row["scored"] - row["allowed"],
                recent_10_wins=row["recent_wins"],
                recent_10_draws=row["recent_draws"],
                recent_10_losses=row["recent_losses"],
                team_batting_average=row["team_batting_average"],
                team_on_base_percentage=row["team_on_base_percentage"],
                team_slugging_percentage=row["team_slugging_percentage"],
                team_ops=round(
                    row["team_on_base_percentage"]
                    + row["team_slugging_percentage"],
                    3,
                ),
                team_hits=row["team_hits"],
                team_home_runs=row["team_home_runs"],
                team_era=row["team_era"],
                team_whip=row["team_whip"],
                team_strikeouts=row["team_strikeouts"],
            )
            for rank, row in enumerate(rows, 1)
        ],
    )
    _standings_cache[season_year] = (now, result)
    return result


@router.get("", response_model=list[TeamRead])
async def list_teams(db: AsyncSession = Depends(get_db)) -> list[Team]:
    result = await db.execute(select(Team).order_by(Team.name))
    return list(result.scalars().all())


@router.get("/standings", response_model=TeamStandingsRead)
async def list_standings(
    season_year: int | None = None,
    db: AsyncSession = Depends(get_db),
) -> TeamStandingsRead:
    return await _standings(db, season_year)


@router.get("/{team_id}", response_model=TeamRead)
async def get_team(team_id: int, db: AsyncSession = Depends(get_db)) -> Team:
    return await db.get_one(Team, team_id)


@router.get("/{team_id}/dashboard", response_model=TeamDashboardRead)
async def get_team_dashboard(
    team_id: int,
    db: AsyncSession = Depends(get_db),
) -> TeamDashboardRead:
    team = await db.get_one(Team, team_id)
    season_year = await db.scalar(select(func.max(Game.season_year)))
    season_year = season_year or datetime.now(KST).year
    completed_games = list(
        (
            await db.execute(
                select(Game).where(
                    Game.season_year == season_year,
                    Game.status == "completed",
                    Game.home_score.is_not(None),
                    Game.away_score.is_not(None),
                )
            )
        ).scalars().all()
    )
    teams = {
        item.id: item.name
        for item in (await db.execute(select(Team))).scalars().all()
    }
    ranked = []
    for candidate_id in teams:
        wins, losses, draws, scored, allowed = _record(completed_games, candidate_id)
        decisions = wins + losses
        ranked.append((candidate_id, wins, losses, draws, scored, allowed,
                       wins / decisions if decisions else 0))
    ranked.sort(key=lambda row: (row[6], row[1], row[4] - row[5]), reverse=True)
    rank, row = next(
        (rank, row) for rank, row in enumerate(ranked, start=1) if row[0] == team_id
    )
    summary = TeamSeasonSummaryRead(
        season_year=season_year, team_id=team_id, team_name=team.name,
        rank=rank, games=row[1] + row[2] + row[3], wins=row[1], losses=row[2],
        draws=row[3], win_rate=round(row[6] * 100, 1), runs_scored=row[4],
        runs_allowed=row[5], run_difference=row[4] - row[5],
        recent_10_wins=0, recent_10_draws=0, recent_10_losses=0,
    )
    stadiums = {
        item.id: item
        for item in (await db.execute(select(Stadium))).scalars().all()
    }
    team_games = list(
        (
            await db.execute(
                select(Game).where(
                    Game.season_year == season_year,
                    (Game.home_team_id == team_id) | (Game.away_team_id == team_id),
                )
            )
        ).scalars().all()
    )

    def read_game(game: Game) -> TeamDashboardGameRead:
        is_home = game.home_team_id == team_id
        opponent_id = game.away_team_id if is_home else game.home_team_id
        my_score = game.home_score if is_home else game.away_score
        opponent_score = game.away_score if is_home else game.home_score
        result = None
        if my_score is not None and opponent_score is not None:
            result = "win" if my_score > opponent_score else "loss" if my_score < opponent_score else "draw"
        return TeamDashboardGameRead(
            game_id=game.id,
            game_date=game.game_date,
            game_time=game.game_time,
            opponent_name=teams[opponent_id],
            is_home=is_home,
            stadium_name=(
                stadiums[game.stadium_id].name
                if game.stadium_id in stadiums
                else None
            ),
            my_score=my_score,
            opponent_score=opponent_score,
            result=result,
        )

    completed = sorted(
        (game for game in team_games if game.status == "completed"),
        key=lambda game: (game.game_date, game.game_time or datetime.min.time()),
        reverse=True,
    )[:5]
    today = datetime.now(KST).date()
    upcoming = sorted(
        (
            game
            for game in team_games
            if game.game_date >= today and game.status in {"scheduled", "in_progress"}
        ),
        key=lambda game: (game.game_date, game.game_time or datetime.max.time()),
    )
    today_games = [
        game
        for game in team_games
        if game.game_date == today and game.status not in {"cancelled", "postponed"}
    ]
    weather_game = (
        next((game for game in today_games if game.status == "in_progress"), None)
        or next((game for game in today_games if game.status == "scheduled"), None)
        or max(
            today_games,
            key=lambda game: (game.game_time or datetime.min.time(), game.id),
            default=None,
        )
    )
    stadium_weather = None
    if (
        weather_game is not None
        and weather_game.stadium_id is not None
        and weather_game.stadium_id in stadiums
    ):
        stadium_weather = await fetch_stadium_weather(
            stadiums[weather_game.stadium_id],
            game_id=weather_game.id,
        )
    return TeamDashboardRead(
        summary=summary,
        recent_games=[read_game(game) for game in completed],
        next_game=read_game(upcoming[0]) if upcoming else None,
        stadium_weather=stadium_weather,
    )


@router.get("/{team_id}/season", response_model=TeamSeasonSummaryRead)
async def get_team_season(
    team_id: int,
    season_year: int | None = None,
    db: AsyncSession = Depends(get_db),
) -> TeamSeasonSummaryRead:
    await db.get_one(Team, team_id)
    data = await _standings(db, season_year)
    return next(row for row in data.standings if row.team_id == team_id)
