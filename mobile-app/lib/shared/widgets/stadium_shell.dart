import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class StadiumAppShell extends StatefulWidget {
  const StadiumAppShell({required this.child, super.key});

  final Widget child;

  @override
  State<StadiumAppShell> createState() => _StadiumAppShellState();
}

class _StadiumAppShellState extends State<StadiumAppShell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 4200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final scale = media.textScaler.scale(1).clamp(.9, 1.22).toDouble();
    return ColoredBox(
      color: AppColors.cream,
      child: Stack(
        fit: StackFit.expand,
        children: [
          RepaintBoundary(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (_, __) => CustomPaint(
                painter: _StadiumBackdropPainter(_controller.value),
              ),
            ),
          ),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: MediaQuery(
                data: media.copyWith(textScaler: TextScaler.linear(scale)),
                child: widget.child,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class StadiumTicket extends StatelessWidget {
  const StadiumTicket({
    required this.child,
    this.padding = const EdgeInsets.all(22),
    this.color = AppColors.white,
    super.key,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _TicketPainter(color),
      child: Padding(padding: padding, child: child),
    );
  }
}

class ScoreboardPanel extends StatelessWidget {
  const ScoreboardPanel({
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.tint = AppColors.scoreboard,
    super.key,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: .08),
            blurRadius: 24,
            offset: const Offset(0, 11),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 11, 16, 0),
            child: Row(
              children: [
                for (final color in const [
                  AppColors.coral,
                  AppColors.butter,
                  AppColors.forest,
                ])
                  Container(
                    width: 7,
                    height: 7,
                    margin: const EdgeInsets.only(right: 6),
                    decoration:
                        BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
                const Spacer(),
                Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.ink.withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ],
            ),
          ),
          Padding(padding: padding, child: child),
        ],
      ),
    );
  }
}

class _StadiumBackdropPainter extends CustomPainter {
  const _StadiumBackdropPainter(this.pulse);

  final double pulse;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final gradient = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFFFFFCF7),
        Color(0xFFF3FBF5),
        Color(0xFFFFF7E8),
      ],
    ).createShader(rect);
    canvas.drawRect(rect, Paint()..shader = gradient);

    final fieldTop = size.height * .46;
    final home = Offset(size.width / 2, size.height * .98);
    final leftFoul = Offset(-size.width * .08, fieldTop);
    final rightFoul = Offset(size.width * 1.08, fieldTop);
    final outfield = Path()
      ..moveTo(home.dx, home.dy)
      ..lineTo(leftFoul.dx, leftFoul.dy)
      ..quadraticBezierTo(
          size.width / 2, size.height * .28, rightFoul.dx, rightFoul.dy)
      ..close();
    canvas.drawPath(
      outfield,
      Paint()..color = AppColors.field.withValues(alpha: .11 + pulse * .012),
    );

    final foulPaint = Paint()
      ..color = AppColors.forest.withValues(alpha: .14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawLine(home, leftFoul, foulPaint);
    canvas.drawLine(home, rightFoul, foulPaint);

    final infieldCenter = Offset(size.width / 2, size.height * .73);
    final infieldRadius = math.min(size.width * .31, 150.0);
    canvas.drawCircle(
      infieldCenter,
      infieldRadius,
      Paint()..color = const Color(0xFFD7B57A).withValues(alpha: .12),
    );
    final baseDistance = infieldRadius * .64;
    final bases = [
      Offset(infieldCenter.dx, infieldCenter.dy - baseDistance),
      Offset(infieldCenter.dx + baseDistance, infieldCenter.dy),
      home,
      Offset(infieldCenter.dx - baseDistance, infieldCenter.dy),
    ];
    final basePath = Path()..moveTo(bases.first.dx, bases.first.dy);
    for (final point in bases.skip(1)) {
      basePath.lineTo(point.dx, point.dy);
    }
    basePath.close();
    canvas.drawPath(basePath, foulPaint);

    final basePaint = Paint()
      ..color = Colors.white.withValues(alpha: .72 + pulse * .05);
    for (final point in [bases[0], bases[1], bases[3]]) {
      canvas.save();
      canvas.translate(point.dx, point.dy);
      canvas.rotate(math.pi / 4);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-6, -6, 12, 12),
          const Radius.circular(2),
        ),
        basePaint,
      );
      canvas.restore();
    }
    final plate = Path()
      ..moveTo(home.dx - 7, home.dy - 9)
      ..lineTo(home.dx + 7, home.dy - 9)
      ..lineTo(home.dx + 7, home.dy - 3)
      ..lineTo(home.dx, home.dy + 3)
      ..lineTo(home.dx - 7, home.dy - 3)
      ..close();
    canvas.drawPath(plate, basePaint);
  }

  @override
  bool shouldRepaint(_StadiumBackdropPainter oldDelegate) =>
      oldDelegate.pulse != pulse;
}

class _TicketPainter extends CustomPainter {
  const _TicketPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final body = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(26),
    );
    canvas.drawShadow(
      Path()..addRRect(body),
      AppColors.ink.withValues(alpha: .13),
      18,
      false,
    );
    canvas.drawRRect(body, Paint()..color = color);
    canvas.drawRRect(
      body,
      Paint()
        ..color = AppColors.line
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    const notchRadius = 10.0;
    final notchPaint = Paint()..color = AppColors.cream;
    for (final y in [size.height * .34, size.height * .72]) {
      canvas.drawCircle(Offset(0, y), notchRadius, notchPaint);
      canvas.drawCircle(Offset(size.width, y), notchRadius, notchPaint);
    }

    final stitchPaint = Paint()
      ..color = AppColors.coral.withValues(alpha: .34)
      ..strokeWidth = 1.4;
    for (double x = 24; x < size.width - 24; x += 9) {
      canvas.drawLine(
        Offset(x, 8),
        Offset(math.min(x + 4, size.width - 24), 8),
        stitchPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_TicketPainter oldDelegate) => oldDelegate.color != color;
}
