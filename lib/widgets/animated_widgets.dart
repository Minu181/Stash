import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stash/providers/settings_provider.dart';

class CountUpText extends StatefulWidget {
  final double value;
  final String Function(double) format;
  final TextStyle? style;
  final Duration duration;
  final bool animate;

  const CountUpText({
    super.key,
    required this.value,
    required this.format,
    this.style,
    this.duration = const Duration(milliseconds: 900),
    this.animate = true,
  });

  @override
  State<CountUpText> createState() => _CountUpTextState();
}

class _CountUpTextState extends State<CountUpText> with SingleTickerProviderStateMixin {
  late double _display;
  late final AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _display = widget.animate ? 0 : widget.value;
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _animation = Tween<double>(begin: _display, end: _display).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _animation.addListener(() {
      if (mounted) setState(() => _display = _animation.value);
    });
    if (widget.animate) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _animateTo(widget.value));
    }
  }

  void _animateTo(double target) {
    _animation = Tween<double>(begin: _display, end: target).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _animation.addListener(() {
      if (mounted) setState(() => _display = _animation.value);
    });
    _controller
      ..reset()
      ..forward();
  }

  @override
  void didUpdateWidget(covariant CountUpText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      if (widget.animate) {
        _animateTo(widget.value);
      } else {
        setState(() => _display = widget.value);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Text(widget.format(_display), style: widget.style);
}

class AnimatedProgressRing extends StatefulWidget {
  final double progress; // 0..1
  final double size;
  final double strokeWidth;
  final Color? color;
  final Widget? center;
  final bool animate;

  const AnimatedProgressRing({
    super.key,
    required this.progress,
    this.size = 90,
    this.strokeWidth = 9,
    this.color,
    this.center,
    this.animate = true,
  });

  @override
  State<AnimatedProgressRing> createState() => _AnimatedProgressRingState();
}

class _AnimatedProgressRingState extends State<AnimatedProgressRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _from = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _animation = Tween<double>(begin: 0, end: widget.progress.clamp(0, 1).toDouble()).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    if (widget.animate) {
      _controller.forward();
    } else {
      _animation = Tween<double>(begin: widget.progress, end: widget.progress).animate(_controller);
      _controller.value = 1;
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedProgressRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      final target = widget.progress.clamp(0, 1).toDouble();
      if (!widget.animate) {
        _animation = Tween<double>(begin: target, end: target).animate(_controller);
        _controller.value = 1;
        return;
      }
      _from = _animation.value;
      _animation = Tween<double>(
        begin: _from,
        end: target,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Theme.of(context).colorScheme.primary;
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) => SizedBox(
        width: widget.size,
        height: widget.size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CircularProgressIndicator(
              value: _animation.value,
              strokeWidth: widget.strokeWidth,
              strokeCap: StrokeCap.round,
              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation(color),
            ),
            if (widget.center != null) widget.center!,
          ],
        ),
      ),
    );
  }
}

Widget slideFadeIn({
  required Widget child,
  required int index,
  required bool animate,
  AxisDirection direction = AxisDirection.up,
}) {
  if (!animate) return child;
  final offset = direction == AxisDirection.up
      ? const Offset(0, 0.25)
      : direction == AxisDirection.down
          ? const Offset(0, -0.25)
          : direction == AxisDirection.left
              ? const Offset(0.25, 0)
              : const Offset(-0.25, 0);
  return child.animate().fadeIn(
        duration: const Duration(milliseconds: 500),
        delay: Duration(milliseconds: 60 * index),
      ).slide(
        begin: offset,
        duration: const Duration(milliseconds: 500),
        delay: Duration(milliseconds: 60 * index),
        curve: Curves.easeOutCubic,
      ).scale(
        begin: const Offset(0.96, 0.96),
        duration: const Duration(milliseconds: 500),
        delay: Duration(milliseconds: 60 * index),
        curve: Curves.easeOutCubic,
      );
}

bool shouldReduceMotion(WidgetRef ref) => ref.watch(settingsProvider).reduceMotion;
