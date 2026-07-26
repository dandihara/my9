import unittest
from types import SimpleNamespace

from app.services.weather import stadium_coordinates, weather_condition


class WeatherTest(unittest.TestCase):
    def test_weather_code_is_mapped_to_app_condition(self) -> None:
        self.assertEqual(weather_condition(0, True), "clear")
        self.assertEqual(weather_condition(0, False), "night")
        self.assertEqual(weather_condition(3, True), "cloudy")
        self.assertEqual(weather_condition(63, True), "rain")
        self.assertEqual(weather_condition(73, False), "snow")

    def test_known_stadium_has_fallback_coordinates(self) -> None:
        stadium = SimpleNamespace(
            name="잠실야구장",
            latitude=None,
            longitude=None,
        )

        self.assertIsNotNone(stadium_coordinates(stadium))


if __name__ == "__main__":
    unittest.main()
