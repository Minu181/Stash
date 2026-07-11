import 'package:file_picker/file_picker.dart';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:stash/providers/settings_provider.dart';
import 'package:stash/providers/data_providers.dart';
import 'package:stash/services/export_service.dart';
import 'package:stash/services/notifications_service.dart';
import 'package:stash/services/sound_service.dart';
import 'package:stash/theme/app_theme.dart';
import 'package:stash/widgets/animated_widgets.dart';
import 'package:stash/widgets/ui.dart';
import 'package:stash/widgets/whats_new_dialog.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  static const currencies = ['USD', 'EUR', 'GBP', 'JPY', 'PHP', 'INR'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.watch(settingsProvider.notifier);
    final reduceMotion = settings.reduceMotion;

    return Scaffold(
      appBar: const GradientAppBar(title: 'Settings', subtitle: 'Make Stash yours'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        children: [
          slideFadeIn(
            index: 0,
            animate: !reduceMotion,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Appearance', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Theme mode', style: Theme.of(context).textTheme.labelLarge),
                        const SizedBox(height: 10),
                        SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(value: 'system', label: Text('System'), icon: Icon(Icons.brightness_auto_rounded)),
                            ButtonSegment(value: 'light', label: Text('Light'), icon: Icon(Icons.light_mode_rounded)),
                            ButtonSegment(value: 'dark', label: Text('Dark'), icon: Icon(Icons.dark_mode_rounded)),
                          ],
                          selected: {settings.themeMode},
                          onSelectionChanged: (s) => notifier.setThemeMode(s.first),
                        ),
                        const SizedBox(height: 16),
                        Text('Color palette', style: Theme.of(context).textTheme.labelLarge),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 42,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: themePresets.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 8),
                            itemBuilder: (context, index) {
                              final preset = themePresets[index];
                              final selected = settings.themeId == preset.id;
                              return GestureDetector(
                                onTap: () => notifier.setThemeId(preset.id),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: selected ? preset.lightSeed.withValues(alpha: 0.15) : Theme.of(context).colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: selected ? preset.lightSeed : Theme.of(context).colorScheme.outlineVariant,
                                      width: selected ? 2.5 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 14,
                                        height: 14,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [preset.lightSeed, preset.darkSeed],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        preset.name,
                                        style: TextStyle(
                                          fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                                          fontSize: 12,
                                          color: selected ? preset.lightSeed : null,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Reduce motion', style: Theme.of(context).textTheme.labelLarge),
                            Switch(
                              value: settings.reduceMotion,
                              onChanged: (v) => notifier.setReduceMotion(v),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Sound effects', style: Theme.of(context).textTheme.labelLarge),
                            Switch(
                              value: SoundService.enabled,
                              onChanged: (v) => SoundService.setEnabled(v),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          slideFadeIn(
            index: 1,
            animate: !reduceMotion,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Region', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.attach_money_rounded),
                    title: const Text('Currency'),
                    trailing: DropdownButton<String>(
                      value: settings.currency,
                      underline: const SizedBox(),
                      items: currencies.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (v) => notifier.setCurrency(v!),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          slideFadeIn(
            index: 2,
            animate: !reduceMotion,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Permissions', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.notifications_active_rounded),
                    title: const Text('Notifications'),
                    subtitle: const Text('Allow daily savings reminders'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final granted = await NotificationsService.requestPermission();
                      if (context.mounted) {
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(granted ? 'Notification permission granted' : 'Notification permission denied'),
                            backgroundColor: granted ? Colors.green : Colors.red,
                          ),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          slideFadeIn(
            index: 3,
            animate: !reduceMotion,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Progress', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                _buildAchievementsTile(context, ref),
              ],
            ),
          ),
          const SizedBox(height: 18),
          slideFadeIn(
            index: 4,
            animate: !reduceMotion,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('App updates', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.system_update_rounded),
                    title: const Text('Check for updates'),
                    subtitle: const Text('Download & install the latest version'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push('/update'),
                  ),
                ),
                const SizedBox(height: 10),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.new_releases_rounded),
                    title: const Text("What's new"),
                    subtitle: const Text('See what changed in the latest version'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => WhatsNewDialog.show(context),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          slideFadeIn(
            index: 5,
            animate: !reduceMotion,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Data & backup', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.upload_rounded),
                    title: const Text('Export data'),
                    subtitle: const Text('Save your goals & transactions as a JSON file'),
                    onTap: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      await ExportService.exportAndShare(context);
                      if (context.mounted) {
                        messenger.showSnackBar(const SnackBar(content: Text('Export ready — share or save the file')));
                      }
                    },
                  ),
                ),
                const SizedBox(height: 10),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.download_rounded),
                    title: const Text('Import data'),
                    subtitle: const Text('Restore goals & transactions from a backup file'),
                    onTap: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final navigator = Navigator.of(context);
                      try {
                        final result = await FilePicker.platform.pickFiles(
                          type: FileType.custom,
                          allowedExtensions: ['json'],
                        );
                        if (result == null || result.files.isEmpty) return;
                        final file = File(result.files.first.path!);
                        final json = await file.readAsString();
                        final success = await ExportService.importFromJson(json);
                        if (context.mounted) {
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(success ? 'Data restored successfully' : 'Failed to restore — invalid backup file'),
                              backgroundColor: success ? Colors.green : Colors.red,
                            ),
                          );
                          if (success) {
                            navigator.pushReplacementNamed('/');
                          }
                        }
                      } catch (e) {
                        if (context.mounted) {
                          messenger.showSnackBar(
                            const SnackBar(content: Text('Error reading backup file'), backgroundColor: Colors.red),
                          );
                        }
                      }
                    },
                  ),
                ),
                const SizedBox(height: 18),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.info_outline_rounded),
                    title: const Text('About'),
                    subtitle: const Text('Version 1.0.2 — made by Ren'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push('/about'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildAchievementsTile(BuildContext context, WidgetRef ref) {
    final achievementsAsync = ref.watch(achievementsProvider);

    return achievementsAsync.when(
      loading: () => const Card(
        child: ListTile(
          leading: Icon(Icons.emoji_events_rounded),
          title: Text('Achievements'),
          subtitle: Text('Loading...'),
        ),
      ),
      error: (_, __) => const Card(
        child: ListTile(
          leading: Icon(Icons.emoji_events_rounded),
          title: Text('Achievements'),
          subtitle: Text('Could not load'),
        ),
      ),
      data: (achievements) {
        final count = achievements.length;
        return Card(
          child: ListTile(
            leading: const Icon(Icons.emoji_events_rounded),
            title: const Text('Achievements'),
            subtitle: Text('$count of 8 unlocked'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push('/achievements'),
          ),
        );
      },
    );
  }
}
