import logging
from typing import Any

from worker.db import get_conn
from worker.sources.base import BaseballDataSource
from worker.jobs.refresh_season_metrics import refresh_season_metrics


logger = logging.getLogger("seungyo.worker.boxscore")


def _ensure_player(conn: Any, item: dict[str, Any]) -> int:
    row = conn.execute(
        "SELECT id FROM players WHERE external_player_id = %s",
        (item["external_player_id"],),
    ).fetchone()
    if row:
        return row[0]
    return conn.execute(
        """
        INSERT INTO players (name, external_player_id)
        VALUES (%s, %s)
        RETURNING id
        """,
        (item["player_name"], item["external_player_id"]),
    ).fetchone()[0]


def sync_boxscore(boxscore: dict[str, Any], *, finalize: bool = False) -> tuple[int, int]:
    with get_conn() as conn:
        game = conn.execute(
            "SELECT id FROM games WHERE external_source = 'kbo' AND external_game_id = %s",
            (boxscore["external_game_id"],),
        ).fetchone()
        if not game:
            raise ValueError(f"Game not found: {boxscore['external_game_id']}")
        game_id = game[0]
        team_ids = dict(conn.execute("SELECT code, id FROM teams").fetchall())

        conn.execute("DELETE FROM batting_game_stats WHERE game_id = %s", (game_id,))
        conn.execute("DELETE FROM pitching_game_stats WHERE game_id = %s", (game_id,))

        for item in boxscore["batting"]:
            player_id = _ensure_player(conn, item)
            conn.execute(
                """
                INSERT INTO batting_game_stats (
                    game_id, player_id, team_id, batting_order, position,
                    ab, r, h, doubles, triples, hr, rbi, bb, hbp, sf, so,
                    sb, avg_after_game
                ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                """,
                (
                    game_id,
                    player_id,
                    team_ids[item["team_code"]],
                    item["batting_order"],
                    item["position"],
                    item["ab"],
                    item["r"],
                    item["h"],
                    item["doubles"],
                    item["triples"],
                    item["hr"],
                    item["rbi"],
                    item["bb"],
                    item["hbp"],
                    item["sf"],
                    item["so"],
                    item["sb"],
                    item["avg_after_game"],
                ),
            )

        for item in boxscore["pitching"]:
            player_id = _ensure_player(conn, item)
            conn.execute(
                """
                INSERT INTO pitching_game_stats (
                    game_id, player_id, team_id, innings_pitched, hits, runs,
                    earned_runs, walks, strikeouts, pitches, era_after_game,
                    home_runs, batters_faced, decision
                ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                """,
                (
                    game_id,
                    player_id,
                    team_ids[item["team_code"]],
                    item["innings_pitched"],
                    item["hits"],
                    item["runs"],
                    item["earned_runs"],
                    item["walks"],
                    item["strikeouts"],
                    item["pitches"],
                    item["era_after_game"],
                    item["home_runs"],
                    item["batters_faced"],
                    item["decision"],
                ),
            )

        if finalize:
            conn.execute(
                "UPDATE games SET boxscore_finalized_at = now() WHERE id = %s",
                (game_id,),
            )

    return len(boxscore["batting"]), len(boxscore["pitching"])


def _completed_game_ids(target_date) -> list[str]:
    with get_conn() as conn:
        rows = conn.execute(
            """
            SELECT external_game_id
            FROM games
            WHERE external_source = 'kbo'
              AND status = 'completed'
              AND game_date = %s
              AND boxscore_finalized_at IS NULL
            ORDER BY game_time, external_game_id
            """,
            (target_date,),
        ).fetchall()
    return [row[0] for row in rows]


async def sync_completed_boxscores(
    source: BaseballDataSource, target_date
) -> tuple[int, int, int]:
    game_ids = _completed_game_ids(target_date)
    batting_total = pitching_total = 0
    for game_id in game_ids:
        boxscore = await source.fetch_boxscore(game_id)
        batting_count, pitching_count = sync_boxscore(boxscore, finalize=True)
        batting_total += batting_count
        pitching_total += pitching_count
    refresh_season_metrics(target_date.year)
    return len(game_ids), batting_total, pitching_total


def _started_games(target_date, current_time) -> list[tuple[str, str]]:
    with get_conn() as conn:
        rows = conn.execute(
            """
            SELECT external_game_id, status
            FROM games
            WHERE external_source = 'kbo'
              AND game_date = %s
              AND game_time IS NOT NULL
              AND game_time <= %s
              AND status IN ('in_progress', 'completed')
              AND external_game_id IS NOT NULL
              AND (status <> 'completed' OR boxscore_finalized_at IS NULL)
            ORDER BY game_time, external_game_id
            """,
            (target_date, current_time),
        ).fetchall()
    return [(row[0], row[1]) for row in rows]


async def sync_started_boxscores(
    source: BaseballDataSource, target_date, current_time
) -> tuple[int, int, int, int]:
    games = _started_games(target_date, current_time)
    synced = batting_total = pitching_total = 0
    for game_id, status in games:
        try:
            boxscore = await source.fetch_boxscore(game_id)
            batting_count, pitching_count = sync_boxscore(
                boxscore, finalize=status == "completed"
            )
            synced += 1
            batting_total += batting_count
            pitching_total += pitching_count
        except Exception:
            logger.exception("boxscore sync failed game_id=%s status=%s", game_id, status)
    if synced:
        refresh_season_metrics(target_date.year)
    return len(games), synced, batting_total, pitching_total
