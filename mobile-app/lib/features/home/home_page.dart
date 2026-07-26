import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/main_menu_button.dart';
import '../../shared/widgets/team_brand.dart';
import '../auth/auth_controller.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const _doosanThemeKey = 'home_doosan_bear_theme';
  bool _doosanBearTheme = false;

  @override
  void initState() {
    super.initState();
    _loadDoosanTheme();
  }

  Future<void> _loadDoosanTheme() async {
    final preferences = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _doosanBearTheme = preferences.getBool(_doosanThemeKey) ?? false;
      });
    }
  }

  Future<void> _toggleDoosanTheme() async {
    final next = !_doosanBearTheme;
    setState(() => _doosanBearTheme = next);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_doosanThemeKey, next);
  }

  Future<void> _openMyTeam(BuildContext context) async {
    if (AuthController.instance.user!.myTeamId != null) {
      context.push('/my-team');
      return;
    }
    final response =
        await ApiClient.instance.dio.get<List<dynamic>>('/v1/teams');
    if (!context.mounted) return;
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
                    borderRadius: BorderRadius.circular(99))),
            const SizedBox(height: 18),
            Text('나의 응원팀 설정', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 5),
            const Text('응원팀은 직관 승률과 팀 기록에 사용돼요.',
                style: TextStyle(color: AppColors.muted)),
            const SizedBox(height: 16),
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
                          teamName: team['name'] as String, size: 46),
                      title: Text(team['name'] as String,
                          style: const TextStyle(fontWeight: FontWeight.w800)),
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
    if (context.mounted) context.push('/my-team');
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AuthController.instance,
      builder: (context, _) {
        final user = AuthController.instance.user!;
        final myTeamName = AuthController.instance.myTeamName;
        final isDoosan = myTeamName != null &&
            (myTeamName.contains('두산') ||
                myTeamName.toUpperCase().contains('DOOSAN'));
        String sectionAsset(TeamIconSection section) => myTeamName == null
            ? teamSectionAssetPath('', section)
            : teamSectionAssetPath(
                myTeamName,
                section,
                doosanBearTheme: _doosanBearTheme,
              );
        return Scaffold(
          appBar: AppBar(
            title: const Text('MY9'),
            actions: [
              if (isDoosan)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: IconButton.filledTonal(
                    tooltip: _doosanBearTheme ? '기존 캐릭터 테마로 변경' : '반달곰 테마로 변경',
                    onPressed: _toggleDoosanTheme,
                    icon: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 240),
                      transitionBuilder: (child, animation) =>
                          ScaleTransition(scale: animation, child: child),
                      child: Icon(
                        _doosanBearTheme
                            ? Icons.pets_rounded
                            : Icons.auto_awesome_rounded,
                        key: ValueKey(_doosanBearTheme),
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: IconButton.filledTonal(
                  tooltip: '로그아웃',
                  onPressed: AuthController.instance.logout,
                  icon: const Icon(Icons.logout_rounded),
                ),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
            children: [
              _TeamDashboardCard(
                key: ValueKey(user.myTeamId),
                teamId: user.myTeamId,
                nickname: user.nickname ?? user.username,
                onSetTeam: () => _openMyTeam(context),
                onOpenTeam: () => context.push('/my-team'),
              ),
              const SizedBox(height: 24),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: .72,
                children: [
                  MainMenuButton(
                    title: '경기 일정',
                    subtitle: '전체 일정과 결과',
                    icon: Icons.calendar_month_rounded,
                    assetPath: sectionAsset(TeamIconSection.schedule),
                    tint: AppColors.leaf,
                    onTap: () => context.push('/schedule'),
                  ),
                  MainMenuButton(
                    title: '직관 기록',
                    subtitle: '메모와 추억 모아보기',
                    icon: Icons.confirmation_number_rounded,
                    assetPath: sectionAsset(TeamIconSection.attendance),
                    tint: AppColors.butter,
                    onTap: () => context.push('/attendance'),
                  ),
                  MainMenuButton(
                    title: '시즌 기록',
                    subtitle: '타자·투수 세이버메트릭스',
                    icon: Icons.insights_rounded,
                    assetPath: sectionAsset(TeamIconSection.stats),
                    tint: const Color(0xFFB9E8DF),
                    onTap: () => context.push('/stats'),
                  ),
                  MainMenuButton(
                    title: 'WPA 분석',
                    subtitle: '승부 흐름과 기여도',
                    icon: Icons.timeline_rounded,
                    assetPath: sectionAsset(TeamIconSection.wpa),
                    tint: const Color(0xFFFFC5B8),
                    onTap: () => context.push('/wpa'),
                  ),
                  MainMenuButton(
                    title: '팀 순위',
                    subtitle: '현재 시즌 순위표',
                    icon: Icons.emoji_events_rounded,
                    tint: const Color(0xFFFFD98E),
                    onTap: () => context.push('/standings'),
                  ),
                  MainMenuButton(
                    title: '직관 리그',
                    subtitle: '친구들과 승·무·패 대결',
                    icon: Icons.groups_rounded,
                    tint: const Color(0xFFBDE8FF),
                    onTap: () => context.push('/attendance-leagues'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TeamDashboardCard extends StatefulWidget {
  const _TeamDashboardCard({
    required this.teamId,
    required this.nickname,
    required this.onSetTeam,
    required this.onOpenTeam,
    super.key,
  });

  final int? teamId;
  final String nickname;
  final VoidCallback onSetTeam;
  final VoidCallback onOpenTeam;

  @override
  State<_TeamDashboardCard> createState() => _TeamDashboardCardState();
}

class _TeamDashboardCardState extends State<_TeamDashboardCard> {
  Future<Map<String, dynamic>>? _dashboard;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    if (widget.teamId == null) {
      _dashboard = null;
      return;
    }
    _dashboard = ApiClient.instance.dio
        .get<Map<String, dynamic>>('/v1/teams/${widget.teamId}/dashboard')
        .then((response) => response.data!);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.teamId == null) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.ink, AppColors.forest],
          ),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${widget.nickname}님, 어느 팀을 응원하시나요?',
              style: const TextStyle(color: AppColors.leaf)),
          const SizedBox(height: 10),
          const Text('MY 팀을 설정하면\n오늘의 순위와 경기를 모아드려요',
              style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Jua',
                  fontSize: 25,
                  height: 1.18)),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: widget.onSetTeam,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.butter,
              foregroundColor: AppColors.ink,
            ),
            child: const Text('MY 팀 설정'),
          ),
        ]),
      );
    }
    return FutureBuilder<Map<String, dynamic>>(
      future: _dashboard,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Card(
            child: SizedBox(
              height: 230,
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }
        if (snapshot.hasError) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(children: [
                const Text('응원팀 기록을 불러오지 못했어요.'),
                TextButton(
                  onPressed: () => setState(_load),
                  child: const Text('다시 시도'),
                ),
              ]),
            ),
          );
        }
        final data = snapshot.data!;
        final summary = data['summary'] as Map<String, dynamic>;
        final recent = (data['recent_games'] as List<dynamic>)
            .cast<Map<String, dynamic>>();
        final next = data['next_game'] as Map<String, dynamic>?;
        final teamName = summary['team_name'] as String;
        final brand = TeamBrand.resolve(teamName);
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 620),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) => Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, 22 * (1 - value)),
              child: child,
            ),
          ),
          child: InkWell(
            onTap: widget.onOpenTeam,
            borderRadius: BorderRadius.circular(32),
            child: Ink(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [brand.primary, brand.secondary],
                ),
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: brand.primary.withValues(alpha: .22),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Stack(children: [
                Positioned(
                  right: -38,
                  top: -45,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: .06),
                    ),
                  ),
                ),
                Positioned(
                  left: -42,
                  bottom: 58,
                  child: Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: .035),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
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
                          Text(
                            'HOME SCOREBOARD',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: .68),
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      Row(children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: .13),
                                  borderRadius: BorderRadius.circular(99),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: .12),
                                  ),
                                ),
                                child: Text(
                                  '$teamName · ${summary['season_year']}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('${summary['rank']}',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontFamily: 'Jua',
                                          fontSize: 47,
                                          height: .9)),
                                  const Padding(
                                    padding:
                                        EdgeInsets.only(left: 3, bottom: 3),
                                    child: Text('위',
                                        style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 18,
                                            fontWeight: FontWeight.w900)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.fromLTRB(14, 11, 14, 10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: .12),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: .1)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${summary['wins']}승 ${summary['losses']}패 ${summary['draws']}무',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '승률 ${summary['win_rate']}%',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ]),
                      const SizedBox(height: 20),
                      Row(children: [
                        const Text('RECENT 5',
                            style: TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.1)),
                        const Spacer(),
                        Text('최근 흐름',
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: .55),
                                fontSize: 10)),
                      ]),
                      const SizedBox(height: 8),
                      if (recent.isEmpty)
                        const Text('완료된 경기가 없습니다.',
                            style: TextStyle(color: Colors.white70))
                      else
                        Row(
                          children: [
                            for (final entry in recent.take(5).indexed) ...[
                              if (entry.$1 > 0) const SizedBox(width: 5),
                              Expanded(
                                child: _RecentGameChip(game: entry.$2),
                              ),
                            ],
                          ],
                        ),
                      const SizedBox(height: 15),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .14),
                          borderRadius: BorderRadius.circular(17),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: .09)),
                        ),
                        child: Row(children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: .14),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.calendar_month_rounded,
                                color: Colors.white, size: 17),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: next == null
                                ? const Text('예정된 다음 경기가 없습니다.',
                                    style: TextStyle(color: Colors.white))
                                : Text(
                                    '${DateFormat('M.d').format(DateTime.parse(next['game_date'] as String))} · vs ${next['opponent_name']}',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900),
                                  ),
                          ),
                          const Icon(Icons.arrow_forward_rounded,
                              color: Colors.white70, size: 18),
                        ]),
                      ),
                    ],
                  ),
                ),
              ]),
            ),
          ),
        );
      },
    );
  }
}

class _RecentGameChip extends StatelessWidget {
  const _RecentGameChip({required this.game});

  final Map<String, dynamic> game;

  @override
  Widget build(BuildContext context) {
    final result = game['result'] as String?;
    final label = switch (result) {
      'win' => '승',
      'loss' => '패',
      _ => '무',
    };
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: result == 'win' ? .94 : .7),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text('${game['opponent_name']} $label',
              maxLines: 1,
              style: TextStyle(
                  color: result == 'win' ? AppColors.forest : AppColors.ink,
                  fontSize: 12,
                  fontWeight: FontWeight.w900)),
        ),
        const SizedBox(height: 2),
        Text('${game['my_score']}:${game['opponent_score']}',
            style: const TextStyle(fontSize: 9, color: AppColors.ink)),
      ]),
    );
  }
}
