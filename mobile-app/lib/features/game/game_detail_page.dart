import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_error.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/async_state_view.dart';
import '../../shared/widgets/team_brand.dart';

class GameDetailPage extends StatefulWidget {
  const GameDetailPage({required this.gameId, super.key});

  final int gameId;

  @override
  State<GameDetailPage> createState() => _GameDetailPageState();
}

class _GameDetailPageState extends State<GameDetailPage> {
  late Future<Map<String, dynamic>> _stats;
  late Future<Map<String, dynamic>?> _live;
  Timer? _liveTimer;
  int? _selectedTeamId;
  bool _showBatting = true;

  @override
  void initState() {
    super.initState();
    _reload();
    _liveTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) setState(() => _live = _fetchLive());
    });
  }

  Future<Map<String, dynamic>?> _fetchLive() async {
    try {
      final response = await ApiClient.instance.dio
          .get<Map<String, dynamic>>('/v1/games/${widget.gameId}/live');
      return response.data;
    } catch (_) {
      return null;
    }
  }

  void _reload() {
    _live = _fetchLive();
    _stats = Future.wait([
      ApiClient.instance.dio
          .get<Map<String, dynamic>>('/v1/games/${widget.gameId}/stats'),
      ApiClient.instance.dio
          .get<Map<String, dynamic>>('/v1/games/${widget.gameId}'),
    ]).then((responses) => {
          ...responses[0].data!,
          'game': responses[1].data!,
        });
  }

  @override
  void dispose() {
    _liveTimer?.cancel();
    super.dispose();
  }

  static String _positionLabel(Object? raw) {
    final value = raw?.toString().trim() ?? '-';
    const labels = {
      '좌': '좌익수',
      '좌익': '좌익수',
      '중': '중견수',
      '중견': '중견수',
      '우': '우익수',
      '우익': '우익수',
      '1': '1루수',
      '一': '1루수',
      '2': '2루수',
      '二': '2루수',
      '3': '3루수',
      '三': '3루수',
      '포': '포수',
      '유': '유격수',
      '지': '지명타자',
      '타': '대타',
      '주': '대주자',
      '투': '투수',
    };
    final exact = labels[value];
    if (exact != null) return exact;

    // KBO는 한 경기에서 수비 위치가 바뀐 선수를 "중우", "유2"처럼
    // 이동 순서대로 붙여 내려준다. 각 위치를 풀어 쓰고 화살표로 연결해
    // 중견수 → 우익수처럼 실제 수비 이동 흐름이 보이게 한다.
    final transitions = value.characters
        .map((token) => labels[token])
        .whereType<String>()
        .toList();
    if (transitions.length > 1 &&
        transitions.length == value.characters.length) {
      return transitions.join(' → ');
    }
    return value;
  }

  static List<List<Map<String, dynamic>>> _lineups(List<dynamic> rows) {
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (var index = 0; index < rows.length; index++) {
      final row = rows[index] as Map<String, dynamic>;
      final order = row['batting_order'];
      final key = order == null
          ? '${row['team_id']}:player:$index'
          : '${row['team_id']}:order:$order';
      grouped.putIfAbsent(key, () => []).add(row);
    }
    return grouped.values.toList();
  }

  Widget _battingSection(
      List<dynamic> rows, List<Map<String, dynamic>> plateAppearances) {
    final groups = _lineups(rows);
    return _Section(
      title: '타자 기록',
      count: rows.length,
      icon: Icons.sports_baseball_rounded,
      color: AppColors.coral,
      child: Column(
        children: groups.asMap().entries.map((entry) {
          final lineup = entry.value;
          return _BattingLineupCard(
            lineup: lineup,
            plateAppearances: plateAppearances,
            positionLabel: _positionLabel,
            showDivider: entry.key != groups.length - 1,
          );
        }).toList(),
      ),
    );
  }

  Widget _pitchingSection(List<dynamic> rows) {
    return _Section(
      title: '투수 기록',
      count: rows.length,
      icon: Icons.speed_rounded,
      color: AppColors.forest,
      child: Column(
        children: rows.asMap().entries.map((entry) {
          final row = entry.value as Map<String, dynamic>;
          return _PlayerRow(
            index: entry.key + 1,
            name: row['player_name']?.toString() ?? '-',
            teamName: row['team_name']?.toString() ?? '-',
            position: '투수',
            metrics:
                '${row['innings_pitched'] ?? '-'}이닝  ${row['strikeouts'] ?? 0}K  ${row['earned_runs'] ?? 0}자책',
            color: AppColors.forest,
            showDivider: entry.key != rows.length - 1,
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('선수 기록')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _stats,
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
          final game = data['game'] as Map<String, dynamic>;
          final awayTeamId = game['away_team_id'] as int;
          final homeTeamId = game['home_team_id'] as int;
          final selectedTeamId = _selectedTeamId ?? awayTeamId;
          final batting = (data['batting'] as List<dynamic>)
              .where((row) =>
                  (row as Map<String, dynamic>)['team_id'] == selectedTeamId)
              .toList();
          final pitching = (data['pitching'] as List<dynamic>)
              .where((row) =>
                  (row as Map<String, dynamic>)['team_id'] == selectedTeamId)
              .toList();
          final plateAppearances =
              (data['plate_appearances'] as List<dynamic>? ?? const [])
                  .cast<Map<String, dynamic>>()
                  .where((row) => row['batting_team_id'] == selectedTeamId)
                  .toList();
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: const BoxDecoration(
                    color: AppColors.ink,
                    borderRadius: BorderRadius.all(Radius.circular(28))),
                child: const Row(children: [
                  Icon(Icons.analytics_rounded,
                      size: 38, color: AppColors.leaf),
                  SizedBox(width: 14),
                  Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('GAME BOX SCORE',
                            style: TextStyle(
                                color: AppColors.butter,
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2)),
                        Text('타자·투수 상세 기록',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w800)),
                      ]),
                ]),
              ),
              const SizedBox(height: 14),
              FutureBuilder<Map<String, dynamic>?>(
                future: _live,
                builder: (context, liveSnapshot) => _LiveScoreboard(
                  game: (liveSnapshot.data?['game'] as Map<String, dynamic>?) ??
                      game,
                  live: liveSnapshot.data,
                  refreshing:
                      liveSnapshot.connectionState == ConnectionState.waiting,
                ),
              ),
              const SizedBox(height: 24),
              _TeamTabs(
                awayTeamName: game['away_team_name'] as String,
                homeTeamName: game['home_team_name'] as String,
                selectedTeamId: selectedTeamId,
                awayTeamId: awayTeamId,
                homeTeamId: homeTeamId,
                onSelected: (teamId) =>
                    setState(() => _selectedTeamId = teamId),
              ),
              const SizedBox(height: 12),
              _RecordTabs(
                showBatting: _showBatting,
                onChanged: (value) => setState(() => _showBatting = value),
              ),
              const SizedBox(height: 18),
              if (_showBatting)
                _battingSection(batting, plateAppearances)
              else
                _pitchingSection(pitching),
            ],
          );
        },
      ),
    );
  }
}

class _LiveScoreboard extends StatelessWidget {
  const _LiveScoreboard({
    required this.game,
    required this.live,
    required this.refreshing,
  });

  final Map<String, dynamic> game;
  final Map<String, dynamic>? live;
  final bool refreshing;

  String get _statusLabel {
    switch (game['status']) {
      case 'in_progress':
        return 'LIVE';
      case 'completed':
        return '경기 종료';
      case 'cancelled':
        return '경기 취소';
      default:
        return '경기 예정';
    }
  }

  String get _inningLabel {
    final inning = live?['inning'];
    if (inning == null) {
      return game['game_time']?.toString().substring(0, 5) ?? '-';
    }
    final half = live?['inning_half'] == 'bottom' ? '말' : '초';
    return '$inning회$half';
  }

  @override
  Widget build(BuildContext context) {
    final awayName = game['away_team_name']?.toString() ?? '-';
    final homeName = game['home_team_name']?.toString() ?? '-';
    final awayBrand = TeamBrand.resolve(awayName);
    final homeBrand = TeamBrand.resolve(homeName);
    final active = game['status'] == 'in_progress';
    final rawBaseState =
        (live?['base_state']?.toString() ?? '000').padRight(3, '0');
    final rawOuts = (live?['outs'] as num?)?.toInt() ?? 0;
    final halfInningEnded = rawOuts >= 3;
    final outs = rawOuts.clamp(0, 3);
    final baseState = halfInningEnded ? '000' : rawBaseState;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFF071D29),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFF244655), width: 1.5),
        boxShadow: const [
          BoxShadow(
              color: Color(0x26001B2A), blurRadius: 22, offset: Offset(0, 12)),
        ],
      ),
      child: Stack(children: [
        Positioned(
          right: -34,
          top: -42,
          child: Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: homeBrand.primary.withValues(alpha: .18),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
          child: Column(children: [
            Row(children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: active
                      ? const Color(0xFFFF4056)
                      : const Color(0xFF91A5AE),
                  shape: BoxShape.circle,
                  boxShadow: active
                      ? const [
                          BoxShadow(color: Color(0x99FF4056), blurRadius: 8)
                        ]
                      : null,
                ),
              ),
              const SizedBox(width: 8),
              Text(_statusLabel,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.1)),
              const Spacer(),
              if (refreshing)
                const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                        strokeWidth: 1.5, color: Color(0xFF83E2B5)))
              else
                const Text('10초 자동 갱신',
                    style: TextStyle(color: Color(0xFF86A1AD), fontSize: 11)),
            ]),
            const SizedBox(height: 18),
            Row(children: [
              Expanded(
                child: _ScoreTeam(
                  teamName: awayName,
                  score: game['away_score'],
                  alignEnd: false,
                  color: awayBrand.primary,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Column(children: [
                  Text(_inningLabel,
                      style: const TextStyle(
                          color: Color(0xFFFFD268),
                          fontSize: 15,
                          fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  const Text('VS',
                      style: TextStyle(
                          color: Color(0xFF6F8994),
                          fontSize: 10,
                          fontWeight: FontWeight.w800)),
                ]),
              ),
              Expanded(
                child: _ScoreTeam(
                  teamName: homeName,
                  score: game['home_score'],
                  alignEnd: true,
                  color: homeBrand.primary,
                ),
              ),
            ]),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF0D2A37),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFF244653)),
              ),
              child: Row(children: [
                _BaseDiamond(baseState: baseState),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            halfInningEnded
                                ? '3아웃 · 이닝 종료'
                                : live?['description']?.toString() ??
                                    _statusLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w800)),
                        const SizedBox(height: 8),
                        Row(
                            children: List.generate(
                                3,
                                (index) => Padding(
                                      padding: const EdgeInsets.only(right: 6),
                                      child: Container(
                                        width: 9,
                                        height: 9,
                                        decoration: BoxDecoration(
                                          color: index < outs
                                              ? const Color(0xFFFF4056)
                                              : const Color(0xFF34515D),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ))),
                      ]),
                ),
                Text(halfInningEnded ? '이닝 종료' : '$outs OUT',
                    style: const TextStyle(
                        color: Color(0xFFFF8C93),
                        fontSize: 12,
                        fontWeight: FontWeight.w900)),
              ]),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _ScoreTeam extends StatelessWidget {
  const _ScoreTeam({
    required this.teamName,
    required this.score,
    required this.alignEnd,
    required this.color,
  });

  final String teamName;
  final Object? score;
  final bool alignEnd;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment:
            alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
                alignEnd ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              if (!alignEnd) TeamMascotIcon(teamName: teamName, size: 34),
              if (!alignEnd) const SizedBox(width: 7),
              Flexible(
                child: Text(teamName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Color(0xFFD8E5EA),
                        fontSize: 12,
                        fontWeight: FontWeight.w800)),
              ),
              if (alignEnd) const SizedBox(width: 7),
              if (alignEnd) TeamMascotIcon(teamName: teamName, size: 34),
            ],
          ),
          const SizedBox(height: 7),
          Text(score?.toString() ?? '-',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 38,
                  height: .95,
                  fontWeight: FontWeight.w900,
                  shadows: [
                    Shadow(color: color.withValues(alpha: .8), blurRadius: 16)
                  ])),
        ],
      );
}

class _BaseDiamond extends StatelessWidget {
  const _BaseDiamond({required this.baseState});

  final String baseState;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 56,
        height: 56,
        child: Stack(children: [
          _base(left: 5, top: 22, occupied: baseState[2] == '1'),
          _base(left: 22, top: 5, occupied: baseState[1] == '1'),
          _base(left: 39, top: 22, occupied: baseState[0] == '1'),
          Positioned(
            left: 23,
            top: 40,
            child: Transform.rotate(
              angle: .785,
              child: Container(
                  width: 10, height: 10, color: const Color(0xFFE8F0F2)),
            ),
          ),
        ]),
      );

  static Widget _base(
          {required double left,
          required double top,
          required bool occupied}) =>
      Positioned(
        left: left,
        top: top,
        child: Transform.rotate(
          angle: .785,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            width: 13,
            height: 13,
            decoration: BoxDecoration(
              color:
                  occupied ? const Color(0xFFFFC94A) : const Color(0xFF294955),
              border: Border.all(
                  color: occupied
                      ? const Color(0xFFFFE094)
                      : const Color(0xFF6F8994)),
              boxShadow: occupied
                  ? const [BoxShadow(color: Color(0x99FFC94A), blurRadius: 8)]
                  : null,
            ),
          ),
        ),
      );
}

class _TeamTabs extends StatelessWidget {
  const _TeamTabs({
    required this.awayTeamName,
    required this.homeTeamName,
    required this.selectedTeamId,
    required this.awayTeamId,
    required this.homeTeamId,
    required this.onSelected,
  });

  final String awayTeamName;
  final String homeTeamName;
  final int selectedTeamId;
  final int awayTeamId;
  final int homeTeamId;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(
          child: _TeamTab(
            teamName: awayTeamName,
            selected: selectedTeamId == awayTeamId,
            onTap: () => onSelected(awayTeamId),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _TeamTab(
            teamName: homeTeamName,
            selected: selectedTeamId == homeTeamId,
            onTap: () => onSelected(homeTeamId),
          ),
        ),
      ]);
}

class _TeamTab extends StatelessWidget {
  const _TeamTab({
    required this.teamName,
    required this.selected,
    required this.onTap,
  });

  final String teamName;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final brand = TeamBrand.resolve(teamName);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color:
              selected ? brand.primary.withValues(alpha: .12) : AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? brand.primary : AppColors.line, width: 2),
        ),
        child: Row(children: [
          TeamMascotIcon(teamName: teamName, size: 32),
          const SizedBox(width: 6),
          Expanded(
            child: Text(teamName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: selected ? brand.primary : AppColors.ink,
                    fontWeight: FontWeight.w900)),
          ),
        ]),
      ),
    );
  }
}

class _RecordTabs extends StatelessWidget {
  const _RecordTabs({required this.showBatting, required this.onChanged});

  final bool showBatting;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => SegmentedButton<bool>(
        segments: const [
          ButtonSegment(
              value: true,
              label: Text('타자'),
              icon: Icon(Icons.sports_baseball_rounded)),
          ButtonSegment(
              value: false, label: Text('투수'), icon: Icon(Icons.speed_rounded)),
        ],
        selected: {showBatting},
        onSelectionChanged: (values) => onChanged(values.first),
        style: const ButtonStyle(
          textStyle: WidgetStatePropertyAll(
              TextStyle(fontFamily: 'Jua', fontSize: 15)),
        ),
      );
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.count,
    required this.icon,
    required this.color,
    required this.child,
  });

  final String title;
  final int count;
  final IconData icon;
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 10),
        child: Row(children: [
          Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: color.withValues(alpha: .14),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, size: 20, color: color)),
          const SizedBox(width: 10),
          Text(title,
              style:
                  const TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
          const Spacer(),
          Text('$count명', style: const TextStyle(color: AppColors.muted)),
        ]),
      ),
      Card(
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        child: count == 0
            ? const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: Text('등록된 기록이 없습니다.')))
            : child,
      ),
    ]);
  }
}

class _BattingLineupCard extends StatelessWidget {
  const _BattingLineupCard({
    required this.lineup,
    required this.plateAppearances,
    required this.positionLabel,
    required this.showDivider,
  });

  final List<Map<String, dynamic>> lineup;
  final List<Map<String, dynamic>> plateAppearances;
  final String Function(Object? value) positionLabel;
  final bool showDivider;

  String _metrics(Map<String, dynamic> row) {
    final awards = <String>[
      if (row['decisive_hit'] == true) '결승타',
      if (row['walkoff_home_run'] == true) '끝내기 홈런',
    ];
    final base =
        '${row['ab'] ?? '-'}타수  ${row['h'] ?? 0}안타  ${row['rbi'] ?? 0}타점';
    return awards.isEmpty ? base : '$base\n${awards.join(' · ')}';
  }

  @override
  Widget build(BuildContext context) {
    final starter = lineup.first;
    final substitutes = lineup.skip(1).toList();
    final order = starter['batting_order'];
    final lineupPlayerIds = lineup.map((row) => row['player_id']).toSet();
    final appearances = plateAppearances
        .where((event) => lineupPlayerIds.contains(event['batter_id']))
        .toList();
    return Container(
      decoration: showDivider
          ? const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.line)))
          : null,
      child: Column(children: [
        _PlayerRow(
          index: order is int ? order : 0,
          name: starter['player_name']?.toString() ?? '-',
          teamName: starter['team_name']?.toString() ?? '-',
          position: positionLabel(starter['position']),
          metrics: _metrics(starter),
          color:
              TeamBrand.resolve(starter['team_name']?.toString() ?? '').primary,
        ),
        if (appearances.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 5,
                runSpacing: 5,
                children: appearances.map((event) {
                  final half = event['inning_half'] == 'bottom' ? '말' : '초';
                  final description = event['description']?.toString() ??
                      _eventLabel(event['event_type']?.toString());
                  return Tooltip(
                    message: description,
                    child: Chip(
                      visualDensity:
                          const VisualDensity(horizontal: -3, vertical: -3),
                      padding: EdgeInsets.zero,
                      labelPadding: const EdgeInsets.symmetric(horizontal: 6),
                      label: Text(
                        '${event['inning']}$half ${_eventLabel(event['event_type']?.toString(), description)}',
                        style: const TextStyle(
                            fontSize: 10, fontWeight: FontWeight.w800),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        if (substitutes.isNotEmpty)
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.fromLTRB(18, 0, 12, 6),
              childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
              leading: const Icon(Icons.swap_vert_circle_rounded,
                  color: AppColors.coral),
              title: Text('교체 ${substitutes.length}명',
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w800)),
              subtitle: const Text('교체 흐름 보기',
                  style: TextStyle(fontSize: 11, color: AppColors.muted)),
              children: substitutes.asMap().entries.map((entry) {
                final incoming = entry.value;
                final outgoing =
                    entry.key == 0 ? starter : substitutes[entry.key - 1];
                return _SubstitutionFlow(
                  outgoing: outgoing,
                  incoming: incoming,
                  position: positionLabel(incoming['position']),
                  metrics: _metrics(incoming),
                );
              }).toList(),
            ),
          ),
      ]),
    );
  }

  static String _eventLabel(String? type, [String? description]) {
    final exact = description?.trim();
    if (exact != null && exact.isNotEmpty && exact != '-') {
      return exact;
    }
    if (description != null) {
      for (final label in const [
        '홈런',
        '3루타',
        '2루타',
        '안타',
        '볼넷',
        '사구',
        '삼진',
        '희생플라이',
        '실책'
      ]) {
        if (description.contains(label)) return label;
      }
    }
    return switch (type) {
      'home_run' => '홈런',
      'hit' => '안타',
      'walk' => '볼넷',
      'strikeout' => '삼진',
      'decisive_hit' => '결승타',
      _ => '타석',
    };
  }
}

class _PlayerRow extends StatelessWidget {
  const _PlayerRow({
    required this.index,
    required this.name,
    required this.teamName,
    required this.position,
    required this.metrics,
    required this.color,
    this.showDivider = false,
  });

  final int index;
  final String name;
  final String teamName;
  final String position;
  final String metrics;
  final Color color;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: showDivider
          ? const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.line)))
          : null,
      child: Row(children: [
        CircleAvatar(
          radius: 17,
          backgroundColor: color.withValues(alpha: .13),
          foregroundColor: color,
          child: Text(index == 0 ? '·' : '$index',
              style: const TextStyle(fontWeight: FontWeight.w800)),
        ),
        const SizedBox(width: 9),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text('$teamName · $position',
                style: const TextStyle(fontSize: 12, color: AppColors.muted)),
          ]),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: color.withValues(alpha: .09),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Text(metrics,
              textAlign: TextAlign.right,
              style: TextStyle(
                  color: color, fontSize: 12, fontWeight: FontWeight.w900)),
        ),
      ]),
    );
  }
}

class _SubstitutionFlow extends StatelessWidget {
  const _SubstitutionFlow({
    required this.outgoing,
    required this.incoming,
    required this.position,
    required this.metrics,
  });

  final Map<String, dynamic> outgoing;
  final Map<String, dynamic> incoming;
  final String position;
  final String metrics;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: AppColors.cream, borderRadius: BorderRadius.circular(16)),
      child: Column(children: [
        Row(children: [
          const _FlowLabel(text: 'OUT', color: AppColors.muted),
          const SizedBox(width: 8),
          Expanded(child: Text(outgoing['player_name']?.toString() ?? '-')),
          const Icon(Icons.arrow_forward_rounded,
              size: 18, color: AppColors.coral),
          const SizedBox(width: 8),
          const _FlowLabel(text: 'IN', color: AppColors.forest),
          const SizedBox(width: 8),
          Expanded(
              child: Text(incoming['player_name']?.toString() ?? '-',
                  style: const TextStyle(fontWeight: FontWeight.w800))),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Text(position,
              style: const TextStyle(fontSize: 11, color: AppColors.muted)),
          const Spacer(),
          Text(metrics,
              style:
                  const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
        ]),
      ]),
    );
  }
}

class _FlowLabel extends StatelessWidget {
  const _FlowLabel({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
          color: color.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(7)),
      child: Text(text,
          style: TextStyle(
              fontSize: 9, fontWeight: FontWeight.w900, color: color)),
    );
  }
}
