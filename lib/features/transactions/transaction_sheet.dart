import 'package:flutter/material.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stash/data/database.dart';
import 'package:stash/features/goals/goal_options.dart';
import 'package:stash/providers/settings_provider.dart';
import 'package:stash/widgets/goal_completed_dialog.dart';

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
      } catch (_) {}
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
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = Color(widget.goal.color);
    final isEdit = widget.existing != null;
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
          const SizedBox(height: 16),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'deposit', label: Text('Deposit'), icon: Icon(Icons.add_rounded)),
              ButtonSegment(value: 'withdrawal', label: Text('Withdraw'), icon: Icon(Icons.remove_rounded)),
            ],
            selected: {_type},
            onSelectionChanged: (s) => setState(() => _type = s.first),
            style: SegmentedButton.styleFrom(
              selectedForegroundColor: Colors.white,
              selectedBackgroundColor: color,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Amount', prefixIcon: Icon(Icons.payments_rounded)),
          ),
          const SizedBox(height: 14),
          Text('Category', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: GoalOptions.categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final cat = GoalOptions.categories[index];
                final selected = _category == cat.name;
                return ChoiceChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(cat.icon, size: 16, color: selected ? Colors.white : cat.color),
                      const SizedBox(width: 4),
                      Text(cat.name),
                    ],
                  ),
                  selected: selected,
                  selectedColor: cat.color,
                  onSelected: (_) => setState(() => _category = cat.name),
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : null,
                    fontSize: 13,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _noteController,
            decoration: const InputDecoration(labelText: 'Note (optional)'),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: _submit,
                  icon: const Icon(Icons.check_rounded),
                  label: Text(isEdit ? 'Save changes' : 'Save transaction'),
                  style: FilledButton.styleFrom(backgroundColor: color),
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
