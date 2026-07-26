import unittest
from datetime import date, time

from worker.sources.kbo_source import (
    _status,
    _game_id_parts,
    parse_boxscore_html,
    parse_game_events_html,
    parse_schedule_html,
)


HTML = """
<table class="tbl"><tbody>
<tr>
  <td class="day" rowspan="2">07.01(수)</td>
  <td class="time"><b>18:30</b></td>
  <td class="play"><span>롯데</span><em><span class="win">5</span><span>vs</span><span class="lose">2</span></em><span>두산</span></td>
  <td class="relay"><a href="/Schedule/GameCenter/Main.aspx?gameDate=20260701&amp;gameId=20260701LTOB0&amp;section=REVIEW">리뷰</a></td>
  <td>하이라이트</td><td>KN-T</td><td></td><td>잠실</td><td>-</td>
</tr>
<tr>
  <td class="time"><b>18:30</b></td>
  <td class="play"><span>NC</span><em><span>vs</span></em><span>한화</span></td>
  <td class="relay"></td><td></td><td>MS-T</td><td></td><td>대전</td><td>우천취소</td>
</tr>
<tr>
  <td class="day">07.21(화)</td>
  <td class="time"><b>18:30</b></td>
  <td class="play"><span>한화</span><em><span>vs</span></em><span>KIA</span></td>
  <td class="relay"><a>리뷰</a></td><td></td><td>MS-T</td><td></td><td>광주</td><td>-</td>
</tr>
</tbody></table>
"""


class ParseScheduleHtmlTest(unittest.TestCase):
    def test_supports_fallback_game_id(self) -> None:
        self.assertEqual(
            _game_id_parts("20260726-WO-OB-1800"),
            ("20260726", "WO", "OB"),
        )

    def test_today_zero_score_without_relay_stays_scheduled(self) -> None:
        self.assertEqual(
            _status("", "", (0, 0), date.today()),
            "scheduled",
        )

    def test_past_game_with_scores_is_completed_without_relay_label(self) -> None:
        self.assertEqual(
            _status("", "", (4, 2), date(2026, 7, 25)),
            "completed",
        )

    def test_parses_completed_game(self) -> None:
        games = parse_schedule_html(HTML, 2026, 7)

        self.assertEqual(len(games), 3)
        self.assertEqual(games[0]["external_game_id"], "20260701LTOB0")
        self.assertEqual(games[0]["game_date"], date(2026, 7, 1))
        self.assertEqual(games[0]["game_time"], time(18, 30))
        self.assertEqual(games[0]["away_team_code"], "LT")
        self.assertEqual(games[0]["home_team_code"], "OB")
        self.assertEqual(games[0]["away_score"], 5)
        self.assertEqual(games[0]["home_score"], 2)
        self.assertEqual(games[0]["status"], "completed")
        self.assertEqual(games[0]["stadium_name"], "잠실야구장")

    def test_parses_cancelled_game_without_scores(self) -> None:
        games = parse_schedule_html(HTML, 2026, 7)

        self.assertEqual(games[1]["status"], "cancelled")
        self.assertIsNone(games[1]["away_score"])
        self.assertIsNone(games[1]["home_score"])
        self.assertEqual(games[1]["stadium_name"], "대전한화생명볼파크")

    def test_does_not_complete_game_without_scores(self) -> None:
        games = parse_schedule_html(HTML, 2026, 7)

        self.assertEqual(games[2]["status"], "scheduled")


BOXSCORE_HTML = """
<table id="tblAwayHitter1"><tbody>
<tr><th>1</th><th>중</th><td>황성빈</td></tr>
</tbody></table>
<table id="tblAwayHitter3"><tbody>
<tr><td>5</td><td>1</td><td>0</td><td>1</td><td>0.294</td></tr>
</tbody></table>
<table id="tblHomeHitter1"><tbody>
<tr><th>1</th><th>중</th><td>정수빈</td></tr>
</tbody></table>
<table id="tblHomeHitter3"><tbody>
<tr><td>5</td><td>0</td><td>0</td><td>0</td><td>0.268</td></tr>
</tbody></table>
<table id="tblEtc"><tbody>
<tr><th>도루</th><td>황성빈2(2회 7회) 정수빈(8회)</td></tr>
</tbody></table>
<table id="tblAwayPitcher"><tbody>
<tr><td>로드리게스</td><td>선발</td><td></td><td>4</td><td>5</td><td>0</td><td>7</td><td>27</td><td>97</td><td>26</td><td>6</td><td>0</td><td>0</td><td>8</td><td>1</td><td>1</td><td>4.52</td></tr>
</tbody></table>
<table id="tblHomePitcher"><tbody>
<tr><td>김동주</td><td>10.4</td><td></td><td>0</td><td>0</td><td>0</td><td>1/3</td><td>2</td><td>9</td><td>2</td><td>1</td><td>0</td><td>0</td><td>1</td><td>0</td><td>0</td><td>4.63</td></tr>
</tbody></table>
"""


class ParseBoxscoreHtmlTest(unittest.TestCase):
    def test_parses_hitters_and_pitchers(self) -> None:
        boxscore = parse_boxscore_html(BOXSCORE_HTML, "20260701LTOB0", "LT", "OB")

        self.assertEqual(len(boxscore["batting"]), 2)
        self.assertEqual(boxscore["batting"][0]["player_name"], "황성빈")
        self.assertEqual(boxscore["batting"][0]["ab"], 5)
        self.assertEqual(boxscore["batting"][0]["h"], 1)
        self.assertEqual(boxscore["batting"][0]["sb"], 2)
        self.assertEqual(boxscore["batting"][1]["sb"], 1)
        self.assertEqual(len(boxscore["pitching"]), 2)
        self.assertEqual(boxscore["pitching"][0]["pitches"], 97)
        self.assertEqual(boxscore["pitching"][1]["innings_pitched"], 0.1)


class ParseGameEventsHtmlTest(unittest.TestCase):
    def test_parses_normalized_relay_event(self) -> None:
        html = """
        <ul class="relay-list">
          <li data-inning="1" data-half="top" data-outs-before="0"
              data-base-before="000" data-score-diff-before="0"
              data-event-type="hit" data-runs="0" data-outs-after="0"
              data-base-after="100" data-score-diff-after="0"
              data-batter="홍길동" data-pitcher="투수1">1회초 홍길동 안타</li>
        </ul>
        """
        events = parse_game_events_html(html)

        self.assertEqual(len(events), 1)
        self.assertEqual(events[0]["inning"], 1)
        self.assertEqual(events[0]["inning_half"], "top")
        self.assertEqual(events[0]["event_type"], "hit")
        self.assertEqual(events[0]["base_state_after"], "100")


if __name__ == "__main__":
    unittest.main()
