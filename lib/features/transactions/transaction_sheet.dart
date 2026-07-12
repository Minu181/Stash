import 'package:flutter/material.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stash/data/database.dart';
import 'package:stash/features/goals/goal_options.dart';
import 'package:stash/providers/settings_provider.dart';
import 'package:stash/widgets/goal_completed_dialog.dart';
import 'package:stash/widgets/milestone_dialog.dart';

class TransactionSheet extends ConsumerStatefulWidget {
  final Goal goal;
  final String initialType;
  final Transaction? existing;

  const TransactionSheet({
    super.key,
    required this.goal,
    this.initialType = 'deposit',
    this.existing,
  });

  @override
  ConsumerState<TransactionSheet> createState() => _TransactionSheetState();
}

class _TransactionSheetState extends ConsumerState<TransactionSheet> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  late String _type;
  late String _category;
  final _symbols = {'USD': '\$', 'EUR': '€', 'GBP': '£', 'JPY': '¥', 'PHP': '₱', 'INR': '₹'};

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _amountController.text = existing.amount.toString();
      _noteController.text = existing.note;
      _type = existing.type;
      _category = existing.category;
    } else {
      _type = widget.initialType;
      _category = GoalOptions.categories.first.name;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_amountController.text.replaceAll(',', ''));
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid amount')),
      );
      return;
    }

    final wasCompleted = widget.goal.savedAmount >= widget.goal.targetAmount;
    final existing = widget.existing;

    if (existing != null) {
      // Reverse the old transaction's effect, then apply the new one.
      await appDatabase.applyTransaction(
        widget.goal.id,
        existing.amount,
        existing.type == 'deposit' ? 'withdrawal' : 'deposit',
      );
      final updated = existing.copyWith(
        amount: amount,
        type: _type,
        note: _noteController.text.trim(),
        category: _category,
      );
      await appDatabase.updateTransaction(updated);
      await appDatabase.applyTransaction(widget.goal.id, amount, _type);
    } else {
      await appDatabase.createTransaction(
        TransactionsCompanion.insert(
          goalId: Value(widget.goal.id),
          amount: amount,
          type: _type,
          note: Value(_noteController.text.trim()),
          category: Value(_category),
        ),
      );
      await appDatabase.applyTransaction(widget.goal.id, amount, _type);
    }

    final updatedGoal = await appDatabase.getGoal(widget.goal.id);
    final nowCompleted = updatedGoal != null &&
        updatedGoal.savedAmount >= updatedGoal.targetAmount &&
        !wasCompleted;

    if (_type == 'deposit') {
      try {
        await appDatabase.updateStreak();
        await appDatabase.checkAndUnlockAchievements(goalId: widget.goal.id);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating progress: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }

    if (mounted) {
      Navigator.of(context).pop();

      if (nowCompleted && _type == 'deposit') {
        final currency = ref.read(settingsProvider).currency;
        GoalCompletedDialog.show(
          context,
          goalName: widget.goal.name,
          amount: updatedGoal.savedAmount,
          currencySymbol: _symbols[currency] ?? '\$',
        );
      } else if (_type == 'deposit' && updatedGoal != null && updatedGoal.targetAmount > 0) {
        final oldProgress = widget.goal.savedAmount / widget.goal.targetAmount;
        final newProgress = updatedGoal.savedAmount / updatedGoal.targetAmount;
        for (final milestone in [0.25, 0.50, 0.75]) {
          if (oldProgress < milestone && newProgress >= milestone) {
            if (mounted) {
              MilestoneDialog.show(
                context,
                goalName: widget.goal.name,
                percent: (milestone * 100).toInt(),
              );
            }
            break;
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = Color(widget.goal.color);
    final isEdit = widget.existing != null;
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isEdit ? 'Edit transaction' : 'Add to ${widget.goal.name}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 18),
          Container(
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.all(4),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _type = 'deposit'),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _type == 'deposit' ? color : Colors.transparent,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_rounded, size: 18, color: _type == 'deposit' ? Colors.white : cs.onSurface),
                          const SizedBox(width: 6),
                          Text(
                            'Deposit',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: _type == 'deposit' ? Colors.white : cs.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _type = 'withdrawal'),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _type == 'withdrawal' ? color : Colors.transparent,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.remove_rounded, size: 18, color: _type == 'withdrawal' ? Colors.white : cs.onSurface),
                          const SizedBox(width: 6),
                          Text(
                            'Withdraw',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: _type == 'withdrawal' ? Colors.white : cs.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: '0.00',
              prefixIcon: Icon(Icons.payments_rounded, color: color),
              prefixText: '${_symbols[ref.watch(settingsProvider).currency] ?? '\$'} ',
              prefixStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: color),
            ),
          ),
          const SizedBox(height: 18),
          Text('Category', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: GoalOptions.categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final cat = GoalOptions.categories[index];
                final selected = _category == cat.name;
                return GestureDetector(
                  onTap: () => setState(() => _category = cat.name),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? cat.color : cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected ? cat.color : cs.outlineVariant,
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(cat.icon, size: 16, color: selected ? Colors.white : cat.color),
                        const SizedBox(width: 6),
                        Text(
                          cat.name,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                            color: selected ? Colors.white : cs.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _noteController,
            decoration: const InputDecoration(hintText: 'Note (optional)', prefixIcon: Icon(Icons.notes_rounded)),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: cs.outlineVariant),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color, HSLColor.fromAHSL(
                        1.0,
                        (HSLColor.fromColor(color).hue + 20) % 360,
                        (HSLColor.fromColor(color).saturation * 0.85).clamp(0.0, 1.0),
                        0.48,
                      ).toColor()],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: FilledButton.icon(
                    onPressed: _submit,
                    icon: const Icon(Icons.check_rounded, color: Colors.white),
                    label: Text(
                      isEdit ? 'Save changes' : 'Save transaction',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ).animate().fadeIn(duration: const Duration(milliseconds: 280)).scale(
            begin: const Offset(0.96, 0.96),
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutBack,
          ),
    );
  }
}

void showTransactionSheet(BuildContext context, Goal goal,
    {String initialType = 'deposit', Transaction? transaction}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => TransactionSheet(
      goal: goal,
      initialType: initialType,
      existing: transaction,
    ),
  );
}
