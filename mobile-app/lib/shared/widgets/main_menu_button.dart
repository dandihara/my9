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
    final iconScale = responsiveIconSize(context, 1);
    final compact = MediaQuery.sizeOf(context).width < 350;
    final cardPadding = compact ? 12.0 : 18.0;
    final iconAreaHeight = compact ? 62.0 : 76.0;
    final iconAreaWidth = compact ? 70.0 : 92.0;
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
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  widget.tint.withValues(alpha: .42),
                  widget.tint.withValues(alpha: .16),
                  AppColors.white,
                ],
                stops: const [0, .46, 1],
              ),
              borderRadius: BorderRadius.circular(26),
            ),
            child: InkWell(
              onTap: widget.onTap,
              onHighlightChanged: (value) => setState(() => _pressed = value),
              borderRadius: BorderRadius.circular(26),
              child: Stack(
                children: [
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
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              height: iconAreaHeight * iconScale,
                              width: iconAreaWidth * iconScale,
                              child: Align(
                                alignment: Alignment.topLeft,
                                child: widget.assetPath == null
                                    ? Container(
                                        width: 50 * iconScale,
                                        height: 50 * iconScale,
                                        decoration: BoxDecoration(
                                          color: widget.tint,
                                          borderRadius:
                                              BorderRadius.circular(16),
                                        ),
                                        child: Icon(widget.icon,
                                            color: AppColors.ink),
                                      )
                                    : Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          Positioned(
                                            left: 0,
                                            top: 8,
                                            child: Container(
                                              width: 58 * iconScale,
                                              height: 58 * iconScale,
                                              decoration: BoxDecoration(
                                                color: widget.tint,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            left: -7,
                                            top: -8,
                                            child: AnimatedBuilder(
                                              animation: _floatController,
                                              builder: (_, child) =>
                                                  Transform.translate(
                                                offset: Offset(
                                                    0,
                                                    -3 *
                                                        _floatController.value),
                                                child: child,
                                              ),
                                              child: Image.asset(
                                                widget.assetPath!,
                                                width: 90 * iconScale,
                                                height: 90 * iconScale,
                                                fit: BoxFit.contain,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                            if (!compact) ...[
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: .72),
                                  borderRadius: BorderRadius.circular(99),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.event_seat_rounded,
                                        size: 11, color: AppColors.ink),
                                    SizedBox(width: 4),
                                    Text(
                                      'BLOCK',
                                      style: TextStyle(
                                        color: AppColors.ink,
                                        fontSize: 8,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: .7,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        const Spacer(),
                        Text(widget.title,
                            style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 5),
                        Text(
                          widget.subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                            height: 1.35,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            for (var i = 0; i < 4; i++)
                              Container(
                                width: 4,
                                height: 4,
                                margin: const EdgeInsets.only(right: 5),
                                decoration: BoxDecoration(
                                  color: widget.tint,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            const Spacer(),
                            AnimatedSlide(
                              offset:
                                  _pressed ? const Offset(.12, 0) : Offset.zero,
                              duration: const Duration(milliseconds: 180),
                              child: const Icon(
                                Icons.arrow_forward_rounded,
                                color: AppColors.ink,
                              ),
                            ),
                          ],
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
}
