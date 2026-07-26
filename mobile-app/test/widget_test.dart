import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seungyo_mobile_app/core/models/game.dart';
import 'package:seungyo_mobile_app/features/auth/login_page.dart';

void main() {
  test('game response parsing', () {
    final game = GameModel.fromJson({
      'id': 1,
      'game_date': '2026-07-01',
      'game_time': '18:30:00',
      'away_team_name': 'KT',
      'home_team_name': '한화',
      'status': 'completed',
      'away_score': 7,
      'home_score': 4,
    });

    expect(game.scoreText, '7 : 4');
    expect(game.homeTeamName, '한화');
  });

  testWidgets('login screen renders empty credential fields', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginPage()));

    expect(find.text('MY9'), findsOneWidget);
    final fields = tester.widgetList<TextField>(find.byType(TextField));
    expect(fields.every((field) => field.controller?.text.isEmpty ?? true),
        isTrue);
    expect(find.text('로그인'), findsOneWidget);
    expect(find.text('처음이신가요? 회원가입'), findsOneWidget);
  });
}
