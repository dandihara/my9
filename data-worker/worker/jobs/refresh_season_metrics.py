from datetime import datetime
from math import floor
from zoneinfo import ZoneInfo

from worker.db import get_conn


KST = ZoneInfo("Asia/Seoul")


def qualification_plate_appearances(team_games: int) -> int:
    """Official rule: 3.1 PA per team game, rounded to the nearest PA."""
    return floor(max(team_games, 0) * 3.1 + 0.5)


def qualification_innings(team_games: int) -> int:
    """KBO/official rule: one inning pitched per team game."""
    return max(team_games, 0)


def _outs(value) -> int:
    innings = float(value or 0)
    whole = int(innings)
    partial = round((innings - whole) * 10)
    return whole * 3 + min(max(partial, 0), 2)


def _display_innings(outs: int) -> float:
    return float(f"{outs // 3}.{outs % 3}")


def refresh_season_metrics(season_year: int, *, force: bool = False) -> tuple[int, int, int]:
    current_year = datetime.now(KST).year
    if season_year != current_year and not force:
        return 0, 0, 0

    with get_conn() as conn:
        started_at = datetime.now(KST)
        game_rows = conn.execute(
            """
            SELECT home_team_id, away_team_id
            FROM games
            WHERE season_year = %s AND status = 'completed'
            """,
            (season_year,),
        ).fetchall()
        team_games: dict[int, int] = {}
        for home_team_id, away_team_id in game_rows:
            team_games[home_team_id] = team_games.get(home_team_id, 0) + 1
            team_games[away_team_id] = team_games.get(away_team_id, 0) + 1

        batting_rows = conn.execute(
            """
            SELECT s.player_id, s.team_id, COUNT(DISTINCT s.game_id),
                   SUM(s.ab), SUM(s.r), SUM(s.h), SUM(s.doubles), SUM(s.triples),
                   SUM(s.hr), SUM(s.rbi), SUM(s.bb), SUM(s.hbp), SUM(s.sf),
                   SUM(s.sh), SUM(s.ci), SUM(s.so), SUM(s.sb)
            FROM batting_game_stats s
            JOIN games g ON g.id = s.game_id
            WHERE g.season_year = %s
            GROUP BY s.player_id, s.team_id
            """,
            (season_year,),
        ).fetchall()
        batting = []
        league_pa = league_weighted = league_runs = 0.0
        for row in batting_rows:
            values = [int(value or 0) for value in row[2:]]
            games, ab, runs, hits, doubles, triples, hr, rbi, bb, hbp, sf, sh, ci, so, sb = values
            # Official PA includes AB, BB, HBP, sacrifice flies/bunts and
            # reaching on catcher interference.
            pa = ab + bb + hbp + sf + sh + ci
            singles = max(hits - doubles - triples - hr, 0)
            weighted = (
                0.69 * bb
                + 0.72 * hbp
                + 0.89 * singles
                + 1.27 * doubles
                + 1.62 * triples
                + 2.10 * hr
            )
            total_bases = singles + 2 * doubles + 3 * triples + 4 * hr
            obp_denominator = ab + bb + hbp + sf
            batting.append(
                {
                    "player_id": row[0], "team_id": row[1], "games": games,
                    "pa": pa, "ab": ab, "r": runs, "h": hits,
                    "doubles": doubles, "triples": triples, "hr": hr,
                    "rbi": rbi, "bb": bb, "hbp": hbp, "sf": sf, "sh": sh,
                    "ci": ci, "so": so,
                    "sb": sb,
                    "avg": hits / ab if ab else 0,
                    "obp": (hits + bb + hbp) / obp_denominator if obp_denominator else 0,
                    "slg": total_bases / ab if ab else 0,
                    "weighted": weighted,
                }
            )
            league_pa += pa
            league_weighted += weighted
            league_runs += runs
        league_woba = league_weighted / league_pa if league_pa else 0
        league_runs_per_pa = league_runs / league_pa if league_pa else 0

        conn.execute(
            "DELETE FROM player_season_batting_metrics WHERE season_year = %s",
            (season_year,),
        )
        for item in batting:
            woba = item["weighted"] / item["pa"] if item["pa"] else 0
            runs_per_pa = (woba - league_woba) / 1.20 + league_runs_per_pa
            wrc = max(runs_per_pa * item["pa"], 0)
            wrc_plus = (
                max(runs_per_pa / league_runs_per_pa * 100, 0)
                if league_runs_per_pa else 0
            )
            qualification = qualification_plate_appearances(
                team_games.get(item["team_id"], 0)
            )
            conn.execute(
                """
                INSERT INTO player_season_batting_metrics (
                    season_year, player_id, team_id, games, pa, ab, r, h, doubles,
                    triples, hr, rbi, bb, hbp, sf, sh, ci, so, sb, avg, obp, slg, ops,
                    estimated_woba, estimated_wrc, estimated_wrc_plus,
                    qualification_pa, is_qualified
                ) VALUES (
                    %s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,
                    %s,%s,%s,%s,%s,%s,%s,%s
                )
                """,
                (
                    season_year, item["player_id"], item["team_id"], item["games"],
                    item["pa"], item["ab"], item["r"], item["h"], item["doubles"],
                    item["triples"], item["hr"], item["rbi"], item["bb"], item["hbp"],
                    item["sf"], item["sh"], item["ci"], item["so"], item["sb"], round(item["avg"], 3),
                    round(item["obp"], 3), round(item["slg"], 3),
                    round(item["obp"] + item["slg"], 3), round(woba, 3),
                    round(wrc, 1), round(wrc_plus, 1), qualification,
                    item["pa"] >= qualification,
                ),
            )

        raw_pitching = conn.execute(
            """
            SELECT s.player_id, s.team_id, s.game_id, s.innings_pitched, s.hits,
                   s.home_runs, s.batters_faced, s.runs, s.earned_runs, s.walks,
                   s.strikeouts, s.pitches
            FROM pitching_game_stats s
            JOIN games g ON g.id = s.game_id
            WHERE g.season_year = %s
            """,
            (season_year,),
        ).fetchall()
        pitching: dict[tuple[int, int], dict] = {}
        for row in raw_pitching:
            key = (row[0], row[1])
            item = pitching.setdefault(
                key,
                {"games": set(), "outs": 0, "hits": 0, "home_runs": 0,
                 "batters_faced": 0, "runs": 0, "earned_runs": 0,
                 "walks": 0, "strikeouts": 0, "pitches": 0},
            )
            item["games"].add(row[2])
            item["outs"] += _outs(row[3])
            for index, field in enumerate(
                ("hits", "home_runs", "batters_faced", "runs", "earned_runs",
                 "walks", "strikeouts", "pitches"),
                start=4,
            ):
                item[field] += int(row[index] or 0)

        league_outs = sum(item["outs"] for item in pitching.values())
        league_innings = league_outs / 3 if league_outs else 0
        league_era = (
            sum(item["earned_runs"] for item in pitching.values()) * 9 / league_innings
            if league_innings else 0
        )
        league_component = (
            sum(13 * item["home_runs"] + 3 * item["walks"] - 2 * item["strikeouts"]
                for item in pitching.values()) / league_innings
            if league_innings else 0
        )
        fip_constant = league_era - league_component

        conn.execute(
            "DELETE FROM player_season_pitching_metrics WHERE season_year = %s",
            (season_year,),
        )
        for (player_id, team_id), item in pitching.items():
            innings = item["outs"] / 3 if item["outs"] else 0
            qualification = qualification_innings(team_games.get(team_id, 0))
            fip = (
                (13 * item["home_runs"] + 3 * item["walks"] - 2 * item["strikeouts"])
                / innings + fip_constant
                if innings else 0
            )
            conn.execute(
                """
                INSERT INTO player_season_pitching_metrics (
                    season_year, player_id, team_id, games, innings_pitched, hits,
                    home_runs, batters_faced, runs, earned_runs, walks, strikeouts,
                    pitches, era, whip, k_per_nine, bb_per_nine, k_bb, fip,
                    k_bb_percent, qualification_innings, is_qualified
                ) VALUES (
                    %s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s
                )
                """,
                (
                    season_year, player_id, team_id, len(item["games"]),
                    _display_innings(item["outs"]), item["hits"], item["home_runs"],
                    item["batters_faced"], item["runs"], item["earned_runs"],
                    item["walks"], item["strikeouts"], item["pitches"],
                    round(item["earned_runs"] * 9 / innings, 2) if innings else 0,
                    round((item["hits"] + item["walks"]) / innings, 2) if innings else 0,
                    round(item["strikeouts"] * 9 / innings, 2) if innings else 0,
                    round(item["walks"] * 9 / innings, 2) if innings else 0,
                    round(item["strikeouts"] / item["walks"], 2) if item["walks"] else item["strikeouts"],
                    round(fip, 2),
                    round((item["strikeouts"] - item["walks"]) / item["batters_faced"] * 100, 1)
                    if item["batters_faced"] else 0,
                    qualification, innings >= qualification,
                ),
            )

        conn.execute(
            "DELETE FROM player_season_wpa_metrics WHERE season_year = %s",
            (season_year,),
        )
        wpa_rows = conn.execute(
            """
            SELECT w.player_id, w.team_id, COUNT(DISTINCT w.game_id),
                   SUM(w.batting_wpa), SUM(w.pitching_wpa), SUM(w.total_wpa)
            FROM player_game_wpa w
            JOIN games g ON g.id = w.game_id
            WHERE g.season_year = %s AND w.team_id IS NOT NULL
            GROUP BY w.player_id, w.team_id
            """,
            (season_year,),
        ).fetchall()
        for player_id, team_id, games, batting_wpa, pitching_wpa, total_wpa in wpa_rows:
            conn.execute(
                """
                INSERT INTO player_season_wpa_metrics (
                    season_year, player_id, team_id, games,
                    batting_wpa, pitching_wpa, total_wpa
                ) VALUES (%s,%s,%s,%s,%s,%s,%s)
                """,
                (
                    season_year, player_id, team_id, games,
                    round(float(batting_wpa or 0), 4),
                    round(float(pitching_wpa or 0), 4),
                    round(float(total_wpa or 0), 4),
                ),
            )
        as_of_date = conn.execute(
            """
            SELECT MAX(game_date)
            FROM games
            WHERE season_year = %s AND status = 'completed'
            """,
            (season_year,),
        ).fetchone()[0]
        conn.execute(
            """
            INSERT INTO sync_jobs (
                job_type, status, target_date, message, started_at, finished_at
            ) VALUES (%s, 'success', %s, %s, %s, %s)
            """,
            (
                f"season_metrics:{season_year}",
                as_of_date.isoformat() if as_of_date else None,
                f"batting={len(batting)} pitching={len(pitching)} wpa={len(wpa_rows)} force={force}",
                started_at,
                datetime.now(KST),
            ),
        )
    return len(batting), len(pitching), len(wpa_rows)
