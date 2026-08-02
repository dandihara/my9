from types import SimpleNamespace

from app.services.decisive_hit import find_decisive_event


def event(team, batter, before, after, runs=1):
    return SimpleNamespace(
        batting_team_id=team,
        batter_id=batter,
        runs_scored=runs,
        score_diff_before=before,
        score_diff_after=after,
    )


def test_returns_lead_event_that_is_never_overturned():
    events = [
        event(1, 10, 0, 1),
        event(2, 20, 1, 0),
        event(1, 30, 0, 2),
        event(2, 40, 2, 1),
    ]
    assert find_decisive_event(events, winning_team_id=1, winner_sign=1) is events[2]


def test_returns_none_for_tie_or_non_batter_scoring_play():
    events = [event(1, None, 0, 1), event(2, 20, 1, 0)]
    assert find_decisive_event(events, winning_team_id=1, winner_sign=1) is None
