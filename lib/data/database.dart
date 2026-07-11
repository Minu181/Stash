import 'dart:developer';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:stash/data/achievements.dart';
import 'package:stash/data/tables.dart';
import 'package:stash/services/notifications_service.dart';

part 'database.g.dart';

@DriftDatabase(tables: [Goals, Transactions, Streaks, Achievements, AppSettings])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openDb());

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await into(appSettings).insert(
            AppSettingsCompanion.insert(
              id: const Value(0),
              themeMode: const Value('system'),
              currency: const Value('USD'),
              reduceMotion: const Value(false),
            ),
          );
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.alterTable(TableMigration(goals, newColumns: [goals.imageUrl]));
          }
          if (from < 3) {
            await m.alterTable(TableMigration(appSettings, newColumns: [
              appSettings.language,
              appSettings.themeId,
              appSettings.displayName,
              appSettings.hasOnboarded,
            ]));
          }
          if (from < 4) {
            await m.createTable(streaks);
            await m.createTable(achievements);
            await into(streaks).insert(
              StreaksCompanion.insert(
                id: const Value(0),
                currentStreak: const Value(0),
                longestStreak: const Value(0),
              ),
            );
          }
        },
      );

  static QueryExecutor _openDb() {
    if (kIsWeb) {
      return driftDatabase(
        name: 'savings_tracker',
        web: DriftWebOptions(
          sqlite3Wasm: Uri.parse('sqlite3.wasm'),
          driftWorker: Uri.parse('drift_worker.js'),
        ),
      );
    }
    return driftDatabase(name: 'savings_tracker');
  }

  // ---- Goals ----
  Future<List<Goal>> getAllGoals() => select(goals).get();
  Stream<List<Goal>> watchAllGoals() => (select(goals)..orderBy([(g) => OrderingTerm.desc(g.createdAt)])).watch();

  Future<Goal?> getGoal(int id) => (select(goals)..where((g) => g.id.equals(id))).getSingleOrNull();

  Future<int> createGoal(GoalsCompanion entry) => into(goals).insert(entry);

  Future<bool> updateGoal(Goal goal) => update(goals).replace(goal);

  Future<int> deleteGoal(int id) {
    (delete(transactions)..where((t) => t.goalId.equals(id))).go();
    return (delete(goals)..where((g) => g.id.equals(id))).go();
  }

  // ---- Transactions ----
  Future<List<Transaction>> getTransactionsForGoal(int goalId) =>
      (select(transactions)..where((t) => t.goalId.equals(goalId))..orderBy([(t) => OrderingTerm.desc(t.date)])).get();

  Stream<List<Transaction>> watchTransactions() =>
      (select(transactions)..orderBy([(t) => OrderingTerm.desc(t.date)])).watch();

  Stream<List<Transaction>> watchTransactionsForGoal(int goalId) =>
      (select(transactions)..where((t) => t.goalId.equals(goalId))..orderBy([(t) => OrderingTerm.desc(t.date)])).watch();

  Future<int> createTransaction(TransactionsCompanion entry) => into(transactions).insert(entry);

  Future<bool> updateTransaction(Transaction transaction) => update(transactions).replace(transaction);

  Future<int> deleteTransaction(int id) => (delete(transactions)..where((t) => t.id.equals(id))).go();

  // ---- Settings ----
  Future<AppSetting?> getSettings() => (select(appSettings)..where((s) => s.id.equals(0))).getSingleOrNull();

  Future<void> updateSettings(AppSettingsCompanion entry) async {
    await into(appSettings).insertOnConflictUpdate(entry);
  }

  // Deposit/withdraw also updates the goal's savedAmount
  Future<void> applyTransaction(int goalId, double amount, String type) async {
    final goal = await getGoal(goalId);
    if (goal == null) return;
    final delta = type == 'deposit' ? amount : -amount;
    final newSaved = (goal.savedAmount + delta).clamp(0.0, goal.targetAmount * 100);
    await updateGoal(goal.copyWith(savedAmount: newSaved));
  }

  // ---- Streaks ----
  Stream<Streak> watchStreak() =>
      (select(streaks)..where((s) => s.id.equals(0))).watchSingle();

  Future<Streak> getStreak() =>
      (select(streaks)..where((s) => s.id.equals(0))).getSingle();

  Future<void> updateStreak() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final current = await getStreak();
    final last = current.lastDepositDate;
    final lastDay = last != null ? DateTime(last.year, last.month, last.day) : null;

    int newStreak;
    if (lastDay == null) {
      newStreak = 1;
    } else {
      final diff = today.difference(lastDay).inDays;
      if (diff == 0) {
        newStreak = current.currentStreak;
      } else if (diff == 1) {
        newStreak = current.currentStreak + 1;
      } else {
        newStreak = 1;
      }
    }

    final newLongest = newStreak > current.longestStreak ? newStreak : current.longestStreak;

    await into(streaks).insertOnConflictUpdate(
      StreaksCompanion.insert(
        id: const Value(0),
        currentStreak: Value(newStreak),
        longestStreak: Value(newLongest),
        lastDepositDate: Value(today),
      ),
    );
  }

  // ---- Achievements ----
  Stream<List<Achievement>> watchAchievements() => select(achievements).watch();

  Future<List<Achievement>> getAchievements() => select(achievements).get();

  Future<void> unlockAchievement(String badgeType, {int? goalId}) async {
    final existing = await (select(achievements)
          ..where((a) => a.badgeType.equals(badgeType)))
        .getSingleOrNull();
    if (existing != null) return;
    await into(achievements).insert(
      AchievementsCompanion.insert(
        badgeType: badgeType,
        goalId: Value(goalId),
      ),
    );
    final def = achievementDefs.firstWhere((d) => d.type == badgeType, orElse: () => achievementDefs.first);
    await NotificationsService.showAchievementUnlocked(def.label);
  }

  Future<void> checkAndUnlockAchievements({int? goalId}) async {
    final allGoals = await getAllGoals();
    final allTransactions = await (select(transactions).get());
    final goalCount = allGoals.length;
    final completedCount = allGoals.where((g) => g.savedAmount >= g.targetAmount).length;
    final totalSaved = allGoals.fold<double>(0, (s, g) => s + g.savedAmount);
    final streak = await getStreak();

    if (allTransactions.isNotEmpty) {
      await unlockAchievement('first_deposit');
    }
    if (completedCount >= 1) {
      await unlockAchievement('first_goal_completed');
    }
    if (totalSaved >= 100) {
      await unlockAchievement('hundred_dollar_saved');
    }
    if (completedCount >= 5) {
      await unlockAchievement('five_goals_completed');
    }
    if (allTransactions.length >= 10) {
      await unlockAchievement('ten_transactions');
    }
    if (streak.currentStreak >= 7) {
      await unlockAchievement('streak_7_days');
    }
    if (streak.currentStreak >= 30) {
      await unlockAchievement('streak_30_days');
    }
    if (goalCount > 0 && completedCount == goalCount) {
      await unlockAchievement('all_goals_completed');
    }
  }
}

final appDatabase = AppDatabase();

Future<void> initDatabase() async {
  log('Savings Tracker database initialised.');
}
