import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:stash/data/database.dart';
import 'package:stash/providers/data_providers.dart';
import 'package:stash/providers/settings_provider.dart';
import 'package:stash/widgets/animated_widgets.dart';
import 'package:stash/widgets/goal_image.dart';
import 'package:stash/features/goals/goal_options.dart';
import 'package:stash/features/transactions/transaction_sheet.dart';
import 'package:stash/widgets/ui.dart';

class GoalDetailPage extends ConsumerStatefulWidget {
  final int goalId;

  const GoalDetailPage({super.key, required this.goalId});

  @override
  ConsumerState<GoalDetailPage> createState() => _GoalDetailPageState();
}

class _GoalDetailPageState extends ConsumerState<GoalDetailPage> {
  static const _gold = Color(0xFFF9A825);
  String _searchQuery = '';
  String? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final currency = settings.currency;
    final reduceMotion = settings.reduceMotion;
    final goalsAsync = ref.watch(goalsProvider);
    final txAsync = ref.watch(transactionsForGoalProvider(widget.goalId));

    final goal = goalsAsync.whenOrNull(data: (goals) => goals.where((g) => g.id == widget.goalId).firstOrNull);

    if (goal == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Goal not found'), backgroundColor: Colors.red),
          );
          context.pop();
        }
      });
      return Scaffold(
        appBar: const GradientAppBar(title: 'Goal'),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final color = Color(goal.color);
    final progress = (goal.targetAmount > 0 ? goal.savedAmount / goal.targetAmount : 0.0)
        .clamp(0.0, 1.0)
        .toDouble();
    final icon = GoalOptions.iconForCodePoint(goal.icon);
    final completed = progress >= 1.0;
    final ringColor = completed ? _gold : color;

    return Scaffold(
      appBar: GradientAppBar(
        title: goal.name,
        actions: [
          PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(
                child: const Row(children: [Icon(Icons.edit_rounded), SizedBox(width: 10), Text('Edit')]),
                onTap: () => Future.microtask(() => context.push('/goal/edit', extra: goal)),
              ),
              PopupMenuItem(
                child: const Row(children: [
                  Icon(Icons.delete_outline_rounded, color: Colors.red),
                  SizedBox(width: 10),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ]),
                onTap: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Delete goal?'),
                      content: const Text('This will remove the goal and its transactions.'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                        FilledButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await appDatabase.deleteGoal(goal.id);
                    if (context.mounted) context.pop();
                  }
                },
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(goalsProvider);
          ref.invalidate(transactionsForGoalProvider(widget.goalId));
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Hero image ──
            if (goal.imageUrl != null && goal.imageUrl!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    children: [
                      GoalImage(
                        imageUrl: goal.imageUrl,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        fallback: Container(
                          height: 200,
                          color: color.withValues(alpha: 0.2),
                          child: Icon(icon, size: 56, color: color),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        height: 60,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Theme.of(context).scaffoldBackgroundColor,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate(autoPlay: !reduceMotion).fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
              ),

            // ── Completed banner ──
            if (completed)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_gold.withValues(alpha: 0.15), _gold.withValues(alpha: 0.05)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _gold.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _gold.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.celebration_rounded, color: _gold, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Goal Reached!',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: _gold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'You saved ${formatCurrency(goal.savedAmount, currency)}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: _gold.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ).animate(autoPlay: !reduceMotion).fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),

            // ── Stats card ──
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: ringColor.withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Card(
                color: completed ? _gold.withValues(alpha: 0.1) : color.withValues(alpha: 0.18),
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Row(
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          AnimatedProgressRing(
                            progress: progress,
                            size: 96,
                            strokeWidth: 9,
                            color: ringColor,
                            animate: !reduceMotion,
                            center: goal.imageUrl != null && goal.imageUrl!.isNotEmpty
                                ? ClipOval(
                                    child: GoalImage(
                                      imageUrl: goal.imageUrl,
                                      width: 72,
                                      height: 72,
                                      fit: BoxFit.cover,
                                      fallback: Icon(icon, color: ringColor, size: 34),
                                    ),
                                  )
                                : completed
                                    ? Icon(Icons.check_rounded, color: _gold, size: 40)
                                    : Icon(icon, color: color, size: 38),
                          ),
                          if (completed)
                            Positioned(
                              right: -3,
                              bottom: -3,
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: _gold,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface,
                                    width: 3,
                                  ),
                                ),
                                child: const Icon(Icons.check_rounded, size: 16, color: Colors.white),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CountUpText(
                              value: goal.savedAmount,
                              animate: !reduceMotion,
                              format: (v) => formatCurrency(v, currency),
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: ringColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'of ${formatCurrency(goal.targetAmount, currency)}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 6,
                                backgroundColor: ringColor.withValues(alpha: 0.2),
                                valueColor: AlwaysStoppedAnimation(ringColor),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Text(
                                  completed ? 'Completed!' : '${(progress * 100).toInt()}% complete',
                                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                    color: ringColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const Spacer(),
                                if (goal.deadline != null)
                                  Text(
                                    'by ${goal.deadline!.day}/${goal.deadline!.month}/${goal.deadline!.year}',
                                    style: Theme.of(context).textTheme.bodySmall,
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
            const SizedBox(height: 20),

            // ── Action buttons ──
            if (!completed)
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [color, HSLColor.fromAHSL(
                            1.0,
                            (HSLColor.fromColor(color).hue + 20) % 360,
                            (HSLColor.fromColor(color).saturation * 0.85).clamp(0.0, 1.0),
                            0.48,
                          ).toColor()],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(alpha: 0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: FilledButton.icon(
                        onPressed: () => showTransactionSheet(context, goal),
                        icon: const Icon(Icons.add_rounded, color: Colors.white),
                        label: const Text('Deposit', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: () => showTransactionSheet(context, goal, initialType: 'withdrawal'),
                        icon: const Icon(Icons.remove_rounded),
                        label: const Text('Withdraw', style: TextStyle(fontWeight: FontWeight.w600)),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            if (!completed) const SizedBox(height: 24),
            Text(
              'Transactions',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            txAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e'),
              data: (txs) {
                if (txs.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(40),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.receipt_long_rounded,
                          size: 48,
                          color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No transactions yet',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Make a deposit to get started',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                              ),
                        ),
                      ],
                    ),
                  );
                }

                final filtered = txs.where((t) {
                  final matchesSearch = _searchQuery.isEmpty ||
                      t.note.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                      t.category.toLowerCase().contains(_searchQuery.toLowerCase());
                  final matchesCategory = _selectedCategory == null || t.category == _selectedCategory;
                  return matchesSearch && matchesCategory;
                }).toList();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: TextField(
                        onChanged: (v) => setState(() => _searchQuery = v),
                        decoration: InputDecoration(
                          hintText: 'Search transactions...',
                          prefixIcon: const Icon(Icons.search_rounded, size: 22),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.close_rounded, size: 18),
                                  onPressed: () => setState(() => _searchQuery = ''),
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 36,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: FilterChip(
                              label: const Text('All'),
                              selected: _selectedCategory == null,
                              onSelected: (_) => setState(() => _selectedCategory = null),
                              showCheckmark: false,
                              selectedColor: color,
                              checkmarkColor: Colors.white,
                              labelStyle: TextStyle(
                                color: _selectedCategory == null ? Colors.white : null,
                                fontSize: 12,
                                fontWeight: _selectedCategory == null ? FontWeight.w600 : FontWeight.normal,
                              ),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                            ),
                          ),
                          for (final cat in GoalOptions.categories)
                            Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: FilterChip(
                                label: Text(cat.name),
                                selected: _selectedCategory == cat.name,
                                onSelected: (_) => setState(() => _selectedCategory = cat.name),
                                showCheckmark: false,
                                avatar: Icon(cat.icon, size: 16, color: _selectedCategory == cat.name ? Colors.white : cat.color),
                                selectedColor: cat.color,
                                checkmarkColor: Colors.white,
                                labelStyle: TextStyle(
                                  color: _selectedCategory == cat.name ? Colors.white : null,
                                  fontSize: 12,
                                  fontWeight: _selectedCategory == cat.name ? FontWeight.w600 : FontWeight.normal,
                                ),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (filtered.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(40),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              _searchQuery.isNotEmpty || _selectedCategory != null
                                  ? Icons.search_off_rounded
                                  : Icons.receipt_long_rounded,
                              size: 48,
                              color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _searchQuery.isNotEmpty || _selectedCategory != null
                                  ? 'No matching transactions'
                                  : 'No transactions yet',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _searchQuery.isNotEmpty || _selectedCategory != null
                                  ? 'Try a different search'
                                  : 'Make a deposit to get started',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                                  ),
                            ),
                          ],
                        ),
                      )
                    else
                      for (var i = 0; i < filtered.length; i++)
                        slideFadeIn(
                          index: i,
                          animate: !reduceMotion,
                          child: _TransactionTile(transaction: filtered[i], currency: currency, goal: goal),
                        ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionTile extends ConsumerWidget {
  final Transaction transaction;
  final String currency;
  final Goal goal;

  const _TransactionTile({required this.transaction, required this.currency, required this.goal});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDeposit = transaction.type == 'deposit';
    final color = isDeposit ? Colors.green : Colors.red;
    final cat = GoalOptions.categoryByName(transaction.category);
    return Dismissible(
      key: Key('tx-${transaction.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.red),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete transaction?'),
            content: const Text('This action cannot be undone.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) async {
        await appDatabase.deleteTransaction(transaction.id);
        final goal = await appDatabase.getGoal(transaction.goalId ?? -1);
        if (goal != null) {
          await appDatabase.applyTransaction(goal.id, transaction.amount, isDeposit ? 'withdrawal' : 'deposit');
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(14),
        ),
        child: ListTile(
          onTap: () => showTransactionSheet(context, goal, transaction: transaction),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: cat.color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(cat.icon, color: cat.color, size: 20),
          ),
          title: Text(transaction.category),
          subtitle: Text(
            '${transaction.date.day}/${transaction.date.month}/${transaction.date.year}'
            '${transaction.note.isNotEmpty ? ' \u2022 ${transaction.note}' : ''}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '${isDeposit ? '+' : '-'}${formatCurrency(transaction.amount, currency).replaceAll('-', '')}',
              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ),
      ),
    );
  }
}
