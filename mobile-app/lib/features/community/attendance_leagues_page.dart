import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_error.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/async_state_view.dart';

class AttendanceLeaguesPage extends StatefulWidget {
  const AttendanceLeaguesPage({super.key});

  @override
  State<AttendanceLeaguesPage> createState() => _AttendanceLeaguesPageState();
}

class _AttendanceLeaguesPageState extends State<AttendanceLeaguesPage> {
  late Future<List<Map<String, dynamic>>> _leagues;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _leagues = ApiClient.instance.dio
        .get<List<dynamic>>('/v1/attendance-leagues')
        .then((response) => response.data!.cast<Map<String, dynamic>>());
  }

  Future<void> _inputDialog({required bool join}) async {
    final controller = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(join ? '초대 코드로 참가' : '새 직관 리그'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: join ? 20 : 60,
          decoration: InputDecoration(labelText: join ? '초대 코드' : '모임 이름'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('취소')),
          FilledButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: Text(join ? '참가' : '만들기')),
        ],
      ),
    );
    controller.dispose();
    if (value == null || value.isEmpty) return;
    try {
      if (join) {
        await ApiClient.instance.dio
            .post('/v1/attendance-leagues/join', data: {'invite_code': value});
      } else {
        await ApiClient.instance.dio
            .post('/v1/attendance-leagues', data: {'name': value});
      }
      if (!mounted) return;
      setState(_reload);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(apiErrorMessage(error))));
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('직관 리그')),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _inputDialog(join: false),
          icon: const Icon(Icons.add_rounded),
          label: const Text('모임 만들기'),
        ),
        body: FutureBuilder<List<Map<String, dynamic>>>(
          future: _leagues,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return AppErrorView(
                  message: apiErrorMessage(snapshot.error!),
                  onRetry: () => setState(_reload));
            }
            final leagues = snapshot.data!;
            return RefreshIndicator(
              onRefresh: () async {
                setState(_reload);
                await _leagues;
              },
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 100),
                children: [
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [AppColors.forest, Color(0xFF53C4A7)]),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.emoji_events_rounded,
                              color: AppColors.butter, size: 34),
                          const SizedBox(height: 12),
                          const Text('친구들과 직관 승률 대결',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900)),
                          const SizedBox(height: 6),
                          const Text('응원팀과 관계없이 승·무·패 기록만으로 순위를 정해요.',
                              style: TextStyle(
                                  color: Colors.white70, height: 1.45)),
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: () => _inputDialog(join: true),
                            style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(color: Colors.white54)),
                            icon: const Icon(Icons.login_rounded),
                            label: const Text('초대 코드로 참가'),
                          ),
                        ]),
                  ),
                  const SizedBox(height: 18),
                  if (leagues.isEmpty)
                    const AppEmptyView(
                        title: '참가한 리그가 없어요',
                        message: '모임을 만들거나 친구에게 받은 초대 코드로 참가해 보세요.',
                        icon: Icons.groups_rounded)
                  else
                    ...leagues.map((league) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Card(
                              child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 10),
                            leading: CircleAvatar(
                                backgroundColor: AppColors.butter,
                                child: Text('${league['member_count']}',
                                    style: const TextStyle(
                                        color: AppColors.ink,
                                        fontWeight: FontWeight.w900))),
                            title: Text(league['name'] as String,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w900)),
                            subtitle: Text('${league['member_count']}명 참가 중'),
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: () => context
                                .push('/attendance-leagues/${league['id']}'),
                          )),
                        )),
                ],
              ),
            );
          },
        ),
      );
}

class AttendanceLeagueDetailPage extends StatefulWidget {
  const AttendanceLeagueDetailPage({required this.leagueId, super.key});
  final int leagueId;

  @override
  State<AttendanceLeagueDetailPage> createState() =>
      _AttendanceLeagueDetailPageState();
}

class _AttendanceLeagueDetailPageState
    extends State<AttendanceLeagueDetailPage> {
  late Future<Map<String, dynamic>> _detail;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _detail = ApiClient.instance.dio
        .get<Map<String, dynamic>>('/v1/attendance-leagues/${widget.leagueId}')
        .then((response) => response.data!);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('리그 순위')),
        body: FutureBuilder<Map<String, dynamic>>(
          future: _detail,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return AppErrorView(
                  message: apiErrorMessage(snapshot.error!),
                  onRetry: () => setState(_load));
            }
            final data = snapshot.data!;
            final rankings = (data['rankings'] as List<dynamic>)
                .cast<Map<String, dynamic>>();
            final inviteCode = data['invite_code'] as String;
            return ListView(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
                children: [
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                        color: AppColors.ink,
                        borderRadius: BorderRadius.circular(28)),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(data['name'] as String,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900)),
                          const SizedBox(height: 6),
                          Text('${data['member_count']}명의 직관 대결',
                              style: const TextStyle(color: Colors.white60)),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                              onPressed: () async {
                                await Clipboard.setData(ClipboardData(
                                    text: 'MY9 직관 리그 초대 코드: $inviteCode'));
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text('초대 코드가 복사됐어요.')));
                                }
                              },
                              icon: const Icon(Icons.ios_share_rounded),
                              label: Text('초대 코드 $inviteCode')),
                        ]),
                  ),
                  const SizedBox(height: 16),
                  ...rankings.map((row) => Card(
                          child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(children: [
                          SizedBox(
                              width: 38,
                              child: Text('${row['rank']}',
                                  style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                      color: row['rank'] == 1
                                          ? AppColors.coral
                                          : AppColors.ink))),
                          Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                Text(
                                    (row['nickname'] ?? row['username'])
                                        as String,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 16)),
                                Text(
                                    '${row['wins']}승 ${row['draws']}무 ${row['losses']}패 · ${row['games']}경기',
                                    style: const TextStyle(
                                        color: AppColors.muted, fontSize: 12)),
                              ])),
                          Text('${row['win_rate']}%',
                              style: const TextStyle(
                                  color: AppColors.forest,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900)),
                        ]),
                      ))),
                ]);
          },
        ),
      );
}
