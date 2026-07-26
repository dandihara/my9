import argparse
import asyncio
from datetime import date

from worker.db import get_conn
from worker.jobs.sync_boxscore import sync_boxscore
from worker.sources.kbo_source import KboSource


def _parse_date(value: str) -> date:
    try:
        return date.fromisoformat(value)
    except ValueError as exc:
        raise argparse.ArgumentTypeError("날짜 형식은 YYYY-MM-DD여야 합니다.") from exc


def _completed_game_ids(
    start: date, end: date, limit: int | None, force: bool
) -> list[str]:
    query = """
        SELECT external_game_id
        FROM games
        WHERE external_source = 'kbo'
          AND status = 'completed'
          AND game_date BETWEEN %s AND %s
          {missing_filter}
        ORDER BY game_date, game_time, external_game_id
    """
    missing_filter = "" if force else """
        AND boxscore_finalized_at IS NULL
    """
    query = query.format(missing_filter=missing_filter)
    with get_conn() as conn:
        rows = conn.execute(query, (start, end)).fetchall()
    game_ids = [row[0] for row in rows]
    return game_ids[:limit] if limit else game_ids


async def run(start: date, end: date, limit: int | None, force: bool) -> None:
    source = KboSource()
    game_ids = _completed_game_ids(start, end, limit, force)
    batting_total = 0
    pitching_total = 0
    try:
        for index, game_id in enumerate(game_ids, start=1):
            boxscore = await source.fetch_boxscore(game_id)
            batting_count, pitching_count = sync_boxscore(boxscore, finalize=True)
            batting_total += batting_count
            pitching_total += pitching_count
            print(
                f"[boxscore] {index}/{len(game_ids)} game={game_id} "
                f"batting={batting_count} pitching={pitching_count}"
            )
    finally:
        await source.aclose()
    print(
        f"[boxscore] games={len(game_ids)} batting={batting_total} pitching={pitching_total}"
    )


def main() -> None:
    parser = argparse.ArgumentParser(description="완료 경기의 타자·투수 기록을 수집합니다.")
    parser.add_argument("--from-date", type=_parse_date, required=True)
    parser.add_argument("--to-date", type=_parse_date, required=True)
    parser.add_argument("--limit", type=int)
    parser.add_argument("--force", action="store_true")
    args = parser.parse_args()
    asyncio.run(run(args.from_date, args.to_date, args.limit, args.force))


if __name__ == "__main__":
    main()
