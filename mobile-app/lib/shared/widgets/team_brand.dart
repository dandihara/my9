import 'package:flutter/material.dart';

double responsiveIconSize(BuildContext context, double baseSize) {
  final widthScale = (MediaQuery.sizeOf(context).width / 390).clamp(.82, 1.18);
  return baseSize * widthScale;
}

class TeamBrand {
  const TeamBrand({
    required this.shortName,
    required this.primary,
    required this.secondary,
  });

  final String shortName;
  final Color primary;
  final Color secondary;

  static const fallback = TeamBrand(
    shortName: 'KBO',
    primary: Color(0xFF17223B),
    secondary: Color(0xFFA9D56B),
  );

  static const _brands = <String, TeamBrand>{
    '두산': TeamBrand(
        shortName: '두산',
        primary: Color(0xFF131230),
        secondary: Color(0xFFED1C24)),
    'LG': TeamBrand(
        shortName: 'LG',
        primary: Color(0xFFC30452),
        secondary: Color(0xFF333333)),
    '삼성': TeamBrand(
        shortName: '삼성',
        primary: Color(0xFF074CA1),
        secondary: Color(0xFFC0C0C0)),
    '키움': TeamBrand(
        shortName: '키움',
        primary: Color(0xFF820024),
        secondary: Color(0xFFD4A62A)),
    'SSG': TeamBrand(
        shortName: 'SSG',
        primary: Color(0xFFCE0E2D),
        secondary: Color(0xFFFFD6C4)),
    'KT': TeamBrand(
        shortName: 'KT',
        primary: Color(0xFF111111),
        secondary: Color(0xFFEC1C24)),
    '롯데': TeamBrand(
        shortName: '롯데',
        primary: Color(0xFF041E42),
        secondary: Color(0xFFD00F31)),
    'KIA': TeamBrand(
        shortName: 'KIA',
        primary: Color(0xFFEA0029),
        secondary: Color(0xFF06141F)),
    '한화': TeamBrand(
        shortName: '한화',
        primary: Color(0xFFF37321),
        secondary: Color(0xFF1A1A1A)),
    'NC': TeamBrand(
        shortName: 'NC',
        primary: Color(0xFF315288),
        secondary: Color(0xFFC8A977)),
  };

  static TeamBrand resolve(String teamName) {
    for (final entry in _brands.entries) {
      if (teamName.toUpperCase().contains(entry.key.toUpperCase())) {
        return entry.value;
      }
    }
    return fallback;
  }
}

class TeamBadge extends StatelessWidget {
  const TeamBadge({required this.teamName, this.size = 46, super.key});

  final String teamName;
  final double size;

  @override
  Widget build(BuildContext context) {
    final brand = TeamBrand.resolve(teamName);
    final effectiveSize = responsiveIconSize(context, size);
    return Container(
      width: effectiveSize,
      height: effectiveSize,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [brand.primary, brand.secondary],
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: brand.primary.withValues(alpha: .2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        brand.shortName.substring(0, brand.shortName.length.clamp(1, 2)),
        style: TextStyle(
          color: Colors.white,
          fontSize: effectiveSize * .25,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

String teamMascotAssetPath(String teamName) {
  final upper = teamName.toUpperCase();
  if (upper.contains('두산') || upper.contains('DOOSAN')) {
    return 'assets/team_icons/doosan.png';
  }
  if (upper.contains('LG')) return 'assets/team_icons/lg.png';
  if (upper.contains('삼성') || upper.contains('SAMSUNG')) {
    return 'assets/team_icons/samsung.png';
  }
  if (upper.contains('키움') || upper.contains('KIWOOM')) {
    return 'assets/team_icons/kiwoom.png';
  }
  if (upper.contains('SSG')) return 'assets/team_icons/ssg.png';
  if (upper.contains('KT')) return 'assets/team_icons/kt.png';
  if (upper.contains('롯데') || upper.contains('LOTTE')) {
    return 'assets/team_icons/lotte.png';
  }
  if (upper.contains('KIA')) return 'assets/team_icons/kia.png';
  if (upper.contains('한화') || upper.contains('HANWHA')) {
    return 'assets/team_icons/hanwha.png';
  }
  if (upper.contains('NC')) return 'assets/team_icons/nc.png';
  return 'assets/app_icon_neutral.png';
}

enum TeamIconSection { schedule, attendance, stats, wpa }

String? _teamAssetKey(String teamName) {
  final upper = teamName.toUpperCase();
  if (upper.contains('두산') || upper.contains('DOOSAN')) return 'doosan';
  if (upper.contains('LG')) return 'lg';
  if (upper.contains('삼성') || upper.contains('SAMSUNG')) return 'samsung';
  if (upper.contains('키움') || upper.contains('KIWOOM')) return 'kiwoom';
  if (upper.contains('SSG')) return 'ssg';
  if (upper.contains('KT')) return 'kt';
  if (upper.contains('롯데') || upper.contains('LOTTE')) return 'lotte';
  if (upper.contains('KIA')) return 'kia';
  if (upper.contains('한화') || upper.contains('HANWHA')) return 'hanwha';
  if (upper.contains('NC')) return 'nc';
  return null;
}

String teamSectionAssetPath(
  String teamName,
  TeamIconSection section, {
  bool doosanMangomTheme = false,
}) {
  final key = _teamAssetKey(teamName);
  if (key == 'doosan' && doosanMangomTheme) {
    return switch (section) {
      TeamIconSection.schedule => 'assets/mascot_schedule.png',
      TeamIconSection.attendance => 'assets/mascot_attendance.png',
      TeamIconSection.stats => 'assets/mascot_stats.png',
      TeamIconSection.wpa => 'assets/mascot_live.png',
    };
  }
  if (key == null) {
    return switch (section) {
      TeamIconSection.schedule => 'assets/mascot_schedule.png',
      TeamIconSection.attendance => 'assets/mascot_attendance.png',
      TeamIconSection.stats => 'assets/mascot_stats.png',
      TeamIconSection.wpa => 'assets/mascot_live.png',
    };
  }
  final assetKey = key == 'doosan' ? 'doosan_cheolwoong' : key;
  return 'assets/team_icons/sections/${assetKey}_${section.name}.png';
}

class TeamMascotIcon extends StatelessWidget {
  const TeamMascotIcon({required this.teamName, this.size = 54, super.key});

  final String teamName;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
        dimension: responsiveIconSize(context, size),
        child: Image.asset(
          teamMascotAssetPath(teamName),
          fit: BoxFit.contain,
          filterQuality: FilterQuality.medium,
          errorBuilder: (_, __, ___) =>
              TeamBadge(teamName: teamName, size: size),
        ),
      );
}

class TeamPlayerAvatar extends StatelessWidget {
  const TeamPlayerAvatar({required this.teamName, this.size = 76, super.key});

  final String teamName;
  final double size;

  @override
  Widget build(BuildContext context) => CustomPaint(
        size: Size.square(responsiveIconSize(context, size)),
        painter: _PlayerAvatarPainter(TeamBrand.resolve(teamName)),
      );
}

class _PlayerAvatarPainter extends CustomPainter {
  const _PlayerAvatarPainter(this.brand);

  final TeamBrand brand;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 100;
    canvas.scale(scale);
    final outline = Paint()..color = Colors.white.withValues(alpha: .95);
    final skin = Paint()..color = const Color(0xFFFFD5B6);
    final hair = Paint()..color = const Color(0xFF2C2522);
    final jersey = Paint()..color = brand.primary;
    final accent = Paint()..color = brand.secondary;
    canvas.drawCircle(const Offset(50, 50), 49, outline);
    canvas.drawPath(
        Path()
          ..moveTo(12, 100)
          ..quadraticBezierTo(16, 72, 39, 68)
          ..lineTo(61, 68)
          ..quadraticBezierTo(84, 72, 88, 100)
          ..close(),
        jersey);
    canvas.drawPath(
        Path()
          ..moveTo(42, 70)
          ..lineTo(50, 82)
          ..lineTo(58, 70)
          ..close(),
        accent);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(43, 57, 14, 18), const Radius.circular(6)),
        skin);
    canvas.drawOval(const Rect.fromLTWH(26, 19, 48, 52), skin);
    canvas.drawArc(const Rect.fromLTWH(25, 13, 50, 31), 3.12, 3.12, true, hair);
    canvas.drawPath(
        Path()
          ..moveTo(24, 30)
          ..quadraticBezierTo(50, 4, 76, 30)
          ..lineTo(69, 19)
          ..quadraticBezierTo(50, 8, 31, 19)
          ..close(),
        jersey);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(24, 28, 54, 8), const Radius.circular(5)),
        accent);
    canvas.drawCircle(const Offset(41, 45), 2.1, hair);
    canvas.drawCircle(const Offset(59, 45), 2.1, hair);
    canvas.drawArc(
        const Rect.fromLTWH(43, 48, 14, 10),
        .2,
        2.7,
        false,
        Paint()
          ..color = hair.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8);
  }

  @override
  bool shouldRepaint(covariant _PlayerAvatarPainter oldDelegate) =>
      oldDelegate.brand != brand;
}
