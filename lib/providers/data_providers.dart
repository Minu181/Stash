import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stash/data/database.dart';

final goalsProvider = StreamProvider<List<Goal>>((ref) => appDatabase.watchAllGoals());

final allTransactionsProvider = StreamProvider<List<Transaction>>((ref) => appDatabase.watchTransactions());

final transactionsForGoalProvider = StreamProvider.family<List<Transaction>, int>((ref, goalId) {
  return appDatabase.watchTransactionsForGoal(goalId);
});

final streakProvider = StreamProvider<Streak>((ref) => appDatabase.watchStreak());

final achievementsProvider = StreamProvider<List<Achievement>>((ref) => appDatabase.watchAchievements());

final weeklySavingsProvider = Provider<AsyncValue<double>>((ref) {
  final txAsync = ref.watch(allTransactionsProvider);
  return txAsync.whenData((transactions) {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    return transactions
        .where((t) => t.type == 'deposit' && t.date.isAfter(weekAgo))
        .fold<double>(0, (sum, t) => sum + t.amount);
  });
});
