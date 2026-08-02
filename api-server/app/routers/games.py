from datetime import date
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import aliased

from app.db.session import get_db
from app.models.game import Game, GameLiveState
from app.models.player import Player
from app.models.stadium import Stadium
from app.models.stat import BattingGameStat, PitchingGameStat
from app.models.team import Team
from app.models.wpa import GameEvent
from app.schemas.game import GameRead, GameStatsRead, LiveGameRead
from app.services.decisive_hit import find_decisive_event


router = APIRouter()


def _game_read(
    game: Game, away_name: str, home_name: str, stadium_name: str | None
) -> GameRead:
    return GameRead(
        **game.__dict__,
        away_team_name=away_name,
        home_team_name=home_name,
        stadium_name=stadium_name,
    )


def _game_query():
    away = aliased(Team)
    home = aliased(Team)
    return (
        select(Game, away.name, home.name, Stadium.name)
        .join(away, away.id == Game.away_team_id)
        .join(home, home.id == Game.home_team_id)
        .outerjoin(Stadium, Stadium.id == Game.stadium_id)
    )


@router.get("", response_model=list[GameRead])
async def list_games(
    date_: date | None = Query(default=None, alias="date"),
    from_date: date | None = None,
    to_date: date | None = None,
    db: AsyncSession = Depends(get_db),
) -> list[GameRead]:
    stmt = _game_query().order_by(Game.game_date, Game.game_time)
    if date_:
        stmt = stmt.where(Game.game_date == date_)
    if from_date:
        stmt = stmt.where(Game.game_date >= from_date)
    if to_date:
        stmt = stmt.where(Game.game_date <= to_date)
    rows = (await db.execute(stmt)).all()
    return [_game_read(*row) for row in rows]


@router.get("/live/today", response_model=list[LiveGameRead])
async def list_today_live_games(db: AsyncSession = Depends(get_db)) -> list[LiveGameRead]:
    games = await list_games(date.today(), None, None, db)
    payload: list[LiveGameRead] = []
    for game in games:
        live = await db.scalar(select(GameLiveState).where(GameLiveState.game_id == game.id))
        payload.append(
            LiveGameRead(
                game=game,
                inning=live.inning if live else None,
                inning_half=live.inning_half if live else None,
                outs=live.outs if live else None,
                base_state=live.base_state if live else None,
                description=live.description if live else None,
            )
        )
    return payload


@router.get("/{game_id}", response_model=GameRead)
async def get_game(game_id: int, db: AsyncSession = Depends(get_db)) -> GameRead:
    row = (await db.execute(_game_query().where(Game.id == game_id))).one_or_none()
    if row is None:
        raise HTTPException(status_code=404, detail="경기를 찾을 수 없습니다.")
    return _game_read(*row)


@router.get("/{game_id}/stats", response_model=GameStatsRead)
async def get_game_stats(game_id: int, db: AsyncSession = Depends(get_db)) -> GameStatsRead:
    game = await db.get(Game, game_id)
    if game is None:
        raise HTTPException(status_code=404, detail="경기를 찾을 수 없습니다.")
    batting_rows = (
        await db.execute(
            select(BattingGameStat, Player.name, Team.name)
            .join(Player, Player.id == BattingGameStat.player_id)
            .join(Team, Team.id == BattingGameStat.team_id)
            .where(BattingGameStat.game_id == game_id)
            .order_by(Team.id, BattingGameStat.batting_order, BattingGameStat.id)
        )
    ).all()

    decisive_player_id: int | None = None
    walkoff_home_run_player_id: int | None = None
    if game.home_score is not None and game.away_score is not None and game.home_score != game.away_score:
        winning_team_id = game.home_team_id if game.home_score > game.away_score else game.away_team_id
        winner_sign = 1 if winning_team_id == game.home_team_id else -1
        event_rows = (await db.execute(
            select(GameEvent)
            .where(GameEvent.game_id == game_id)
            .order_by(GameEvent.sequence_no)
        )).scalars().all()
        event = find_decisive_event(
            event_rows,
            winning_team_id=winning_team_id,
            winner_sign=winner_sign,
        )
        if event is not None:
            decisive_player_id = event.batter_id
            if (
                winning_team_id == game.home_team_id
                and event.inning_half.lower() in {"bottom", "말"}
                and event.event_type == "home_run"
            ):
                walkoff_home_run_player_id = event.batter_id
    pitching_rows = (
        await db.execute(
            select(PitchingGameStat, Player.name, Team.name)
            .join(Player, Player.id == PitchingGameStat.player_id)
            .join(Team, Team.id == PitchingGameStat.team_id)
            .where(PitchingGameStat.game_id == game_id)
            .order_by(Team.id, PitchingGameStat.id)
        )
    ).all()

    def batting_item(row):
        stat, player_name, team_name = row
        return {
            **stat.__dict__,
            "player_name": player_name,
            "team_name": team_name,
            "avg_after_game": float(stat.avg_after_game) if stat.avg_after_game is not None else None,
            "decisive_hit": stat.player_id == decisive_player_id,
            "walkoff_home_run": stat.player_id == walkoff_home_run_player_id,
        }

    def pitching_item(row):
        stat, player_name, team_name = row
        return {
            **stat.__dict__,
            "player_name": player_name,
            "team_name": team_name,
            "innings_pitched": (
                float(stat.innings_pitched) if stat.innings_pitched is not None else None
            ),
            "era_after_game": (
                float(stat.era_after_game) if stat.era_after_game is not None else None
            ),
        }

    return GameStatsRead(
        batting=[batting_item(row) for row in batting_rows],
        pitching=[pitching_item(row) for row in pitching_rows],
    )


@router.get("/{game_id}/live", response_model=LiveGameRead)
async def get_live_game(game_id: int, db: AsyncSession = Depends(get_db)) -> LiveGameRead:
    game = await get_game(game_id, db)
    live = await db.scalar(select(GameLiveState).where(GameLiveState.game_id == game_id))
    return LiveGameRead(
        game=game,
        inning=live.inning if live else None,
        inning_half=live.inning_half if live else None,
        outs=live.outs if live else None,
        base_state=live.base_state if live else None,
        description=live.description if live else None,
    )
