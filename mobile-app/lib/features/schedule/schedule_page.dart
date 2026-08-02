import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/models/game.dart';
import '../../core/models/attendance.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_error.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/async_state_view.dart';
import '../../shared/widgets/team_brand.dart';
import '../auth/auth_controller.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({this.initialDate, this.highlightGameId, super.key});

  final DateTime? initialDate;
  final int? highlightGameId;

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  final Map<String, List<GameModel>> _games = {};
  final Map<int, String> _attendanceResults = {};
  bool _loading = true;
  String? _error;
  int _loadRequestId = 0;

  String _key(DateTime day) => DateFormat('yyyy-MM-dd').format(day);

  @override
  void initState() {
    super.initState();
    if (widget.initialDate != null) {
      _focusedDay = widget.initialDate!;
      _selectedDay = widget.initialDate!;
    }
    _loadMonth(_focusedDay);
    _loadAttendances();
  }

  Future<void> _loadAttendances() async {
    try {
      final response =
          await ApiClient.instance.dio.get<List<dynamic>>('/v1/attendances');
      final results = <int, String>{};
      for (final item in response.data!) {
        final record = AttendanceModel.fromJson(item as Map<String, dynamic>);
        if (record.resultForMyTeam != null) {
          results[record.gameId] = record.resultForMyTeam!;
        }
      }
      if (mounted) {
        setState(() {
          _attendanceResults
            ..clear()
            ..addAll(results);
        });
      }
    } on DioException {
      // Schedule data remains usable even if personal records fail to load.
    }
  }

  Future<void> _loadMonth(DateTime day) async {
    final requestId = ++_loadRequestId;
    setState(() {
      _loading = true;
      _error = null;
    });
    final first = DateTime(day.year, day.month, 1);
    final last = DateTime(day.year, day.month + 1, 0);
    try {
      final response = await ApiClient.instance.dio.get<List<dynamic>>(
        '/v1/games',
        queryParameters: {'from_date': _key(first), 'to_date': _key(last)},
      );
      final grouped = <String, List<GameModel>>{};
      for (final item in response.data!) {
        final game = GameModel.fromJson(item as Map<String, dynamic>);
        grouped.putIfAbsent(_key(game.gameDate), () => []).add(game);
      }
      if (mounted && requestId == _loadRequestId) {
        setState(() {
          _games.removeWhere((key, _) {
            final date = DateTime.parse(key);
            return date.year == day.year && date.month == day.month;
          });
          _games.addAll(grouped);
        });
      }
    } on DioException catch (error) {
      if (mounted && requestId == _loadRequestId) {
        setState(() => _error = apiErrorMessage(error));
      }
    } finally {
      if (mounted && requestId == _loadRequestId) {
        setState(() => _loading = false);
      }
    }
  }

  String _status(String value) => switch (value) {
        'completed' => '경기 종료',
        'in_progress' => 'LIVE',
        'cancelled' => '경기 취소',
        _ => '경기 예정',
      };

  Color _statusColor(String value) => switch (value) {
        'completed' => const Color(0xFFDDEBF5),
        'in_progress' => const Color(0xFFFFB6A8),
        'cancelled' => const Color(0xFFFFDCD6),
        _ => const Color(0xFFE3F4C7),
      };

  @override
  Widget build(BuildContext context) {
    final selectedGames = List<GameModel>.of(
      _games[_key(_selectedDay)] ?? const <GameModel>[],
    );
    final myTeamName = AuthController.instance.myTeamName;
    if (myTeamName != null) {
      bool isMyTeamGame(GameModel game) =>
          game.awayTeamName == myTeamName || game.homeTeamName == myTeamName;
      selectedGames.sort((a, b) {
        final aPriority = isMyTeamGame(a) ? 0 : 1;
        final bPriority = isMyTeamGame(b) ? 0 : 1;
        return aPriority.compareTo(bPriority);
      });
    }
    return Scaffold(
      appBar: AppBar(title: const Text('경기 일정')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final landscape = constraints.maxWidth > constraints.maxHeight;
          final calendarRowHeight = landscape ? 36.0 : 54.0;
          final daysOfWeekHeight = landscape ? 22.0 : 28.0;
          final calendarPadding = landscape
              ? const EdgeInsets.fromLTRB(8, 6, 8, 8)
              : const EdgeInsets.fromLTRB(8, 8, 8, 12);
          final calendarCard = Card(
            child: Padding(
              padding: calendarPadding,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TableCalendar<GameModel>(
                    firstDay: DateTime.utc(2020, 1, 1),
                    lastDay: DateTime.utc(2030, 12, 31),
                    focusedDay: _focusedDay,
                    rowHeight: calendarRowHeight,
                    daysOfWeekHeight: daysOfWeekHeight,
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    eventLoader: (day) => _games[_key(day)] ?? const [],
                    calendarBuilders: CalendarBuilders<GameModel>(
                      markerBuilder: (context, day, events) {
                        if (events.isEmpty) return null;
                        final results = events
                            .map((game) => _attendanceResults[game.id])
                            .whereType<String>()
                            .toSet()
                            .toList();
                        if (results.isEmpty) {
                          return const Positioned(
                            bottom: 4,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: AppColors.coral,
                                shape: BoxShape.circle,
                              ),
                              child: SizedBox(width: 5, height: 5),
                            ),
                          );
                        }
                        return Positioned(
                          bottom: 0,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: results
                                .take(2)
                                .map((result) => _AttendanceResultMarker(
                                      result: result,
                                    ))
                                .toList(),
                          ),
                        );
                      },
                    ),
                    headerStyle: const HeaderStyle(
                      titleCentered: true,
                      formatButtonVisible: false,
                      titleTextStyle: TextStyle(
                          color: AppColors.ink,
                          fontSize: 19,
                          fontWeight: FontWeight.w900),
                      leftChevronIcon: Icon(Icons.chevron_left_rounded,
                          color: AppColors.ink),
                      rightChevronIcon: Icon(Icons.chevron_right_rounded,
                          color: AppColors.ink),
                    ),
                    calendarStyle: const CalendarStyle(
                      todayDecoration: BoxDecoration(
                          color: AppColors.butter, shape: BoxShape.circle),
                      todayTextStyle: TextStyle(
                          color: AppColors.ink, fontWeight: FontWeight.w800),
                      selectedDecoration: BoxDecoration(
                          color: AppColors.ink, shape: BoxShape.circle),
                      markerDecoration: BoxDecoration(
                          color: AppColors.coral, shape: BoxShape.circle),
                      markerSize: 5,
                      markersMaxCount: 1,
                    ),
                    onDaySelected: (selected, _) {
                      final monthChanged = selected.year != _focusedDay.year ||
                          selected.month != _focusedDay.month;
                      setState(() {
                        _selectedDay = selected;
                        _focusedDay = selected;
                      });
                      if (monthChanged) _loadMonth(selected);
                    },
                    onPageChanged: (focused) {
                      setState(() {
                        _focusedDay = focused;
                        if (_selectedDay.year != focused.year ||
                            _selectedDay.month != focused.month) {
                          _selectedDay =
                              DateTime(focused.year, focused.month, 1);
                        }
                      });
                      _loadMonth(focused);
                    },
                  ),
                  SizedBox(height: landscape ? 5 : 8),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _CalendarLegend(label: '승', color: AppColors.forest),
                      SizedBox(width: 12),
                      _CalendarLegend(label: '무', color: AppColors.muted),
                      SizedBox(width: 12),
                      _CalendarLegend(label: '패', color: AppColors.coral),
                    ],
                  ),
                ],
              ),
            ),
          );
          final selectedHeader = Padding(
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 10),
            child: Row(
              children: [
                Text(DateFormat('M월 d일').format(_selectedDay),
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(width: 8),
                Text('${selectedGames.length}경기',
                    style: const TextStyle(
                        color: AppColors.coral, fontWeight: FontWeight.w900)),
              ],
            ),
          );
          final gameList = _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? AppErrorView(
                      message: _error!,
                      onRetry: () => _loadMonth(_focusedDay),
                    )
                  : selectedGames.isEmpty
                      ? const _EmptySchedule()
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(14, 0, 14, 28),
                          itemCount: selectedGames.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) => _GameCard(
                            game: selectedGames[index],
                            highlighted: selectedGames[index].id ==
                                widget.highlightGameId,
                            status: _status(selectedGames[index].status),
                            statusColor:
                                _statusColor(selectedGames[index].status),
                            onAttendanceSaved: _loadAttendances,
                          ),
                        );

          if (landscape) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 11,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 8, 12),
                    child: calendarCard,
                  ),
                ),
                Expanded(
                  flex: 9,
                  child: Column(
                    children: [
                      selectedHeader,
                      Expanded(child: gameList),
                    ],
                  ),
                ),
              ],
            );
          }
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                child: calendarCard,
              ),
              selectedHeader,
              Expanded(child: gameList),
            ],
          );
        },
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  const _GameCard({
    required this.game,
    required this.highlighted,
    required this.status,
    required this.statusColor,
    required this.onAttendanceSaved,
  });

  final GameModel game;
  final bool highlighted;
  final String status;
  final Color statusColor;
  final Future<void> Function() onAttendanceSaved;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: highlighted ? AppColors.leaf.withValues(alpha: .32) : null,
      child: InkWell(
        onTap: () => context.push('/games/${game.id}'),
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(99)),
                    child: Text(status,
                        style: const TextStyle(
                            color: AppColors.ink,
                            fontSize: 12,
                            fontWeight: FontWeight.w900)),
                  ),
                  const Spacer(),
                  const Icon(Icons.location_on_outlined,
                      size: 16, color: AppColors.muted),
                  const SizedBox(width: 4),
                  Text(game.stadiumName ?? '-',
                      style: const TextStyle(fontSize: 12)),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                      child: _TeamName(name: game.awayTeamName, label: 'AWAY')),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Column(
                      children: [
                        Text(game.scoreText,
                            style: const TextStyle(
                                color: AppColors.ink,
                                fontSize: 25,
                                fontWeight: FontWeight.w900)),
                        const SizedBox(height: 3),
                        Text(game.gameTime?.substring(0, 5) ?? '-',
                            style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                  Expanded(
                      child: _TeamName(name: game.homeTeamName, label: 'HOME')),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 11),
              Row(
                children: [
                  TextButton.icon(
                      onPressed: () => context.push('/games/${game.id}'),
                      icon: const Icon(Icons.query_stats_rounded, size: 18),
                      label: const Text('선수 기록')),
                  if (_ticketUrl(game.homeTeamName) != null)
                    TextButton.icon(
                      onPressed: () => _openTicket(context),
                      icon: const Icon(Icons.confirmation_number_rounded,
                          size: 18),
                      label: const Text('예매'),
                    ),
                  const Spacer(),
                  FilledButton.tonalIcon(
                      onPressed: () async {
                        final saved = await context.push<bool>(
                          '/attendance/new?gameId=${game.id}',
                        );
                        if (saved == true && context.mounted) {
                          await onAttendanceSaved();
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('직관 기록을 저장했어요.')),
                          );
                        }
                      },
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('직관 기록')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openTicket(BuildContext context) async {
    final url = _ticketUrl(game.homeTeamName);
    if (url == null) return;
    final opened = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('예매 페이지를 열지 못했어요.')),
      );
    }
  }
}

String? _ticketUrl(String homeTeamName) {
  final upper = homeTeamName.toUpperCase();
  if (upper.contains('두산') || upper.contains('DOOSAN')) {
    return 'https://ticket.interpark.com/Contents/Sports/GoodsInfo?SportsCode=07001&TeamCode=PB004';
  }
  if (upper.contains('키움') || upper.contains('KIWOOM')) {
    return 'https://ticket.interpark.com/Contents/Sports/GoodsInfo?SportsCode=07001&TeamCode=PB003';
  }
  if (upper.contains('SSG')) return 'https://www.ssglanders.com/ticket/ticket';
  if (upper.contains('롯데') || upper.contains('LOTTE')) {
    return 'https://www.giantsclub.com/html/?pcode=257';
  }
  if (upper.contains('NC')) return 'https://www.ncdinos.com/ticket/guide';
  return 'https://www.ticketlink.co.kr/sports/baseball';
}

class _TeamName extends StatelessWidget {
  const _TeamName({required this.name, required this.label});
  final String name;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TeamMascotIcon(teamName: name, size: 64),
        const SizedBox(height: 8),
        Text(label,
            style: const TextStyle(
                color: AppColors.muted,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2)),
        const SizedBox(height: 4),
        Text(name,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge),
      ],
    );
  }
}

class _AttendanceResultMarker extends StatelessWidget {
  const _AttendanceResultMarker({required this.result});

  final String result;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (result) {
      'win' => ('승', AppColors.forest),
      'loss' => ('패', AppColors.coral),
      _ => ('무', AppColors.muted),
    };
    return Container(
      constraints: const BoxConstraints(minWidth: 22, minHeight: 20),
      margin: const EdgeInsets.symmetric(horizontal: 2),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
    );
  }
}

class _CalendarLegend extends StatelessWidget {
  const _CalendarLegend({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 18,
            height: 18,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label == '승'
                ? '승리'
                : label == '무'
                    ? '무승부'
                    : '패배',
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      );
}

class _EmptySchedule extends StatelessWidget {
  const _EmptySchedule();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              padding: const EdgeInsets.all(18),
              decoration: const BoxDecoration(
                  color: Color(0xFFE1F5EC), shape: BoxShape.circle),
              child: const Icon(Icons.event_busy_rounded,
                  size: 34, color: AppColors.forest)),
          const SizedBox(height: 13),
          Text('경기가 없는 날이에요', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          const Text('다른 날짜를 선택해 보세요.'),
        ],
      ),
    );
  }
}
