import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../core/network/api_client.dart';

class AuthUser {
  const AuthUser({
    required this.id,
    required this.username,
    this.nickname,
    this.myTeamId,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
        id: json['id'] as int,
        username: json['username'] as String,
        nickname: json['nickname'] as String?,
        myTeamId: json['my_team_id'] as int?,
      );

  final int id;
  final String username;
  final String? nickname;
  final int? myTeamId;
}

class AuthController extends ChangeNotifier {
  AuthController._();

  static final AuthController instance = AuthController._();

  final ApiClient _api = ApiClient.instance;
  static const _iconChannel = MethodChannel('seungyo/app_icon');
  AuthUser? user;
  String? myTeamName;

  bool get isAuthenticated => user != null;

  Future<void> initialize() async {
    await _api.initialize();
    if (!_api.hasToken) return;
    try {
      final response = await _api.dio.get<Map<String, dynamic>>('/v1/auth/me');
      user = AuthUser.fromJson(response.data!);
      await _syncMyTeamName();
    } catch (_) {
      await _api.clearToken();
    }
  }

  Future<void> login(String username, String password) async {
    final response = await _api.dio.post<Map<String, dynamic>>(
      '/v1/auth/login',
      data: {'username': username, 'password': password},
    );
    await _applySession(response.data!);
  }

  Future<void> register(
      String username, String password, String nickname) async {
    final response = await _api.dio.post<Map<String, dynamic>>(
      '/v1/auth/register',
      data: {
        'username': username,
        'password': password,
        'nickname': nickname.isEmpty ? username : nickname,
      },
    );
    await _applySession(response.data!);
  }

  Future<void> _applySession(Map<String, dynamic> data) async {
    await _api.setToken(data['access_token'] as String);
    user = AuthUser.fromJson(data['user'] as Map<String, dynamic>);
    await _syncMyTeamName();
    notifyListeners();
  }

  Future<void> logout() async {
    await _api.clearToken();
    user = null;
    myTeamName = null;
    notifyListeners();
  }

  Future<void> setMyTeam(int teamId, {String? teamName}) async {
    final response = await _api.dio.patch<Map<String, dynamic>>(
      '/v1/auth/me',
      data: {'my_team_id': teamId},
    );
    user = AuthUser.fromJson(response.data!);
    myTeamName = teamName;
    await _syncMyTeamName(teamName: teamName);
    notifyListeners();
  }

  Future<void> _syncMyTeamName({String? teamName}) async {
    try {
      if (teamName == null && user?.myTeamId != null) {
        final response = await _api.dio.get<Map<String, dynamic>>(
          '/v1/teams/${user!.myTeamId}',
        );
        teamName = response.data?['name'] as String?;
      }
      myTeamName = teamName;
      // Changing an Android launcher alias while this activity is running can
      // terminate the process on some devices. In-app team branding is enough.
      if (defaultTargetPlatform == TargetPlatform.android) return;
      if (defaultTargetPlatform != TargetPlatform.android) return;
      await _iconChannel.invokeMethod<void>(
        'setTeamIcon',
        {'team': teamName?.contains('두산') == true ? 'doosan' : 'default'},
      );
    } catch (_) {
      // Icon switching is cosmetic and must never block authentication.
    }
  }
}
