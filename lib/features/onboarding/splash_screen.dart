import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import 'package:stash/constants.dart';
import 'package:stash/services/app_prefs.dart';
import 'package:stash/theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _ringController;
  late final Animation<double> _ringAnimation;

  @override
  void initState() {
    super.initState();
    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _ringAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ringController, curve: Curves.easeOutCubic),
    );
    _ringController.forward();

    Future.delayed(const Duration(milliseconds: 2200), _goToLastTab);
  }

  Future<void> _goToLastTab() async {
    if (!mounted) return;
    final tab = await AppPrefs.getLastTab();
    if (!mounted) return;
    context.go(kTabRoutes[tab]);
  }

  @override
  void dispose() {
    _ringController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: GestureDetector(
        onTap: _goToLastTab,
        child: Scaffold(
          body: Container(
          decoration: BoxDecoration(
            gradient: AppGradients.vibrant(context, direction: GradientDirection.vertical),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: AnimatedBuilder(
                    animation: _ringAnimation,
                    builder: (context, _) {
                      return CustomPaint(
                        painter: _RingPainter(
                          progress: _ringAnimation.value,
                          color: Colors.white,
                          bgColor: Colors.white.withValues(alpha: 0.3),
                        ),
                        child: Center(
                          child: const Icon(
                            Icons.savings_rounded,
                            size: 56,
                            color: Colors.white,
                          ),
                        ),
                      );
                    },
                  ),
                )
                    .animate()
                    .scale(
                      duration: 600.ms,
                      delay: 100.ms,
                      curve: Curves.easeOutBack,
                    )
                    .then(delay: 200.ms)
                    .shimmer(duration: 800.ms, color: Colors.white.withValues(alpha: 0.25)),
                const SizedBox(height: 32),
                Text(
                  'Stash',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                )
                    .animate()
                    .fadeIn(duration: 500.ms, delay: 400.ms)
                    .slideY(begin: 0.3, end: 0, duration: 500.ms, delay: 400.ms, curve: Curves.easeOutCubic),
                const SizedBox(height: 8),
                Text(
                  'Your goals, beautifully tracked',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                )
                    .animate()
                    .fadeIn(duration: 500.ms, delay: 600.ms)
                    .slideY(begin: 0.2, end: 0, duration: 500.ms, delay: 600.ms, curve: Curves.easeOutCubic),
              ],
            ),
          ),
        ),
      ),
    ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color bgColor;

  _RingPainter({required this.progress, required this.color, required this.bgColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;

    final bgPaint = Paint()
      ..color = bgColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    final fgPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -3.14159 / 2,
      2 * 3.14159 * progress,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress || old.color != color;
}
