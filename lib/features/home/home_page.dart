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
    final showAchievements = settings.showAchievements;
    final goalsAsync = ref.watch(goalsProvider);
    final streakAsync = ref.watch(streakProvider);
    final achievementsAsync = ref.watch(achievementsProvider);
    final weeklySavings = ref.watch(weeklySavingsProvider);

    final greeting = _greetingText();

    return Scaffold(
      appBar: GradientAppBar(
        title: settings.displayName != null && settings.displayName!.isNotEmpty
            ? '$greeting, ${settings.displayName}'
            : '$greeting!',
        subtitle: 'Let\'s grow your savings',
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
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
            children: [
              Container(
                height: 0,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
              ),
              EnterTransition(
                animate: !reduceMotion,
                child: GradientContainer(
                  borderRadius: BorderRadius.circular(24),
                  padding: const EdgeInsets.all(22),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total saved',
                              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            CountUpText(
                              value: total,
                              animate: !reduceMotion,
                              format: (v) => formatCurrency(v, currency),
                              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: -1,
                                  ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'of ${formatCurrency(target, currency)} goal',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.7),
                                  ),
                            ),
                            const SizedBox(height: 14),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: overall,
                                minHeight: 8,
                                backgroundColor: Colors.white.withValues(alpha: 0.2),
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${(overall * 100).toInt()}% complete',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.65),
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      AnimatedProgressRing(
                        progress: overall,
                        size: 72,
                        strokeWidth: 8,
                        color: Colors.white,
                        animate: !reduceMotion,
                        center: Text(
                          '${(overall * 100).toInt()}%',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
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
                  final cs = Theme.of(context).colorScheme;
                  final isDark = Theme.of(context).brightness == Brightness.dark;
                  return slideFadeIn(
                    index: 0,
                    animate: !reduceMotion,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: cs.primary.withValues(alpha: 0.25),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                          BoxShadow(
                            color: cs.primary.withValues(alpha: 0.1),
                            blurRadius: 40,
                            offset: const Offset(0, 16),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                cs.primary,
                                HSLColor.fromAHSL(
                                  1.0,
                                  (HSLColor.fromColor(cs.primary).hue + 30) % 360,
                                  (HSLColor.fromColor(cs.primary).saturation * 0.8).clamp(0.0, 1.0),
                                  isDark ? 0.48 : 0.42,
                                ).toColor(),
                              ],
                            ),
                          ),
                          child: Stack(
                            children: [
                              Positioned(
                                right: -20,
                                top: -20,
                                child: Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withValues(alpha: isDark ? 0.06 : 0.1),
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 30,
                                bottom: -30,
                                child: Container(
                                  width: 70,
                                  height: 70,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withValues(alpha: isDark ? 0.04 : 0.07),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(18),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: const Icon(Icons.savings_rounded, color: Colors.white, size: 26),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'This week',
                                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            'You saved ${formatCurrency(weekTotal, currency)}',
                                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                              color: Colors.white.withValues(alpha: 0.75),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        '+${formatCurrency(weekTotal, currency)}',
                                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                        ),
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
                  );
                },
              ),
              const SizedBox(height: 18),
              streakAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (streak) {
                  if (streak.currentStreak == 0) return const SizedBox.shrink();
                  final isBest = streak.currentStreak >= streak.longestStreak;
                  return slideFadeIn(
                    index: 0,
                    animate: !reduceMotion,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF6B35).withValues(alpha: 0.3),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                          BoxShadow(
                            color: const Color(0xFFFF6B35).withValues(alpha: 0.1),
                            blurRadius: 40,
                            offset: const Offset(0, 16),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFFFF6B35), Color(0xFFFFB300)],
                            ),
                          ),
                          child: Stack(
                            children: [
                              Positioned(
                                right: -8,
                                top: -8,
                                child: Icon(
                                  Icons.local_fire_department_rounded,
                                  size: 60,
                                  color: Colors.white.withValues(alpha: 0.08),
                                ),
                              ),
                              Positioned(
                                right: 40,
                                bottom: -12,
                                child: Icon(
                                  Icons.local_fire_department_rounded,
                                  size: 44,
                                  color: Colors.white.withValues(alpha: 0.06),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(18),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: const Icon(Icons.local_fire_department_rounded, color: Colors.white, size: 26),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${streak.currentStreak} day streak!',
                                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            isBest ? 'New personal best!' : 'Best: ${streak.longestStreak} days',
                                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                              color: Colors.white.withValues(alpha: 0.75),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          '${streak.currentStreak}',
                                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                            fontWeight: FontWeight.w900,
                                            color: Colors.white,
                                          ),
                                        ),
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
                  );
                },
              ),
              const SizedBox(height: 18),
              _DueSoon(goals: goals, currency: currency, reduceMotion: reduceMotion),
              const SizedBox(height: 18),
              if (showAchievements)
                achievementsAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (achievements) {
                  if (achievements.isEmpty) return const SizedBox.shrink();
                  final unlocked = achievements.map((a) => a.badgeType).toSet();
                  final progress = unlocked.length / achievementDefs.length;
                  return slideFadeIn(
                    index: 2,
                    animate: !reduceMotion,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Header with gradient icon + progress bar ──
                        Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Theme.of(context).colorScheme.primary,
                                    Theme.of(context).colorScheme.tertiary,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(11),
                              ),
                              child: const Icon(Icons.emoji_events_rounded, size: 20, color: Colors.white),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Achievements',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${unlocked.length}/${achievementDefs.length}',
                                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        // Progress bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 4,
                            backgroundColor: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.4),
                            valueColor: AlwaysStoppedAnimation(Theme.of(context).colorScheme.primary),
                          ),
                        ),
                        const SizedBox(height: 14),
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
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).colorScheme.primary,
                            Theme.of(context).colorScheme.tertiary,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: const Icon(Icons.flag_rounded, size: 20, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Your goals',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${goals.length}',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
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

  String _greetingText() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
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

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    if (!widget.reduceMotion) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _startAutoScroll());
    }
  }

  void _startAutoScroll() async {
    await Future.delayed(const Duration(seconds: 2));
    while (mounted) {
      if (!mounted || !_scrollController.hasClients) break;
      final maxScroll = _scrollController.position.maxScrollExtent;
      if (maxScroll <= 0) {
        await Future.delayed(const Duration(milliseconds: 200));
        continue;
      }
      final current = _scrollController.offset;
      final target = current + 100;
      if (target >= maxScroll) {
        _scrollController.jumpTo(0);
        await Future.delayed(const Duration(seconds: 1));
      } else {
        await _scrollController.animateTo(
          target,
          duration: const Duration(milliseconds: 1200),
          curve: Curves.easeInOutCubic,
        );
        await Future.delayed(const Duration(milliseconds: 800));
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final doubled = [
      for (var i = 0; i < 2; i++)
        for (var def in achievementDefs) def,
    ];
    return SizedBox(
      height: 110,
      child: ListView.separated(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: doubled.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final def = doubled[index];
          final isUnlocked = widget.unlocked.contains(def.type);
          return _AchievementBadge(def: def, isUnlocked: isUnlocked);
        },
      ),
    );
  }
}

class _AchievementBadge extends StatelessWidget {
  final AchievementDef def;
  final bool isUnlocked;

  const _AchievementBadge({required this.def, required this.isUnlocked});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final width = isUnlocked ? 96.0 : 74.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      width: width,
      padding: EdgeInsets.symmetric(
        vertical: isUnlocked ? 14 : 10,
        horizontal: 6,
      ),
      decoration: BoxDecoration(
        gradient: isUnlocked
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  def.color.withValues(alpha: 0.25),
                  def.color.withValues(alpha: 0.08),
                ],
              )
            : null,
        color: isUnlocked ? null : cs.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isUnlocked ? def.color.withValues(alpha: 0.55) : cs.outlineVariant.withValues(alpha: 0.4),
          width: isUnlocked ? 2 : 1,
        ),
        boxShadow: isUnlocked
            ? [
                BoxShadow(
                  color: def.color.withValues(alpha: 0.3),
                  blurRadius: 16,
                  spreadRadius: -3,
                  offset: const Offset(0, 5),
                ),
                BoxShadow(
                  color: def.color.withValues(alpha: 0.1),
                  blurRadius: 28,
                  spreadRadius: -6,
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: isUnlocked ? 46 : 36,
            height: isUnlocked ? 46 : 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: isUnlocked
                  ? RadialGradient(
                      colors: [
                        def.color.withValues(alpha: 0.35),
                        def.color.withValues(alpha: 0.08),
                      ],
                    )
                  : null,
              color: isUnlocked ? null : cs.outlineVariant.withValues(alpha: 0.15),
            ),
            child: Icon(
              def.icon,
              size: isUnlocked ? 26 : 20,
              color: isUnlocked ? def.color : cs.outline.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            def.label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontSize: isUnlocked ? 10.5 : 9,
              fontWeight: isUnlocked ? FontWeight.w700 : FontWeight.w500,
              color: isUnlocked ? def.color : cs.outline.withValues(alpha: 0.55),
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
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
        _SectionHeader(
          icon: Icons.event_repeat_rounded,
          title: 'Due soon',
          trailing: Text(
            '${upcoming.length}',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
        const SizedBox(height: 12),
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
          backgroundColor: color.withValues(alpha: 0.2),
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

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;

  const _SectionHeader({required this.icon, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
          ),
        ),
        if (trailing != null) trailing!,
      ],
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
