import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/models/attendance.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_error.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/async_state_view.dart';
import '../../shared/widgets/team_brand.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  late Future<_AttendanceData> _data;
  String _resultFilter = 'all';
  bool _showOpponentRecords = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _data = Future.wait([
      ApiClient.instance.dio.get<List<dynamic>>('/v1/attendances'),
      ApiClient.instance.dio
          .get<Map<String, dynamic>>('/v1/attendances/summary'),
    ]).then((responses) {
      final recordsResponse = responses[0];
      final summaryResponse = responses[1];
      final rawRecords =
          (recordsResponse.data as List<dynamic>?) ?? const <dynamic>[];
      final rawSummary = (summaryResponse.data as Map<String, dynamic>?) ??
          const <String, dynamic>{};
      final records = rawRecords
          .map((item) => AttendanceModel.fromJson(item as Map<String, dynamic>))
          .toList();
      return _AttendanceData(
        records: records,
        summary: rawSummary,
      );
    });
  }

  Future<void> _delete(int id) async {
    await ApiClient.instance.dio.delete('/v1/attendances/$id');
    setState(_reload);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('나의 직관 기록')),
      body: FutureBuilder<_AttendanceData>(
        future: _data,
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
          if (data.records.isEmpty) return const _EmptyAttendance();
          final records = _filteredRecords(data.records);
          return RefreshIndicator(
            onRefresh: () async {
              setState(_reload);
              await _data;
            },
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              itemCount: records.length + 2,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _AttendanceReveal(
                    index: index,
                    child: _AttendanceInsightCard(
                      summary: data.summary,
                      records: data.records,
                      showOpponentRecords: _showOpponentRecords,
                      onToggleOpponentRecords: () => setState(
                        () => _showOpponentRecords = !_showOpponentRecords,
                      ),
                    ),
                  );
                }
                if (index == 1) {
                  return _AttendanceReveal(
                    index: index,
                    child: _AttendanceListFilter(
                      selected: _resultFilter,
                      counts: _resultCounts(data.records),
                      onSelected: (value) =>
                          setState(() => _resultFilter = value),
                    ),
                  );
                }
                return _AttendanceReveal(
                  index: index,
                  child: _AttendanceCard(
                      record: records[index - 2], onDelete: _delete),
                );
              },
            ),
          );
        },
      ),
    );
  }

  List<AttendanceModel> _filteredRecords(List<AttendanceModel> records) {
    if (_resultFilter == 'all') return records;
    return records
        .where((record) => record.resultForMyTeam == _resultFilter)
        .toList();
  }

  Map<String, int> _resultCounts(List<AttendanceModel> records) {
    final counts = {'all': records.length, 'win': 0, 'draw': 0, 'loss': 0};
    for (final record in records) {
      final result = record.resultForMyTeam;
      if (result != null && counts.containsKey(result)) {
        counts[result] = counts[result]! + 1;
      }
    }
    return counts;
  }
}

class _AttendanceData {
  const _AttendanceData({required this.records, required this.summary});
  final List<AttendanceModel> records;
  final Map<String, dynamic> summary;
}

class _AttendanceBoardLight extends StatelessWidget {
  const _AttendanceBoardLight({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 9,
      height: 9,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: .55), blurRadius: 8),
        ],
      ),
    );
  }
}

class _AttendanceInsightCard extends StatelessWidget {
  const _AttendanceInsightCard({
    required this.summary,
    required this.records,
    required this.showOpponentRecords,
    required this.onToggleOpponentRecords,
  });
  final Map<String, dynamic> summary;
  final List<AttendanceModel> records;
  final bool showOpponentRecords;
  final VoidCallback onToggleOpponentRecords;

  @override
  Widget build(BuildContext context) {
    final hitters =
        summary['top_batting_players'] as List<dynamic>? ?? const [];
    final pitchers = summary['top_pitchers'] as List<dynamic>? ?? const [];
    final decisiveHitLeaders =
        summary['decisive_hit_leaders'] as List<dynamic>? ?? const [];
    final weekdays = (summary['weekday_records'] as List<dynamic>? ?? const []);
    final stadiums = (summary['stadium_records'] as List<dynamic>? ?? const []);
    final qualifiedGames =
        (summary['qualified_games'] as num?)?.toInt() ?? records.length;
    final wins = (summary['wins'] as num?)?.toInt() ?? 0;
    final losses = (summary['losses'] as num?)?.toInt() ?? 0;
    final draws = (summary['draws'] as num?)?.toInt() ?? 0;
    final winRate = (summary['win_rate'] as num?)?.toDouble() ?? 0;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFF0F1D27),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: .24)),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: .16),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(children: [
        Positioned.fill(
          child: Image.asset(
            'assets/stadium_outfield_backdrop.png',
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
          ),
        ),
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xB8172940),
                  Color(0xE3183E34),
                  Color(0xF2762635),
                ],
                stops: [0, .48, 1],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(22),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Row(children: [
              _AttendanceBoardLight(color: AppColors.coral),
              SizedBox(width: 6),
              _AttendanceBoardLight(color: AppColors.butter),
              SizedBox(width: 6),
              _AttendanceBoardLight(color: AppColors.leaf),
              Spacer(),
              Text('MY9 BALLPARK',
                  style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2)),
            ]),
            const SizedBox(height: 24),
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              const Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('내 직관 승률',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w900)),
                    ]),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: .24),
                  borderRadius: BorderRadius.circular(18),
                  border:
                      Border.all(color: AppColors.butter.withValues(alpha: .4)),
                ),
                child: Text('$winRate%',
                    style: const TextStyle(
                        color: AppColors.butter,
                        fontSize: 31,
                        fontWeight: FontWeight.w900)),
              ),
            ]),
            const SizedBox(height: 10),
            Text(
              '$qualifiedGames전 $wins승 $losses패 $draws무',
              style: const TextStyle(color: Colors.white70),
            ),
            if (weekdays.isNotEmpty) ...[
              const SizedBox(height: 18),
              _RecordBreakdown(title: '요일별 승률', items: weekdays),
            ],
            if (stadiums.isNotEmpty) ...[
              const SizedBox(height: 12),
              _RecordBreakdown(title: '구장별 승률', items: stadiums),
            ],
            const SizedBox(height: 12),
            _OpponentSummary(
              records: records,
              expanded: showOpponentRecords,
              onToggle: onToggleOpponentRecords,
            ),
            const SizedBox(height: 20),
            Divider(color: Colors.white.withValues(alpha: .14), height: 1),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
              decoration: BoxDecoration(
                color: const Color(0xD1122430),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.white.withValues(alpha: .15)),
              ),
              child: Row(children: [
                const Icon(Icons.emoji_events_rounded,
                    color: AppColors.butter, size: 22),
                const SizedBox(width: 9),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('내 승리 지킴이',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900)),
                      Text('응원팀 승리 경기의 플레이어 보드',
                          style:
                              TextStyle(color: Colors.white60, fontSize: 10)),
                    ],
                  ),
                ),
                Image.asset(
                  'assets/baseball_gear_cluster.png',
                  width: 78,
                  height: 62,
                  fit: BoxFit.contain,
                ),
              ]),
            ),
            const SizedBox(height: 14),
            if (hitters.isEmpty &&
                pitchers.isEmpty &&
                decisiveHitLeaders.isEmpty)
              const Text('응원팀이 지정된 완료 경기부터 선수 기록이 집계됩니다.',
                  style: TextStyle(color: Colors.white60, height: 1.5))
            else ...[
              _GuardianSection(
                title: '타자 TOP 5',
                items: hitters,
                decisiveHitLeaders: decisiveHitLeaders,
              ),
              const SizedBox(height: 12),
              _GuardianSection(title: '투수 TOP 5', items: pitchers),
            ],
          ]),
        ),
      ]),
    );
  }
}

class _RecordBreakdown extends StatelessWidget {
  const _RecordBreakdown({required this.title, required this.items});
  final String title;
  final List<dynamic> items;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w900,
                  fontSize: 12)),
          const SizedBox(height: 8),
          SizedBox(
            height: 82,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final item = items[index] as Map<String, dynamic>;
                return Container(
                  width: 112,
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .09),
                      borderRadius: BorderRadius.circular(16)),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item['label'] as String,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900)),
                        const Spacer(),
                        Text('${item['win_rate']}%',
                            style: const TextStyle(
                                color: AppColors.butter,
                                fontSize: 18,
                                fontWeight: FontWeight.w900)),
                        Text(
                            '${item['wins']}승 ${item['draws']}무 ${item['losses']}패',
                            style: const TextStyle(
                                color: Colors.white54, fontSize: 10)),
                      ]),
                );
              },
            ),
          ),
        ],
      );
}

class _OpponentSummary extends StatelessWidget {
  const _OpponentSummary({
    required this.records,
    required this.expanded,
    required this.onToggle,
  });

  final List<AttendanceModel> records;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final values = <String, List<int>>{};
    for (final record in records) {
      final result = record.resultForMyTeam;
      if (result == null || record.myTeamId == null) continue;
      final opponent = _opponentName(record);
      if (opponent == null) continue;
      final bucket = values.putIfAbsent(opponent, () => [0, 0, 0]);
      if (result == 'win') {
        bucket[0] += 1;
      } else if (result == 'draw') {
        bucket[1] += 1;
      } else if (result == 'loss') {
        bucket[2] += 1;
      }
    }
    final rows = values.entries.map((entry) {
      final wins = entry.value[0];
      final draws = entry.value[1];
      final losses = entry.value[2];
      final decisions = wins + losses;
      return (
        name: entry.key,
        wins: wins,
        draws: draws,
        losses: losses,
        games: wins + draws + losses,
        rate: decisions == 0 ? 0.0 : wins / decisions * 100,
      );
    }).toList()
      ..sort((a, b) {
        final rateCompare = b.rate.compareTo(a.rate);
        if (rateCompare != 0) return rateCompare;
        return b.games.compareTo(a.games);
      });
    if (rows.isEmpty) return const SizedBox.shrink();
    final visible = expanded ? rows : rows.take(4).toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Text(
          '상대 구단별 기록',
          style: TextStyle(
            color: Colors.white70,
            fontWeight: FontWeight.w900,
            fontSize: 12,
          ),
        ),
        const Spacer(),
        TextButton(
          onPressed: onToggle,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.butter,
            padding: EdgeInsets.zero,
            minimumSize: const Size(44, 30),
          ),
          child: Text(expanded ? '접기' : '전체'),
        ),
      ]),
      const SizedBox(height: 8),
      SizedBox(
        height: 128,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          itemCount: visible.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final row = visible[index];
            return SizedBox(
              width: 156,
              child: Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .09),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        TeamMascotIcon(teamName: row.name, size: 30),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            row.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      '${row.rate.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        color: AppColors.butter,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      '${row.wins} W · ${row.draws} D · ${row.losses} L',
                      style:
                          const TextStyle(color: Colors.white54, fontSize: 10),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    ]);
  }

  String? _opponentName(AttendanceModel record) {
    if (record.myTeamId == record.homeTeamId) return record.awayTeamName;
    if (record.myTeamId == record.awayTeamId) return record.homeTeamName;
    return null;
  }
}

class _AttendanceListFilter extends StatelessWidget {
  const _AttendanceListFilter({
    required this.selected,
    required this.counts,
    required this.onSelected,
  });

  final String selected;
  final Map<String, int> counts;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.line),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: .045),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                  value: 'all',
                  icon: Icon(Icons.stadium_rounded),
                  label: Text('전체')),
              ButtonSegment(
                  value: 'win',
                  icon: Icon(Icons.check_rounded),
                  label: Text('승')),
              ButtonSegment(
                  value: 'draw',
                  icon: Icon(Icons.remove_rounded),
                  label: Text('무')),
              ButtonSegment(
                  value: 'loss',
                  icon: Icon(Icons.close_rounded),
                  label: Text('패')),
            ],
            selected: {selected},
            onSelectionChanged: (values) => onSelected(values.first),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.ink,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.butter.withValues(alpha: .36),
                ),
              ),
              child: Text(
                _summaryText(),
                style: const TextStyle(
                  color: AppColors.butter,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _summaryText() {
    final wins = counts['win'] ?? 0;
    final draws = counts['draw'] ?? 0;
    final losses = counts['loss'] ?? 0;
    final total = counts['all'] ?? wins + draws + losses;
    return switch (selected) {
      'win' => '$wins승',
      'draw' => '$draws무',
      'loss' => '$losses패',
      _ => '$total전 $wins승 $losses패${draws > 0 ? ' $draws무' : ''}',
    };
  }
}

class _GuardianSection extends StatelessWidget {
  const _GuardianSection({
    required this.title,
    required this.items,
    this.decisiveHitLeaders = const [],
  });
  final String title;
  final List<dynamic> items;
  final List<dynamic> decisiveHitLeaders;

  List<Map<String, dynamic>> _top(String key) {
    if (key == 'decisive_hits') {
      final values = decisiveHitLeaders
          .map((item) => item as Map<String, dynamic>)
          .toList();
      values.sort((a, b) =>
          ((b['count'] as num?) ?? 0).compareTo((a['count'] as num?) ?? 0));
      return values.take(5).toList();
    }
    final values = items.map((item) => item as Map<String, dynamic>).toList();
    final sortKey = key == 'innings' ? 'innings_pitched' : key;
    values.sort((a, b) =>
        ((b[sortKey] as num?) ?? 0).compareTo((a[sortKey] as num?) ?? 0));
    return values.take(5).toList();
  }

  String _display(Map<String, dynamic> player, String key) {
    if (key == 'innings') {
      return '${player['innings_pitched']}이닝 · ${player['wins'] ?? 0}승 · ERA ${player['era']}';
    }
    if (key == 'decisive_hits') return '${player['count'] ?? 0}개';
    if (key == 'strikeouts') return '${player['strikeouts'] ?? 0}개';
    if (key == 'holds') return '${player['holds'] ?? 0}개';
    if (key == 'wins') return '${player['wins'] ?? 0}승';
    if (key == 'hr') return '${player['hr'] ?? 0}개';
    if (key == 'rbi') return '${player['rbi'] ?? 0}점';
    if (key == 'h') return '${player['h'] ?? 0}개';
    if (key == 'sb') return '${player['sb'] ?? 0}개';
    final value = (player[key] as num?)?.toDouble() ?? 0;
    return value.toStringAsFixed(3);
  }

  @override
  Widget build(BuildContext context) {
    final isPitching = items.isNotEmpty &&
        (items.first as Map<String, dynamic>).containsKey('k_per_nine');
    final tabs = isPitching
        ? const [
            ('탈삼진', '내가 본 경기에서 삼진을 잡은 누계', 'strikeouts'),
            ('홀드', '리드를 지킨 중간 투수의 홀드 누계', 'holds'),
            ('승수', '내가 본 경기에서 기록한 승리 누계', 'wins'),
            ('이닝', '내가 본 경기에서 던진 이닝 누계', 'innings'),
          ]
        : const [
            ('홈런', '내가 본 경기에서 친 홈런 누계', 'hr'),
            ('타점', '내가 본 경기에서 올린 타점 누계', 'rbi'),
            ('안타', '내가 본 경기에서 친 안타 누계', 'h'),
            ('도루', '내가 본 경기에서 성공한 도루 누계', 'sb'),
            ('결승타', '승리팀 리드를 끝까지 만든 타점성 이벤트 누계', 'decisive_hits'),
          ];
    return DefaultTabController(
      length: tabs.length,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: const TextStyle(
                color: Colors.white60,
                fontSize: 11,
                fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        TabBar(
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelPadding: const EdgeInsets.only(right: 18),
          labelColor: AppColors.butter,
          unselectedLabelColor: Colors.white54,
          indicatorColor: AppColors.butter,
          dividerColor: Colors.transparent,
          tabs: [for (final tab in tabs) Tab(text: tab.$1)],
        ),
        SizedBox(
          height: 295,
          child: TabBarView(children: [
            for (final tab in tabs)
              TweenAnimationBuilder<double>(
                key: ValueKey(tab.$3),
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 380),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) => Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(12 * (1 - value), 0),
                    child: child,
                  ),
                ),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 7),
                      Text(tab.$2,
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 11)),
                      const SizedBox(height: 7),
                      if (_top(tab.$3).isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 22),
                          child: Text('아직 집계된 선수가 없습니다.',
                              style: TextStyle(color: Colors.white54)),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 13, vertical: 9),
                          decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: .08),
                              borderRadius: BorderRadius.circular(18)),
                          child: Column(children: [
                            for (final player in _top(tab.$3))
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4),
                                child: Row(children: [
                                  Expanded(
                                      child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                        Text(player['player_name'] as String,
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w800)),
                                        Text(player['team_name'] as String,
                                            style: const TextStyle(
                                                color: Colors.white54,
                                                fontSize: 10)),
                                      ])),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerRight,
                                      child: Text(_display(player, tab.$3),
                                          style: const TextStyle(
                                              color: AppColors.butter,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w900)),
                                    ),
                                  ),
                                ]),
                              ),
                          ]),
                        ),
                    ]),
              ),
          ]),
        ),
      ]),
    );
  }
}

class _AttendanceCard extends StatelessWidget {
  const _AttendanceCard({required this.record, required this.onDelete});
  final AttendanceModel record;
  final Future<void> Function(int id) onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.line),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: .045),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(children: [
        const Positioned.fill(
          child: CustomPaint(
            painter: _AttendanceTicketPainter(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(18),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                    color: AppColors.ink,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.butter.withValues(alpha: .38),
                    )),
                child: Text(DateFormat('MM.dd').format(record.gameDate),
                    style: const TextStyle(
                        color: AppColors.butter, fontWeight: FontWeight.w900)),
              ),
              const Spacer(),
              IconButton(
                tooltip: '기록 삭제',
                icon: const Icon(Icons.delete_outline_rounded),
                onPressed: () => onDelete(record.id),
              ),
            ]),
            const SizedBox(height: 12),
            _TeamMatchup(
              awayTeamName: record.awayTeamName,
              homeTeamName: record.homeTeamName,
            ),
            if (record.memo != null) ...[
              const SizedBox(height: 14),
              Wrap(spacing: 8, runSpacing: 8, children: [
                if (record.memo != null)
                  _InfoChip(icon: Icons.notes_rounded, label: record.memo!),
              ]),
            ],
          ]),
        ),
      ]),
    );
  }
}

class _AttendanceTicketPainter extends CustomPainter {
  const _AttendanceTicketPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = AppColors.leaf.withValues(alpha: .22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final path = Path()
      ..moveTo(size.width * .5, size.height * .38)
      ..lineTo(size.width * .64, size.height * .52)
      ..lineTo(size.width * .5, size.height * .68)
      ..lineTo(size.width * .36, size.height * .52)
      ..close();
    canvas.drawPath(path, line);
    canvas.drawLine(
      Offset(size.width * .5, size.height * .68),
      Offset(size.width * .22, size.height),
      line,
    );
    canvas.drawLine(
      Offset(size.width * .5, size.height * .68),
      Offset(size.width * .78, size.height),
      line,
    );
  }

  @override
  bool shouldRepaint(covariant _AttendanceTicketPainter oldDelegate) => false;
}

class _AttendanceReveal extends StatelessWidget {
  const _AttendanceReveal({required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 460 + (index.clamp(0, 5).toInt() * 55)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 18 * (1 - value)),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

class _TeamMatchup extends StatelessWidget {
  const _TeamMatchup({required this.awayTeamName, required this.homeTeamName});

  final String awayTeamName;
  final String homeTeamName;

  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(child: _MatchupTeam(name: awayTeamName)),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Text('VS',
              style: TextStyle(
                  color: AppColors.coral,
                  fontSize: 12,
                  fontWeight: FontWeight.w900)),
        ),
        Expanded(child: _MatchupTeam(name: homeTeamName)),
      ]);
}

class _MatchupTeam extends StatelessWidget {
  const _MatchupTeam({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) => Column(children: [
        TeamMascotIcon(teamName: name, size: 50),
        const SizedBox(height: 5),
        Text(name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w900)),
      ]);
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
          color: AppColors.leaf.withValues(alpha: .18),
          borderRadius: BorderRadius.circular(12)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 16, color: AppColors.forest),
        const SizedBox(width: 6),
        Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
      ]),
    );
  }
}

class _EmptyAttendance extends StatelessWidget {
  const _EmptyAttendance();

  @override
  Widget build(BuildContext context) {
    return const AppEmptyView(
      title: '아직 직관 기록이 없어요',
      message: '일정에서 경기를 선택해 첫 기록을 남겨보세요.',
      icon: Icons.confirmation_number_outlined,
    );
  }
}
