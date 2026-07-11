import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:stash/constants.dart';
import 'package:stash/widgets/ui.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  Future<void> _copyDiscord(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: appDiscord));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Copied $appDiscord to clipboard')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: const GradientAppBar(title: 'About'),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [cs.primary, cs.tertiary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.savings_rounded, size: 44, color: Colors.white),
            ),
          )
              .animate()
              .scale(duration: 500.ms, delay: 100.ms, curve: Curves.easeOutBack)
              .then(delay: 200.ms)
              .shimmer(duration: 800.ms, color: Colors.white.withValues(alpha: 0.25)),
          const SizedBox(height: 16),
          Center(
            child: Text(appName, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0, delay: 300.ms),
          Center(
            child: Text(
              'Version $appVersion',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.outline),
            ),
          ).animate().fadeIn(delay: 400.ms),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Made by $appAuthor',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text('A personal savings tracker, built with Flutter.'),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.discord_rounded),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Discord', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: cs.outline)),
                            const SizedBox(height: 2),
                            Text(appDiscord, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => _copyDiscord(context),
                        icon: const Icon(Icons.copy_rounded),
                        label: const Text('Copy'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1, end: 0, delay: 500.ms),
          const SizedBox(height: 16),
          Card(
            child: const ListTile(
              leading: Icon(Icons.cloud_off_rounded),
              title: Text('Works fully offline'),
              subtitle: Text('Your data stays on your device. No account required.'),
            ),
          ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1, end: 0, delay: 600.ms),
        ],
      ),
    );
  }
}
