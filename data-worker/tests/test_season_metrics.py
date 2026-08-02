import unittest

from worker.jobs.refresh_season_metrics import (
    _display_innings,
    _outs,
    qualification_innings,
    qualification_plate_appearances,
)


class QualificationTest(unittest.TestCase):
    def test_plate_appearances_use_3_point_1_per_team_game(self) -> None:
        self.assertEqual(qualification_plate_appearances(100), 310)
        self.assertEqual(qualification_plate_appearances(95), 295)
        self.assertEqual(qualification_plate_appearances(1), 3)
        self.assertEqual(qualification_plate_appearances(101), 313)
        self.assertEqual(qualification_plate_appearances(144), 446)

    def test_innings_use_one_per_team_game(self) -> None:
        self.assertEqual(qualification_innings(100), 100)
        self.assertEqual(qualification_innings(0), 0)

    def test_baseball_innings_round_trip_as_outs(self) -> None:
        self.assertEqual(_outs(5.2), 17)
        self.assertEqual(_outs(5.1), 16)
        self.assertEqual(_display_innings(17), 5.2)


if __name__ == "__main__":
    unittest.main()
