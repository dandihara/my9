import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_error.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/async_state_view.dart';
import '../../shared/widgets/team_brand.dart';

Future<T?> _openSeasonPlayerPage<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool? isScrollControlled,
  Color? backgroundColor,
  ShapeBorder? shape,
}) {
  return Navigator.of(context).push<T>(
    MaterialPageRoute<T>(
      builder: (context) => Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(title: const Text('시즌 선수 기록')),
        body: builder(context),
      ),
    ),
  );
}

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
  bool _applyQualificationToTopFive = true;

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
      (true, 'wins') => 'wins',
      (true, 'losses') => 'losses',
      (true, 'holds') => 'holds',
      (true, 'saves') => 'saves',
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
          'wins',
          'holds',
          'saves',
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
    final recentGames =
        (player['recent_games'] as List<dynamic>? ?? const <dynamic>[])
            .cast<Map<String, dynamic>>();
    final primary = _pitching
        ? <String, String>{
            'ERA': '${player['era']}',
            'WHIP': '${player['whip']}',
          }
        : <String, String>{
            'OPS': '${player['ops']}',
            '추정 wRC+': '${player['estimated_wrc_plus']}',
          };
    final statGroups = _pitching
        ? <_StatGroup>[
            _StatGroup(
              title: '',
              icon: Icons.sports_baseball_rounded,
              stats: {
                '승': '${player['wins'] ?? 0}',
                '패': '${player['losses'] ?? 0}',
                '홀드': '${player['holds'] ?? 0}',
                '세이브': '${player['saves'] ?? 0}',
                '이닝': '${player['innings_pitched']}',
                '자책': '${player['earned_runs']}',
                '삼진': '${player['strikeouts']}',
                '피안타': '${player['hits']}',
                '볼넷': '${player['walks']}',
                '피홈런': '${player['home_runs']}',
                '상대 타자': '${player['batters_faced']}',
                'K/9': '${player['k_per_nine']}',
                'K/BB': '${player['k_bb']}',
                'FIP': '${player['fip']}',
              },
            ),
          ]
        : <_StatGroup>[
            _StatGroup(
              title: '',
              icon: Icons.sports_baseball_rounded,
              stats: {
                '타율': '${player['avg']}',
                '타수': '${player['ab']}',
                '안타': '${player['h']}',
                '홈런': '${player['hr']}',
                '타점': '${player['rbi']}',
                '득점': '${player['r']}',
                '도루': '${player['sb'] ?? 0}',
                '볼넷': '${player['bb']}',
                '삼진': '${player['so']}',
                '출루율': '${player['obp']}',
                '장타율': '${player['slg']}',
              },
            ),
          ];

    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => _SeasonPlayerDetailPage(
            player: player,
            pitching: _pitching,
            brand: brand,
            primary: primary,
            statGroups: statGroups,
            recentGames: recentGames,
            asOfDate: asOfDate,
          ),
        ),
      );
      return;
    }

    _openSeasonPlayerPage<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFF8F3EB),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 1,
        minChildSize: 1,
        maxChildSize: 1,
        builder: (context, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 36),
          children: [
            const SizedBox(height: 4),
            _PlayerDetailHero(
              player: player,
              brand: brand,
              pitching: _pitching,
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
            const Text(
              '시즌 핵심 기록',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            _DetailReveal(
              intervalStart: 0,
              child: Row(children: [
                Expanded(
                  child: _MetricCard(
                      label: primary.keys.first,
                      value: primary.values.first,
                      color: AppColors.coral,
                      rank: player[_pitching ? 'era_rank' : 'ops_rank'] as int?,
                      percentile: player[_pitching
                          ? 'era_percentile'
                          : 'ops_percentile'] as int?),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MetricCard(
                      label: primary.keys.last,
                      value: primary.values.last,
                      color: AppColors.forest,
                      rank: player[_pitching ? 'whip_rank' : 'wrc_plus_rank']
                          as int?,
                      percentile: player[_pitching
                          ? 'whip_percentile'
                          : 'wrc_plus_percentile'] as int?),
                ),
              ]),
            ),
            const SizedBox(height: 16),
            if (recentGames.isNotEmpty) ...[
              const Row(children: [
                Text('최근 경기 기록',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                Spacer(),
                Text('최근 10경기',
                    style: TextStyle(fontSize: 11, color: AppColors.muted)),
              ]),
              const SizedBox(height: 10),
              _DetailReveal(
                intervalStart: .08,
                child: _RecentFiveGamePanel(
                  games: recentGames,
                  pitching: _pitching,
                  accent: brand.primary,
                ),
              ),
              const SizedBox(height: 16),
            ],
            const Text(
              '시즌 주요 기록',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            ...statGroups.indexed.expand((entry) => [
                  _DetailReveal(
                    intervalStart: .16 + entry.$1 * .08,
                    child: _StatGroupCard(
                      group: entry.$2,
                      accent: brand.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                ]),
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
          // 투수 기록은 규정이닝으로 구분하지 않고 전원을 표시한다.
          final primaryPlayers = _pitching
              ? filtered
              : filtered
                  .where((player) => player['is_qualified'] == true)
                  .toList();
          final below = _pitching
              ? <Map<String, dynamic>>[]
              : filtered
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
                    season: source['season_year'] as int, pitching: _pitching),
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
                if (query.isEmpty) ...[
                  Card(
                    child: CheckboxListTile(
                      value: _applyQualificationToTopFive,
                      onChanged: (value) => setState(
                        () => _applyQualificationToTopFive = value ?? true,
                      ),
                      controlAffinity: ListTileControlAffinity.leading,
                      dense: true,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 12),
                      title: Text(
                        'TOP 5 · 비율 지표 ${_pitching ? '규정이닝' : '규정타석'} '
                        '${_applyQualificationToTopFive ? '적용' : '미적용'}',
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      subtitle: Text(
                        _applyQualificationToTopFive
                            ? '비율 지표에 KBO 공식 기준 적용 · 누계 지표는 전체 선수'
                            : '표본 확대 · 공식 기준의 50% 이상만 포함',
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _TopRecordStrip(
                    players: filtered,
                    pitching: _pitching,
                    applyQualification: _applyQualificationToTopFive,
                    onPlayerTap: (player) => _showPlayer(
                      player,
                      methodology,
                      source['as_of_date'] as String?,
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                if (primaryPlayers.isEmpty)
                  const Card(
                      child: Padding(
                          padding: EdgeInsets.all(22),
                          child: Center(child: Text('조건에 맞는 선수가 없습니다.'))))
                else
                  ...primaryPlayers.map((player) => Padding(
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
            isExpanded: true,
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
            isExpanded: true,
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
                        ('wins', '승 많은 순'),
                        ('losses', '패 적은 순'),
                        ('holds', '홀드 많은 순'),
                        ('saves', '세이브 많은 순'),
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
        title: Text('규정타석 미달 선수 ${players.length}명',
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

class _SeasonPlayerDetailPage extends StatelessWidget {
  const _SeasonPlayerDetailPage({
    required this.player,
    required this.pitching,
    required this.brand,
    required this.primary,
    required this.statGroups,
    required this.recentGames,
    required this.asOfDate,
  });

  final Map<String, dynamic> player;
  final bool pitching;
  final TeamBrand brand;
  final Map<String, String> primary;
  final List<_StatGroup> statGroups;
  final List<Map<String, dynamic>> recentGames;
  final String? asOfDate;

  int? _rank(bool secondary) => player[pitching
      ? (secondary ? 'whip_rank' : 'era_rank')
      : (secondary ? 'wrc_plus_rank' : 'ops_rank')] as int?;

  int? _percentile(bool secondary) => player[pitching
      ? (secondary ? 'whip_percentile' : 'era_percentile')
      : (secondary ? 'wrc_plus_percentile' : 'ops_percentile')] as int?;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFCF7),
      appBar: AppBar(title: const Text('시즌 선수 기록')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 36),
        children: [
          _PlayerDetailHero(player: player, brand: brand, pitching: pitching),
          const SizedBox(height: 20),
          Row(children: [
            Text(
              '${DateTime.now().year} 시즌 기록',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
            ),
            const Spacer(),
            if (asOfDate != null)
              Text(
                '$asOfDate 기준',
                style: const TextStyle(color: AppColors.muted, fontSize: 10),
              ),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: _ReferenceMetricCard(
                label: primary.keys.first,
                value: primary.values.first,
                color: AppColors.coral,
                rank: _rank(false),
                percentile: _percentile(false),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ReferenceMetricCard(
                label: primary.keys.last,
                value: primary.values.last,
                color: AppColors.forest,
                rank: _rank(true),
                percentile: _percentile(true),
              ),
            ),
          ]),
          const SizedBox(height: 14),
          if (recentGames.isNotEmpty) ...[
            _DetailSectionCard(
              title: '최근 경기 기록',
              trailing: '최근 10경기',
              child: _RecentFiveGamePanel(
                games: recentGames,
                pitching: pitching,
                accent: brand.primary,
              ),
            ),
            const SizedBox(height: 14),
          ],
          _DetailSectionCard(
            title: '시즌 주요 기록',
            child: Column(
              children: statGroups
                  .map((group) =>
                      _StatGroupCard(group: group, accent: brand.primary))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReferenceMetricCard extends StatelessWidget {
  const _ReferenceMetricCard({
    required this.label,
    required this.value,
    required this.color,
    required this.rank,
    required this.percentile,
  });

  final String label;
  final String value;
  final Color color;
  final int? rank;
  final int? percentile;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 132,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: .25)),
      ),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(label,
            style: TextStyle(
                color: color, fontSize: 12, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        FittedBox(
          child: Text(value,
              style: TextStyle(
                  color: color, fontSize: 31, fontWeight: FontWeight.w900)),
        ),
        const SizedBox(height: 7),
        Text(
          rank == null
              ? '규정 기준 집계 중'
              : '리그 $rank위 · 상위 ${100 - (percentile ?? 0)}%',
          style: TextStyle(
              color: color, fontSize: 10, fontWeight: FontWeight.w800),
        ),
      ]),
    );
  }
}

class _DetailSectionCard extends StatelessWidget {
  const _DetailSectionCard(
      {required this.title, required this.child, this.trailing});

  final String title;
  final String? trailing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(
            title.contains('최근')
                ? Icons.show_chart_rounded
                : Icons.grid_view_rounded,
            size: 18,
            color: AppColors.coral,
          ),
          const SizedBox(width: 7),
          Text(title,
              style:
                  const TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
          const Spacer(),
          if (trailing != null)
            Text(trailing!,
                style: const TextStyle(color: AppColors.muted, fontSize: 10)),
        ]),
        const SizedBox(height: 10),
        child,
      ]),
    );
  }
}

class _PlayerDetailHero extends StatelessWidget {
  const _PlayerDetailHero({
    required this.player,
    required this.brand,
    required this.pitching,
  });

  final Map<String, dynamic> player;
  final TeamBrand brand;
  final bool pitching;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 178,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.ink, brand.primary, brand.secondary],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: .24)),
      ),
      child: Stack(children: [
        Positioned(
          right: -8,
          bottom: -34,
          child: Text(
            brand.initials,
            style: TextStyle(
                color: Colors.white.withValues(alpha: .055),
                fontSize: 92,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic),
          ),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            _BoardLight(color: brand.secondary),
            const SizedBox(width: 7),
            Text(
              pitching ? 'BULLPEN PROFILE' : 'LINEUP PROFILE',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
            const Spacer(),
            const Icon(Icons.stadium_outlined, color: Colors.white70, size: 19),
          ]),
          const SizedBox(height: 18),
          Row(children: [
            Container(
              width: 82,
              height: 82,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .92),
                borderRadius: BorderRadius.circular(22),
              ),
              child: TeamPlayerAvatar(
                teamName: player['team_name'] as String,
                size: 70,
              ),
            ),
            const SizedBox(width: 17),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(player['team_name'] as String,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text(player['player_name'] as String,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 29,
                            fontWeight: FontWeight.w900)),
                  ]),
            ),
          ]),
        ]),
      ]),
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
      (true, 'wins') => ('승', player['wins'] ?? 0),
      (true, 'losses') => ('패', player['losses'] ?? 0),
      (true, 'holds') => ('홀드', player['holds'] ?? 0),
      (true, 'saves') => ('세이브', player['saves'] ?? 0),
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
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.ink, brand.primary.withValues(alpha: .88)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: .18)),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: .045),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
          child: Column(children: [
            Row(children: [
              Container(
                width: 62,
                height: 62,
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(19),
                  border:
                      Border.all(color: brand.primary.withValues(alpha: .18)),
                ),
                child: TeamPlayerAvatar(
                  teamName: player['team_name'] as String,
                  size: 52,
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
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w900)),
                      const SizedBox(height: 5),
                      _PlayerMetaPill(text: player['team_name'] as String),
                    ]),
              ),
              const SizedBox(width: 8),
              Container(
                width: 86,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                decoration: BoxDecoration(
                  color: AppColors.ink,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: brand.primary.withValues(alpha: .55),
                    width: 1.3,
                  ),
                ),
                child: Column(children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('$value',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900)),
                  ),
                  const SizedBox(height: 2),
                  Text(label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                          fontWeight: FontWeight.w800)),
                ]),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right_rounded, color: Colors.white70),
            ]),
            if (pitching) ...[
              const SizedBox(height: 10),
              _PitchingDecisionStrip(player: player),
            ],
          ]),
        ),
      ),
    );
  }
}

class _PitchingDecisionStrip extends StatelessWidget {
  const _PitchingDecisionStrip({required this.player});

  final Map<String, dynamic> player;

  @override
  Widget build(BuildContext context) {
    final decisions = [
      ('승', player['wins'] ?? 0),
      ('패', player['losses'] ?? 0),
      ('홀드', player['holds'] ?? 0),
      ('세이브', player['saves'] ?? 0),
    ];
    return Row(
      children: decisions
          .map(
            (decision) => Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${decision.$1} ${decision.$2}',
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          )
          .toList(),
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
        color: Colors.white.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.white70,
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
    required this.applyQualification,
    required this.onPlayerTap,
  });

  final List<Map<String, dynamic>> players;
  final bool pitching;
  final bool applyQualification;
  final ValueChanged<Map<String, dynamic>> onPlayerTap;

  List<_LeaderSpec> get _specs => pitching
      ? const [
          _LeaderSpec('ERA', 'era', ascending: true, usesQualification: true),
          _LeaderSpec('WHIP', 'whip', ascending: true, usesQualification: true),
          _LeaderSpec('승', 'wins'),
          _LeaderSpec('패', 'losses'),
          _LeaderSpec('홀드', 'holds'),
          _LeaderSpec('세이브', 'saves'),
          _LeaderSpec('탈삼진', 'strikeouts'),
          _LeaderSpec('K-BB%', 'k_bb_percent',
              suffix: '%', usesQualification: true),
        ]
      : const [
          _LeaderSpec('OPS', 'ops', usesQualification: true),
          _LeaderSpec('홈런', 'hr'),
          _LeaderSpec('타점', 'rbi'),
          _LeaderSpec('WPA', 'total_wpa'),
        ];

  @override
  Widget build(BuildContext context) {
    if (players.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) => SizedBox(
        height: 352,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          itemCount: _specs.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (context, index) {
            final spec = _specs[index];
            final source = players.where((player) {
              final value = ((player[spec.field] as num?) ?? 0).toDouble();
              if (value <= 0) return false;
              if (!spec.usesQualification) return true;
              if (applyQualification) return player['is_qualified'] == true;
              final sample =
                  ((player[pitching ? 'innings_pitched' : 'pa'] as num?) ?? 0)
                      .toDouble();
              final official = ((player[pitching
                          ? 'qualification_innings'
                          : 'qualification_pa'] as num?) ??
                      0)
                  .toDouble();
              return sample > 0 && (official <= 0 || sample >= official * .5);
            }).toList();
            source.sort((left, right) {
              final a = (left[spec.field] as num?) ?? 0;
              final b = (right[spec.field] as num?) ?? 0;
              return spec.ascending ? a.compareTo(b) : b.compareTo(a);
            });
            final ranked = source.take(5).toList();
            if (ranked.isEmpty) return const SizedBox.shrink();
            final brand =
                TeamBrand.resolve(ranked.first['team_name'] as String);
            return Container(
              width: constraints.maxWidth * .94,
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.ink,
                    brand.primary.withValues(alpha: .76),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: .2)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.ink.withValues(alpha: .14),
                    blurRadius: 18,
                    offset: const Offset(0, 9),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(children: [
                    _BoardLight(color: brand.secondary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        spec.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: .24),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: const Text(
                        'TOP 5',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 10),
                  for (var rank = 0; rank < ranked.length; rank++)
                    Expanded(
                      child: InkWell(
                        onTap: () => onPlayerTap(ranked[rank]),
                        borderRadius: BorderRadius.circular(13),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          child: Row(children: [
                            SizedBox(
                              width: 25,
                              child: Text(
                                '${rank + 1}',
                                style: TextStyle(
                                  color: rank == 0
                                      ? AppColors.butter
                                      : Colors.white54,
                                  fontSize: rank == 0 ? 18 : 14,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            TeamPlayerAvatar(
                              teamName: ranked[rank]['team_name'] as String,
                              size: 34,
                            ),
                            const SizedBox(width: 9),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    ranked[rank]['player_name'] as String,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  Text(
                                    ranked[rank]['team_name'] as String,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white54,
                                      fontSize: 9,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${ranked[rank][spec.field]}${spec.suffix}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ]),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
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
    this.usesQualification = false,
  });

  final String label;
  final String field;
  final bool ascending;
  final String suffix;
  final bool usesQualification;
}

class _BoardLight extends StatelessWidget {
  const _BoardLight({required this.color});

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
          BoxShadow(
            color: color.withValues(alpha: .55),
            blurRadius: 8,
          ),
        ],
      ),
    );
  }
}

class _StatsHeader extends StatelessWidget {
  const _StatsHeader({
    required this.season,
    required this.pitching,
  });
  final int season;
  final bool pitching;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF182744), Color(0xFF234D3D), Color(0xFF7F2635)],
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: .28)),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: .16),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const _BoardLight(color: AppColors.coral),
          const SizedBox(width: 6),
          const _BoardLight(color: AppColors.butter),
          const SizedBox(width: 6),
          const _BoardLight(color: AppColors.leaf),
          const Spacer(),
          Text(
            pitching ? 'PITCHER BOARD' : 'BATTER BOARD',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.1,
            ),
          ),
        ]),
        const SizedBox(height: 34),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .9),
            borderRadius: BorderRadius.circular(18),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(
                pitching ? Icons.speed_rounded : Icons.sports_baseball_rounded,
                color: AppColors.ink,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                '$season SEASON',
                style: const TextStyle(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ]),
          ),
        ),
        const SizedBox(height: 14),
        Text('$season ${pitching ? '투수' : '타자'} 시즌 지표',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 27,
                fontWeight: FontWeight.w900)),
      ]),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard(
      {required this.label,
      required this.value,
      required this.color,
      this.rank,
      this.percentile});
  final String label;
  final String value;
  final Color color;
  final int? rank;
  final int? percentile;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .09),
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: color.withValues(alpha: .28)),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: .08),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          _BoardLight(color: color),
          const SizedBox(width: 7),
          Text(label,
              style: TextStyle(color: color, fontWeight: FontWeight.w900)),
        ]),
        const SizedBox(height: 8),
        Text(value,
            style: TextStyle(
                color: color, fontSize: 28, fontWeight: FontWeight.w900)),
        if (rank != null) ...[
          const SizedBox(height: 5),
          Text(
            '리그 $rank위 · 상위 ${100 - (percentile ?? 0)}%',
            style: TextStyle(
              color: color.withValues(alpha: .82),
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ]),
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
        color: const Color(0xFFFFFCF4),
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
        if (group.title.isNotEmpty) ...[
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
        ],
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.line.withValues(alpha: .72)),
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

class _RecentFiveGamePanel extends StatelessWidget {
  const _RecentFiveGamePanel({
    required this.games,
    required this.pitching,
    required this.accent,
  });

  final List<Map<String, dynamic>> games;
  final bool pitching;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final ordered = games.take(10).toList().reversed.toList();
    final values = ordered.map((game) {
      if (pitching) {
        final era = game['era_after_game'] as num?;
        if (era != null) return era.toDouble();
        final innings = (game['innings_pitched'] as num?)?.toDouble() ?? 0;
        final earned = (game['earned_runs'] as num?)?.toDouble() ?? 0;
        return innings <= 0 ? 0.0 : earned * 9 / innings;
      }
      final avg = game['avg_after_game'] as num?;
      if (avg != null) return avg.toDouble();
      final ab = (game['ab'] as num?)?.toDouble() ?? 0;
      final hits = (game['h'] as num?)?.toDouble() ?? 0;
      return ab <= 0 ? 0.0 : hits / ab;
    }).toList();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF4),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
          height: 126,
          child: CustomPaint(
            painter: _RecentLineChartPainter(values: values, color: accent),
            child: const SizedBox.expand(),
          ),
        ),
        const SizedBox(height: 12),
        ...ordered.map((game) => _RecentGameSummaryTile(
              game: game,
              pitching: pitching,
              accent: accent,
            )),
      ]),
    );
  }
}

class _RecentGameSummaryTile extends StatelessWidget {
  const _RecentGameSummaryTile({
    required this.game,
    required this.pitching,
    required this.accent,
  });

  final Map<String, dynamic> game;
  final bool pitching;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final date = DateTime.parse(game['game_date'] as String);
    final dateText = '${date.month}.${date.day.toString().padLeft(2, '0')}';
    final value = pitching
        ? '${game['innings_pitched']}이닝 · ${game['earned_runs']}자책 · ${game['strikeouts']}K'
        : '${game['ab']}타수 ${game['h']}안타 · ${game['rbi']}타점 · ${game['bb']}볼넷';
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(children: [
        Container(
          width: 54,
          padding: const EdgeInsets.symmetric(vertical: 7),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: .1),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Text(
            dateText,
            style: TextStyle(
              color: accent,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'vs ${game['opponent_name']}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ]),
    );
  }
}

class _RecentLineChartPainter extends CustomPainter {
  const _RecentLineChartPainter({required this.values, required this.color});

  final List<double> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final maxValue =
        values.fold<double>(1, (max, value) => value > max ? value : max);
    final minValue = values.fold<double>(
        maxValue, (min, value) => value < min ? value : min);
    final range = (maxValue - minValue).abs() < .001 ? 1 : maxValue - minValue;
    final chartRect = Rect.fromLTWH(8, 10, size.width - 16, size.height - 34);
    final grid = Paint()
      ..color = AppColors.line.withValues(alpha: .7)
      ..strokeWidth = 1;
    for (var i = 0; i < 4; i++) {
      final y = chartRect.top + chartRect.height * i / 3;
      canvas.drawLine(
          Offset(chartRect.left, y), Offset(chartRect.right, y), grid);
    }
    final points = <Offset>[];
    for (var i = 0; i < values.length; i++) {
      final x = values.length == 1
          ? chartRect.center.dx
          : chartRect.left + chartRect.width * i / (values.length - 1);
      final y = chartRect.bottom -
          ((values[i] - minValue) / range) * chartRect.height;
      points.add(Offset(x, y));
    }
    final line = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(path, line);
    for (final point in points) {
      canvas.drawCircle(point, 4.5, Paint()..color = Colors.white);
      canvas.drawCircle(
          point,
          4.5,
          Paint()
            ..color = color
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2);
    }
    final labelPainter = TextPainter(
      text: TextSpan(
        text: '최근 ERA ${values.last.toStringAsFixed(2)}',
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    labelPainter.paint(canvas, Offset(chartRect.right - labelPainter.width, 0));
  }

  @override
  bool shouldRepaint(covariant _RecentLineChartPainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.color != color;
}
