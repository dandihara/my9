import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'team_brand.dart';

class MainMenuButton extends StatefulWidget {
  const MainMenuButton({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.tint,
    required this.onTap,
    this.assetPath,
    super.key,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color tint;
  final VoidCallback onTap;
  final String? assetPath;

  @override
  State<MainMenuButton> createState() => _MainMenuButtonState();
}

class _MainMenuButtonState extends State<MainMenuButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _floatController;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 500;
    final iconScale = responsiveIconSize(context, 1)
        .clamp(.88, compact ? .96 : 1.08)
        .toDouble();
    final cardPadding = compact ? 10.0 : 14.0;
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeOutCubic,
      tween: Tween(begin: 0, end: 1),
      builder: (context, entrance, child) => Opacity(
        opacity: entrance,
        child: Transform.translate(
          offset: Offset(0, 18 * (1 - entrance)),
          child: child,
        ),
      ),
      child: AnimatedScale(
        scale: _pressed ? .965 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  widget.tint.withValues(alpha: .58),
                  Colors.white.withValues(alpha: .82),
                  AppColors.white,
                ],
                stops: const [0, .58, 1],
              ),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: Colors.white.withValues(alpha: .72)),
            ),
            child: InkWell(
              onTap: widget.onTap,
              onHighlightChanged: (value) => setState(() => _pressed = value),
              borderRadius: BorderRadius.circular(26),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _MenuStadiumPainter(widget.tint),
                    ),
                  ),
                  Positioned(
                    right: -9,
                    top: 46,
                    child: Container(
                      width: 19,
                      height: 19,
                      decoration: const BoxDecoration(
                        color: AppColors.cream,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Positioned(
                    left: -9,
                    bottom: 46,
                    child: Container(
                      width: 19,
                      height: 19,
                      decoration: const BoxDecoration(
                        color: AppColors.cream,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(cardPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: compact ? 86 : 102,
                          width: double.infinity,
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: AnimatedBuilder(
                              animation: _floatController,
                              builder: (_, child) => Transform.translate(
                                offset: Offset(0, -4 * _floatController.value),
                                child: child,
                              ),
                              child: _buildHeroIcon(iconScale, compact),
                            ),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(12, 10, 10, 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: .82),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: AppColors.line.withValues(alpha: .72),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      widget.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(fontSize: 19),
                                    ),
                                  ],
                                ),
                              ),
                              AnimatedSlide(
                                offset: _pressed
                                    ? const Offset(.12, 0)
                                    : Offset.zero,
                                duration: const Duration(milliseconds: 180),
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            AppColors.ink.withValues(alpha: .1),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.arrow_forward_rounded,
                                    color: AppColors.ink,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroIcon(double iconScale, bool compact) {
    if (widget.assetPath != null) {
      final dimension = (compact ? 98 : 104) * iconScale;
      return SizedBox.square(
        dimension: dimension,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Image.asset(
            widget.assetPath!,
            width: dimension,
            height: dimension,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.high,
          ),
        ),
      );
    }
    return Container(
      width: 58 * iconScale,
      height: 58 * iconScale,
      decoration: BoxDecoration(
        color: widget.tint,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Icon(widget.icon, color: AppColors.ink),
    );
  }
}

class _MenuStadiumPainter extends CustomPainter {
  const _MenuStadiumPainter(this.tint);

  final Color tint;

  @override
  void paint(Canvas canvas, Size size) {
    final sky = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha: .16),
          tint.withValues(alpha: .18),
          Colors.white.withValues(alpha: .46),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, sky);

    final stand = Paint()
      ..color = AppColors.ink.withValues(alpha: .08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    for (var i = 0; i < 4; i++) {
      final y = size.height * (.23 + i * .08);
      canvas.drawArc(
        Rect.fromLTWH(-size.width * .2, y, size.width * 1.4, size.height * .68),
        3.35,
        -.52,
        false,
        stand,
      );
    }
    final light = Paint()
      ..color = Colors.white.withValues(alpha: .42)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(Offset(size.width * .2, size.height * .12), 26, light);
    canvas.drawCircle(Offset(size.width * .8, size.height * .16), 22, light);
  }

  @override
  bool shouldRepaint(covariant _MenuStadiumPainter oldDelegate) =>
      oldDelegate.tint != tint;
}
