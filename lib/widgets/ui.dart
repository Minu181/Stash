import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:stash/theme/app_theme.dart';

/// A container painted with the active theme's primary gradient.
class GradientContainer extends StatelessWidget {
  final Widget child;
  final GradientDirection direction;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final double? height;
  final Gradient? gradient;
  final BoxShape shape;

  const GradientContainer({
    super.key,
    required this.child,
    this.direction = GradientDirection.diagonal,
    this.padding,
    this.borderRadius,
    this.height,
    this.gradient,
    this.shape = BoxShape.rectangle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        gradient: gradient ?? AppGradients.vibrant(context, direction: direction),
        borderRadius: shape == BoxShape.circle ? null : borderRadius,
        shape: shape,
      ),
      child: child,
    );
  }
}

/// One-shot entrance animation (fade + slide-up). Plays on first insert.
class EnterTransition extends StatelessWidget {
  final Widget child;
  final Duration duration;
  final bool animate;
  final double beginY;

  const EnterTransition({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 500),
    this.animate = true,
    this.beginY = 0.12,
  });

  @override
  Widget build(BuildContext context) {
    if (!animate) return child;
    return child
        .animate()
        .fadeIn(duration: duration, curve: Curves.easeOutCubic)
        .slideY(begin: beginY, end: 0, duration: duration, curve: Curves.easeOutCubic);
  }
}

/// Gradient header card used at the top of each tab.
class PageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? action;
  final bool animate;

  const PageHeader({super.key, required this.title, this.subtitle, this.action, this.animate = true});

  @override
  Widget build(BuildContext context) {
    return EnterTransition(
      animate: animate,
      child: GradientContainer(
        direction: GradientDirection.horizontal,
        borderRadius: BorderRadius.circular(24),
        padding: const EdgeInsets.all(22),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.3,
                        ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.88), fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ],
                ],
              ),
            ),
            if (action != null) action!,
          ],
        ),
      ),
    );
  }
}

/// Floating action button with a gradient fill.
class GradientFAB extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget? child;
  final String? tooltip;

  const GradientFAB({super.key, this.onPressed, this.child, this.tooltip});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final content = child ?? const Icon(Icons.add_rounded, color: Colors.white, size: 28);
    return FloatingActionButton(
      onPressed: onPressed,
      tooltip: tooltip,
      backgroundColor: Colors.transparent,
      elevation: 6,
      child: Container(
        decoration: BoxDecoration(
          gradient: AppGradients.vibrant(context, direction: GradientDirection.vertical),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: cs.primary.withValues(alpha: 0.45), blurRadius: 12, offset: const Offset(0, 6)),
          ],
        ),
        child: Center(child: content),
      ),
    );
  }
}

/// A gradient AppBar with white title/subtitle and light status-bar icons.
class GradientAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final Widget? leading;

  const GradientAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.leading,
  });

  @override
  Size get preferredSize => Size.fromHeight(subtitle != null ? 78 : kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: leading,
      actions: actions,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      centerTitle: false,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 21, letterSpacing: -0.3),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ],
        ],
      ),
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: AppGradients.vibrant(context, direction: GradientDirection.diagonal),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.25),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
      ),
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );
  }
}
