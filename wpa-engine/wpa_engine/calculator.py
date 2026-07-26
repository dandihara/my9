from wpa_engine.models import GameEvent, WpaResult
from wpa_engine.win_expectancy import SimpleWinExpectancyModel


class WpaCalculator:
    def __init__(self) -> None:
        self.model = SimpleWinExpectancyModel()

    def calculate_event(self, event: GameEvent) -> WpaResult:
        we_before = self.model.estimate(event.before)
        we_after = self.model.estimate(event.after)
        return WpaResult(
            event_id=event.id,
            we_before=we_before,
            we_after=we_after,
            wpa=we_after - we_before,
            batter_id=event.batter_id,
            pitcher_id=event.pitcher_id,
        )
