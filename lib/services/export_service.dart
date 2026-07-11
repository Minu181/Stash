import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:stash/constants.dart';
import 'package:stash/data/database.dart';

class ExportService {
  static Future<String> buildJson() async {
    final settings = await appDatabase.getSettings();
    final goals = await appDatabase.getAllGoals();
    final transactions = await appDatabase.watchTransactions().first;

    final data = {
      'app': appName,
      'version': appVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'settings': settings?.toJson(),
      'goals': goals.map((g) => g.toJson()).toList(),
      'transactions': transactions.map((t) => t.toJson()).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  static Future<void> exportAndShare(BuildContext context) async {
    final json = await buildJson();
    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;
    final file = File('${dir.path}/savings_tracker_backup_$timestamp.json');
    await file.writeAsString(json);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        subject: '$appName backup',
      ),
    );
  }

  static Future<bool> importFromJson(String jsonString) async {
    try {
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      if (data['app'] != appName) return false;

      await appDatabase.transaction(() async {
        // Clear existing data
        await appDatabase.delete(appDatabase.transactions).go();
        await appDatabase.delete(appDatabase.goals).go();
        await appDatabase.delete(appDatabase.achievements).go();
        await appDatabase.delete(appDatabase.streaks).go();

        // Restore settings
        if (data['settings'] != null) {
          final s = data['settings'] as Map<String, dynamic>;
          await appDatabase.updateSettings(
            AppSettingsCompanion.insert(
              id: const Value(0),
              themeMode: Value(s['themeMode'] as String? ?? 'system'),
              currency: Value(s['currency'] as String? ?? 'USD'),
              reduceMotion: Value(s['reduceMotion'] as bool? ?? false),
              language: Value(s['language'] as String? ?? 'en'),
              themeId: Value(s['themeId'] as String? ?? 'aurora'),
              displayName: Value(s['displayName'] as String?),
              hasOnboarded: Value(s['hasOnboarded'] as bool? ?? false),
            ),
          );
        }

        // Restore streaks singleton
        await appDatabase.into(appDatabase.streaks).insert(
          StreaksCompanion.insert(
            id: const Value(0),
            currentStreak: const Value(0),
            longestStreak: const Value(0),
          ),
        );

        // Restore goals
        if (data['goals'] != null) {
          for (final g in data['goals'] as List) {
            final gm = g as Map<String, dynamic>;
            await appDatabase.into(appDatabase.goals).insert(
              GoalsCompanion.insert(
                name: gm['name'] as String,
                targetAmount: (gm['targetAmount'] as num).toDouble(),
                savedAmount: Value((gm['savedAmount'] as num?)?.toDouble() ?? 0.0),
                color: gm['color'] as int,
                icon: Value(gm['icon'] as int? ?? 0xEE51),
                imageUrl: Value(gm['imageUrl'] as String?),
                createdAt: Value(DateTime.parse(gm['createdAt'] as String)),
                deadline: Value(gm['deadline'] != null ? DateTime.parse(gm['deadline'] as String) : null),
              ),
            );
          }
        }

        // Restore transactions
        if (data['transactions'] != null) {
          for (final t in data['transactions'] as List) {
            final tm = t as Map<String, dynamic>;
            await appDatabase.into(appDatabase.transactions).insert(
              TransactionsCompanion.insert(
                goalId: Value(tm['goalId'] as int?),
                amount: (tm['amount'] as num).toDouble(),
                type: tm['type'] as String,
                note: Value(tm['note'] as String? ?? ''),
                category: Value(tm['category'] as String? ?? 'General'),
                date: Value(DateTime.parse(tm['date'] as String)),
              ),
            );
          }
        }
      });

      return true;
    } catch (e) {
      return false;
    }
  }
}
