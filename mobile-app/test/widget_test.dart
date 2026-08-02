import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seungyo_mobile_app/core/models/game.dart';
import 'package:seungyo_mobile_app/features/auth/login_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  testWidgets('login screen renders account memory option', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const MaterialApp(home: LoginPage()));
    await tester.pump();

    final fields = tester.widgetList<TextField>(find.byType(TextField));
    expect(fields.every((field) => field.controller?.text.isEmpty ?? true),
        isTrue);
    expect(find.text('계정 기억하기'), findsOneWidget);
    expect(tester.widget<CheckboxListTile>(find.byType(CheckboxListTile)).value,
        isFalse);
  });

  testWidgets('login screen restores a remembered account', (tester) async {
    SharedPreferences.setMockInitialValues({
      'remember_account': true,
      'remembered_username': 'remember-me',
    });
    await tester.pumpWidget(const MaterialApp(home: LoginPage()));
    await tester.pump();

    final fields =
        tester.widgetList<TextField>(find.byType(TextField)).toList();
    expect(fields.first.controller?.text, 'remember-me');
    expect(tester.widget<CheckboxListTile>(find.byType(CheckboxListTile)).value,
        isTrue);
  });
}
