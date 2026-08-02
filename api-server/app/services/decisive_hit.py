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
