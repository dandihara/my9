import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seungyo_mobile_app/core/network/api_client.dart';
import 'package:seungyo_mobile_app/core/theme/app_theme.dart';
import 'package:seungyo_mobile_app/features/auth/login_page.dart';
import 'package:seungyo_mobile_app/features/auth/signup_page.dart';
import 'package:seungyo_mobile_app/features/attendance/attendance_page.dart';
import 'package:seungyo_mobile_app/features/stats/stats_page.dart';
import 'package:seungyo_mobile_app/features/team/standings_page.dart';
import 'package:seungyo_mobile_app/shared/widgets/stadium_shell.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final viewports = <Size>[
    const Size(320, 480),
    const Size(320, 568),
    const Size(360, 640),
    const Size(375, 667),
    const Size(390, 844),
    const Size(393, 852),
    const Size(412, 915),
    const Size(430, 932),
    const Size(480, 800),
    const Size(600, 960),
    const Size(839, 1080),
    const Size(840, 1200),
    const Size(568, 320),
    const Size(844, 390),
  ];

  setUpAll(() async {
    final jua = FontLoader('Jua')
      ..addFont(rootBundle.load('assets/fonts/Jua-Regular.ttf'));
    final gowun = FontLoader('GowunDodum')
      ..addFont(rootBundle.load('assets/fonts/GowunDodum-Regular.ttf'));
    await Future.wait([jua.load(), gowun.load()]);
    ApiClient.instance.dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) => handler.resolve(
          Response<dynamic>(
            requestOptions: options,
            statusCode: 200,
            data: _apiPayload(options.path),
          ),
        ),
      ),
    );
  });

  setUp(() => SharedPreferences.setMockInitialValues({}));

  Widget app(Widget page) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: StadiumAppShell(child: page),
      );

  Future<void> setViewport(
      WidgetTester tester, Size size, double textScale) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  }

  for (final viewport in viewports) {
    for (final textScale in const [1.0, 1.3]) {
      testWidgets(
        'core screens fit ${viewport.width.toInt()}x${viewport.height.toInt()} '
        'at ${textScale}x text',
        (tester) async {
          await setViewport(tester, viewport, textScale);
          for (final page in const <Widget>[
            LoginPage(),
            SignupPage(),
            StatsPage(),
            StandingsPage(),
            AttendancePage(),
          ]) {
            await tester.pumpWidget(app(page));
            await tester.pump(const Duration(milliseconds: 900));
            expect(tester.takeException(), isNull,
                reason: page.runtimeType.toString());
          }
        },
      );
    }
  }

  testWidgets('season stats redesign golden', (tester) async {
    await setViewport(tester, const Size(390, 844), 1);
    await tester.pumpWidget(app(const StatsPage()));
    await tester.pump(const Duration(milliseconds: 900));
    await tester.runAsync(
      () => precacheImage(
        const AssetImage('assets/player_ball_face.png'),
        tester.element(find.byType(StatsPage)),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    await expectLater(
      find.byType(StatsPage),
      matchesGoldenFile('goldens/stats_redesign.png'),
    );
  });

  testWidgets('top five toggles qualifying innings without hiding pitchers',
      (tester) async {
    await setViewport(tester, const Size(390, 844), 1);
    await tester.pumpWidget(app(const StatsPage()));
    await tester.pump(const Duration(milliseconds: 900));
    await tester.tap(find.text('투수'));
    await tester.pump(const Duration(milliseconds: 900));

    expect(find.text('TOP 5 · 비율 지표 규정이닝 적용'), findsOneWidget);
    expect(find.textContaining('규정이닝 미달 선수'), findsNothing);
    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    expect(find.text('TOP 5 · 비율 지표 규정이닝 미적용'), findsOneWidget);
    expect(find.text('테스트 선수'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('pitcher cards expose wins losses holds and saves',
      (tester) async {
    await setViewport(tester, const Size(390, 844), 1);
    await tester.pumpWidget(app(const StatsPage()));
    await tester.pump(const Duration(milliseconds: 900));
    await tester.tap(find.text('투수'));
    await tester.pump(const Duration(milliseconds: 900));
    await tester.drag(find.byType(ListView).first, const Offset(0, -700));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('승 8'), findsWidgets);
    expect(find.text('패 2'), findsWidgets);
    expect(find.text('홀드 12'), findsWidgets);
    expect(find.text('세이브 9'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('each metric card contains only its first five ranked players',
      (tester) async {
    await setViewport(tester, const Size(390, 844), 1);
    await tester.pumpWidget(app(const StatsPage()));
    await tester.pump(const Duration(milliseconds: 900));
    final strip = find.byWidgetPredicate(
      (widget) => widget.runtimeType.toString() == '_TopRecordStrip',
    );
    expect(find.descendant(of: strip, matching: find.text('테스트 선수 5')),
        findsWidgets);
    expect(find.descendant(of: strip, matching: find.text('테스트 선수 6')),
        findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final viewport in const [
    Size(320, 568),
    Size(390, 844),
    Size(600, 960),
    Size(844, 390),
  ]) {
    testWidgets(
        'ballpark team detail fits ${viewport.width}x${viewport.height}',
        (tester) async {
      await setViewport(tester, viewport, 1.3);
      await tester.pumpWidget(app(const StandingsPage()));
      await tester.pump(const Duration(milliseconds: 900));
      await tester.tap(find.text('두산 베어스').first);
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text('승부 요약'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}

dynamic _apiPayload(String path) {
  if (path == '/v1/teams/standings') return _standingsPayload();
  if (path == '/v1/attendances') return _attendancePayload();
  if (path == '/v1/attendances/summary') return _attendanceSummaryPayload();
  return _statsPayload(pitching: path.contains('pitching'));
}

Map<String, dynamic> _standingsPayload() => {
      'season_year': 2026,
      'as_of_date': '2026-08-03',
      'standings': [
        {
          'rank': 1,
          'team_name': '두산 베어스',
          'games': 97,
          'wins': 59,
          'losses': 36,
          'draws': 2,
          'win_rate': 62.1,
          'recent_10_wins': 8,
          'recent_10_draws': 1,
          'recent_10_losses': 1,
          'run_difference': 83,
          'team_batting_average': .283,
          'team_home_runs': 75,
          'team_hits': 957,
          'team_on_base_percentage': .366,
          'team_slugging_percentage': .405,
          'team_ops': .771,
          'team_era': 3.21,
          'team_whip': 1.18,
          'team_strikeouts': 741,
          'runs_scored': 498,
          'runs_allowed': 415,
        }
      ],
    };

List<Map<String, dynamic>> _attendancePayload() => [
      {
        'id': 1,
        'game_id': 10,
        'game_date': '2026-08-02',
        'away_team_id': 2,
        'away_team_name': 'LG 트윈스',
        'home_team_id': 1,
        'home_team_name': '두산 베어스',
        'my_team_id': 1,
        'result_for_my_team': 'win',
        'seat_section': '1루 내야석',
        'memo': '응원팀 승리',
      }
    ];

Map<String, dynamic> _attendanceSummaryPayload() => {
      'qualified_games': 1,
      'wins': 1,
      'losses': 0,
      'draws': 0,
      'win_rate': 100.0,
      'weekday_records': [
        {'label': '일', 'wins': 1, 'draws': 0, 'losses': 0, 'win_rate': 100.0}
      ],
      'stadium_records': [
        {
          'label': '잠실야구장',
          'wins': 1,
          'draws': 0,
          'losses': 0,
          'win_rate': 100.0
        }
      ],
      'top_batting_players': <dynamic>[],
      'top_pitchers': <dynamic>[],
      'decisive_hit_leaders': <dynamic>[],
    };

Map<String, dynamic> _statsPayload({required bool pitching}) {
  return {
    'season_year': 2026,
    'as_of_date': '2026-08-03',
    'methodology': 'responsive test fixture',
    'players': List.generate(6, (index) {
      final common = <String, dynamic>{
        'player_id': index + 1,
        'player_name': index == 0 ? '테스트 선수' : '테스트 선수 ${index + 1}',
        'team_name': 'NC 다이노스',
        'is_qualified': !pitching,
        'pa': 320 - index * 10,
        'qualification_pa': 280,
        'innings_pitched': 75 - index * 4,
        'qualification_innings': 100,
        'total_wpa': 1.25 - index * .05,
        'recent_games': <dynamic>[],
      };
      if (pitching) {
        return {
          ...common,
          'era': 2.31 + index * .1,
          'whip': 1.05 + index * .02,
          'wins': 8 - index,
          'losses': 2 + index,
          'holds': 12 - index,
          'saves': 9 - index,
          'strikeouts': 88 - index,
          'fip': 2.75 + index * .1,
          'k_bb': 4.2 - index * .1,
          'k_bb_percent': 19.1 - index * .2,
          'bb_per_nine': 2.1 + index * .1,
          'hits': 61 + index,
        };
      }
      return {
        ...common,
        'ops': .921 - index * .01,
        'avg': .312 - index * .005,
        'obp': .401 - index * .005,
        'slg': .520 - index * .005,
        'h': 101 - index,
        'hr': 21 - index,
        'rbi': 67 - index,
        'r': 72 - index,
        'sb': 11 - index,
        'estimated_wrc_plus': 143 - index,
      };
    }),
  };
}
