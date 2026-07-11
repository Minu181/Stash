import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stash/data/database.dart';
import 'package:stash/providers/data_providers.dart';
import 'package:stash/providers/settings_provider.dart';
import 'package:stash/widgets/goal_card.dart';
import 'package:stash/widgets/animated_widgets.dart';
import 'package:stash/widgets/ui.dart';

class GoalsPage extends ConsumerStatefulWidget {
  const GoalsPage({super.key});

  @override
  ConsumerState<GoalsPage> createState() => _GoalsPageState();
}

class _GoalsPageState extends ConsumerState<GoalsPage> {
  String _filter = 'all';

  bool _isCompleted(Goal g) =>
      g.targetAmount > 0 && (g.savedAmount / g.targetAmount).clamp(0.0, 1.0) >= 1.0;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = ref.watch(settingsProvider).reduceMotion;
    final goalsAsync = ref.watch(goalsProvider);

    return Scaffold(
      appBar: goalsAsync.when(
        loading: () => const GradientAppBar(title: 'Your Goals'),
        error: (_, __) => const GradientAppBar(title: 'Your Goals'),
        data: (goals) {
          final saved = goals.fold<double>(0, (s, g) => s + g.savedAmount);
          return GradientAppBar(
            title: 'Your Goals',
            subtitle: goals.isEmpty
                ? 'Start saving for what matters'
                : '${goals.length} goals · ${formatCurrency(saved, ref.watch(settingsProvider).currency)} saved',
          );
        },
      ),
      body: goalsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (goals) {
          final filtered = switch (_filter) {
            'active' => goals.where((g) => !_isCompleted(g)).toList(),
            'completed' => goals.where(_isCompleted).toList(),
            _ => goals,
          };

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            children: [
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'all', label: Text('All')),
                  ButtonSegment(value: 'active', label: Text('Active')),
                  ButtonSegment(value: 'completed', label: Text('Completed')),
                ],
                selected: {_filter},
                onSelectionChanged: (s) => setState(() => _filter = s.first),
              ),
              const SizedBox(height: 16),
              if (filtered.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Text(
                      _filter == 'completed'
                          ? 'No completed goals yet.'
                          : _filter == 'active'
                              ? 'No active goals.'
                              : 'No goals yet. Tap + to create one.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                    ),
                  ),
                )
              else
                for (var i = 0; i < filtered.length; i++)
                  slideFadeIn(
                    index: i,
                    animate: !reduceMotion,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GoalCard(goal: filtered[i]),
                    ),
                  ),
            ],
          );
        },
      ),
    );
  }
}
