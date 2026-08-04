import 'package:flutter/material.dart';

double responsiveIconSize(BuildContext context, double baseSize) {
  final widthScale = (MediaQuery.sizeOf(context).width / 390).clamp(.82, 1.18);
  return baseSize * widthScale;
}

class TeamBrand {
  const TeamBrand({
    required this.shortName,
    required this.initials,
    required this.primary,
    required this.secondary,
  });

  final String shortName;
  final String initials;
  final Color primary;
  final Color secondary;

  static const fallback = TeamBrand(
    shortName: 'KBO',
    initials: 'K',
    primary: Color(0xFF17223B),
    secondary: Color(0xFFA9D56B),
  );

  static const _brands = <String, TeamBrand>{
    '두산': TeamBrand(
        shortName: '두산',
        initials: 'D',
        primary: Color(0xFF131230),
        secondary: Color(0xFFED1C24)),
    'LG': TeamBrand(
        shortName: 'LG',
        initials: 'LG',
        primary: Color(0xFFC30452),
        secondary: Color(0xFF333333)),
    '삼성': TeamBrand(
        shortName: '삼성',
        initials: 'SL',
        primary: Color(0xFF074CA1),
        secondary: Color(0xFFC0C0C0)),
    '키움': TeamBrand(
        shortName: '키움',
        initials: 'KH',
        primary: Color(0xFF820024),
        secondary: Color(0xFFD4A62A)),
    'SSG': TeamBrand(
        shortName: 'SSG',
        initials: 'SS',
        primary: Color(0xFFCE0E2D),
        secondary: Color(0xFFFFD6C4)),
    'KT': TeamBrand(
        shortName: 'KT',
        initials: 'KT',
        primary: Color(0xFF111111),
        secondary: Color(0xFFEC1C24)),
    '롯데': TeamBrand(
        shortName: '롯데',
        initials: 'LT',
        primary: Color(0xFF041E42),
        secondary: Color(0xFFD00F31)),
    'KIA': TeamBrand(
        shortName: 'KIA',
        initials: 'KI',
        primary: Color(0xFFEA0029),
        secondary: Color(0xFF06141F)),
    '한화': TeamBrand(
        shortName: '한화',
        initials: 'HE',
        primary: Color(0xFFF37321),
        secondary: Color(0xFF1A1A1A)),
    'NC': TeamBrand(
        shortName: 'NC',
        initials: 'NC',
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
        brand.initials,
        style: TextStyle(
          color: Colors.white,
          fontSize: effectiveSize * (brand.initials.length > 1 ? .23 : .33),
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

String standingTeamMascotAssetPath(String teamName) {
  final upper = teamName.toUpperCase();
  if (upper.contains('두산') || upper.contains('DOOSAN'))
    return 'assets/team_mascot_standing/doosan.png';
  if (upper.contains('LG')) return 'assets/team_mascot_standing/lg.png';
  if (upper.contains('삼성') || upper.contains('SAMSUNG'))
    return 'assets/team_mascot_standing/samsung.png';
  if (upper.contains('키움') || upper.contains('KIWOOM'))
    return 'assets/team_mascot_standing/kiwoom.png';
  if (upper.contains('SSG')) return 'assets/team_mascot_standing/ssg.png';
  if (upper.contains('KT')) return 'assets/team_mascot_standing/kt.png';
  if (upper.contains('롯데') || upper.contains('LOTTE'))
    return 'assets/team_mascot_standing/lotte.png';
  if (upper.contains('KIA')) return 'assets/team_mascot_standing/kia.png';
  if (upper.contains('한화') || upper.contains('HANWHA'))
    return 'assets/team_mascot_standing/hanwha.png';
  return 'assets/team_mascot_standing/nc.png';
}

enum TeamIconSection { schedule, attendance, stats, wpa, standings, league }

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
      TeamIconSection.standings => 'assets/mascot_standings.png',
      TeamIconSection.league => 'assets/mascot_league.png',
    };
  }
  if (key == null) {
    return switch (section) {
      TeamIconSection.schedule => 'assets/mascot_schedule.png',
      TeamIconSection.attendance => 'assets/mascot_attendance.png',
      TeamIconSection.stats => 'assets/mascot_stats.png',
      TeamIconSection.wpa => 'assets/mascot_live.png',
      TeamIconSection.standings => 'assets/mascot_standings.png',
      TeamIconSection.league => 'assets/mascot_league.png',
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
  Widget build(BuildContext context) {
    final effectiveSize = responsiveIconSize(context, size);
    final upper = teamName.toUpperCase();
    final cropWhiteFrame = upper.contains('NC') ||
        upper.contains('키움') ||
        upper.contains('KIWOOM');
    return ClipRRect(
      borderRadius: BorderRadius.circular(effectiveSize * .2),
      child: SizedBox.square(
        dimension: effectiveSize,
        child: Transform.scale(
          scale: cropWhiteFrame ? 1.16 : 1,
          child: Image.asset(
            teamMascotAssetPath(teamName),
            fit: BoxFit.cover,
            filterQuality: FilterQuality.medium,
            errorBuilder: (_, __, ___) =>
                TeamBadge(teamName: teamName, size: size),
          ),
        ),
      ),
    );
  }
}

class TeamSectionIcon extends StatelessWidget {
  const TeamSectionIcon({
    required this.teamName,
    required this.section,
    this.size = 104,
    super.key,
  });

  final String teamName;
  final TeamIconSection section;
  final double size;

  @override
  Widget build(BuildContext context) => CustomPaint(
        size: Size.square(responsiveIconSize(context, size)),
        painter: _TeamMascotPainter(
          brand: TeamBrand.resolve(teamName),
          section: section,
        ),
      );
}

class _TeamMascotPainter extends CustomPainter {
  const _TeamMascotPainter({
    required this.brand,
    required this.section,
  });

  final TeamBrand brand;
  final TeamIconSection? section;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 120;
    canvas
      ..save()
      ..scale(scale);
    final shadow = Paint()
      ..color = Colors.black.withValues(alpha: .12)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawOval(const Rect.fromLTWH(20, 98, 82, 12), shadow);

    final ball = Paint()..color = const Color(0xFFFFF7EA);
    final outline = Paint()
      ..color = brand.primary.withValues(alpha: .75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(const Offset(60, 61), 43, ball);
    canvas.drawCircle(const Offset(60, 61), 43, outline);

    final stitch = Paint()
      ..color = brand.secondary.withValues(alpha: .78)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
        const Rect.fromLTWH(21, 30, 25, 62), -1.1, 2.2, false, stitch);
    canvas.drawArc(
        const Rect.fromLTWH(74, 30, 25, 62), 2.05, 2.2, false, stitch);
    for (var i = 0; i < 7; i++) {
      final y = 38 + i * 7.2;
      canvas.drawLine(Offset(34, y), Offset(42, y + 3), stitch);
      canvas.drawLine(Offset(86, y), Offset(78, y + 3), stitch);
    }

    final cap = Paint()..color = brand.primary;
    canvas.drawPath(
      Path()
        ..moveTo(31, 40)
        ..quadraticBezierTo(60, 13, 89, 40)
        ..lineTo(82, 47)
        ..quadraticBezierTo(60, 35, 38, 47)
        ..close(),
      cap,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(34, 41, 52, 9), const Radius.circular(9)),
      Paint()..color = brand.secondary.withValues(alpha: .9),
    );
    _drawCenteredText(canvas, brand.initials, const Offset(60, 35), 13,
        Colors.white, FontWeight.w900);

    final eye = Paint()..color = const Color(0xFF17223B);
    canvas.drawCircle(const Offset(48, 61), 3.2, eye);
    canvas.drawCircle(const Offset(72, 61), 3.2, eye);
    canvas.drawArc(
      const Rect.fromLTWH(52, 65, 16, 10),
      .15,
      2.85,
      false,
      Paint()
        ..color = eye.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(const Offset(42, 69), 4.2,
        Paint()..color = const Color(0xFFFF9E9B).withValues(alpha: .55));
    canvas.drawCircle(const Offset(78, 69), 4.2,
        Paint()..color = const Color(0xFFFF9E9B).withValues(alpha: .55));

    _paintSectionProp(canvas);
    canvas.restore();
  }

  void _paintSectionProp(Canvas canvas) {
    if (section == null) return;
    final propPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final line = Paint()
      ..color = brand.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    switch (section!) {
      case TeamIconSection.schedule:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
              const Rect.fromLTWH(76, 60, 30, 28), const Radius.circular(7)),
          propPaint,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
              const Rect.fromLTWH(76, 60, 30, 28), const Radius.circular(7)),
          line,
        );
        canvas.drawLine(const Offset(82, 70), const Offset(100, 70), line);
        canvas.drawLine(const Offset(82, 78), const Offset(96, 78), line);
        break;
      case TeamIconSection.attendance:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
              const Rect.fromLTWH(78, 59, 28, 32), const Radius.circular(5)),
          propPaint,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
              const Rect.fromLTWH(78, 59, 28, 32), const Radius.circular(5)),
          line,
        );
        canvas.drawLine(const Offset(84, 74), const Offset(90, 80), line);
        canvas.drawLine(const Offset(90, 80), const Offset(100, 66), line);
        break;
      case TeamIconSection.stats:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
              const Rect.fromLTWH(75, 59, 33, 31), const Radius.circular(5)),
          propPaint,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
              const Rect.fromLTWH(75, 59, 33, 31), const Radius.circular(5)),
          line,
        );
        for (final bar in const [
          Rect.fromLTWH(82, 76, 4, 8),
          Rect.fromLTWH(91, 69, 4, 15),
          Rect.fromLTWH(100, 63, 4, 21),
        ]) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(bar, const Radius.circular(2)),
            Paint()..color = brand.secondary,
          );
        }
        break;
      case TeamIconSection.wpa:
        canvas.drawLine(const Offset(82, 84), const Offset(100, 66), line);
        canvas.drawCircle(const Offset(60, 60), 0, line);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
              const Rect.fromLTWH(79, 61, 29, 25), const Radius.circular(6)),
          propPaint..color = Colors.white.withValues(alpha: .9),
        );
        canvas.drawPath(
          Path()
            ..moveTo(84, 79)
            ..lineTo(91, 72)
            ..lineTo(96, 75)
            ..lineTo(103, 66),
          line,
        );
        break;
      case TeamIconSection.standings:
      case TeamIconSection.league:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
              const Rect.fromLTWH(77, 61, 31, 28), const Radius.circular(6)),
          propPaint,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
              const Rect.fromLTWH(77, 61, 31, 28), const Radius.circular(6)),
          line,
        );
        canvas.drawLine(const Offset(84, 83), const Offset(84, 71), line);
        canvas.drawLine(const Offset(92, 83), const Offset(92, 66), line);
        canvas.drawLine(const Offset(100, 83), const Offset(100, 75), line);
        break;
    }
    canvas.drawCircle(
        const Offset(31, 76), 8, Paint()..color = brand.secondary);
    canvas.drawCircle(const Offset(89, 82), 8, Paint()..color = brand.primary);
  }

  void _drawCenteredText(
    Canvas canvas,
    String text,
    Offset center,
    double fontSize,
    Color color,
    FontWeight weight,
  ) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: weight,
          fontFamily: 'Pretendard',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
        canvas, center - Offset(painter.width / 2, painter.height / 2));
  }

  @override
  bool shouldRepaint(covariant _TeamMascotPainter oldDelegate) =>
      oldDelegate.brand != brand || oldDelegate.section != section;
}

class TeamPlayerAvatar extends StatelessWidget {
  const TeamPlayerAvatar({required this.teamName, this.size = 76, super.key});

  final String teamName;
  final double size;

  @override
  Widget build(BuildContext context) {
    final effectiveSize = responsiveIconSize(context, size);
    final brand = TeamBrand.resolve(teamName);
    return SizedBox.square(
      dimension: effectiveSize,
      child: CustomPaint(
        painter: _PlayerBallPainter(brand),
      ),
    );
  }
}

class _PlayerBallPainter extends CustomPainter {
  const _PlayerBallPainter(this.brand);

  final TeamBrand brand;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 100;
    canvas
      ..save()
      ..scale(scale);

    canvas.drawOval(
      const Rect.fromLTWH(21, 84, 58, 9),
      Paint()
        ..color = const Color(0xFF10213A).withValues(alpha: .14)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );

    final faceRect = Rect.fromCircle(center: const Offset(50, 57), radius: 35);
    canvas.drawCircle(
      const Offset(50, 57),
      35,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-.32, -.38),
          radius: .92,
          colors: [Color(0xFFFFFFFF), Color(0xFFFFF8EC), Color(0xFFE9DED0)],
          stops: [0, .7, 1],
        ).createShader(faceRect),
    );

    final seam = Paint()
      ..color = const Color(0xFFE74B42)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.55
      ..strokeCap = StrokeCap.round;
    final leftSeam = Path()
      ..moveTo(24, 35)
      ..cubicTo(34, 43, 34, 69, 25, 79);
    final rightSeam = Path()
      ..moveTo(76, 35)
      ..cubicTo(66, 43, 66, 69, 75, 79);
    canvas
      ..drawPath(leftSeam, seam)
      ..drawPath(rightSeam, seam);
    for (var i = 0; i < 6; i++) {
      final y = 41 + i * 6.4;
      canvas.drawLine(Offset(28.5, y), Offset(33.5, y - 2.2), seam);
      canvas.drawLine(Offset(71.5, y), Offset(66.5, y - 2.2), seam);
    }

    final capShadow = Paint()..color = Colors.black.withValues(alpha: .14);
    canvas.drawPath(
      Path()
        ..moveTo(23, 36)
        ..quadraticBezierTo(28, 12, 52, 10)
        ..quadraticBezierTo(74, 12, 79, 35)
        ..quadraticBezierTo(51, 29, 23, 36)
        ..close(),
      capShadow,
    );
    canvas.drawPath(
      Path()
        ..moveTo(22, 34)
        ..quadraticBezierTo(28, 9, 51, 8)
        ..quadraticBezierTo(74, 10, 79, 33)
        ..quadraticBezierTo(52, 27, 22, 34)
        ..close(),
      Paint()..color = brand.primary,
    );
    canvas.drawPath(
      Path()
        ..moveTo(22, 33)
        ..quadraticBezierTo(52, 26, 85, 35)
        ..quadraticBezierTo(71, 41, 54, 35)
        ..quadraticBezierTo(36, 30, 22, 33)
        ..close(),
      Paint()..color = brand.secondary,
    );

    final mark = TextPainter(
      text: TextSpan(
        text: brand.initials,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          height: 1,
          fontWeight: FontWeight.w900,
          fontFamily: 'Pretendard',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    mark.paint(canvas, Offset(51 - mark.width / 2, 15));

    final eye = Paint()..color = const Color(0xFF17223B);
    canvas
      ..drawOval(const Rect.fromLTWH(39, 50, 4.2, 5.6), eye)
      ..drawOval(const Rect.fromLTWH(57, 50, 4.2, 5.6), eye)
      ..drawCircle(const Offset(36, 60), 3.6,
          Paint()..color = const Color(0xFFFFA7A3).withValues(alpha: .55))
      ..drawCircle(const Offset(64, 60), 3.6,
          Paint()..color = const Color(0xFFFFA7A3).withValues(alpha: .55));
    canvas.drawArc(
      const Rect.fromLTWH(44, 55, 12, 8),
      .15,
      2.84,
      false,
      Paint()
        ..color = eye.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _PlayerBallPainter oldDelegate) =>
      oldDelegate.brand != brand;
}
