from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import create_access_token, hash_password, verify_password
from app.db.session import get_db
from app.dependencies.auth import get_current_user
from app.models.attendance import AttendanceRecord
from app.models.game import Game
from app.models.team import Team
from app.models.user import User
from app.schemas.auth import AchievementRead, LoginRequest, RegisterRequest, TokenRead, UserRead, UserUpdate


router = APIRouter()


@router.post("/register", response_model=TokenRead, status_code=status.HTTP_201_CREATED)
async def register(payload: RegisterRequest, db: AsyncSession = Depends(get_db)) -> TokenRead:
    if await db.scalar(select(User).where(User.username == payload.username)):
        raise HTTPException(status_code=409, detail="이미 사용 중인 아이디입니다.")
    if payload.my_team_id is not None and await db.get(Team, payload.my_team_id) is None:
        raise HTTPException(status_code=400, detail="존재하지 않는 팀입니다.")
    user = User(
        username=payload.username,
        password_hash=hash_password(payload.password),
        nickname=payload.nickname or payload.username,
        my_team_id=payload.my_team_id,
        is_active=True,
    )
    db.add(user)
    await db.commit()
    await db.refresh(user)
    return TokenRead(access_token=create_access_token(user.id), user=UserRead.model_validate(user))


@router.post("/login", response_model=TokenRead)
async def login(payload: LoginRequest, db: AsyncSession = Depends(get_db)) -> TokenRead:
    user = await db.scalar(select(User).where(User.username == payload.username))
    if user is None or not verify_password(payload.password, user.password_hash):
        raise HTTPException(status_code=401, detail="아이디 또는 비밀번호가 올바르지 않습니다.")
    if not user.is_active:
        raise HTTPException(status_code=403, detail="비활성화된 계정입니다.")
    return TokenRead(access_token=create_access_token(user.id), user=UserRead.model_validate(user))


@router.get("/me", response_model=UserRead)
async def me(user: User = Depends(get_current_user)) -> User:
    return user


@router.patch("/me", response_model=UserRead)
async def update_me(
    payload: UserUpdate,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> User:
    if payload.my_team_id is not None and await db.get(Team, payload.my_team_id) is None:
        raise HTTPException(status_code=400, detail="존재하지 않는 팀입니다.")
    user.my_team_id = payload.my_team_id
    await db.commit()
    await db.refresh(user)
    return user


@router.get("/me/achievements", response_model=list[AchievementRead])
async def my_achievements(
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> list[AchievementRead]:
    rows = (
        await db.execute(
            select(AttendanceRecord, Game)
            .join(Game, Game.id == AttendanceRecord.game_id)
            .where(AttendanceRecord.user_id == user.id)
            .order_by(Game.game_date, Game.game_time, Game.id)
        )
    ).all()
    stadium_rows = [row for row in rows if row[0].attend_type == "stadium"]
    wins = sum(record.result_for_my_team == "win" for record, _ in stadium_rows)
    away_games = sum(
        record.my_team_id is not None and record.my_team_id == game.away_team_id
        for record, game in stadium_rows
    )
    stadiums = len({game.stadium_id for _, game in stadium_rows if game.stadium_id})
    weekend_games = sum(game.game_date.weekday() >= 5 for _, game in stadium_rows)
    longest_streak = streak = 0
    for record, _ in stadium_rows:
        if record.result_for_my_team == "win":
            streak += 1
            longest_streak = max(longest_streak, streak)
        elif record.result_for_my_team == "loss":
            streak = 0

    values = {
        "first_game": len(stadium_rows), "five_games": len(stadium_rows),
        "ten_games": len(stadium_rows), "thirty_games": len(stadium_rows),
        "first_win": wins, "three_streak": longest_streak,
        "road_trip": away_games, "stadium_tour": stadiums,
        "weekend_fan": weekend_games,
    }
    catalog = [
        ("first_game", "플레이 볼", "첫 직관 기록 남기기", "ticket", 1),
        ("five_games", "야구장 단골", "직관 5경기 달성", "stadium", 5),
        ("ten_games", "열 번째 함성", "직관 10경기 달성", "cheer", 10),
        ("thirty_games", "시즌 동반자", "직관 30경기 달성", "season", 30),
        ("first_win", "승리요정의 시작", "첫 직관 승리", "win", 1),
        ("three_streak", "승리의 루틴", "직관 3연승 달성", "streak", 3),
        ("road_trip", "원정대", "원정 직관 1경기", "road", 1),
        ("stadium_tour", "구장 탐험가", "서로 다른 구장 5곳 방문", "map", 5),
        ("weekend_fan", "주말은 야구", "주말 직관 5경기", "weekend", 5),
    ]
    return [
        AchievementRead(
            code=code, title=title, description=description, icon=icon,
            current=min(values[code], target), target=target,
            unlocked=values[code] >= target,
        )
        for code, title, description, icon, target in catalog
    ]
