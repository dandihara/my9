from wpa_engine.models import GameState


class SimpleWinExpectancyModel:
    """초기 개발용 간이 WE 모델.

    실제 서비스에서는 KBO 과거 이벤트 데이터 기반 win_expectancy_table을 사용하세요.
    """

    def estimate(self, state: GameState) -> float:
        score_component = state.score_diff * 0.08
        inning_component = min(state.inning, 12) * 0.01
        out_component = state.outs * -0.015
        base_component = state.base_state.count("1") * 0.02
        home_half_bonus = 0.015 if state.inning_half == "bottom" else 0.0
        raw = 0.5 + score_component + inning_component + out_component + base_component + home_half_bonus
        return max(0.01, min(0.99, raw))
