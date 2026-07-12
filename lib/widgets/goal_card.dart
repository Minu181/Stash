import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:stash/data/database.dart';
import 'package:stash/providers/settings_provider.dart';
import 'package:stash/widgets/animated_widgets.dart';
import 'package:stash/widgets/goal_image.dart';
import 'package:stash/features/goals/goal_options.dart';

class GoalCard extends ConsumerWidget {
  final Goal goal;

  const GoalCard({super.key, required this.goal});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final currency = settings.currency;
    final reduceMotion = settings.reduceMotion;
    final color = Color(goal.color);
    final progress = (goal.targetAmount > 0 ? goal.savedAmount / goal.targetAmount : 0.0)
        .clamp(0.0, 1.0)
        .toDouble();
    final icon = GoalOptions.iconForCodePoint(goal.icon);
    final completed = progress >= 1.0;
    final gold = const Color(0xFFF9A825);
    final displayColor = completed ? gold : color;

    final daysLeft = goal.deadline != null
        ? goal.deadline!.difference(DateTime.now()).inDays
        : null;
    final urgent = daysLeft != null && daysLeft <= 7 && !completed;

    return _GoalCardInkwell(
      onTap: () => context.push('/goal/${goal.id}'),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: displayColor.withValues(alpha: completed ? 0.35 : 0.25),
              blurRadius: completed ? 24 : 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Card(
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          clipBehavior: Clip.antiAlias,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  width: 5,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: completed
                          ? [gold, gold.withValues(alpha: 0.4)]
                          : [color, color.withValues(alpha: 0.5)],
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            AnimatedProgressRing(
                              progress: progress,
                              size: 64,
                              strokeWidth: 6,
                              color: displayColor,
                              animate: !reduceMotion,
                              center: goal.imageUrl != null && goal.imageUrl!.isNotEmpty
                                  ? ClipOval(
                                      child: GoalImage(
                                        imageUrl: goal.imageUrl,
                                        width: 48,
                                        height: 48,
                                        fit: BoxFit.cover,
                                        fallback: Icon(icon, color: displayColor, size: 22),
                                      ),
                                    )
                                  : Icon(icon, color: displayColor, size: 24),
                            ),
                            if (completed)
                              Positioned(
                                right: -2,
                                bottom: -2,
                                child: Container(
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    color: gold,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Theme.of(context).colorScheme.surface,
                                      width: 2,
                                    ),
                                  ),
                                  child: const Icon(Icons.check_rounded, size: 12, color: Colors.white),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      goal.name,
                                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: -0.2,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (completed) ...[
                                    const SizedBox(width: 4),
                                    Icon(Icons.star_rounded, size: 16, color: gold),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 4),
                              CountUpText(
                                value: goal.savedAmount,
                                animate: !reduceMotion,
                                format: (v) => formatCurrency(v, currency),
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: displayColor,
                                ),
                              ),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  minHeight: 5,
                                  backgroundColor: displayColor.withValues(alpha: 0.18),
                                  valueColor: AlwaysStoppedAnimation(displayColor),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      completed
                                          ? 'Completed!'
                                          : 'of ${formatCurrency(goal.targetAmount, currency)}',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: completed
                                            ? gold
                                            : Theme.of(context).colorScheme.outline,
                                        fontWeight: completed ? FontWeight.w600 : null,
                                      ),
                                    ),
                                  ),
                                  if (daysLeft != null && !completed)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: urgent
                                            ? Colors.redAccent.withValues(alpha: 0.12)
                                            : Theme.of(context).colorScheme.surfaceContainerHighest,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '${daysLeft}d left',
                                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: urgent ? Colors.redAccent : Theme.of(context).colorScheme.outline,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GoalCardInkwell extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final BorderRadius borderRadius;

  const _GoalCardInkwell({
    required this.child,
    required this.onTap,
    required this.borderRadius,
  });

  @override
  State<_GoalCardInkwell> createState() => _GoalCardInkwellState();
}

class _GoalCardInkwellState extends State<_GoalCardInkwell> {
  bool _pressing = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressing = true),
      onTapUp: (_) => setState(() => _pressing = false),
      onTapCancel: () => setState(() => _pressing = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressing ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutExpo,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutExpo,
          decoration: BoxDecoration(
            boxShadow: _pressing
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
