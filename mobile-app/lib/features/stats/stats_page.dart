import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_error.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/async_state_view.dart';
import '../../shared/widgets/team_brand.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  late Future<_SeasonStatsData> _stats;
  final _search = TextEditingController();
  String? _selectedTeam;
  String _sortKey = 'primary';
  bool _pitching = false;

  void _sortPlayers(List<Map<String, dynamic>> players) {
    final field = switch ((_pitching, _sortKey)) {
      (false, 'ops') => 'ops',
      (false, 'avg') => 'avg',
      (false, 'hits') => 'h',
      (false, 'hr') => 'hr',
      (false, 'rbi') => 'rbi',
      (false, 'runs') => 'r',
      (false, 'obp') => 'obp',
      (false, 'slg') => 'slg',
      (false, 'sb') => 'sb',
      (false, 'wpa') => 'total_wpa',
      (true, 'fip') => 'fip',
      (true, 'whip') => 'whip',
      (true, 'strikeouts') => 'strikeouts',
      (true, 'k_bb') => 'k_bb',
      (true, 'k_bb_percent') => 'k_bb_percent',
      (true, 'bb_per_nine') => 'bb_per_nine',
      (true, 'hits') => 'hits',
      (true, 'wpa') => 'total_wpa',
      (true, _) => 'era',
      _ => 'estimated_wrc_plus',
    };
    final ascending = _pitching &&
        !{
          'strikeouts',
          'k_bb',
          'k_bb_percent',
          'wpa',
        }.contains(_sortKey);
    players.sort((left, right) {
      final a = (left[field] as num?) ?? 0;
      final b = (right[field] as num?) ?? 0;
      return ascending ? a.compareTo(b) : b.compareTo(a);
    });
  }

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _stats = Future.wait([
      ApiClient.instance.dio
          .get<Map<String, dynamic>>('/v1/stats/season/batting'),
      ApiClient.instance.dio
          .get<Map<String, dynamic>>('/v1/stats/season/pitching'),
    ]).then((responses) => _SeasonStatsData(
          batting: responses[0].data!,
          pitching: responses[1].data!,
        ));
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _showPlayer(
    Map<String, dynamic> player,
    String methodology,
    String? asOfDate,
  ) {
    final brand = TeamBrand.resolve(player['team_name'] as String);
    final primary = _pitching
        ? <String, String>{
            'ERA': '${player['era']}',
            '이닝': '${player['innings_pitched']}',
          }
        : <String, String>{
            'OPS': '${player['ops']}',
            '추정 wRC+': '${player['estimated_wrc_plus']}',
          };
    final statGroups = _pitching
        ? <_StatGroup>[
            _StatGroup(
              title: '기본 투구',
              icon: Icons.sports_baseball_rounded,
              stats: {
                '이닝': '${player['innings_pitched']}',
                '피안타': '${player['hits']}',
                '실점': '${player['runs']}',
                '자책': '${player['earned_runs']}',
                '볼넷': '${player['walks']}',
                '삼진': '${player['strikeouts']}',
              },
            ),
            _StatGroup(
              title: '구위와 제구',
              icon: Icons.speed_rounded,
              stats: {
                'K/9': '${player['k_per_nine']}',
                'BB/9': '${player['bb_per_nine']}',
                'K/BB': '${player['k_bb']}',
                '피홈런': '${player['home_runs']}',
                '상대 타자': '${player['batters_faced']}',
              },
            ),
            _StatGroup(
              title: '고급 지표',
              icon: Icons.auto_graph_rounded,
              stats: {
                'FIP': '${player['fip']}',
                'K-BB%': '${player['k_bb_percent']}%',
                '투구 WPA': '${player['pitching_wpa']}',
                '종합 WPA': '${player['total_wpa']}',
              },
            ),
            _StatGroup(
              title: '승리 억제 지표',
              icon: Icons.lock_rounded,
              stats: {
                'ERA': '${player['era']}',
                'WHIP': '${player['whip']}',
                '피안타': '${player['hits']}',
                'BB/9': '${player['bb_per_nine']}',
                'K-BB%': '${player['k_bb_percent']}%',
                '투구 WPA': '${player['pitching_wpa']}',
              },
            ),
          ]
        : <_StatGroup>[
            _StatGroup(
              title: '기본 타격',
              icon: Icons.sports_baseball_rounded,
              stats: {
                '타율': '${player['avg']}',
                '타수': '${player['ab']}',
                '안타': '${player['h']}',
                '홈런': '${player['hr']}',
                '도루': '${player['sb'] ?? 0}',
                '타점': '${player['rbi']}',
                '득점': '${player['r']}',
              },
            ),
            _StatGroup(
              title: '타구와 출루',
              icon: Icons.ads_click_rounded,
              stats: {
                '볼넷': '${player['bb']}',
                '삼진': '${player['so']}',
                '2루타': '${player['doubles']}',
                '3루타': '${player['triples']}',
                '사구': '${player['hbp']}',
              },
            ),
            _StatGroup(
              title: '비율과 기여',
              icon: Icons.insights_rounded,
              stats: {
                '출루율': '${player['obp']}',
                '장타율': '${player['slg']}',
                'OPS': '${player['ops']}',
                '추정 wOBA': '${player['estimated_woba']}',
                '타격 WPA': '${player['batting_wpa']}',
                '종합 WPA': '${player['total_wpa']}',
              },
            ),
            _StatGroup(
              title: '승리 생산 지표',
              icon: Icons.emoji_events_rounded,
              stats: {
                '타점': '${player['rbi']}',
                '득점': '${player['r']}',
                'OPS': '${player['ops']}',
                '출루율': '${player['obp']}',
                '장타율': '${player['slg']}',
                '타격 WPA': '${player['batting_wpa']}',
              },
            ),
          ];
    final chart = _pitching
        ? <String, num>{
            '이닝': player['innings_pitched'] as num,
            '삼진': player['strikeouts'] as num,
            '피안타': player['hits'] as num,
            '볼넷': player['walks'] as num,
          }
        : <String, num>{
            '안타': player['h'] as num,
            '홈런': player['hr'] as num,
            '타점': player['rbi'] as num,
            '볼넷': player['bb'] as num,
          };

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: .8,
        maxChildSize: .94,
        builder: (context, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 36),
          children: [
            Center(
              child: Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                    color: AppColors.line,
                    borderRadius: BorderRadius.circular(99)),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient:
                    LinearGradient(colors: [brand.primary, brand.secondary]),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Row(children: [
                TeamPlayerAvatar(
                    teamName: player['team_name'] as String, size: 78),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(player['team_name'] as String,
                            style: const TextStyle(color: Colors.white70)),
                        Text(player['player_name'] as String,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 27,
                                fontWeight: FontWeight.w900)),
                        Text('${player['games']}경기',
                            style: const TextStyle(color: Colors.white70)),
                      ]),
                ),
              ]),
            ),
            const SizedBox(height: 16),
            if (asOfDate != null) ...[
              Text(
                '$asOfDate 경기까지 반영',
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
            ],
            _DetailReveal(
              intervalStart: 0,
              child: Row(children: [
                Expanded(
                  child: _MetricCard(
                      label: primary.keys.first,
                      value: primary.values.first,
                      color: AppColors.coral),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MetricCard(
                      label: primary.keys.last,
                      value: primary.values.last,
                      color: AppColors.forest),
                ),
              ]),
            ),
            const SizedBox(height: 16),
            ...statGroups.indexed.expand((entry) => [
                  _DetailReveal(
                    intervalStart: .08 + entry.$1 * .08,
                    child: _StatGroupCard(
                      group: entry.$2,
                      accent: brand.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                ]),
            _DetailReveal(
              intervalStart: .32,
              child: _SeasonBarChart(values: chart, color: brand.primary),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: AppColors.cream,
                  borderRadius: BorderRadius.circular(18)),
              child: Text('계산 안내\n$methodology',
                  style: const TextStyle(
                      color: AppColors.muted, height: 1.5, fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('시즌 선수 기록')),
      body: FutureBuilder<_SeasonStatsData>(
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
          final source =
              _pitching ? snapshot.data!.pitching : snapshot.data!.batting;
          final players = source['players'] as List<dynamic>;
          if (players.isEmpty) {
            return const AppEmptyView(
              title: '시즌 기록이 없습니다',
              message: '경기 기록 적재가 완료되면 선수 지표가 표시됩니다.',
              icon: Icons.query_stats_rounded,
            );
          }
          final teams = players
              .map((item) =>
                  (item as Map<String, dynamic>)['team_name'] as String)
              .toSet()
              .toList()
            ..sort();
          final query = _search.text.trim().toLowerCase();
          final filtered = players
              .where((item) {
                final player = item as Map<String, dynamic>;
                return (query.isEmpty ||
                        (player['player_name'] as String)
                            .toLowerCase()
                            .contains(query)) &&
                    (_selectedTeam == null ||
                        player['team_name'] == _selectedTeam);
              })
              .cast<Map<String, dynamic>>()
              .toList();
          _sortPlayers(filtered);
          final qualified = filtered
              .where((player) => player['is_qualified'] == true)
              .toList();
          final below = filtered
              .where((player) => player['is_qualified'] != true)
              .toList();
          final methodology = source['methodology'] as String;

          return RefreshIndicator(
            onRefresh: () async {
              setState(_reload);
              await _stats;
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
              children: [
                _StatsHeader(
                    season: source['season_year'] as int,
                    playerCount: players.length,
                    pitching: _pitching),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(
                            value: false,
                            icon: Icon(Icons.sports_baseball_rounded),
                            label: Text('타자')),
                        ButtonSegment(
                            value: true,
                            icon: Icon(Icons.speed_rounded),
                            label: Text('투수')),
                      ],
                      selected: {_pitching},
                      onSelectionChanged: (selected) => setState(() {
                        _pitching = selected.first;
                        _selectedTeam = null;
                        _sortKey = 'primary';
                      }),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _PlayerFilters(
                  controller: _search,
                  teams: teams,
                  selectedTeam: _selectedTeam,
                  pitching: _pitching,
                  sortKey: _sortKey,
                  onSearch: (_) => setState(() {}),
                  onTeamChanged: (value) =>
                      setState(() => _selectedTeam = value),
                  onSortChanged: (value) => setState(() => _sortKey = value),
                ),
                const SizedBox(height: 14),
                _TopRecordStrip(
                  players: filtered,
                  pitching: _pitching,
                  onPlayerTap: (player) => _showPlayer(
                    player,
                    methodology,
                    source['as_of_date'] as String?,
                  ),
                ),
                const SizedBox(height: 18),
                Text(_pitching ? '규정이닝 충족' : '규정타석 충족',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 10),
                if (qualified.isEmpty)
                  const Card(
                      child: Padding(
                          padding: EdgeInsets.all(22),
                          child: Center(child: Text('조건에 맞는 선수가 없습니다.'))))
                else
                  ...qualified.map((player) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _PlayerCard(
                          player: player,
                          pitching: _pitching,
                          sortKey: _sortKey,
                          onTap: () => _showPlayer(
                            player,
                            methodology,
                            source['as_of_date'] as String?,
                          ),
                        ),
                      )),
                if (below.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _BelowQualificationCard(
                    players: below,
                    pitching: _pitching,
                    sortKey: _sortKey,
                    onPlayerTap: (player) => _showPlayer(
                      player,
                      methodology,
                      source['as_of_date'] as String?,
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SeasonStatsData {
  const _SeasonStatsData({required this.batting, required this.pitching});
  final Map<String, dynamic> batting;
  final Map<String, dynamic> pitching;
}

class _PlayerFilters extends StatelessWidget {
  const _PlayerFilters({
    required this.controller,
    required this.teams,
    required this.selectedTeam,
    required this.pitching,
    required this.sortKey,
    required this.onSearch,
    required this.onTeamChanged,
    required this.onSortChanged,
  });
  final TextEditingController controller;
  final List<String> teams;
  final String? selectedTeam;
  final bool pitching;
  final String sortKey;
  final ValueChanged<String> onSearch;
  final ValueChanged<String?> onTeamChanged;
  final ValueChanged<String> onSortChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          TextField(
            controller: controller,
            onChanged: onSearch,
            decoration: const InputDecoration(
                hintText: '선수명 검색', prefixIcon: Icon(Icons.search_rounded)),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: selectedTeam,
            decoration: const InputDecoration(
                labelText: '구단별 보기', prefixIcon: Icon(Icons.shield_rounded)),
            items: [
              const DropdownMenuItem<String>(value: null, child: Text('전체 구단')),
              ...teams.map((team) =>
                  DropdownMenuItem<String>(value: team, child: Text(team))),
            ],
            onChanged: onTeamChanged,
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: sortKey,
            decoration: const InputDecoration(
              labelText: '정렬 기준',
              prefixIcon: Icon(Icons.swap_vert_rounded),
            ),
            items: (pitching
                    ? const [
                        ('primary', 'ERA 낮은 순'),
                        ('fip', 'FIP 낮은 순'),
                        ('whip', 'WHIP 낮은 순'),
                        ('strikeouts', '탈삼진 높은 순'),
                        ('k_bb', 'K/BB 높은 순'),
                        ('k_bb_percent', 'K-BB% 높은 순'),
                        ('bb_per_nine', 'BB/9 낮은 순'),
                        ('hits', '피안타 낮은 순'),
                        ('wpa', 'WPA 높은 순'),
                      ]
                    : const [
                        ('primary', 'wRC+ 높은 순'),
                        ('ops', 'OPS 높은 순'),
                        ('avg', '타율 높은 순'),
                        ('obp', '출루율 높은 순'),
                        ('slg', '장타율 높은 순'),
                        ('hits', '안타 높은 순'),
                        ('hr', '홈런 높은 순'),
                        ('rbi', '타점 높은 순'),
                        ('runs', '득점 높은 순'),
                        ('sb', '도루 높은 순'),
                        ('wpa', 'WPA 높은 순'),
                      ])
                .map((option) => DropdownMenuItem<String>(
                      value: option.$1,
                      child: Text(option.$2),
                    ))
                .toList(),
            onChanged: (value) {
              if (value != null) onSortChanged(value);
            },
          ),
        ]),
      ),
    );
  }
}

class _BelowQualificationCard extends StatelessWidget {
  const _BelowQualificationCard({
    required this.players,
    required this.pitching,
    required this.sortKey,
    required this.onPlayerTap,
  });
  final List<Map<String, dynamic>> players;
  final bool pitching;
  final String sortKey;
  final ValueChanged<Map<String, dynamic>> onPlayerTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ExpansionTile(
        leading:
            const Icon(Icons.visibility_off_rounded, color: AppColors.muted),
        title: Text('${pitching ? '규정이닝' : '규정타석'} 미달 선수 ${players.length}명',
            style: const TextStyle(fontWeight: FontWeight.w900)),
        subtitle: const Text('눌러서 보기 또는 숨기기',
            style: TextStyle(color: AppColors.muted, fontSize: 12)),
        childrenPadding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
        children: players
            .map((player) => Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: _PlayerCard(
                    player: player,
                    pitching: pitching,
                    sortKey: sortKey,
                    onTap: () => onPlayerTap(player),
                  ),
                ))
            .toList(),
      ),
    );
  }
}

class _PlayerCard extends StatelessWidget {
  const _PlayerCard(
      {required this.player,
      required this.pitching,
      required this.sortKey,
      required this.onTap});
  final Map<String, dynamic> player;
  final bool pitching;
  final String sortKey;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final brand = TeamBrand.resolve(player['team_name'] as String);
    final display = switch ((pitching, sortKey)) {
      (false, 'ops') => ('OPS', player['ops']),
      (false, 'avg') => ('타율', player['avg']),
      (false, 'obp') => ('출루율', player['obp']),
      (false, 'slg') => ('장타율', player['slg']),
      (false, 'hits') => ('안타', player['h']),
      (false, 'hr') => ('홈런', player['hr']),
      (false, 'rbi') => ('타점', player['rbi']),
      (false, 'runs') => ('득점', player['r']),
      (false, 'sb') => ('도루', player['sb'] ?? 0),
      (false, 'wpa') => ('WPA', player['total_wpa']),
      (true, 'fip') => ('FIP', player['fip']),
      (true, 'whip') => ('WHIP', player['whip']),
      (true, 'strikeouts') => ('탈삼진', player['strikeouts']),
      (true, 'k_bb') => ('K/BB', player['k_bb']),
      (true, 'k_bb_percent') => ('K-BB%', '${player['k_bb_percent']}%'),
      (true, 'bb_per_nine') => ('BB/9', player['bb_per_nine']),
      (true, 'hits') => ('피안타', player['hits']),
      (true, 'wpa') => ('WPA', player['total_wpa']),
      (true, _) => ('ERA', player['era']),
      _ => ('추정 wRC+', player['estimated_wrc_plus']),
    };
    final label = display.$1;
    final value = display.$2;
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
          child: Row(children: [
            Container(
              width: 58,
              height: 58,
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: brand.primary.withValues(alpha: .08),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: brand.primary.withValues(alpha: .12)),
              ),
              child: TeamPlayerAvatar(
                teamName: player['team_name'] as String,
                size: 48,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(player['player_name'] as String,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 3),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _PlayerMetaPill(text: player['team_name'] as String),
                        _PlayerMetaPill(text: '${player['games']}경기'),
                        if (player['is_qualified'] == true)
                          const _PlayerMetaPill(text: '규정 충족'),
                      ],
                    ),
                  ]),
            ),
            const SizedBox(width: 8),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text('$value',
                    style: TextStyle(
                        color: brand.primary,
                        fontSize: 22,
                        fontWeight: FontWeight.w900)),
              ),
              Text(label,
                  style: const TextStyle(color: AppColors.muted, fontSize: 10)),
            ]),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
          ]),
        ),
      ),
    );
  }
}

class _PlayerMetaPill extends StatelessWidget {
  const _PlayerMetaPill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: AppColors.muted,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _TopRecordStrip extends StatelessWidget {
  const _TopRecordStrip({
    required this.players,
    required this.pitching,
    required this.onPlayerTap,
  });

  final List<Map<String, dynamic>> players;
  final bool pitching;
  final ValueChanged<Map<String, dynamic>> onPlayerTap;

  List<_LeaderSpec> get _specs => pitching
      ? const [
          _LeaderSpec('ERA', 'era', ascending: true),
          _LeaderSpec('WHIP', 'whip', ascending: true),
          _LeaderSpec('탈삼진', 'strikeouts'),
          _LeaderSpec('K-BB%', 'k_bb_percent', suffix: '%'),
        ]
      : const [
          _LeaderSpec('OPS', 'ops'),
          _LeaderSpec('홈런', 'hr'),
          _LeaderSpec('타점', 'rbi'),
          _LeaderSpec('WPA', 'total_wpa'),
        ];

  @override
  Widget build(BuildContext context) {
    if (players.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 154,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _specs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final spec = _specs[index];
          final source = spec.ascending
              ? players
                  .where((player) => ((player[spec.field] as num?) ?? 0) > 0)
                  .toList()
              : players.toList();
          if (source.isEmpty) return const SizedBox.shrink();
          final ranked = source
            ..sort((left, right) {
              final a = (left[spec.field] as num?) ?? 0;
              final b = (right[spec.field] as num?) ?? 0;
              return spec.ascending ? a.compareTo(b) : b.compareTo(a);
            });
          final player = ranked.first;
          final brand = TeamBrand.resolve(player['team_name'] as String);
          final value = player[spec.field];
          return SizedBox(
            width: 178,
            child: Card(
              margin: EdgeInsets.zero,
              child: InkWell(
                onTap: () => onPlayerTap(player),
                borderRadius: BorderRadius.circular(24),
                child: Padding(
                  padding: const EdgeInsets.all(13),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: brand.primary.withValues(alpha: .1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            pitching
                                ? Icons.speed_rounded
                                : Icons.sports_baseball_rounded,
                            color: brand.primary,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          spec.label,
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ]),
                      const Spacer(),
                      Row(children: [
                        TeamPlayerAvatar(
                          teamName: player['team_name'] as String,
                          size: 42,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                player['player_name'] as String,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text(
                                player['team_name'] as String,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.muted,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ]),
                      const SizedBox(height: 8),
                      Text(
                        '$value${spec.suffix}',
                        style: TextStyle(
                          color: brand.primary,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _LeaderSpec {
  const _LeaderSpec(
    this.label,
    this.field, {
    this.ascending = false,
    this.suffix = '',
  });

  final String label;
  final String field;
  final bool ascending;
  final String suffix;
}

class _StatsHeader extends StatelessWidget {
  const _StatsHeader({
    required this.season,
    required this.playerCount,
    required this.pitching,
  });
  final int season;
  final int playerCount;
  final bool pitching;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
          color: AppColors.forest, borderRadius: BorderRadius.circular(30)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(pitching ? Icons.speed_rounded : Icons.insights_rounded,
            color: AppColors.butter, size: 38),
        const SizedBox(height: 34),
        const Text('SEASON SABERMETRICS',
            style: TextStyle(
                color: AppColors.leaf,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
                fontSize: 12)),
        const SizedBox(height: 8),
        Text('$season ${pitching ? '투수' : '타자'} 시즌 지표',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 27,
                fontWeight: FontWeight.w900)),
        const SizedBox(height: 5),
        Text('$playerCount명의 시즌 누적 기록',
            style: const TextStyle(color: Colors.white70)),
      ]),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard(
      {required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(color: AppColors.muted)),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  color: color, fontSize: 27, fontWeight: FontWeight.w900)),
        ]),
      ),
    );
  }
}

class _StatGroup {
  const _StatGroup({
    required this.title,
    required this.icon,
    required this.stats,
  });

  final String title;
  final IconData icon;
  final Map<String, String> stats;
}

class _StatGroupCard extends StatelessWidget {
  const _StatGroupCard({required this.group, required this.accent});

  final _StatGroup group;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.line),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: .045),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(group.icon, color: accent, size: 18),
          ),
          const SizedBox(width: 10),
          Text(
            group.title,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ]),
        const SizedBox(height: 13),
        LayoutBuilder(
          builder: (context, constraints) {
            const spacing = 9.0;
            final width = (constraints.maxWidth - spacing) / 2;
            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                for (final stat in group.stats.entries)
                  SizedBox(
                    width: width,
                    child: _StatTile(label: stat.key, value: stat.value),
                  ),
              ],
            );
          },
        ),
      ]),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 69),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.muted, fontSize: 10)),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value,
                style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 18,
                    fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }
}

class _DetailReveal extends StatelessWidget {
  const _DetailReveal({
    required this.child,
    required this.intervalStart,
  });

  final Widget child;
  final double intervalStart;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 650),
      curve: Interval(intervalStart.clamp(0, .7).toDouble(), 1,
          curve: Curves.easeOutCubic),
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

class _SeasonBarChart extends StatelessWidget {
  const _SeasonBarChart({required this.values, required this.color});
  final Map<String, num> values;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final maxValue =
        values.values.fold<num>(1, (max, value) => value > max ? value : max);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('시즌 기록 차트',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
          const SizedBox(height: 18),
          ...values.entries.map((entry) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(children: [
                  SizedBox(
                      width: 42,
                      child: Text(entry.key,
                          style: const TextStyle(
                              color: AppColors.muted, fontSize: 11))),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: entry.value / maxValue,
                        minHeight: 10,
                        color: color,
                        backgroundColor: color.withValues(alpha: .12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                      width: 34,
                      child: Text('${entry.value}',
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontWeight: FontWeight.w800))),
                ]),
              )),
        ]),
      ),
    );
  }
}
