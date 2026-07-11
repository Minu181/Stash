import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:stash/constants.dart';

class WhatsNewDialog extends StatelessWidget {
  const WhatsNewDialog({super.key});

  static Future<void> showIfNeeded(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final lastSeen = prefs.getString('last_seen_version');
    if (lastSeen == appVersion) return;
    await prefs.setString('last_seen_version', appVersion);
    if (context.mounted) {
      await show(context);
    }
  }

  static Future<void> show(BuildContext context) async {
    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'What\'s new',
      transitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (_, __, ___) => const WhatsNewDialog(),
      transitionBuilder: (_, animation, __, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final features = [
      (Icons.image_rounded, 'Image cropping', 'Crop and adjust goal images before saving'),
      (Icons.palette_rounded, 'Custom colors', 'Pick any color with hex input for goals'),
      (Icons.emoji_events_rounded, 'More achievements', '5 new badges to unlock — 13 total'),
      (Icons.system_update_rounded, 'Update dialog', 'Get notified about new versions on launch'),
      (Icons.savings_rounded, 'Weekly summary', 'Track your savings momentum each week'),
    ];

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [cs.primary, cs.tertiary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Icon(Icons.auto_awesome_rounded, size: 28, color: Colors.white),
            ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
            const SizedBox(height: 16),
            Text(
              "What's new in $appVersion",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2, end: 0, delay: 100.ms),
            const SizedBox(height: 20),
            for (var i = 0; i < features.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: cs.primaryContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(features[i].$1, size: 18, color: cs.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            features[i].$2,
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            features[i].$3,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.outline),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: (200 + i * 80).ms).slideX(begin: 0.1, end: 0, delay: (200 + i * 80).ms),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Let\'s go!'),
              ),
            ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1, end: 0, delay: 600.ms),
          ],
        ),
      ),
    );
  }
}
