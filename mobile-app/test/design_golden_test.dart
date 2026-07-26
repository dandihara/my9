import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seungyo_mobile_app/core/theme/app_theme.dart';
import 'package:seungyo_mobile_app/features/auth/login_page.dart';
import 'package:seungyo_mobile_app/features/auth/signup_page.dart';
import 'package:seungyo_mobile_app/shared/widgets/main_menu_button.dart';
import 'package:seungyo_mobile_app/shared/widgets/home_weather_backdrop.dart';
import 'package:seungyo_mobile_app/shared/widgets/stadium_shell.dart';

void main() {
  setUpAll(() async {
    final jua = FontLoader('Jua')
      ..addFont(rootBundle.load('assets/fonts/Jua-Regular.ttf'));
    final gowun = FontLoader('GowunDodum')
      ..addFont(rootBundle.load('assets/fonts/GowunDodum-Regular.ttf'));
    await Future.wait([jua.load(), gowun.load()]);
  });

  Future<void> preparePhone(WidgetTester tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Future<void> setViewport(
    WidgetTester tester,
    Size size, {
    double textScale = 1,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  }

  Widget app(Widget page) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: StadiumAppShell(child: page),
    );
  }

  testWidgets('login stadium theme renders without overflow', (tester) async {
    await preparePhone(tester);
    await tester.pumpWidget(app(const LoginPage()));
    await tester.pump(const Duration(milliseconds: 900));

    expect(tester.takeException(), isNull);
    await expectLater(
      find.byType(LoginPage),
      matchesGoldenFile('goldens/login_stadium.png'),
    );
  });

  testWidgets('signup stadium theme renders without overflow', (tester) async {
    await preparePhone(tester);
    await tester.pumpWidget(app(const SignupPage()));
    await tester.pump(const Duration(milliseconds: 900));

    expect(tester.takeException(), isNull);
    await expectLater(
      find.byType(SignupPage),
      matchesGoldenFile('goldens/signup_stadium.png'),
    );
  });

  for (final viewport in const [
    Size(320, 568),
    Size(360, 800),
    Size(390, 844),
    Size(430, 932),
    Size(600, 960),
  ]) {
    testWidgets(
      'auth screens stay responsive at ${viewport.width.toInt()}x${viewport.height.toInt()}',
      (tester) async {
        await setViewport(tester, viewport, textScale: 1.25);
        await tester.pumpWidget(app(const LoginPage()));
        await tester.pump(const Duration(milliseconds: 900));
        expect(tester.takeException(), isNull);

        await tester.pumpWidget(app(const SignupPage()));
        await tester.pump(const Duration(milliseconds: 900));
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('two-column stadium menu survives smallest phone',
      (tester) async {
    await setViewport(tester, const Size(320, 568), textScale: 1.25);
    await tester.pumpWidget(
      app(
        Scaffold(
          body: GridView.count(
            padding: const EdgeInsets.all(12),
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: .72,
            children: [
              for (var index = 0; index < 6; index++)
                MainMenuButton(
                  title: '경기 기록',
                  subtitle: '야구장의 모든 순간 모아보기',
                  icon: Icons.stadium_rounded,
                  tint: index.isEven ? AppColors.leaf : AppColors.butter,
                  onTap: () {},
                ),
            ],
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 900));
    expect(tester.takeException(), isNull);
  });

  for (final viewport in const [
    Size(390, 844),
    Size(430, 932),
  ]) {
    testWidgets(
      'mascot menu has no right overflow at ${viewport.width.toInt()} width',
      (tester) async {
        await setViewport(tester, viewport, textScale: 1.25);
        await tester.pumpWidget(
          app(
            Scaffold(
              body: GridView.count(
                padding: const EdgeInsets.all(16),
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: .72,
                children: [
                  for (var index = 0; index < 6; index++)
                    MainMenuButton(
                      title: '시즌 기록',
                      subtitle: '타자·투수 세이버메트릭스',
                      icon: Icons.stadium_rounded,
                      assetPath: 'assets/mascot_schedule.png',
                      tint: index.isEven ? AppColors.leaf : AppColors.butter,
                      onTap: () {},
                    ),
                ],
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 900));
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final condition in const [
    'clear',
    'cloudy',
    'rain',
    'snow',
    'night',
    'spring',
    'summer',
    'autumn',
    'winter',
  ]) {
    testWidgets('home $condition backdrop renders without exception',
        (tester) async {
      await setViewport(tester, const Size(430, 932));
      await tester.pumpWidget(
        app(HomeWeatherBackdrop(condition: condition)),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull);
    });
  }
}
