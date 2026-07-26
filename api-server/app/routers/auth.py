from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import create_access_token, hash_password, verify_password
from app.db.session import get_db
from app.dependencies.auth import get_current_user
from app.models.team import Team
from app.models.user import User
from app.schemas.auth import LoginRequest, RegisterRequest, TokenRead, UserRead, UserUpdate


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
