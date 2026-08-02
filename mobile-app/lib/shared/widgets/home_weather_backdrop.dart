import 'dart:math' as math;

import 'package:flutter/material.dart';

class HomeWeatherBackdrop extends StatefulWidget {
  const HomeWeatherBackdrop({
    required this.condition,
    super.key,
  });

  final String condition;

  @override
  State<HomeWeatherBackdrop> createState() => _HomeWeatherBackdropState();
}

class _HomeWeatherBackdropState extends State<HomeWeatherBackdrop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 8),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 700),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: SizedBox.expand(
          key: ValueKey(widget.condition),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: _gradient(widget.condition),
              ),
            ),
            child: AnimatedBuilder(
              animation: _controller,
              builder: (_, __) => CustomPaint(
                painter: _WeatherPainter(
                  condition: widget.condition,
                  progress: _controller.value,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Color> _gradient(String condition) => switch (condition) {
        'rain' => const [
            Color(0xFF9FC5D2),
            Color(0xFFD8E9EA),
            Color(0xFFF8F5EA),
          ],
        'cloudy' => const [
            Color(0xFFC8D8E4),
            Color(0xFFE8EFEF),
            Color(0xFFFFF8EA),
          ],
        'snow' => const [
            Color(0xFFDDEAFF),
            Color(0xFFF4F4FF),
            Color(0xFFFFFBF2),
          ],
        'night' => const [
            Color(0xFF283A62),
            Color(0xFF778CB0),
            Color(0xFFE9E8F3),
          ],
        'spring' => const [
            Color(0xFFFFDFE7),
            Color(0xFFEAF6DD),
            Color(0xFFFFF9F2),
          ],
        'summer' => const [
            Color(0xFFCDEEFF),
            Color(0xFFDDF4CE),
            Color(0xFFFFF9F2),
          ],
        'autumn' => const [
            Color(0xFFFFD39B),
            Color(0xFFF5E2BD),
            Color(0xFFFFF9F2),
          ],
        'winter' => const [
            Color(0xFFDDEAFF),
            Color(0xFFF2F5F8),
            Color(0xFFFFFBF4),
          ],
        _ => const [
            Color(0xFFFFE7A8),
            Color(0xFFE7F6EE),
            Color(0xFFFFF9F2),
          ],
      };
}

class _WeatherPainter extends CustomPainter {
  const _WeatherPainter({
    required this.condition,
    required this.progress,
  });

  final String condition;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    _paintBallparkBase(canvas, size);
    switch (condition) {
      case 'rain':
        _paintRain(canvas, size);
        return;
      case 'cloudy':
        _paintClouds(canvas, size, .22);
        return;
      case 'snow':
        _paintSnow(canvas, size);
        return;
      case 'night':
        _paintNight(canvas, size);
        return;
      case 'spring':
        _paintSeasonParticles(canvas, size, const Color(0xFFFF9FB2), true);
        return;
      case 'autumn':
        _paintSeasonParticles(canvas, size, const Color(0xFFE38B4A), false);
        return;
      case 'winter':
        _paintSnow(canvas, size);
        return;
      case 'summer':
        _paintSun(canvas, size);
        return;
      default:
        _paintSun(canvas, size);
        return;
    }
  }

  void _paintBallparkBase(Canvas canvas, Size size) {
    final standPaint = Paint()
      ..color = const Color(0xFF17223B).withValues(alpha: .08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    for (var i = 0; i < 7; i++) {
      final rect = Rect.fromLTWH(
        -size.width * (.28 + i * .03),
        size.height * (.16 + i * .028),
        size.width * (1.56 + i * .06),
        size.height * (.52 + i * .025),
      );
      canvas.drawArc(rect, 3.34, -.64, false, standPaint);
    }

    final lightPaint = Paint()
      ..color = Colors.white.withValues(alpha: .42)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
    for (final light in [
      Offset(size.width * .12, size.height * .18),
      Offset(size.width * .88, size.height * .2),
    ]) {
      canvas.drawCircle(light, 42, lightPaint);
      canvas.drawLine(
        light,
        Offset(size.width * .5, size.height * .52),
        Paint()
          ..color = Colors.white.withValues(alpha: .08)
          ..strokeWidth = 34
          ..strokeCap = StrokeCap.round,
      );
    }

    final fieldTop = size.height * .72;
    canvas.drawPath(
      Path()
        ..moveTo(0, size.height)
        ..lineTo(size.width * .38, fieldTop)
        ..lineTo(size.width * .62, fieldTop)
        ..lineTo(size.width, size.height)
        ..close(),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x55BCE8D1), Color(0x66C79B65)],
        ).createShader(
            Rect.fromLTWH(0, fieldTop, size.width, size.height - fieldTop)),
    );
    canvas.drawPath(
      Path()
        ..moveTo(size.width * .5, fieldTop + 18)
        ..lineTo(size.width * .12, size.height)
        ..moveTo(size.width * .5, fieldTop + 18)
        ..lineTo(size.width * .88, size.height),
      Paint()
        ..color = Colors.white.withValues(alpha: .24)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  void _paintSun(Canvas canvas, Size size) {
    final center = Offset(size.width * .82, size.height * .1);
    final pulse = 1 + math.sin(progress * math.pi * 2) * .04;
    canvas.drawCircle(
      center,
      58 * pulse,
      Paint()..color = const Color(0xFFFFD978).withValues(alpha: .22),
    );
    canvas.drawCircle(
      center,
      35 * pulse,
      Paint()..color = const Color(0xFFFFC957).withValues(alpha: .34),
    );
  }

  void _paintClouds(Canvas canvas, Size size, double opacity) {
    final drift = math.sin(progress * math.pi * 2) * 12;
    final paint = Paint()..color = Colors.white.withValues(alpha: opacity);
    for (final origin in [
      Offset(size.width * .08 + drift, size.height * .1),
      Offset(size.width * .62 - drift, size.height * .25),
    ]) {
      canvas.drawCircle(origin, 36, paint);
      canvas.drawCircle(origin + const Offset(38, 4), 48, paint);
      canvas.drawCircle(origin + const Offset(82, 11), 31, paint);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(origin.dx - 10, origin.dy + 8, 122, 42),
          const Radius.circular(30),
        ),
        paint,
      );
    }
  }

  void _paintRain(Canvas canvas, Size size) {
    _paintClouds(canvas, size, .2);
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: .28)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (var row = 0; row < 12; row++) {
      for (var column = 0; column < 7; column++) {
        final x = column * size.width / 6 + (row.isEven ? 14 : -8);
        final y = ((row * 83 + progress * 120) % (size.height + 60)) - 30;
        canvas.drawLine(Offset(x, y), Offset(x - 8, y + 18), paint);
      }
    }
  }

  void _paintSnow(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: .7);
    for (var index = 0; index < 45; index++) {
      final x = ((index * 71.0) % size.width);
      final y =
          ((index * 97.0 + progress * (45 + index % 4 * 12)) % size.height);
      canvas.drawCircle(Offset(x, y), 2 + index % 3.0, paint);
    }
  }

  void _paintNight(Canvas canvas, Size size) {
    final moon = Offset(size.width * .82, size.height * .1);
    canvas.drawCircle(
      moon,
      34,
      Paint()..color = const Color(0xFFFFF1B8).withValues(alpha: .84),
    );
    final starPaint = Paint()..color = Colors.white.withValues(alpha: .62);
    for (var index = 0; index < 24; index++) {
      final twinkle =
          .45 + .35 * math.sin(progress * math.pi * 2 + index * .8).abs();
      starPaint.color = Colors.white.withValues(alpha: twinkle);
      canvas.drawCircle(
        Offset(
          (index * 83.0) % size.width,
          38 + (index * 47.0) % (size.height * .38),
        ),
        1 + index % 2.0,
        starPaint,
      );
    }
  }

  void _paintSeasonParticles(
    Canvas canvas,
    Size size,
    Color color,
    bool petals,
  ) {
    final paint = Paint()..color = color.withValues(alpha: .3);
    for (var index = 0; index < 24; index++) {
      final x = (index * 79.0 + math.sin(progress * math.pi * 2 + index) * 16) %
          size.width;
      final y = (index * 103.0 + progress * (22 + index % 3 * 8)) % size.height;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(progress * math.pi * 2 + index);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset.zero,
          width: petals ? 8 : 10,
          height: petals ? 5 : 7,
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_WeatherPainter oldDelegate) =>
      oldDelegate.condition != condition || oldDelegate.progress != progress;
}
