import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stash/app.dart';
import 'package:stash/theme/app_theme.dart';
import 'package:stash/providers/settings_provider.dart';
import 'package:stash/services/notifications_service.dart';
import 'package:stash/services/reminder_prefs.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationsService.init();

  // Re-arm the daily reminder on every cold launch so it stays active across
  // app updates and any time the system clears the scheduled alarm.
  final reminderEnabled = await ReminderPrefs.getEnabled();
  if (reminderEnabled) {
    final hour = await ReminderPrefs.getHour();
    final minute = await ReminderPrefs.getMinute();
    final title = await ReminderPrefs.getTitle();
    final body = await ReminderPrefs.getBody();
    await NotificationsService.scheduleDailyReminder(hour: hour, minute: minute, title: title, body: body);
  }

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final router = ref.watch(routerProvider);
    final themeMode = switch (settings.themeMode) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };

    return MaterialApp.router(
      title: 'Stash',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(settings.themeId),
      darkTheme: AppTheme.dark(settings.themeId),
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
