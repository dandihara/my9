from datetime import date

from worker.db import get_conn
from worker.sources.base import BaseballDataSource


async def sync_live_games(source: BaseballDataSource, target_date: date) -> int:
    live_games = await source.fetch_live_games(target_date)
    count = 0
    with get_conn() as conn:
        for item in live_games:
            row = conn.execute(
                """
                SELECT id FROM games
                WHERE external_source = %s AND external_game_id = %s
                """,
                (item["external_source"], item["external_game_id"]),
            ).fetchone()
            if not row:
                continue
            game_id = row[0]
            conn.execute(
                """
                UPDATE games
                SET boxscore_finalized_at = CASE
                        WHEN status IS DISTINCT FROM %s
                          OR home_score IS DISTINCT FROM %s
                          OR away_score IS DISTINCT FROM %s
                        THEN NULL
                        ELSE boxscore_finalized_at
                    END,
                    status = %s,
                    home_score = %s,
                    away_score = %s,
                    updated_at = now()
                WHERE id = %s
                """,
                (
                    item["status"],
                    item["home_score"],
                    item["away_score"],
                    item["status"],
                    item["home_score"],
                    item["away_score"],
                    game_id,
                ),
            )
            conn.execute(
                """
                INSERT INTO game_live_states (
                    game_id, inning, inning_half, outs, base_state, description, last_source_updated_at
                ) VALUES (%s, %s, %s, %s, %s, %s, now())
                ON CONFLICT (game_id)
                DO UPDATE SET
                    inning = EXCLUDED.inning,
                    inning_half = EXCLUDED.inning_half,
                    outs = EXCLUDED.outs,
                    base_state = EXCLUDED.base_state,
                    description = EXCLUDED.description,
                    last_source_updated_at = now(),
                    updated_at = now()
                """,
                (
                    game_id,
                    item.get("inning"),
                    item.get("inning_half"),
                    item.get("outs"),
                    item.get("base_state"),
                    item.get("description"),
                ),
            )
            count += 1
    return count
