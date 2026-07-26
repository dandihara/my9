from fastapi import APIRouter, Depends, HTTPException, Response, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import aliased

from app.db.session import get_db
from app.dependencies.auth import get_current_user
from app.models.attendance import AttendanceRecord
from app.models.game import Game
from app.models.player import Player
from app.models.stat import BattingGameStat, PitchingGameStat
from app.models.stadium import Stadium
from app.models.team import Team
from app.models.user import User
from app.models.wpa import GameEvent
from app.schemas.attendance import (
    AttendanceBreakdown,
    AttendanceCreate,
    AttendancePitchingLeader,
    AttendanceRead,
    AttendanceSummaryRead,
    AttendanceUpdate,
    AttendanceBattingLeader,
)


router = APIRouter()


def _outs(value: float | None) -> int:
    innings = float(value or 0)
    whole = int(innings)
    partial = round((innings - whole) * 10)
    return whole * 3 + min(max(partial, 0), 2)


def _result_for_team(game: Game, team_id: int | None) -> str | None:
    if (
        team_id not in (game.home_team_id, game.away_team_id)
        or game.home_score is None
        or game.away_score is None
    ):
        return None
    my_score, opponent_score = (
        (game.home_score, game.away_score)
        if team_id == game.home_team_id
        else (game.away_score, game.home_score)
    )
    if my_score > opponent_score:
        return "win"
    if my_score < opponent_score:
        return "loss"
    return "draw"


def _read(record: AttendanceRecord, game: Game, away_name: str, home_name: str) -> AttendanceRead:
    values = {
        **record.__dict__,
        "result_for_my_team": _result_for_team(game, record.my_team_id)
        or record.result_for_my_team,
    }
    return AttendanceRead(
        **values,
        game_date=game.game_date,
        away_team_name=away_name,
        home_team_name=home_name,
    )


async def _owned_record(db: AsyncSession, attendance_id: int, user_id: int) -> AttendanceRecord:
    record = await db.scalar(
        select(AttendanceRecord).where(
            AttendanceRecord.id == attendance_id, AttendanceRecord.user_id == user_id
        )
    )
    if record is None:
        raise HTTPException(status_code=404, detail="직관 기록을 찾을 수 없습니다.")
    return record


@router.post("", response_model=AttendanceRead, status_code=status.HTTP_201_CREATED)
async def create_attendance(
    payload: AttendanceCreate,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> AttendanceRead:
    game = await db.get(Game, payload.game_id)
    if game is None:
        raise HTTPException(status_code=400, detail="존재하지 않는 경기입니다.")
    my_team_id = None if payload.is_neutral else payload.my_team_id or user.my_team_id
    if my_team_id is not None and my_team_id not in (game.home_team_id, game.away_team_id):
        raise HTTPException(status_code=400, detail="응원팀은 해당 경기의 홈팀 또는 원정팀이어야 합니다.")
    values = payload.model_dump(exclude={"is_neutral"})
    values["my_team_id"] = my_team_id
    values["result_for_my_team"] = _result_for_team(game, my_team_id)
    record = AttendanceRecord(user_id=user.id, **values)
    db.add(record)
    await db.commit()
    return (await list_attendances(user, db, record.id))[0]


@router.get("", response_model=list[AttendanceRead])
async def list_attendances(
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
    attendance_id: int | None = None,
) -> list[AttendanceRead]:
    away = aliased(Team)
    home = aliased(Team)
    stmt = (
        select(AttendanceRecord, Game, away.name, home.name)
        .join(Game, Game.id == AttendanceRecord.game_id)
        .join(away, away.id == Game.away_team_id)
        .join(home, home.id == Game.home_team_id)
        .where(AttendanceRecord.user_id == user.id)
        .order_by(Game.game_date.desc(), AttendanceRecord.created_at.desc())
    )
    if attendance_id is not None:
        stmt = stmt.where(AttendanceRecord.id == attendance_id)
    rows = (await db.execute(stmt)).all()
    return [_read(record, game, away_name, home_name) for record, game, away_name, home_name in rows]


@router.get("/summary", response_model=AttendanceSummaryRead)
async def attendance_summary(
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> AttendanceSummaryRead:
    rows = (
        await db.execute(
            select(AttendanceRecord, Game)
            .join(Game, Game.id == AttendanceRecord.game_id)
            .where(AttendanceRecord.user_id == user.id)
        )
    ).all()

    game_teams: dict[tuple[int, int], Game] = {}
    for record, game in rows:
        team_id = record.my_team_id or user.my_team_id
        if team_id in (game.home_team_id, game.away_team_id):
            game_teams[(game.id, team_id)] = game

    # 결승타는 직관 경기별로 계산한 뒤, 같은 선수가 몇 번 기록했는지 집계한다.
    decisive_hits: list[dict[str, object]] = []
    attended_games = {game.id: game for game in game_teams.values()}
    if attended_games:
        event_rows = (
            await db.execute(
                select(GameEvent, Player.name, Team.name)
                .join(Player, Player.id == GameEvent.batter_id)
                .join(Team, Team.id == GameEvent.batting_team_id)
                .where(GameEvent.game_id.in_(attended_games))
                .order_by(GameEvent.game_id, GameEvent.sequence_no)
            )
        ).all()
        events_by_game: dict[int, list[tuple[GameEvent, str, str]]] = {}
        for event, player_name, team_name in event_rows:
            events_by_game.setdefault(event.game_id, []).append(
                (event, player_name, team_name)
            )

        for game_id, game in attended_games.items():
            if (
                game.home_score is None
                or game.away_score is None
                or game.home_score == game.away_score
            ):
                decisive_hits.append(
                    {
                        "game_id": game_id,
                        "game_date": game.game_date,
                        "player_id": None,
                        "player_name": None,
                        "team_name": None,
                    }
                )
                continue
            winning_team_id = (
                game.home_team_id
                if game.home_score > game.away_score
                else game.away_team_id
            )
            winner_sign = 1 if winning_team_id == game.home_team_id else -1
            events = events_by_game.get(game_id, [])
            found = False
            for index, (event, player_name, team_name) in enumerate(events):
                if (
                    event.batting_team_id != winning_team_id
                    or event.batter_id is None
                    or not event.runs_scored
                    or event.score_diff_before is None
                    or event.score_diff_after is None
                    or winner_sign * event.score_diff_before > 0
                    or winner_sign * event.score_diff_after <= 0
                ):
                    continue
                if not all(
                    later.score_diff_after is not None
                    and winner_sign * later.score_diff_after > 0
                    for later, _, _ in events[index:]
                ):
                    continue
                decisive_hits.append(
                    {
                        "game_id": game_id,
                        "game_date": game.game_date,
                        "player_id": event.batter_id,
                        "player_name": player_name,
                        "team_name": team_name,
                    }
                )
                found = True
                break
            if not found:
                decisive_hits.append(
                    {
                        "game_id": game_id,
                        "game_date": game.game_date,
                        "player_id": None,
                        "player_name": None,
                        "team_name": None,
                    }
                )

    decisive_hit_counts: dict[tuple[int, str, str], int] = {}
    for hit in decisive_hits:
        if hit["player_id"] is None:
            continue
        key = (int(hit["player_id"]), str(hit["player_name"]), str(hit["team_name"]))
        decisive_hit_counts[key] = decisive_hit_counts.get(key, 0) + 1
    decisive_hit_leaders = [
        {
            "player_id": player_id,
            "player_name": player_name,
            "team_name": team_name,
            "count": count,
        }
        for (player_id, player_name, team_name), count in sorted(
            decisive_hit_counts.items(), key=lambda item: (-item[1], item[0][1])
        )[:3]
    ]

    wins = losses = draws = 0
    weekdays = ["월", "화", "수", "목", "금", "토", "일"]
    weekday_values: dict[str, list[int]] = {}
    stadium_values: dict[int | None, list[int]] = {}
    for (_, team_id), game in game_teams.items():
        if game.home_score is None or game.away_score is None:
            continue
        my_score, opponent_score = (
            (game.home_score, game.away_score)
            if team_id == game.home_team_id
            else (game.away_score, game.home_score)
        )
        bucket = 0 if my_score > opponent_score else 1 if my_score == opponent_score else 2
        weekday_values.setdefault(weekdays[game.game_date.weekday()], [0, 0, 0])[bucket] += 1
        stadium_values.setdefault(game.stadium_id, [0, 0, 0])[bucket] += 1
        if my_score > opponent_score:
            wins += 1
        elif my_score < opponent_score:
            losses += 1
        else:
            draws += 1

    aggregates: dict[tuple[int, int], dict[str, int | str]] = {}
    if game_teams:
        game_ids = {game_id for game_id, _ in game_teams}
        stat_rows = (
            await db.execute(
                select(BattingGameStat, Player.name, Team.name)
                .join(Player, Player.id == BattingGameStat.player_id)
                .join(Team, Team.id == BattingGameStat.team_id)
                .where(BattingGameStat.game_id.in_(game_ids))
            )
        ).all()
        for stat, player_name, team_name in stat_rows:
            if (stat.game_id, stat.team_id) not in game_teams:
                continue
            key = (stat.player_id, stat.team_id)
            item = aggregates.setdefault(
                key,
                {
                    "player_id": stat.player_id,
                    "player_name": player_name,
                    "team_id": stat.team_id,
                    "team_name": team_name,
                    "games": 0,
                    "ab": 0,
                    "r": 0,
                    "h": 0,
                    "doubles": 0,
                    "triples": 0,
                    "hr": 0,
                    "rbi": 0,
                    "bb": 0,
                    "hbp": 0,
                    "sf": 0,
                },
            )
            item["games"] = int(item["games"]) + 1
            for field in (
                "ab", "r", "h", "doubles", "triples", "hr", "rbi",
                "bb", "hbp", "sf",
            ):
                item[field] = int(item[field]) + int(getattr(stat, field) or 0)

    leaders = []
    for item in aggregates.values():
        ab = int(item["ab"])
        bb = int(item["bb"])
        hbp = int(item["hbp"])
        sf = int(item["sf"])
        pa = ab + bb + hbp + sf
        if ab <= 0 or pa <= 0:
            continue
        hits = int(item["h"])
        doubles = int(item["doubles"])
        triples = int(item["triples"])
        hr = int(item["hr"])
        singles = max(hits - doubles - triples - hr, 0)
        obp = (hits + bb + hbp) / pa
        slg = (singles + 2 * doubles + 3 * triples + 4 * hr) / ab
        leaders.append(
            AttendanceBattingLeader(
                player_id=int(item["player_id"]),
                player_name=str(item["player_name"]),
                team_id=int(item["team_id"]),
                team_name=str(item["team_name"]),
                games=int(item["games"]),
                pa=pa,
                h=int(item["h"]),
                hr=int(item["hr"]),
                rbi=int(item["rbi"]),
                bb=int(item["bb"]),
                obp=round(obp, 3),
                slg=round(slg, 3),
                ops=round(obp + slg, 3),
            )
        )

    pitching_aggregates: dict[tuple[int, int], dict[str, int | float | str]] = {}
    if game_teams:
        pitching_rows = (
            await db.execute(
                select(PitchingGameStat, Player.name, Team.name)
                .join(Player, Player.id == PitchingGameStat.player_id)
                .join(Team, Team.id == PitchingGameStat.team_id)
                .where(PitchingGameStat.game_id.in_({key[0] for key in game_teams}))
            )
        ).all()
        for stat, player_name, team_name in pitching_rows:
            if (stat.game_id, stat.team_id) not in game_teams:
                continue
            key = (stat.player_id, stat.team_id)
            item = pitching_aggregates.setdefault(
                key,
                {
                    "player_id": stat.player_id,
                    "player_name": player_name,
                    "team_id": stat.team_id,
                    "team_name": team_name,
                    "games": 0,
                    "wins": 0,
                    "outs": 0,
                    "hits": 0,
                    "earned_runs": 0,
                    "walks": 0,
                    "strikeouts": 0,
                    "batters_faced": 0,
                },
            )
            item["games"] = int(item["games"]) + 1
            if stat.decision and "승" in stat.decision:
                item["wins"] = int(item["wins"]) + 1
            item["outs"] = int(item["outs"]) + _outs(stat.innings_pitched)
            for field in ("hits", "earned_runs", "walks", "strikeouts", "batters_faced"):
                item[field] = int(item[field]) + int(getattr(stat, field) or 0)

    pitcher_leaders = []
    minimum_innings = max(len(game_teams) * 0.3, 1.0)
    for item in pitching_aggregates.values():
        outs = int(item["outs"])
        innings = outs / 3
        hits = int(item["hits"])
        walks = int(item["walks"])
        strikeouts = int(item["strikeouts"])
        batters_faced = int(item["batters_faced"])
        earned_runs = int(item["earned_runs"])
        pitcher_leaders.append(
            AttendancePitchingLeader(
                player_id=int(item["player_id"]),
                player_name=str(item["player_name"]),
                team_id=int(item["team_id"]),
                team_name=str(item["team_name"]),
                games=int(item["games"]),
                wins=int(item["wins"]),
                innings_pitched=float(f"{outs // 3}.{outs % 3}"),
                strikeouts=strikeouts,
                era=round(earned_runs * 9 / innings, 2) if innings else 0.0,
                whip=round((hits + walks) / innings, 2) if innings else 0.0,
                k_per_nine=round(strikeouts * 9 / innings, 2) if innings else 0.0,
                batting_average_against=round(hits / batters_faced, 3)
                if batters_faced
                else 0.0,
            )
        )
    pitcher_leaders.sort(
        key=lambda player: (
            player.innings_pitched >= minimum_innings,
            -player.era,
            -player.whip,
            player.k_per_nine,
        ),
        reverse=True,
    )
    stadium_names = {}
    stadium_ids = [stadium_id for stadium_id in stadium_values if stadium_id is not None]
    if stadium_ids:
        stadium_names = dict((await db.execute(
            select(Stadium.id, Stadium.name).where(Stadium.id.in_(stadium_ids))
        )).all())

    def breakdown(values, labels=None):
        items = []
        for key, (item_wins, item_draws, item_losses) in values.items():
            decisions = item_wins + item_losses
            label = (labels or {}).get(key, "구장 미정") if labels is not None else str(key)
            items.append(AttendanceBreakdown(
                label=label,
                games=item_wins + item_draws + item_losses,
                wins=item_wins,
                draws=item_draws,
                losses=item_losses,
                win_rate=round(item_wins / decisions * 100, 1) if decisions else 0.0,
            ))
        return sorted(items, key=lambda item: (item.win_rate, item.games), reverse=True)

    decisions = wins + losses
    return AttendanceSummaryRead(
        total_records=len(rows),
        qualified_games=len(game_teams),
        wins=wins,
        losses=losses,
        draws=draws,
        win_rate=round(wins / decisions * 100, 1) if decisions else 0.0,
        top_batting_players=leaders,
        top_pitchers=pitcher_leaders,
        decisive_hit_leaders=decisive_hit_leaders,
        decisive_hits=decisive_hits,
        weekday_records=breakdown(weekday_values),
        stadium_records=breakdown(stadium_values, stadium_names),
    )


@router.get("/{attendance_id}", response_model=AttendanceRead)
async def get_attendance(
    attendance_id: int,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> AttendanceRead:
    rows = await list_attendances(user, db, attendance_id)
    if not rows:
        raise HTTPException(status_code=404, detail="직관 기록을 찾을 수 없습니다.")
    return rows[0]


@router.patch("/{attendance_id}", response_model=AttendanceRead)
async def update_attendance(
    attendance_id: int,
    payload: AttendanceUpdate,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> AttendanceRead:
    record = await _owned_record(db, attendance_id, user.id)
    for key, value in payload.model_dump(exclude_unset=True).items():
        setattr(record, key, value)
    await db.commit()
    return await get_attendance(attendance_id, user, db)


@router.delete("/{attendance_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_attendance(
    attendance_id: int,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> Response:
    record = await _owned_record(db, attendance_id, user.id)
    await db.delete(record)
    await db.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)
