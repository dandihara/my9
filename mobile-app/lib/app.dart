import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/app_theme.dart';
import 'features/attendance/attendance_form_page.dart';
import 'features/attendance/attendance_page.dart';
import 'features/auth/auth_controller.dart';
import 'features/auth/login_page.dart';
import 'features/auth/signup_page.dart';
import 'features/community/attendance_leagues_page.dart';
import 'features/game/game_detail_page.dart';
import 'features/home/home_page.dart';
import 'features/schedule/schedule_page.dart';
import 'features/stats/stats_page.dart';
import 'features/team/my_team_page.dart';
import 'features/team/standings_page.dart';
import 'features/wpa/wpa_page.dart';
import 'shared/widgets/stadium_shell.dart';

CustomTransitionPage<void> _page(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 280),
    reverseTransitionDuration: const Duration(milliseconds: 220),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: Tween<double>(begin: .72, end: 1).animate(curved),
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(.08, 0),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}

final router = GoRouter(
  refreshListenable: AuthController.instance,
  redirect: (context, state) {
    final authenticated = AuthController.instance.isAuthenticated;
    final publicRoute =
        state.matchedLocation == '/login' || state.matchedLocation == '/signup';
    if (!authenticated && !publicRoute) return '/login';
    if (authenticated && publicRoute) return '/';
    return null;
  },
  routes: [
    GoRoute(
        path: '/login',
        pageBuilder: (context, state) => _page(state, const LoginPage())),
    GoRoute(
        path: '/signup',
        pageBuilder: (context, state) => _page(state, const SignupPage())),
    GoRoute(
        path: '/',
        pageBuilder: (context, state) => _page(state, const HomePage())),
    GoRoute(
        path: '/schedule',
        pageBuilder: (context, state) => _page(state, const SchedulePage())),
    GoRoute(
      path: '/games/:gameId',
      pageBuilder: (context, state) => _page(
        state,
        GameDetailPage(gameId: int.parse(state.pathParameters['gameId']!)),
      ),
    ),
    GoRoute(
        path: '/attendance',
        pageBuilder: (context, state) => _page(state, const AttendancePage())),
    GoRoute(
        path: '/attendance-leagues',
        pageBuilder: (context, state) =>
            _page(state, const AttendanceLeaguesPage())),
    GoRoute(
      path: '/attendance-leagues/:leagueId',
      pageBuilder: (context, state) => _page(
          state,
          AttendanceLeagueDetailPage(
              leagueId: int.parse(state.pathParameters['leagueId']!))),
    ),
    GoRoute(
      path: '/attendance/new',
      pageBuilder: (context, state) => _page(
        state,
        AttendanceFormPage(
          gameId: int.parse(state.uri.queryParameters['gameId']!),
        ),
      ),
    ),
    GoRoute(
        path: '/stats',
        pageBuilder: (context, state) => _page(state, const StatsPage())),
    GoRoute(
        path: '/my-team',
        pageBuilder: (context, state) => _page(state, const MyTeamPage())),
    GoRoute(
        path: '/standings',
        pageBuilder: (context, state) => _page(state, const StandingsPage())),
    GoRoute(
        path: '/wpa',
        pageBuilder: (context, state) => _page(state, const WpaPage())),
  ],
);

class My9App extends StatelessWidget {
  const My9App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'MY9',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      builder: (context, child) =>
          StadiumAppShell(child: child ?? const SizedBox.shrink()),
      routerConfig: router,
    );
  }
}
