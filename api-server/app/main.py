from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.core.config import settings
from app.routers import attendance, attendance_leagues, auth, games, health, stadiums, stats, teams, wpa

app = FastAPI(
    title="Seungyo API",
    version="0.1.0",
    description="야구 직관 관리 앱 API",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(health.router)
app.include_router(auth.router, prefix="/v1/auth", tags=["auth"])
app.include_router(teams.router, prefix="/v1/teams", tags=["teams"])
app.include_router(stadiums.router, prefix="/v1/stadiums", tags=["stadiums"])
app.include_router(games.router, prefix="/v1/games", tags=["games"])
app.include_router(attendance.router, prefix="/v1/attendances", tags=["attendances"])
app.include_router(attendance_leagues.router, prefix="/v1/attendance-leagues", tags=["attendance-leagues"])
app.include_router(stats.router, prefix="/v1/stats", tags=["stats"])
app.include_router(wpa.router, prefix="/v1", tags=["wpa"])
