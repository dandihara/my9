import argparse
import asyncio
from datetime import date, timedelta

from worker.db import get_conn
from worker.jobs.refresh_season_metrics import refresh_season_metrics
from worker.jobs.sync_boxscore import sync_boxscore
from worker.jobs.sync_schedule import upsert_games
from worker.sources.kbo_source import KboSource


def _dates(start: date, end: date):
    current = start
    while current <= end:
        yield current
        current += timedelta(days=1)


def _completed_game_ids(
    season_year: int, *, missing_plate_appearances_only: bool = False
) -> list[str]:
    with get_conn() as conn:
        rows = conn.execute(
            """
            SELECT external_game_id
            FROM games
            WHERE season_year = %s
              AND external_source = 'kbo'
              AND status = 'completed'
              AND (
                NOT %s OR EXISTS (
                  SELECT 1 FROM batting_game_stats b
                  WHERE b.game_id = games.id AND b.plate_appearances IS NULL
                )
              )
            ORDER BY game_date, game_time, external_game_id
            """,
            (season_year, missing_plate_appearances_only),
        ).fetchall()
    return [row[0] for row in rows]


async def run(
    season_year: int,
    *,
    boxscores_only: bool = False,
    missing_plate_appearances_only: bool = False,
) -> None:
    source = KboSource()
    start = date(season_year, 1, 1)
    end = date(season_year, 12, 31)
    try:
        schedule_total = 0
        if not boxscores_only:
            for target_date in _dates(start, end):
                games = await source.fetch_schedule(target_date)
                if games:
                    upsert_games(games)
                    schedule_total += len(games)
        game_ids = _completed_game_ids(
            season_year,
            missing_plate_appearances_only=missing_plate_appearances_only,
        )
        for index, game_id in enumerate(game_ids, start=1):
            boxscore = await source.fetch_boxscore(game_id)
            game_events = (
                None
                if missing_plate_appearances_only
                else await source.fetch_game_events(game_id)
            )
            sync_boxscore(boxscore, game_events=game_events, finalize=True)
            print(f"[history] {index}/{len(game_ids)} game={game_id}")
        batting, pitching, wpa = refresh_season_metrics(season_year, force=True)
        print(
            f"[history] season={season_year} schedule={schedule_total} "
            f"batting={batting} pitching={pitching} wpa={wpa}"
        )
    finally:
        await source.aclose()


def main() -> None:
    parser = argparse.ArgumentParser(
        description="과거 KBO 한 시즌을 실제 Chrome으로 1회 적재합니다."
    )
    parser.add_argument("--season-year", type=int, required=True)
    parser.add_argument("--boxscores-only", action="store_true")
    parser.add_argument("--missing-plate-appearances-only", action="store_true")
    args = parser.parse_args()
    asyncio.run(run(
        args.season_year,
        boxscores_only=args.boxscores_only,
        missing_plate_appearances_only=args.missing_plate_appearances_only,
    ))


if __name__ == "__main__":
    main()
