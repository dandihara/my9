from datetime import date
from typing import Any

from worker.db import get_conn
from worker.sources.base import BaseballDataSource


def _ensure_team(conn: Any, code: str, name: str) -> int:
    row = conn.execute("SELECT id FROM teams WHERE code = %s", (code,)).fetchone()
    if row:
        return row[0]
    return conn.execute(
        """
        INSERT INTO teams (code, name, short_name)
        VALUES (%s, %s, %s)
        RETURNING id
        """,
        (code, name, name),
    ).fetchone()[0]


def _ensure_stadium(conn: Any, name: str | None) -> int | None:
    if not name:
        return None
    row = conn.execute("SELECT id FROM stadiums WHERE name = %s", (name,)).fetchone()
    if row:
        return row[0]
    return conn.execute(
        "INSERT INTO stadiums (name) VALUES (%s) RETURNING id", (name,)
    ).fetchone()[0]


def upsert_games(games: list[dict[str, Any]]) -> int:
    count = 0
    with get_conn() as conn:
        for game in games:
            home_team_id = _ensure_team(
                conn, game["home_team_code"], game["home_team_name"]
            )
            away_team_id = _ensure_team(
                conn, game["away_team_code"], game["away_team_name"]
            )
            stadium_id = _ensure_stadium(conn, game.get("stadium_name"))
            existing = conn.execute(
                """
                SELECT id FROM games
                WHERE game_date = %s
                  AND home_team_id = %s
                  AND away_team_id = %s
                  AND game_time IS NOT DISTINCT FROM %s
                ORDER BY id
                LIMIT 1
                """,
                (
                    game["game_date"],
                    home_team_id,
                    away_team_id,
                    game["game_time"],
                ),
            ).fetchone()
            if existing:
                conn.execute(
                    """
                    UPDATE games SET
                        boxscore_finalized_at = CASE
                            WHEN status IS DISTINCT FROM %s
                              OR home_score IS DISTINCT FROM %s
                              OR away_score IS DISTINCT FROM %s
                            THEN NULL
                            ELSE boxscore_finalized_at
                        END,
                        season_year = %s,
                        stadium_id = %s,
                        status = %s,
                        home_score = %s,
                        away_score = %s,
                        external_source = %s,
                        external_game_id = %s,
                        updated_at = now()
                    WHERE id = %s
                    """,
                    (
                        game["status"],
                        game.get("home_score"),
                        game.get("away_score"),
                        game["season_year"],
                        stadium_id,
                        game["status"],
                        game.get("home_score"),
                        game.get("away_score"),
                        game["external_source"],
                        game["external_game_id"],
                        existing[0],
                    ),
                )
                count += 1
                continue
            conn.execute(
                """
                INSERT INTO games (
                    season_year, game_date, game_time, home_team_id, away_team_id,
                    stadium_id, status, home_score, away_score,
                    external_source, external_game_id
                ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                ON CONFLICT (external_source, external_game_id)
                DO UPDATE SET
                    boxscore_finalized_at = CASE
                        WHEN games.status IS DISTINCT FROM EXCLUDED.status
                          OR games.home_score IS DISTINCT FROM EXCLUDED.home_score
                          OR games.away_score IS DISTINCT FROM EXCLUDED.away_score
                        THEN NULL
                        ELSE games.boxscore_finalized_at
                    END,
                    season_year = EXCLUDED.season_year,
                    game_date = EXCLUDED.game_date,
                    game_time = EXCLUDED.game_time,
                    home_team_id = EXCLUDED.home_team_id,
                    away_team_id = EXCLUDED.away_team_id,
                    stadium_id = EXCLUDED.stadium_id,
                    status = EXCLUDED.status,
                    home_score = EXCLUDED.home_score,
                    away_score = EXCLUDED.away_score,
                    updated_at = now()
                """,
                (
                    game["season_year"],
                    game["game_date"],
                    game["game_time"],
                    home_team_id,
                    away_team_id,
                    stadium_id,
                    game["status"],
                    game.get("home_score"),
                    game.get("away_score"),
                    game["external_source"],
                    game["external_game_id"],
                ),
            )
            count += 1
    return count


async def sync_schedule(source: BaseballDataSource, target_date: date) -> int:
    return upsert_games(await source.fetch_schedule(target_date))
