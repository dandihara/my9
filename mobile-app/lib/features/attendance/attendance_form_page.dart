import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_error.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/team_brand.dart';
import '../auth/auth_controller.dart';

class AttendanceFormPage extends StatefulWidget {
  const AttendanceFormPage({required this.gameId, super.key});

  final int gameId;

  @override
  State<AttendanceFormPage> createState() => _AttendanceFormPageState();
}

class _AttendanceFormPageState extends State<AttendanceFormPage> {
  final _memo = TextEditingController();
  late Future<Map<String, dynamic>> _game;
  int? _myTeamId;
  bool _isNeutral = false;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _game = _loadGame();
  }

  Future<Map<String, dynamic>> _loadGame() async {
    final response = await ApiClient.instance.dio
        .get<Map<String, dynamic>>('/v1/games/${widget.gameId}');
    final game = response.data!;
    final defaultTeam = AuthController.instance.user?.myTeamId;
    if (defaultTeam == game['home_team_id'] ||
        defaultTeam == game['away_team_id']) {
      _myTeamId = defaultTeam;
    }
    return game;
  }

  @override
  void dispose() {
    _memo.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_myTeamId == null && !_isNeutral) {
      setState(() => _error = '응원한 팀을 선택해 주세요.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ApiClient.instance.dio.post('/v1/attendances', data: {
        'game_id': widget.gameId,
        'is_neutral': _isNeutral,
        'my_team_id': _myTeamId,
        'memo': _memo.text.trim().isEmpty ? null : _memo.text.trim(),
      });
      if (mounted) {
        if (context.canPop()) {
          context.pop(true);
        } else {
          context.go('/schedule');
        }
      }
    } on DioException catch (error) {
      setState(() => _error = apiErrorMessage(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('직관 기록하기')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: const BoxDecoration(
                color: AppColors.ink,
                borderRadius: BorderRadius.all(Radius.circular(28))),
            child: const Row(children: [
              Icon(Icons.edit_calendar_rounded,
                  color: AppColors.butter, size: 36),
              SizedBox(width: 16),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('오늘의 야구를 남겨요',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800)),
                Text('직관의 순간을 기록해 보세요',
                    style: TextStyle(color: Colors.white70)),
              ]),
            ]),
          ),
          const SizedBox(height: 16),
          FutureBuilder<Map<String, dynamic>>(
            future: _game,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Card(
                    child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: CircularProgressIndicator())));
              }
              if (snapshot.hasError) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(apiErrorMessage(snapshot.error!),
                        style: const TextStyle(color: AppColors.coral)),
                  ),
                );
              }
              final game = snapshot.data!;
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('어느 팀을 응원했나요?',
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 14),
                        Row(children: [
                          Expanded(
                            child: _TeamChoice(
                              teamId: game['away_team_id'] as int,
                              teamName: game['away_team_name'] as String,
                              selected: _myTeamId == game['away_team_id'],
                              onTap: () => setState(() {
                                _isNeutral = false;
                                _myTeamId = game['away_team_id'] as int;
                              }),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _TeamChoice(
                              teamId: game['home_team_id'] as int,
                              teamName: game['home_team_name'] as String,
                              selected: _myTeamId == game['home_team_id'],
                              onTap: () => setState(() {
                                _isNeutral = false;
                                _myTeamId = game['home_team_id'] as int;
                              }),
                            ),
                          ),
                        ]),
                        const SizedBox(height: 12),
                        InkWell(
                          onTap: () => setState(() {
                            _isNeutral = true;
                            _myTeamId = null;
                          }),
                          borderRadius: BorderRadius.circular(16),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: _isNeutral
                                  ? AppColors.leaf.withValues(alpha: .22)
                                  : AppColors.cream,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _isNeutral
                                    ? AppColors.forest
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Row(children: [
                              Icon(Icons.sports_baseball_rounded,
                                  color: _isNeutral
                                      ? AppColors.forest
                                      : AppColors.muted),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('응원팀 없이 관람',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w900)),
                                    Text('승·무·패와 승률 집계에서는 제외돼요.',
                                        style: TextStyle(
                                            color: AppColors.muted,
                                            fontSize: 11)),
                                  ],
                                ),
                              ),
                              Icon(_isNeutral
                                  ? Icons.check_circle_rounded
                                  : Icons.circle_outlined),
                            ]),
                          ),
                        ),
                      ]),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(children: [
                TextField(
                  controller: _memo,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: '오늘의 메모',
                    alignLabelWithHint: true,
                    prefixIcon: Icon(Icons.notes_rounded),
                  ),
                ),
              ]),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: AppColors.coral)),
          ],
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: const Icon(Icons.check_rounded),
            label: Text(_saving ? '저장 중...' : '기록 저장'),
          ),
        ],
      ),
    );
  }
}

class _TeamChoice extends StatelessWidget {
  const _TeamChoice({
    required this.teamId,
    required this.teamName,
    required this.selected,
    required this.onTap,
  });

  final int teamId;
  final String teamName;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final brand = TeamBrand.resolve(teamName);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color:
              selected ? brand.primary.withValues(alpha: .1) : AppColors.cream,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: selected ? brand.primary : Colors.transparent, width: 2),
        ),
        child: Column(children: [
          TeamBadge(teamName: teamName),
          const SizedBox(height: 8),
          Text(teamName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: selected ? brand.primary : AppColors.ink,
                  fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Icon(selected ? Icons.check_circle_rounded : Icons.circle_outlined,
              size: 18, color: selected ? brand.primary : AppColors.muted),
        ]),
      ),
    );
  }
}
