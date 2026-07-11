import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stash/data/database.dart';

final goalsProvider = StreamProvider<List<Goal>>((ref) => appDatabase.watchAllGoals());

final allTransactionsProvider = StreamProvider<List<Transaction>>((ref) => appDatabase.watchTransactions());

final transactionsForGoalProvider = StreamProvider.family<List<Transaction>, int>((ref, goalId) {
  return appDatabase.watchTransactionsForGoal(goalId);
});

final streakProvider = StreamProvider<Streak>((ref) => appDatabase.watchStreak());

final achievementsProvider = StreamProvider<List<Achievement>>((ref) => appDatabase.watchAchievements());
