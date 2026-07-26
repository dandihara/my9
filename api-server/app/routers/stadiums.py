from fastapi import APIRouter, Depends
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.session import get_db
from app.models.stadium import Stadium
from app.schemas.stadium import StadiumRead

router = APIRouter()


@router.get("", response_model=list[StadiumRead])
async def list_stadiums(db: AsyncSession = Depends(get_db)) -> list[Stadium]:
    result = await db.execute(select(Stadium).order_by(Stadium.name))
    return list(result.scalars().all())
