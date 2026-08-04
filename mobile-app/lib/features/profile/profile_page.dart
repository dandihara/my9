import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_error.dart';
import '../../core/services/game_companion_service.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/async_state_view.dart';
import '../auth/auth_controller.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late Future<List<dynamic>> _achievements = _load();
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((prefs) {
      if (mounted) {
        setState(() => _notificationsEnabled =
            prefs.getBool('game_notifications') ?? true);
      }
    });
  }

  Future<void> _setNotifications(bool enabled) async {
    setState(() => _notificationsEnabled = enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('game_notifications', enabled);
    await GameCompanionService.setNotificationsEnabled(enabled);
  }

  Future<List<dynamic>> _load() async => (await ApiClient.instance.dio
          .get<List<dynamic>>('/v1/auth/me/achievements'))
      .data!;

  @override
  Widget build(BuildContext context) {
    final user = AuthController.instance.user!;
    return Scaffold(
      appBar: AppBar(title: const Text('마이페이지')),
      body: FutureBuilder<List<dynamic>>(
        future: _achievements,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return AppErrorView(
              message: apiErrorMessage(snapshot.error!),
              onRetry: () => setState(() => _achievements = _load()),
            );
          }
          final rows = snapshot.data!.cast<Map<String, dynamic>>();
          rows.sort((a, b) => (b['unlocked'] == true ? 1 : 0)
              .compareTo(a['unlocked'] == true ? 1 : 0));
          final unlocked = rows.where((row) => row['unlocked'] == true).length;
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [
                    Color(0xFF10172A), Color(0xFF314B76), Color(0xFF147A63)
                  ]),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: const [BoxShadow(color: Color(0x44314776), blurRadius: 22, offset: Offset(0, 10))],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(user.nickname ?? user.username,
                        style: const TextStyle(color: Colors.white, fontSize: 23,
                            fontWeight: FontWeight.w900)),
                    const SizedBox(height: 6),
                    Text('업적 $unlocked / ${rows.length}',
                        style: const TextStyle(color: AppColors.leaf)),
                  ]),
                ),
              ),
              const SizedBox(height: 20),
              Card(
                color: AppColors.butter.withValues(alpha: .72),
                child: SwitchListTile(
                  value: _notificationsEnabled,
                  onChanged: _setNotifications,
                  secondary: const Icon(Icons.notifications_active_rounded,
                      color: AppColors.coral),
                  title: const Text('경기 시작 알림',
                      style: TextStyle(fontWeight: FontWeight.w900)),
                  subtitle: const Text('MY팀 경기 1시간 전에 알려드려요.'),
                ),
              ),
              const SizedBox(height: 20),
              const Text('나의 업적', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
              const SizedBox(height: 10),
              ...rows.map((row) {
                final unlocked = row['unlocked'] == true;
                final current = row['current'] as int;
                final target = row['target'] as int;
                final accent = unlocked ? const Color(0xFFFFC44D) : AppColors.line;
                return Card(
                  color: unlocked ? const Color(0xFFFFF2C5) : AppColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                    side: BorderSide(color: accent, width: unlocked ? 2 : 1),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: unlocked ? AppColors.butter : AppColors.line,
                      child: Icon(unlocked ? Icons.emoji_events_rounded : Icons.lock_outline_rounded,
                          color: AppColors.ink),
                    ),
                    title: Text(row['title'] as String,
                        style: const TextStyle(fontWeight: FontWeight.w900)),
                    subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(row['description'] as String),
                      const SizedBox(height: 6),
                      LinearProgressIndicator(value: current / target),
                    ]),
                    trailing: Text('$current/$target'),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}
