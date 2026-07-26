from fastapi import APIRouter, Depends
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.session import get_db
from app.models.wpa import GameEvent, PlayerGameWpa, WpaEvent

router = APIRouter()


@router.get("/games/{game_id}/wpa/events")
async def list_wpa_events(game_id: int, db: AsyncSession = Depends(get_db)) -> list[dict]:
    stmt = (
        select(WpaEvent, GameEvent)
        .join(GameEvent, WpaEvent.game_event_id == GameEvent.id)
        .where(GameEvent.game_id == game_id)
        .order_by(GameEvent.sequence_no)
    )
    result = await db.execute(stmt)
    return [
        {
            "event_id": event.id,
            "sequence_no": game_event.sequence_no,
            "inning": game_event.inning,
            "inning_half": game_event.inning_half,
            "description": game_event.description,
            "we_before": float(event.we_before),
            "we_after": float(event.we_after),
            "wpa": float(event.wpa),
            "batter_id": event.batter_id,
            "pitcher_id": event.pitcher_id,
        }
        for event, game_event in result.all()
    ]


@router.get("/games/{game_id}/wpa/players")
async def list_player_wpa(game_id: int, db: AsyncSession = Depends(get_db)) -> list[dict]:
    result = await db.execute(select(PlayerGameWpa).where(PlayerGameWpa.game_id == game_id))
    rows = result.scalars().all()
    return [
        {
            "player_id": row.player_id,
            "team_id": row.team_id,
            "batting_wpa": float(row.batting_wpa),
            "pitching_wpa": float(row.pitching_wpa),
            "total_wpa": float(row.total_wpa),
        }
        for row in rows
    ]
