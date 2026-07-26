import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_error.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/async_state_view.dart';
import '../../shared/widgets/team_brand.dart';

class WpaPage extends StatefulWidget {
  const WpaPage({super.key});

  @override
  State<WpaPage> createState() => _WpaPageState();
}

class _WpaPageState extends State<WpaPage> {
  late Future<Map<String, dynamic>> _records;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _records = ApiClient.instance.dio
        .get<Map<String, dynamic>>('/v1/stats/season/wpa')
        .then((response) => response.data!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('시즌 WPA')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _records,
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
          final players =
              (data['players'] as List<dynamic>).cast<Map<String, dynamic>>();
          if (players.isEmpty) {
            return const AppEmptyView(
              title: 'WPA 기록이 없습니다',
              message: '경기 이벤트 분석이 완료되면 일별 시즌 WPA가 표시됩니다.',
              icon: Icons.timeline_rounded,
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              setState(_reload);
              await _records;
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
              children: [
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.ink, AppColors.forest],
                    ),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.ink.withValues(alpha: .18),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
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
                            'WIN PROBABILITY BOARD',
                            style: TextStyle(
                              color: Colors.white60,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: .7,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 13),
                      Row(children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: .12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.auto_graph_rounded,
                              color: AppColors.butter, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Text('${data['season_year']} SEASON',
                            style: const TextStyle(color: AppColors.butter)),
                      ]),
                      const SizedBox(height: 4),
                      const Text('승부 기여도',
                          style: TextStyle(
                              color: Colors.white,
                              fontFamily: 'Jua',
                              fontSize: 28)),
                      if (data['as_of_date'] != null)
                        Text('${data['as_of_date']} 경기까지 반영',
                            style: const TextStyle(
                                color: Colors.white54, fontSize: 12)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ...players.map((player) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Card(
                        elevation: 0,
                        clipBehavior: Clip.antiAlias,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(children: [
                            TeamBadge(
                                teamName: player['team_name'] as String,
                                size: 48),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(player['player_name'] as String,
                                      style: const TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w900)),
                                  Text(
                                    '${player['team_name']} · ${player['games']}경기',
                                    style: const TextStyle(
                                        color: AppColors.muted, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            _WpaValue(
                                label: '타격', value: player['batting_wpa']),
                            _WpaValue(
                                label: '투구', value: player['pitching_wpa']),
                            _WpaValue(label: '종합', value: player['total_wpa']),
                          ]),
                        ),
                      ),
                    )),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _WpaValue extends StatelessWidget {
  const _WpaValue({required this.label, required this.value});

  final String label;
  final dynamic value;

  @override
  Widget build(BuildContext context) {
    final number = (value as num?)?.toDouble() ?? 0;
    return SizedBox(
      width: 48,
      child: Column(children: [
        Text(label,
            style: const TextStyle(color: AppColors.muted, fontSize: 10)),
        Text(number.toStringAsFixed(2),
            style: TextStyle(
                color: number >= 0 ? AppColors.forest : AppColors.coral,
                fontWeight: FontWeight.w900)),
      ]),
    );
  }
}
