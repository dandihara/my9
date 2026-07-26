import argparse
import asyncio
import json
from datetime import date, timedelta

from worker.jobs.sync_schedule import upsert_games
from worker.sources.kbo_source import KboSource


def _parse_date(value: str) -> date:
    try:
        return date.fromisoformat(value)
    except ValueError as exc:
        raise argparse.ArgumentTypeError("날짜 형식은 YYYY-MM-DD여야 합니다.") from exc


def _dates(start: date, end: date):
    current = start
    while current <= end:
        yield current
        current += timedelta(days=1)


async def run(start: date, end: date, *, dry_run: bool, keep_browser_open: bool) -> None:
    if end < start:
        raise ValueError("종료일은 시작일보다 빠를 수 없습니다.")
    if (end - start).days > 366:
        raise ValueError("한 번에 최대 1년까지 수집할 수 있습니다.")

    source = KboSource(keep_open=keep_browser_open)
    total = 0
    try:
        for target_date in _dates(start, end):
            games = await source.fetch_schedule(target_date)
            if dry_run and games:
                print(json.dumps(games, ensure_ascii=False, default=str, indent=2))
            elif games:
                upsert_games(games)
            total += len(games)
            print(f"[scraper] date={target_date} games={len(games)}")
    finally:
        await source.aclose()

    mode = "parsed" if dry_run else "upserted"
    print(f"[scraper] {mode}={total} range={start}..{end}")


def main() -> None:
    parser = argparse.ArgumentParser(description="KBO 일정/결과를 실제 Chrome으로 수집합니다.")
    parser.add_argument("--from-date", type=_parse_date, default=date.today())
    parser.add_argument("--to-date", type=_parse_date)
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--keep-browser-open", action="store_true")
    args = parser.parse_args()
    asyncio.run(
        run(
            args.from_date,
            args.to_date or args.from_date,
            dry_run=args.dry_run,
            keep_browser_open=args.keep_browser_open,
        )
    )


if __name__ == "__main__":
    main()
