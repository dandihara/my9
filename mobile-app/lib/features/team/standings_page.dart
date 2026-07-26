import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_error.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/async_state_view.dart';
import '../../shared/widgets/team_brand.dart';

class StandingsPage extends StatefulWidget {
  const StandingsPage({super.key});

  @override
  State<StandingsPage> createState() => _StandingsPageState();
}

class _StandingsPageState extends State<StandingsPage> {
  late Future<Map<String, dynamic>> _standings;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _standings = ApiClient.instance.dio
        .get<Map<String, dynamic>>('/v1/teams/standings')
        .then((response) => response.data!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('팀 순위')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _standings,
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
          final rows =
              (data['standings'] as List<dynamic>).cast<Map<String, dynamic>>();
          if (rows.isEmpty) {
            return const AppEmptyView(
              title: '순위 기록이 없습니다',
              message: '완료된 경기가 적재되면 팀 순위가 표시됩니다.',
              icon: Icons.emoji_events_outlined,
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              setState(_reload);
              await _standings;
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 36),
              children: [
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.ink, AppColors.forest],
                    ),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          for (final color in const [
                            AppColors.coral,
                            AppColors.butter,
                            AppColors.leaf,
                          ])
                            Container(
                              width: 7,
                              height: 7,
                              margin: const EdgeInsets.only(right: 6),
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                          const Spacer(),
                          const Text(
                            'LEAGUE SCOREBOARD',
                            style: TextStyle(
                              color: Colors.white60,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: .8,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 13),
                      const Icon(Icons.emoji_events_rounded,
                          color: AppColors.butter, size: 36),
                      const SizedBox(height: 18),
                      Text('${data['season_year']} KBO',
                          style: const TextStyle(color: AppColors.leaf)),
                      if (data['as_of_date'] != null)
                        Text(
                          '기준일 ${(data['as_of_date'] as String).replaceAll('-', '.')}',
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 11),
                        ),
                      const Text('현재 팀 순위',
                          style: TextStyle(
                              color: Colors.white,
                              fontFamily: 'Jua',
                              fontSize: 28)),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                ...rows.map((row) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _StandingCard(row: row),
                    )),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StandingCard extends StatelessWidget {
  const _StandingCard({required this.row});

  final Map<String, dynamic> row;

  void _showTeamDetails(BuildContext context) {
    final teamName = row['team_name'] as String;
    final brand = TeamBrand.resolve(teamName);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: .66,
        maxChildSize: .9,
        builder: (context, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            Center(
              child: Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.line,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 18),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 520),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) => Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 18 * (1 - value)),
                  child: child,
                ),
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [brand.primary, brand.secondary],
                  ),
                  borderRadius: BorderRadius.circular(27),
                ),
                child: Row(children: [
                  Container(
                    width: 78,
                    height: 78,
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .92),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TeamMascotIcon(teamName: teamName, size: 64),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(teamName,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 25,
                                fontWeight: FontWeight.w900)),
                        Text(
                          '${row['rank']}위 · ${row['games']}경기',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '${row['wins']}승 ${row['losses']}패 ${row['draws']}무',
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                ]),
              ),
            ),
            const SizedBox(height: 14),
            _TeamMetricSection(
              title: '승부 요약',
              icon: Icons.scoreboard_rounded,
              accent: brand.primary,
              metrics: [
                ('순위', '${row['rank']}위'),
                ('승률', '${row['win_rate']}%'),
                ('승패', '${row['wins']}승 ${row['losses']}패'),
                ('무승부', row['draws']),
                ('최근 10G',
                    '${row['recent_10_wins']}승 ${row['recent_10_draws']}무 ${row['recent_10_losses']}패'),
                ('득실차', row['run_difference']),
              ],
            ),
            const SizedBox(height: 12),
            _TeamMetricSection(
              title: '팀 타격',
              icon: Icons.sports_baseball_rounded,
              accent: AppColors.forest,
              metrics: [
                ('타율', row['team_batting_average']),
                ('홈런', row['team_home_runs']),
                ('안타', row['team_hits']),
                ('출루율', row['team_on_base_percentage']),
                ('장타율', row['team_slugging_percentage']),
                ('OPS', row['team_ops']),
              ],
            ),
            const SizedBox(height: 12),
            _TeamMetricSection(
              title: '팀 투수',
              icon: Icons.speed_rounded,
              accent: brand.primary,
              metrics: [
                ('ERA', row['team_era']),
                ('WHIP', row['team_whip']),
                ('탈삼진', row['team_strikeouts']),
                ('실점', row['runs_allowed']),
              ],
            ),
            const SizedBox(height: 12),
            _TeamMetricSection(
              title: '득점 생산',
              icon: Icons.trending_up_rounded,
              accent: AppColors.coral,
              metrics: [
                ('득점', row['runs_scored']),
                ('실점', row['runs_allowed']),
                ('경기당 득점',
                    _perGame(row['runs_scored'] as num?, row['games'] as num?)),
                ('경기당 실점',
                    _perGame(row['runs_allowed'] as num?, row['games'] as num?)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final brand = TeamBrand.resolve(row['team_name'] as String);
    final teamName = row['team_name'] as String;
    return Card(
      child: InkWell(
        onTap: () => _showTeamDetails(context),
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
          child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            SizedBox(
              width: 30,
              child: Text(
                '${row['rank']}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: brand.primary,
                  fontFamily: 'Jua',
                  fontSize: 24,
                  height: 1,
                ),
              ),
            ),
            const SizedBox(width: 8),
            TeamMascotIcon(teamName: teamName, size: 50),
            const SizedBox(width: 12),
            Expanded(
              flex: 11,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    teamName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      height: 1.12,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      _MiniStatPill(
                        text:
                            '${row['wins']}승 ${row['losses']}패 ${row['draws']}무',
                        color: brand.primary,
                      ),
                      _MiniStatPill(
                        text:
                            '10G ${row['recent_10_wins']}-${row['recent_10_draws']}-${row['recent_10_losses']}',
                        color: AppColors.forest,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 70,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '${row['win_rate']}%',
                      style: const TextStyle(
                        color: AppColors.forest,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const Text(
                    '승률',
                    style: TextStyle(color: AppColors.muted, fontSize: 10),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.muted, size: 19),
          ]),
        ),
      ),
    );
  }
}

String _perGame(num? value, num? games) {
  final denominator = games?.toDouble() ?? 0;
  if (denominator <= 0) return '0.0';
  return ((value?.toDouble() ?? 0) / denominator).toStringAsFixed(1);
}

class _MiniStatPill extends StatelessWidget {
  const _MiniStatPill({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _TeamMetricSection extends StatelessWidget {
  const _TeamMetricSection({
    required this.title,
    required this.icon,
    required this.accent,
    required this.metrics,
  });

  final String title;
  final IconData icon;
  final Color accent;
  final List<(String, dynamic)> metrics;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.line),
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
            child: Icon(icon, color: accent, size: 18),
          ),
          const SizedBox(width: 10),
          Text(title,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
        ]),
        const SizedBox(height: 13),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: metrics.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1.35,
          ),
          itemBuilder: (context, index) {
            final metric = metrics[index];
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
              decoration: BoxDecoration(
                color: AppColors.cream,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(metric.$1,
                        style: const TextStyle(
                            color: AppColors.muted, fontSize: 10)),
                    const SizedBox(height: 3),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text('${metric.$2 ?? '-'}',
                          style: TextStyle(
                              color: accent,
                              fontSize: 17,
                              fontWeight: FontWeight.w900)),
                    ),
                  ]),
            );
          },
        ),
      ]),
    );
  }
}
