from wpa_engine import GameEvent, GameState, WpaCalculator


def test_wpa_calculator_returns_delta() -> None:
    event = GameEvent(
        id=1,
        before=GameState(inning=9, inning_half="bottom", outs=2, base_state="100", score_diff=-1),
        after=GameState(inning=9, inning_half="bottom", outs=2, base_state="000", score_diff=1),
        batter_id=10,
        pitcher_id=20,
    )
    result = WpaCalculator().calculate_event(event)
    assert result.wpa > 0
