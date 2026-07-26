import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_error.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/async_state_view.dart';
import '../../shared/widgets/team_brand.dart';
import '../auth/auth_controller.dart';

class MyTeamPage extends StatefulWidget {
  const MyTeamPage({super.key});

  @override
  State<MyTeamPage> createState() => _MyTeamPageState();
}

class _MyTeamPageState extends State<MyTeamPage> {
  late Future<Map<String, dynamic>> _summary;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    final teamId = AuthController.instance.user!.myTeamId!;
    _summary = ApiClient.instance.dio
        .get<Map<String, dynamic>>('/v1/teams/$teamId/season')
        .then((response) => response.data!);
  }

  Future<void> _changeTeam() async {
    final response =
        await ApiClient.instance.dio.get<List<dynamic>>('/v1/teams');
    if (!mounted) return;
    final teams = response.data!.cast<Map<String, dynamic>>();
    final selected = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 42,
              height: 5,
              decoration: BoxDecoration(
                  color: AppColors.line,
                  borderRadius: BorderRadius.circular(99)),
            ),
            const SizedBox(height: 18),
            const Text('응원팀 변경',
                style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900)),
            const SizedBox(height: 14),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: teams.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final team = teams[index];
                  return Card(
                    child: ListTile(
                      onTap: () => Navigator.pop(context, team),
                      leading: TeamMascotIcon(
                          teamName: team['name'] as String, size: 42),
                      title: Text(team['name'] as String,
                          style: const TextStyle(fontWeight: FontWeight.w900)),
                      trailing: const Icon(Icons.chevron_right_rounded),
                    ),
                  );
                },
              ),
            ),
          ]),
        ),
      ),
    );
    if (selected == null) return;
    await AuthController.instance.setMyTeam(
      selected['id'] as int,
      teamName: selected['name'] as String,
    );
    if (mounted) setState(_reload);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('나의 응원팀'),
        actions: [
          TextButton.icon(
            onPressed: _changeTeam,
            icon: const Icon(Icons.edit_rounded),
            label: const Text('변경'),
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _summary,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return AppErrorView(
              message: apiErrorMessage(snapshot.error!),
              onRetry: () => setState(_reload),
            );
          }
          final data = snapshot.data!;
          final brand = TeamBrand.resolve(data['team_name'] as String);
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient:
                      LinearGradient(colors: [brand.primary, brand.secondary]),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(children: [
                  TeamMascotIcon(
                      teamName: data['team_name'] as String, size: 82),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${data['season_year']} SEASON',
                              style: const TextStyle(color: Colors.white70)),
                          Text(data['team_name'] as String,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'Jua',
                                  fontSize: 28)),
                          Text('현재 ${data['rank']}위',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800)),
                        ]),
                  ),
                ]),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(children: [
                    Row(children: [
                      Expanded(
                          child: _TeamMetric(
                              label: '경기', value: '${data['games']}')),
                      Expanded(
                          child: _TeamMetric(
                              label: '승률', value: '${data['win_rate']}%')),
                    ]),
                    const Divider(height: 28),
                    Row(children: [
                      Expanded(
                          child: _TeamMetric(
                              label: '승', value: '${data['wins']}')),
                      Expanded(
                          child: _TeamMetric(
                              label: '패', value: '${data['losses']}')),
                      Expanded(
                          child: _TeamMetric(
                              label: '무', value: '${data['draws']}')),
                    ]),
                    const Divider(height: 28),
                    Row(children: [
                      Expanded(
                          child: _TeamMetric(
                              label: '득점', value: '${data['runs_scored']}')),
                      Expanded(
                          child: _TeamMetric(
                              label: '실점', value: '${data['runs_allowed']}')),
                      Expanded(
                          child: _TeamMetric(
                              label: '득실차',
                              value: '${data['run_difference']}')),
                    ]),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TeamMetric extends StatelessWidget {
  const _TeamMetric({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
      const SizedBox(height: 5),
      Text(value,
          style: const TextStyle(
              color: AppColors.ink, fontFamily: 'Jua', fontSize: 23)),
    ]);
  }
}
