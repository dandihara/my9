from collections.abc import Sequence
from typing import Protocol, TypeVar


class ScoringEvent(Protocol):
    batting_team_id: int
    batter_id: int | None
    runs_scored: int
    score_diff_before: int | None
    score_diff_after: int | None


EventT = TypeVar("EventT", bound=ScoringEvent)


def find_decisive_event(
    events: Sequence[EventT], *, winning_team_id: int, winner_sign: int
) -> EventT | None:
    """Return the scoring event that created the winner's final, never-lost lead."""
    for index, event in enumerate(events):
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
        if all(
            later.score_diff_after is not None
            and winner_sign * later.score_diff_after > 0
            for later in events[index:]
        ):
            return event
    return None


def find_favorite_team_decisive_event(
    events: Sequence[EventT],
    *,
    favorite_team_id: int | None,
    home_team_id: int,
    away_team_id: int,
    home_score: int | None,
    away_score: int | None,
) -> EventT | None:
    """Return a decisive hit only when the user's favorite team won the game."""
    if (
        favorite_team_id is None
        or favorite_team_id not in (home_team_id, away_team_id)
        or home_score is None
        or away_score is None
        or home_score == away_score
    ):
        return None
    winning_team_id = home_team_id if home_score > away_score else away_team_id
    if winning_team_id != favorite_team_id:
        return None
    return find_decisive_event(
        events,
        winning_team_id=favorite_team_id,
        winner_sign=1 if favorite_team_id == home_team_id else -1,
    )
