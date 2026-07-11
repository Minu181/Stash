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

    return _GoalCardInkwell(
      onTap: () => context.push('/goal/${goal.id}'),
      borderRadius: BorderRadius.circular(20),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: completed
              ? BorderSide(color: gold.withValues(alpha: 0.5), width: 2)
              : BorderSide.none,
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            Container(
              width: 4,
              height: double.infinity,
              color: completed ? gold : color,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        AnimatedProgressRing(
                          progress: progress,
                          size: 76,
                          strokeWidth: 8,
                          color: completed ? gold : color,
                          animate: !reduceMotion,
                          center: goal.imageUrl != null && goal.imageUrl!.isNotEmpty
                              ? ClipOval(
                                  child: GoalImage(
                                    imageUrl: goal.imageUrl,
                                    width: 56,
                                    height: 56,
                                    fit: BoxFit.cover,
                                    fallback: Icon(icon, color: completed ? gold : color, size: 28),
                                  ),
                                )
                              : Icon(icon, color: completed ? gold : color, size: 30),
                        ),
                        if (completed)
                          Positioned(
                            right: -2,
                            bottom: -2,
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: gold,
                                shape: BoxShape.circle,
                                border: Border.all(color: Theme.of(context).colorScheme.surface, width: 2),
                              ),
                              child: const Icon(Icons.check_rounded, size: 14, color: Colors.white),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  goal.name,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (completed)
                                Padding(
                                  padding: const EdgeInsets.only(left: 6),
                                  child: Icon(Icons.star_rounded, size: 18, color: gold),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          CountUpText(
                            value: goal.savedAmount,
                            animate: !reduceMotion,
                            format: (v) => formatCurrency(v, currency),
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(color: completed ? gold : color),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            completed ? 'Completed!' : 'of ${formatCurrency(goal.targetAmount, currency)}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: completed ? gold : Theme.of(context).colorScheme.outline,
                                  fontWeight: completed ? FontWeight.w600 : null,
                                ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// InkWell wrapper that scales down on press for tactile feedback.
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
        scale: _pressing ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            boxShadow: _pressing
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
