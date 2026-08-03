from app.routers.stats import _pitching_decision_field


def test_pitching_decision_field_recognizes_kbo_labels():
    assert _pitching_decision_field("승") == "wins"
    assert _pitching_decision_field("패") == "losses"
    assert _pitching_decision_field("홀드") == "holds"
    assert _pitching_decision_field("홀") == "holds"
    assert _pitching_decision_field("세이브") == "saves"
    assert _pitching_decision_field("세") == "saves"


def test_pitching_decision_field_ignores_blank_or_unknown_labels():
    assert _pitching_decision_field(None) is None
    assert _pitching_decision_field("  ") is None
    assert _pitching_decision_field("무관") is None
