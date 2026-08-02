import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/main_menu_button.dart';
import '../../shared/widgets/home_weather_backdrop.dart';
import '../../shared/widgets/team_brand.dart';
import '../auth/auth_controller.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Map<String, dynamic>? _stadiumWeather;

  @override
  void initState() {
    super.initState();
  }

  void _updateStadiumWeather(Map<String, dynamic>? weather) {
    final previous = _stadiumWeather?['condition'];
    final next = weather?['condition'];
    if (previous == next &&
        _stadiumWeather?['game_id'] == weather?['game_id']) {
      return;
    }
    if (mounted) setState(() => _stadiumWeather = weather);
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
        String sectionAsset(TeamIconSection section) => myTeamName == null
            ? teamSectionAssetPath('', section)
            : teamSectionAssetPath(
                myTeamName,
                section,
                doosanMangomTheme: AppConfig.useDoosanMangomSections,
              );
        final weatherCondition = _stadiumWeather?['condition']?.toString() ??
            _seasonalBackdropCondition(DateTime.now().month);
        final darkWeather =
            weatherCondition == 'night' || weatherCondition == 'rain';
        final weatherForeground = darkWeather ? Colors.white : AppColors.ink;
        final headerBackground = darkWeather
            ? const Color(0xFF22324F).withValues(alpha: .94)
            : AppColors.white.withValues(alpha: .9);
        final weatherButtonStyle = IconButton.styleFrom(
          foregroundColor: weatherForeground,
          backgroundColor:
              Colors.white.withValues(alpha: darkWeather ? .16 : .5),
        );
        return Stack(
          children: [
            Positioned.fill(
              child: HomeWeatherBackdrop(condition: weatherCondition),
            ),
            Scaffold(
              appBar: AppBar(
                backgroundColor: headerBackground,
                foregroundColor: weatherForeground,
                surfaceTintColor: Colors.transparent,
                scrolledUnderElevation: 0,
                title: Text(
                  'MY9',
                  style: TextStyle(color: weatherForeground, fontFamily: 'Jua'),
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: IconButton.filledTonal(
                      style: weatherButtonStyle,
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
                    onWeatherChanged: _updateStadiumWeather,
                  ),
                  const SizedBox(height: 24),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: .78,
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
                        assetPath: sectionAsset(TeamIconSection.standings),
                        tint: const Color(0xFFFFD98E),
                        onTap: () => context.push('/standings'),
                      ),
                      MainMenuButton(
                        title: '직관 리그',
                        subtitle: '친구들과 승·무·패 대결',
                        icon: Icons.groups_rounded,
                        assetPath: sectionAsset(TeamIconSection.league),
                        tint: const Color(0xFFBDE8FF),
                        onTap: () => context.push('/attendance-leagues'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
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
    required this.onWeatherChanged,
    super.key,
  });

  final int? teamId;
  final String nickname;
  final VoidCallback onSetTeam;
  final VoidCallback onOpenTeam;
  final ValueChanged<Map<String, dynamic>?> onWeatherChanged;

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
        .then((response) {
      final data = response.data!;
      widget.onWeatherChanged(
        data['stadium_weather'] as Map<String, dynamic>?,
      );
      return data;
    });
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
                  colors: [
                    const Color(0xFF10172A),
                    brand.primary.withValues(alpha: .92),
                    const Color(0xFF263755),
                    brand.secondary.withValues(alpha: .78),
                  ],
                  stops: const [0, .34, .72, 1],
                ),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: Colors.white.withValues(alpha: .7),
                  width: 1.4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: brand.primary.withValues(alpha: .22),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Stack(children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _DashboardStadiumPainter(brand),
                  ),
                ),
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
                            'MY9 BALLPARK',
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
                              _BallparkTeamPlate(
                                teamName: teamName,
                                seasonYear: summary['season_year'] as int,
                                brand: brand,
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
                        _RecordScoreboard(
                          wins: summary['wins'] as int,
                          losses: summary['losses'] as int,
                          draws: summary['draws'] as int,
                          winRate: summary['win_rate'],
                          brand: brand,
                        ),
                      ]),
                      const SizedBox(height: 20),
                      Row(children: [
                        const Text('최근 경기 전적',
                            style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                letterSpacing: .2)),
                        const Spacer(),
                        Text('LAST 5',
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
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: next == null
                            ? null
                            : () {
                                final date = next['game_date'] as String;
                                final gameId = next['game_id'] as int?;
                                final suffix = gameId == null
                                    ? 'date=$date'
                                    : 'date=$date&gameId=$gameId';
                                context.push('/schedule?$suffix');
                              },
                        child: Container(
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

String _seasonalBackdropCondition(int month) => switch (month) {
      >= 3 && <= 5 => 'spring',
      >= 6 && <= 8 => 'summer',
      >= 9 && <= 11 => 'autumn',
      _ => 'winter',
    };

class _BallparkTeamPlate extends StatelessWidget {
  const _BallparkTeamPlate({
    required this.teamName,
    required this.seasonYear,
    required this.brand,
  });

  final String teamName;
  final int seasonYear;
  final TeamBrand brand;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(9, 7, 13, 7),
      decoration: BoxDecoration(
        color: const Color(0xFF0C1426).withValues(alpha: .72),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: .22)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .18),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        CustomPaint(
          size: const Size(30, 24),
          painter: _HomePlatePainter(brand.primary),
        ),
        const SizedBox(width: 9),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            teamName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            '$seasonYear SEASON',
            style: TextStyle(
              color: AppColors.butter.withValues(alpha: .92),
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: .8,
            ),
          ),
        ]),
      ]),
    );
  }
}

class _RecordScoreboard extends StatelessWidget {
  const _RecordScoreboard({
    required this.wins,
    required this.losses,
    required this.draws,
    required this.winRate,
    required this.brand,
  });

  final int wins;
  final int losses;
  final int draws;
  final Object? winRate;
  final TeamBrand brand;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(13, 10, 13, 11),
      decoration: BoxDecoration(
        color: const Color(0xFF08101F).withValues(alpha: .82),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.butter.withValues(alpha: .34)),
        boxShadow: [
          BoxShadow(
            color: brand.primary.withValues(alpha: .24),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Row(mainAxisSize: MainAxisSize.min, children: [
          _ScoreCell(label: 'W', value: wins, color: AppColors.leaf),
          const SizedBox(width: 7),
          _ScoreCell(label: 'L', value: losses, color: AppColors.coral),
          const SizedBox(width: 7),
          _ScoreCell(label: 'D', value: draws, color: Colors.white70),
        ]),
        const SizedBox(height: 7),
        Text(
          '승률 $winRate%',
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ]),
    );
  }
}

class _ScoreCell extends StatelessWidget {
  const _ScoreCell({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(label,
          style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: .6)),
      Text('$value',
          style: const TextStyle(
              color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
    ]);
  }
}

class _HomePlatePainter extends CustomPainter {
  const _HomePlatePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final plate = Path()
      ..moveTo(size.width * .14, 0)
      ..lineTo(size.width * .86, 0)
      ..lineTo(size.width * .86, size.height * .56)
      ..lineTo(size.width * .5, size.height)
      ..lineTo(size.width * .14, size.height * .56)
      ..close();
    canvas.drawPath(
      plate,
      Paint()..color = Colors.white.withValues(alpha: .95),
    );
    canvas.drawPath(
      plate,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.drawCircle(
      Offset(size.width * .5, size.height * .36),
      5,
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant _HomePlatePainter oldDelegate) =>
      oldDelegate.color != color;
}

class _DashboardStadiumPainter extends CustomPainter {
  const _DashboardStadiumPainter(this.brand);

  final TeamBrand brand;

  @override
  void paint(Canvas canvas, Size size) {
    final night = Paint()
      ..shader = RadialGradient(
        center: const Alignment(.65, -.35),
        radius: .9,
        colors: [
          Colors.white.withValues(alpha: .22),
          Colors.transparent,
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, night);

    final glow = Paint()
      ..color = Colors.white.withValues(alpha: .26)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22);
    canvas.drawCircle(Offset(size.width * .78, size.height * .12), 58, glow);
    canvas.drawCircle(Offset(size.width * .08, size.height * .34), 38, glow);

    final stand = Paint()
      ..color = Colors.white.withValues(alpha: .13)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;
    for (var i = 0; i < 6; i++) {
      canvas.drawArc(
        Rect.fromLTWH(
          -size.width * .22,
          size.height * (.24 + i * .045),
          size.width * 1.44,
          size.height * (.42 + i * .03),
        ),
        3.38,
        -.72,
        false,
        stand,
      );
    }

    final stitch = Paint()
      ..color = Colors.white.withValues(alpha: .16)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromLTWH(size.width - 86, -28, 96, 96),
      1.65,
      1.75,
      false,
      stitch,
    );
    for (var i = 0; i < 7; i++) {
      final y = 7.0 + i * 9;
      canvas.drawLine(
        Offset(size.width - 39, y),
        Offset(size.width - 28, y + 5),
        stitch,
      );
    }

    final field = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          brand.secondary.withValues(alpha: .16),
          const Color(0xFF5BBF9F).withValues(alpha: .12),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawPath(
      Path()
        ..moveTo(0, size.height)
        ..lineTo(size.width * .5, size.height * .58)
        ..lineTo(size.width, size.height)
        ..close(),
      field,
    );
    final diamond = Paint()
      ..color = Colors.white.withValues(alpha: .12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final center = Offset(size.width * .5, size.height * .78);
    final base = Path()
      ..moveTo(center.dx, center.dy - 42)
      ..lineTo(center.dx + 46, center.dy)
      ..lineTo(center.dx, center.dy + 42)
      ..lineTo(center.dx - 46, center.dy)
      ..close();
    canvas.drawPath(base, diamond);
    canvas.drawCircle(
        center, 4, Paint()..color = Colors.white.withValues(alpha: .24));
  }

  @override
  bool shouldRepaint(covariant _DashboardStadiumPainter oldDelegate) =>
      oldDelegate.brand != brand;
}

class _RecentGameChip extends StatelessWidget {
  const _RecentGameChip({required this.game});

  final Map<String, dynamic> game;

  @override
  Widget build(BuildContext context) {
    final result = game['result'] as String?;
    final (label, accent) = switch (result) {
      'win' => ('승', AppColors.leaf),
      'loss' => ('패', AppColors.coral),
      _ => ('무', Colors.white70),
    };
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF09111F).withValues(alpha: .68),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: .4)),
      ),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 18,
          height: 3,
          decoration: BoxDecoration(
            color: accent,
            borderRadius: BorderRadius.circular(99),
          ),
        ),
        const SizedBox(height: 5),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            '${game['opponent_name']}',
            maxLines: 1,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '${game['my_score']}:${game['opponent_score']} $label',
          style: TextStyle(
            fontSize: 10,
            color: accent,
            fontWeight: FontWeight.w900,
          ),
        ),
      ]),
    );
  }
}
