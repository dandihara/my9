from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import case, func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.session import get_db
from app.dependencies.auth import get_current_user
from app.models.attendance import AttendanceRecord
from app.models.attendance_league import AttendanceLeague, AttendanceLeagueMember
from app.models.user import User
from app.schemas.attendance_league import LeagueCreate, LeagueDetailRead, LeagueJoin, LeagueRankingRead, LeagueRead


router = APIRouter()


async def _membership(db: AsyncSession, league_id: int, user_id: int):
    return await db.scalar(select(AttendanceLeagueMember).where(
        AttendanceLeagueMember.league_id == league_id,
        AttendanceLeagueMember.user_id == user_id,
    ))


async def _read(db: AsyncSession, league: AttendanceLeague) -> LeagueRead:
    count = await db.scalar(select(func.count()).where(AttendanceLeagueMember.league_id == league.id))
    return LeagueRead(id=league.id, name=league.name, owner_id=league.owner_id,
                      invite_code=league.invite_code, member_count=int(count or 0),
                      created_at=league.created_at)


@router.get("", response_model=list[LeagueRead])
async def list_leagues(user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    leagues = (await db.scalars(select(AttendanceLeague).join(AttendanceLeagueMember)
        .where(AttendanceLeagueMember.user_id == user.id)
        .order_by(AttendanceLeague.created_at.desc()))).all()
    return [await _read(db, league) for league in leagues]


@router.post("", response_model=LeagueRead, status_code=status.HTTP_201_CREATED)
async def create_league(payload: LeagueCreate, user: User = Depends(get_current_user),
                        db: AsyncSession = Depends(get_db)):
    league = AttendanceLeague(name=payload.name.strip(), owner_id=user.id)
    db.add(league)
    await db.flush()
    db.add(AttendanceLeagueMember(league_id=league.id, user_id=user.id, role="owner"))
    await db.commit()
    await db.refresh(league)
    return await _read(db, league)


@router.post("/join", response_model=LeagueRead)
async def join_league(payload: LeagueJoin, user: User = Depends(get_current_user),
                      db: AsyncSession = Depends(get_db)):
    league = await db.scalar(select(AttendanceLeague).where(
        AttendanceLeague.invite_code == payload.invite_code.strip()))
    if league is None:
        raise HTTPException(status_code=404, detail="유효하지 않은 초대 코드입니다.")
    if await _membership(db, league.id, user.id) is None:
        db.add(AttendanceLeagueMember(league_id=league.id, user_id=user.id))
        await db.commit()
    return await _read(db, league)


@router.get("/{league_id}", response_model=LeagueDetailRead)
async def league_detail(league_id: int, user: User = Depends(get_current_user),
                        db: AsyncSession = Depends(get_db)):
    league = await db.get(AttendanceLeague, league_id)
    if league is None or await _membership(db, league_id, user.id) is None:
        raise HTTPException(status_code=404, detail="직관 리그를 찾을 수 없습니다.")
    rows = (await db.execute(select(
        User.id, User.username, User.nickname,
        func.sum(case((AttendanceRecord.result_for_my_team.is_not(None), 1), else_=0)),
        func.sum(case((AttendanceRecord.result_for_my_team == "win", 1), else_=0)),
        func.sum(case((AttendanceRecord.result_for_my_team == "draw", 1), else_=0)),
        func.sum(case((AttendanceRecord.result_for_my_team == "loss", 1), else_=0)),
    ).join(AttendanceLeagueMember, AttendanceLeagueMember.user_id == User.id)
      .outerjoin(AttendanceRecord, AttendanceRecord.user_id == User.id)
      .where(AttendanceLeagueMember.league_id == league_id).group_by(User.id))).all()
    values = []
    for user_id, username, nickname, games, wins, draws, losses in rows:
        wins, draws, losses = int(wins or 0), int(draws or 0), int(losses or 0)
        decisions = wins + losses
        values.append(dict(user_id=user_id, username=username, nickname=nickname,
                           games=int(games or 0), wins=wins, draws=draws, losses=losses,
                           win_rate=round(wins / decisions * 100, 1) if decisions else 0.0))
    values.sort(key=lambda item: (item["win_rate"], item["wins"], item["games"]), reverse=True)
    rankings = [LeagueRankingRead(rank=i + 1, **item) for i, item in enumerate(values)]
    base = await _read(db, league)
    return LeagueDetailRead(**base.model_dump(), rankings=rankings)
