import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seungyo_mobile_app/core/network/api_client.dart';
import 'package:seungyo_mobile_app/core/theme/app_theme.dart';
import 'package:seungyo_mobile_app/features/auth/login_page.dart';
import 'package:seungyo_mobile_app/features/auth/signup_page.dart';
import 'package:seungyo_mobile_app/features/stats/stats_page.dart';
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
          Response<Map<String, dynamic>>(
            requestOptions: options,
            statusCode: 200,
            data: _statsPayload(pitching: options.path.contains('pitching')),
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
}

Map<String, dynamic> _statsPayload({required bool pitching}) {
  final common = <String, dynamic>{
    'player_id': 1,
    'player_name': '테스트 선수',
    'team_name': 'NC 다이노스',
    'is_qualified': true,
    'total_wpa': 1.25,
    'recent_games': <dynamic>[],
  };
  return {
    'season_year': 2026,
    'as_of_date': '2026-08-03',
    'methodology': 'responsive test fixture',
    'players': [
      if (pitching)
        {
          ...common,
          'era': 2.31,
          'whip': 1.05,
          'strikeouts': 88,
          'fip': 2.75,
          'k_bb': 4.2,
          'k_bb_percent': 19.1,
          'bb_per_nine': 2.1,
          'hits': 61,
        }
      else
        {
          ...common,
          'ops': .921,
          'avg': .312,
          'obp': .401,
          'slg': .520,
          'h': 101,
          'hr': 21,
          'rbi': 67,
          'r': 72,
          'sb': 11,
          'estimated_wrc_plus': 143,
        },
    ],
  };
}
