from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.session import get_db
from app.models.player import Player
from app.models.season_metric import (
    PlayerSeasonBattingMetric,
    PlayerSeasonPitchingMetric,
    PlayerSeasonWpaMetric,
)
from app.models.team import Team
from app.models.sync_job import SyncJob
from app.schemas.stats import (
    SeasonBattingPlayerRead,
    SeasonBattingRead,
    SeasonPitchingPlayerRead,
    SeasonPitchingRead,
    SeasonWpaPlayerRead,
    SeasonWpaRead,
)


router = APIRouter()


def _float(value) -> float:
    return float(value or 0)


async def _as_of_date(db: AsyncSession, season_year: int) -> str | None:
    return await db.scalar(
        select(SyncJob.target_date)
        .where(
            SyncJob.job_type == f"season_metrics:{season_year}",
            SyncJob.status == "success",
        )
        .order_by(SyncJob.finished_at.desc())
        .limit(1)
    )


@router.get("/season/batting", response_model=SeasonBattingRead)
async def season_batting(
    season_year: int | None = Query(default=None),
    db: AsyncSession = Depends(get_db),
) -> SeasonBattingRead:
    if season_year is None:
        season_year = await db.scalar(
            select(func.max(PlayerSeasonBattingMetric.season_year))
        )
    if season_year is None:
        raise HTTPException(status_code=404, detail="집계된 타자 시즌 기록이 없습니다.")
    rows = (
        await db.execute(
            select(PlayerSeasonBattingMetric, Player.name, Team.name, PlayerSeasonWpaMetric)
            .join(Player, Player.id == PlayerSeasonBattingMetric.player_id)
            .join(Team, Team.id == PlayerSeasonBattingMetric.team_id)
            .outerjoin(
                PlayerSeasonWpaMetric,
                (PlayerSeasonWpaMetric.season_year == PlayerSeasonBattingMetric.season_year)
                & (PlayerSeasonWpaMetric.player_id == PlayerSeasonBattingMetric.player_id)
                & (PlayerSeasonWpaMetric.team_id == PlayerSeasonBattingMetric.team_id),
            )
            .where(PlayerSeasonBattingMetric.season_year == season_year)
            .order_by(PlayerSeasonBattingMetric.estimated_wrc_plus.desc())
        )
    ).all()
    players = []
    for metric, player_name, team_name, wpa in rows:
        players.append(
            SeasonBattingPlayerRead(
                player_id=metric.player_id,
                player_name=player_name,
                team_id=metric.team_id,
                team_name=team_name,
                games=metric.games,
                pa=metric.pa,
                ab=metric.ab,
                r=metric.r,
                h=metric.h,
                doubles=metric.doubles,
                triples=metric.triples,
                hr=metric.hr,
                rbi=metric.rbi,
                bb=metric.bb,
                hbp=metric.hbp,
                sf=metric.sf,
                so=metric.so,
                sb=metric.sb,
                avg=_float(metric.avg),
                obp=_float(metric.obp),
                slg=_float(metric.slg),
                ops=_float(metric.ops),
                estimated_woba=_float(metric.estimated_woba),
                estimated_wrc=_float(metric.estimated_wrc),
                estimated_wrc_plus=_float(metric.estimated_wrc_plus),
                qualification_pa=metric.qualification_pa,
                is_qualified=metric.is_qualified,
                batting_wpa=_float(wpa.batting_wpa) if wpa else 0,
                pitching_wpa=_float(wpa.pitching_wpa) if wpa else 0,
                total_wpa=_float(wpa.total_wpa) if wpa else 0,
            )
        )
    return SeasonBattingRead(
        season_year=season_year,
        as_of_date=await _as_of_date(db, season_year),
        methodology=(
            "시즌 집계 테이블의 AVG·OBP·SLG·OPS와 추정 wOBA·wRC입니다. "
            "현재 시즌은 자정 동기화 후 재계산되고 과거 시즌은 고정됩니다."
        ),
        players=players,
    )


@router.get("/season/pitching", response_model=SeasonPitchingRead)
async def season_pitching(
    season_year: int | None = Query(default=None),
    db: AsyncSession = Depends(get_db),
) -> SeasonPitchingRead:
    if season_year is None:
        season_year = await db.scalar(
            select(func.max(PlayerSeasonPitchingMetric.season_year))
        )
    if season_year is None:
        raise HTTPException(status_code=404, detail="집계된 투수 시즌 기록이 없습니다.")
    rows = (
        await db.execute(
            select(PlayerSeasonPitchingMetric, Player.name, Team.name, PlayerSeasonWpaMetric)
            .join(Player, Player.id == PlayerSeasonPitchingMetric.player_id)
            .join(Team, Team.id == PlayerSeasonPitchingMetric.team_id)
            .outerjoin(
                PlayerSeasonWpaMetric,
                (PlayerSeasonWpaMetric.season_year == PlayerSeasonPitchingMetric.season_year)
                & (PlayerSeasonWpaMetric.player_id == PlayerSeasonPitchingMetric.player_id)
                & (PlayerSeasonWpaMetric.team_id == PlayerSeasonPitchingMetric.team_id),
            )
            .where(PlayerSeasonPitchingMetric.season_year == season_year)
            .order_by(
                PlayerSeasonPitchingMetric.is_qualified.desc(),
                PlayerSeasonPitchingMetric.fip,
                PlayerSeasonPitchingMetric.era,
            )
        )
    ).all()
    players = []
    for metric, player_name, team_name, wpa in rows:
        players.append(
            SeasonPitchingPlayerRead(
                player_id=metric.player_id,
                player_name=player_name,
                team_id=metric.team_id,
                team_name=team_name,
                games=metric.games,
                innings_pitched=_float(metric.innings_pitched),
                hits=metric.hits,
                home_runs=metric.home_runs,
                batters_faced=metric.batters_faced,
                runs=metric.runs,
                earned_runs=metric.earned_runs,
                walks=metric.walks,
                strikeouts=metric.strikeouts,
                pitches=metric.pitches,
                era=_float(metric.era),
                whip=_float(metric.whip),
                k_per_nine=_float(metric.k_per_nine),
                bb_per_nine=_float(metric.bb_per_nine),
                k_bb=_float(metric.k_bb),
                fip=_float(metric.fip),
                k_bb_percent=_float(metric.k_bb_percent),
                qualification_innings=metric.qualification_innings,
                is_qualified=metric.is_qualified,
                batting_wpa=_float(wpa.batting_wpa) if wpa else 0,
                pitching_wpa=_float(wpa.pitching_wpa) if wpa else 0,
                total_wpa=_float(wpa.total_wpa) if wpa else 0,
            )
        )
    return SeasonPitchingRead(
        season_year=season_year,
        as_of_date=await _as_of_date(db, season_year),
        methodology=(
            "시즌 집계 테이블의 ERA·WHIP·K/9·BB/9·K/BB·FIP·K-BB%입니다. "
            "현재 시즌은 자정 동기화 후 재계산되고 과거 시즌은 고정됩니다."
        ),
        players=players,
    )


@router.get("/season/wpa", response_model=SeasonWpaRead)
async def season_wpa(
    season_year: int | None = Query(default=None),
    db: AsyncSession = Depends(get_db),
) -> SeasonWpaRead:
    if season_year is None:
        season_year = await db.scalar(select(func.max(PlayerSeasonWpaMetric.season_year)))
    if season_year is None:
        season_year = await db.scalar(
            select(func.max(PlayerSeasonBattingMetric.season_year))
        )
    if season_year is None:
        raise HTTPException(status_code=404, detail="집계된 시즌 기록이 없습니다.")
    rows = (
        await db.execute(
            select(PlayerSeasonWpaMetric, Player.name, Team.name)
            .join(Player, Player.id == PlayerSeasonWpaMetric.player_id)
            .join(Team, Team.id == PlayerSeasonWpaMetric.team_id)
            .where(PlayerSeasonWpaMetric.season_year == season_year)
            .order_by(PlayerSeasonWpaMetric.total_wpa.desc())
        )
    ).all()
    return SeasonWpaRead(
        season_year=season_year,
        as_of_date=await _as_of_date(db, season_year),
        players=[
            SeasonWpaPlayerRead(
                player_id=metric.player_id,
                player_name=player_name,
                team_id=metric.team_id,
                team_name=team_name,
                games=metric.games,
                batting_wpa=_float(metric.batting_wpa),
                pitching_wpa=_float(metric.pitching_wpa),
                total_wpa=_float(metric.total_wpa),
            )
            for metric, player_name, team_name in rows
        ],
    )
