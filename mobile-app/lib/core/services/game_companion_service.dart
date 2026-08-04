import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class GameCompanionService {
  static const _channel = MethodChannel('seungyo/game_companion');

  static Future<void> updateNextGame(Map<String, dynamic>? game) async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await _channel.invokeMethod<void>('updateNextGame', game == null
          ? <String, dynamic>{}
          : {
              'gameId': game['game_id'],
              'gameDate': game['game_date'],
              'gameTime': game['game_time'],
              'opponent': game['opponent_name'],
              'stadium': game['stadium_name'],
            });
    } catch (_) {
      // 위젯·알림 실패가 홈 화면 데이터 로딩을 막아서는 안 된다.
    }
  }

  static Future<void> setNotificationsEnabled(bool enabled) async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    await _channel.invokeMethod<void>(
        'setNotificationsEnabled', {'enabled': enabled});
  }
}
