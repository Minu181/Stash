import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import 'package:stash/data/database.dart';
import 'package:stash/data/achievements.dart';
import 'package:stash/providers/data_providers.dart';
import 'package:stash/providers/settings_provider.dart';
import 'package:stash/widgets/animated_widgets.dart';
import 'package:stash/widgets/goal_card.dart';
import 'package:stash/widgets/ui.dart';
import 'package:stash/features/home/reminder_dialog.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final currency = settings.currency;
    final reduceMotion = settings.reduceMotion;
    final goalsAsync = ref.watch(goalsProvider);
    final streakAsync = ref.watch(streakProvider);
    final achievementsAsync = ref.watch(achievementsProvider);
    final weeklySavings = ref.watch(weeklySavingsProvider);

    return Scaffold(
      appBar: GradientAppBar(
        title: settings.displayName != null && settings.displayName!.isNotEmpty
            ? 'Hi, ${settings.displayName}'
            : 'Stash',
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: () => showReminderDialog(context),
          ),
          streakAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (streak) {
              if (streak.currentStreak == 0) return const SizedBox.shrink();
              return IconButton(
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.local_fire_department_rounded),
                    Positioned(
                      right: -4,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF6B35),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Text(
                          '${streak.currentStreak}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
                onPressed: () => _showStreakSheet(context, streak),
              );
            },
          ),
        ],
      ),
      body: goalsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (goals) {
          final total = goals.fold<double>(0, (sum, g) => sum + g.savedAmount);
          final target = goals.fold<double>(0, (sum, g) => sum + g.targetAmount);
          final overall = (target > 0 ? total / target : 0.0).clamp(0.0, 1.0).toDouble();

          if (goals.isEmpty) {
            return _EmptyState(reduceMotion: reduceMotion);
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(goalsProvider);
              ref.invalidate(streakProvider);
              ref.invalidate(achievementsProvider);
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              EnterTransition(
                animate: !reduceMotion,
                child: GradientContainer(
                  borderRadius: BorderRadius.circular(24),
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total saved',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                      ),
                      const SizedBox(height: 6),
                      CountUpText(
                        value: total,
                        animate: !reduceMotion,
                        format: (v) => formatCurrency(v, currency),
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                      ),
                      const SizedBox(height: 14),
                      AnimatedProgressRing(
                        progress: overall,
                        size: 56,
                        strokeWidth: 7,
                        color: Colors.white,
                        animate: !reduceMotion,
                        center: Text(
                          '${(overall * 100).toInt()}%',
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Goal: ${formatCurrency(target, currency)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              weeklySavings.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (weekTotal) {
                  if (weekTotal <= 0) return const SizedBox.shrink();
                  return slideFadeIn(
                    index: 0,
                    animate: !reduceMotion,
                    child: Card(
                      child: ListTile(
                        leading: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.savings_rounded, color: Theme.of(context).colorScheme.primary, size: 24),
                        ),
                        title: Text(
                          'This week',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'You saved ${formatCurrency(weekTotal, currency)} in the last 7 days',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        trailing: Text(
                          '+${formatCurrency(weekTotal, currency)}',
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 18),
              streakAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (streak) {
                  if (streak.currentStreak == 0) return const SizedBox.shrink();
                  return slideFadeIn(
                    index: 0,
                    animate: !reduceMotion,
                    child: Card(
                      child: ListTile(
                        leading: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF6B35), Color(0xFFFFD700)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.local_fire_department_rounded, color: Colors.white, size: 24),
                        ),
                        title: Text(
                          '${streak.currentStreak} day streak!',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          streak.currentStreak >= streak.longestStreak
                              ? 'New personal best!'
                              : 'Best: ${streak.longestStreak} days',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        trailing: Text(
                          '${streak.currentStreak}',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFFF6B35),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 18),
              _DueSoon(goals: goals, currency: currency, reduceMotion: reduceMotion),
              const SizedBox(height: 18),
              achievementsAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (achievements) {
                  if (achievements.isEmpty) return const SizedBox.shrink();
                  final unlocked = achievements.map((a) => a.badgeType).toSet();
                  return slideFadeIn(
                    index: 2,
                    animate: !reduceMotion,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.emoji_events_rounded, size: 18, color: Theme.of(context).colorScheme.primary),
                            const SizedBox(width: 8),
                            Text(
                              'Achievements',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _AutoScrollingAchievements(unlocked: unlocked, reduceMotion: reduceMotion),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 18),
              slideFadeIn(
                index: goals.length + 2,
                animate: !reduceMotion,
                child: Text(
                  'Your goals',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 10),
              for (var i = 0; i < goals.length; i++)
                slideFadeIn(
                  index: i,
                  animate: !reduceMotion,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: GoalCard(goal: goals[i]),
                  ),
                ),
            ],
          ),
          );
        },
      ),
    );
  }

  void _showStreakSheet(BuildContext context, dynamic streak) {
    final cs = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF6B35), Color(0xFFFFD700)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.local_fire_department_rounded, color: Colors.white, size: 36),
            ),
            const SizedBox(height: 16),
            Text(
              '${streak.currentStreak} day streak',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              streak.currentStreak >= streak.longestStreak
                  ? 'New personal best!'
                  : 'Best: ${streak.longestStreak} days',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.outline),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _streakStat('Current', '${streak.currentStreak} days', cs),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _streakStat('Best', '${streak.longestStreak} days', cs),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'This week',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            _StreakCalendar(streak: streak),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _streakStat(String label, String value, ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: cs.outline)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: cs.onSurface)),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool reduceMotion;
  const _EmptyState({required this.reduceMotion});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.savings_outlined,
              size: 84,
              color: Theme.of(context).colorScheme.outline,
            ).animate(autoPlay: !reduceMotion).scale(duration: 500.ms, curve: Curves.easeOutBack),
            const SizedBox(height: 20),
            Text(
              'No savings goals yet',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the + button to create your first goal and start saving.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AutoScrollingAchievements extends StatefulWidget {
  final Set<String> unlocked;
  final bool reduceMotion;
  const _AutoScrollingAchievements({required this.unlocked, required this.reduceMotion});

  @override
  State<_AutoScrollingAchievements> createState() => _AutoScrollingAchievementsState();
}

class _AutoScrollingAchievementsState extends State<_AutoScrollingAchievements> {
  late final ScrollController _scrollController;
  late final Duration _scrollDuration;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollDuration = Duration(milliseconds: achievementDefs.length * 280);
    if (!widget.reduceMotion) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _startAutoScroll());
    }
  }

  void _startAutoScroll() async {
    while (mounted) {
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted || !_scrollController.hasClients) break;
      final maxScroll = _scrollController.position.maxScrollExtent;
      if (maxScroll <= 0) continue;

      await _scrollController.animateTo(
        maxScroll,
        duration: _scrollDuration,
        curve: Curves.linear,
      );
      if (!mounted) break;
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted || !_scrollController.hasClients) break;
      await _scrollController.animateTo(
        0,
        duration: Duration(milliseconds: 500),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 90,
      child: ListView.separated(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        itemCount: achievementDefs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final def = achievementDefs[index];
          final unlockedBadge = widget.unlocked.contains(def.type);
          return Container(
            width: 80,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
            decoration: BoxDecoration(
              color: unlockedBadge
                  ? def.color.withValues(alpha: 0.12)
                  : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: unlockedBadge ? def.color.withValues(alpha: 0.4) : Theme.of(context).colorScheme.outlineVariant,
                width: unlockedBadge ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  def.icon,
                  size: 28,
                  color: unlockedBadge ? def.color : Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(height: 4),
                Text(
                  def.label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: unlockedBadge ? def.color : Theme.of(context).colorScheme.outline,
                      ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DueSoon extends StatelessWidget {
  final List<Goal> goals;
  final String currency;
  final bool reduceMotion;

  const _DueSoon({required this.goals, required this.currency, required this.reduceMotion});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final upcoming = goals
        .where((g) => g.deadline != null && g.deadline!.isAfter(now) && g.savedAmount < g.targetAmount)
        .toList()
      ..sort((a, b) => a.deadline!.compareTo(b.deadline!));

    if (upcoming.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.event_repeat_rounded, size: 18, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              'Due soon',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 10),
        for (var i = 0; i < upcoming.length; i++)
          slideFadeIn(
            index: i,
            animate: !reduceMotion,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _DueSoonTile(goal: upcoming[i], currency: currency),
            ),
          ),
      ],
    );
  }
}

class _DueSoonTile extends StatelessWidget {
  final Goal goal;
  final String currency;

  const _DueSoonTile({required this.goal, required this.currency});

  @override
  Widget build(BuildContext context) {
    final days = goal.deadline!.difference(DateTime.now()).inDays;
    final color = Color(goal.color);
    return Card(
      child: ListTile(
        onTap: () => context.push('/goal/${goal.id}'),
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(Icons.flag_rounded, color: color),
        ),
        title: Text(goal.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          days == 0 ? 'Due today' : days == 1 ? 'Due tomorrow' : 'Due in $days days',
          style: TextStyle(color: color, fontWeight: FontWeight.w600),
        ),
        trailing: Text(
          '${((goal.savedAmount / goal.targetAmount) * 100).toInt()}%',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class _StreakCalendar extends StatelessWidget {
  final dynamic streak;
  const _StreakCalendar({required this.streak});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastDeposit = streak.lastDepositDate;
    final lastDay = lastDeposit != null ? DateTime(lastDeposit.year, lastDeposit.month, lastDeposit.day) : null;

    final days = <DateTime>[];
    for (var i = 6; i >= 0; i--) {
      days.add(today.subtract(Duration(days: i)));
    }

    final dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (i) {
        final day = days[i];
        final isToday = day == today;
        bool active = false;
        if (lastDay != null && !day.isBefore(lastDay)) {
          final diff = day.difference(lastDay).inDays;
          if (diff < streak.currentStreak) active = true;
        }

        final cs = Theme.of(context).colorScheme;
        return Column(
          children: [
            Text(
              dayLabels[day.weekday - 1],
              style: TextStyle(fontSize: 11, color: cs.outline),
            ),
            const SizedBox(height: 6),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: active
                    ? const Color(0xFFFF6B35)
                    : isToday
                        ? cs.primaryContainer
                        : cs.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
                border: isToday
                    ? Border.all(color: cs.primary, width: 1.5)
                    : null,
              ),
              child: Center(
                child: Text(
                  '${day.day}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: active ? Colors.white : isToday ? cs.primary : cs.outline,
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}
