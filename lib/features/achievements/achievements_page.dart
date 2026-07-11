import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:stash/data/achievements.dart';
import 'package:stash/providers/data_providers.dart';
import 'package:stash/providers/settings_provider.dart';
import 'package:stash/widgets/ui.dart';

class AchievementsPage extends ConsumerWidget {
  const AchievementsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final reduceMotion = settings.reduceMotion;
    final achievementsAsync = ref.watch(achievementsProvider);

    return Scaffold(
      appBar: const GradientAppBar(title: 'Achievements'),
      body: achievementsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (achievements) {
          final unlocked = achievements.map((a) => a.badgeType).toSet();
          final count = unlocked.length;
          final total = achievementDefs.length;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.emoji_events_rounded,
                      size: 48,
                      color: count > 0
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.outline,
                    )
                        .animate()
                        .scale(duration: 400.ms, delay: 100.ms, curve: Curves.easeOutBack),
                    const SizedBox(height: 12),
                    Text(
                      '$count of $total unlocked',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    )
                        .animate()
                        .fadeIn(delay: 200.ms)
                        .slideY(begin: 0.2, end: 0, delay: 200.ms),
                    const SizedBox(height: 4),
                    Text(
                      count == total
                          ? 'You unlocked them all!'
                          : 'Keep saving to unlock more badges.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                    ).animate().fadeIn(delay: 300.ms),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.0,
                ),
                itemCount: total,
                itemBuilder: (context, index) {
                  final def = achievementDefs[index];
                  final isUnlocked = unlocked.contains(def.type);
                  return _AchievementBadge(
                    def: def,
                    isUnlocked: isUnlocked,
                    animate: !reduceMotion,
                    delay: (300 + index * 80).ms,
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AchievementBadge extends StatelessWidget {
  final AchievementDef def;
  final bool isUnlocked;
  final bool animate;
  final Duration delay;

  const _AchievementBadge({
    required this.def,
    required this.isUnlocked,
    required this.animate,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: isUnlocked
            ? BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    def.color.withValues(alpha: 0.12),
                    def.color.withValues(alpha: 0.04),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              )
            : null,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: isUnlocked
                          ? def.color.withValues(alpha: 0.15)
                          : cs.surfaceContainerHighest,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      def.icon,
                      size: 28,
                      color: isUnlocked ? def.color : cs.outline,
                    ),
                  ),
                  if (!isUnlocked)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: cs.surface,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.lock_rounded,
                          size: 14,
                          color: cs.outline,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                def.label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isUnlocked ? null : cs.outline,
                    ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Flexible(
                child: Text(
                  def.description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.outline,
                      ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(delay: delay)
        .scale(duration: 300.ms, delay: delay, curve: Curves.easeOutBack);
  }
}
