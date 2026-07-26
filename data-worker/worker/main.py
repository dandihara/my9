import asyncio
import logging
from datetime import datetime, timedelta
from zoneinfo import ZoneInfo

from apscheduler.schedulers.asyncio import AsyncIOScheduler

from worker.jobs.sync_boxscore import sync_completed_boxscores, sync_started_boxscores
from worker.jobs.sync_live_games import sync_live_games
from worker.jobs.sync_schedule import sync_schedule
from worker.config import settings
from worker.db import get_conn
from worker.sources.base import BaseballDataSource
from worker.sources.factory import get_data_source


logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(name)s %(message)s",
)
logger = logging.getLogger("seungyo.worker")
KST = ZoneInfo("Asia/Seoul")


class WorkerJobs:
    def __init__(self, source: BaseballDataSource) -> None:
        self.source = source
        self.lock = asyncio.Lock()

    async def _close_browser(self) -> None:
        close = getattr(self.source, "aclose", None)
        if close is not None:
            await close()

    async def sync_today_schedule(self) -> None:
        async with self.lock:
            target_date = datetime.now(KST).date()
            try:
                count = await sync_schedule(self.source, target_date)
                logger.info("schedule sync complete date=%s games=%s", target_date, count)
            except Exception:
                logger.exception("schedule sync failed date=%s", target_date)
            finally:
                await self._close_browser()

    @staticmethod
    def _has_pollable_game(now: datetime) -> bool:
        with get_conn() as conn:
            rows = conn.execute(
                """
                SELECT game_time, status
                FROM games
                WHERE game_date = %s
                  AND status IN ('scheduled', 'in_progress')
                """,
                (now.date(),),
            ).fetchall()
        for game_time, status in rows:
            if status == "in_progress":
                return True
            if game_time is None:
                continue
            start = datetime.combine(now.date(), game_time, tzinfo=KST)
            if start - timedelta(minutes=30) <= now <= start + timedelta(hours=6):
                return True
        return False

    async def sync_live_game_states(self) -> None:
        now = datetime.now(KST)
        if not self._has_pollable_game(now):
            return
        async with self.lock:
            try:
                count = await sync_live_games(self.source, now.date())
                logger.info(
                    "live game sync complete date=%s games=%s",
                    now.date(),
                    count,
                )
            except Exception:
                logger.exception("live game sync failed date=%s", now.date())

    async def sync_yesterday_boxscores(self) -> None:
        async with self.lock:
            target_date = datetime.now(KST).date() - timedelta(days=1)
            try:
                games, batting, pitching = await sync_completed_boxscores(
                    self.source, target_date
                )
                logger.info(
                    "boxscore sync complete date=%s games=%s batting=%s pitching=%s",
                    target_date,
                    games,
                    batting,
                    pitching,
                )
            except Exception:
                logger.exception("boxscore sync failed date=%s", target_date)
            finally:
                await self._close_browser()

    async def sync_recent_results(self) -> None:
        """Repair and refresh the rolling recent-results window."""
        async with self.lock:
            today = datetime.now(KST).date()
            start_date = today - timedelta(days=3)
            current = start_date
            try:
                while current <= today:
                    schedule_count = await sync_schedule(self.source, current)
                    games, batting, pitching = await sync_completed_boxscores(
                        self.source, current
                    )
                    logger.info(
                        "recent results sync date=%s schedule=%s games=%s batting=%s pitching=%s",
                        current,
                        schedule_count,
                        games,
                        batting,
                        pitching,
                    )
                    current += timedelta(days=1)
            except Exception:
                logger.exception("recent results sync failed date=%s", current)
            finally:
                await self._close_browser()

    async def sync_started_game_boxscores(self) -> None:
        async with self.lock:
            now = datetime.now(KST)
            try:
                eligible, synced, batting, pitching = await sync_started_boxscores(
                    self.source, now.date(), now.time().replace(tzinfo=None)
                )
                logger.info(
                    "started game boxscore sync date=%s eligible=%s synced=%s batting=%s pitching=%s",
                    now.date(),
                    eligible,
                    synced,
                    batting,
                    pitching,
                )
            except Exception:
                logger.exception("started game boxscore sync failed date=%s", now.date())
            finally:
                await self._close_browser()

    @staticmethod
    def _backfill_start_date(today):
        """Choose a DB-driven resume point for startup repair."""
        season_start = today.replace(month=3, day=1)
        rolling_start = today - timedelta(days=settings.startup_backfill_days)
        with get_conn() as conn:
            full_backfill_done = conn.execute(
                """
                SELECT EXISTS (
                    SELECT 1
                    FROM sync_jobs
                    WHERE job_type = %s
                      AND status = 'success'
                      AND target_date >= %s
                )
                """,
                (f"season_backfill:{today.year}", today.isoformat()),
            ).fetchone()[0]
            if not full_backfill_done:
                return min(rolling_start, season_start)

            repair_date = conn.execute(
                """
                SELECT MIN(game_date)
                FROM games
                WHERE season_year = %s
                  AND game_date < %s
                  AND (
                      status IN ('scheduled', 'in_progress')
                      OR (status = 'completed' AND boxscore_finalized_at IS NULL)
                  )
                """,
                (today.year, today),
            ).fetchone()[0]
        return min(rolling_start, repair_date) if repair_date else rolling_start

    @staticmethod
    def _mark_full_backfill(today, start_date, failures: int) -> None:
        season_start = today.replace(month=3, day=1)
        if failures or start_date > season_start:
            return
        finished_at = datetime.now(KST)
        with get_conn() as conn:
            conn.execute(
                """
                INSERT INTO sync_jobs (
                    job_type, status, target_date, message, started_at, finished_at
                ) VALUES (%s, 'success', %s, %s, %s, %s)
                """,
                (
                    f"season_backfill:{today.year}",
                    today.isoformat(),
                    f"range={start_date.isoformat()}..{today.isoformat()} failures=0",
                    finished_at,
                    finished_at,
                ),
            )

    async def backfill_recent_data(self) -> None:
        """Repair from a DB-selected resume point and record full coverage."""
        async with self.lock:
            today = datetime.now(KST).date()
            start_date = self._backfill_start_date(today)
            failures = 0
            logger.info(
                "startup backfill started range=%s..%s",
                start_date,
                today,
            )
            current = start_date
            while current <= today:
                try:
                    count = await sync_schedule(self.source, current)
                    logger.info("startup schedule sync date=%s games=%s", current, count)
                except Exception:
                    failures += 1
                    logger.exception("startup schedule sync failed date=%s", current)
                    await self._close_browser()
                current += timedelta(days=1)

            current = start_date
            while current < today:
                try:
                    games, batting, pitching = await sync_completed_boxscores(
                        self.source, current
                    )
                    logger.info(
                        "startup boxscore sync date=%s games=%s batting=%s pitching=%s",
                        current,
                        games,
                        batting,
                        pitching,
                    )
                except Exception:
                    failures += 1
                    logger.exception("startup boxscore sync failed date=%s", current)
                    await self._close_browser()
                current += timedelta(days=1)
            await self._close_browser()
            self._mark_full_backfill(today, start_date, failures)
            logger.info(
                "startup backfill finished range=%s..%s failures=%s",
                start_date,
                today,
                failures,
            )


async def main() -> None:
    source = get_data_source()
    jobs = WorkerJobs(source)
    scheduler = AsyncIOScheduler(timezone=KST)
    scheduler.add_job(
        jobs.sync_today_schedule,
        "cron",
        minute="0,30",
        id="sync_schedule_every_30_minutes",
        max_instances=1,
        coalesce=True,
        misfire_grace_time=300,
    )
    scheduler.add_job(
        jobs.sync_yesterday_boxscores,
        "cron",
        hour=0,
        minute=0,
        id="sync_player_stats_at_midnight",
        max_instances=1,
        coalesce=True,
        misfire_grace_time=3600,
    )
    scheduler.add_job(
        jobs.sync_recent_results,
        "cron",
        minute="5,35",
        id="sync_recent_results_every_30_minutes",
        max_instances=1,
        coalesce=True,
        misfire_grace_time=300,
    )
    scheduler.add_job(
        jobs.sync_started_game_boxscores,
        "cron",
        minute="*/10",
        id="sync_started_game_boxscores_every_10_minutes",
        max_instances=1,
        coalesce=True,
        misfire_grace_time=300,
    )
    scheduler.add_job(
        jobs.sync_live_game_states,
        "interval",
        seconds=10,
        id="sync_live_game_states_every_10_seconds",
        max_instances=1,
        coalesce=True,
        misfire_grace_time=10,
    )
    scheduler.start()
    try:
        await jobs.backfill_recent_data()
        await jobs.sync_today_schedule()
        await jobs.sync_yesterday_boxscores()
        while True:
            await asyncio.sleep(3600)
    finally:
        scheduler.shutdown(wait=False)
        close = getattr(source, "aclose", None)
        if close is not None:
            await close()


if __name__ == "__main__":
    asyncio.run(main())
