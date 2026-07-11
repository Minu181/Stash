import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stash/providers/update_provider.dart';

class UpdateAvailableDialog extends ConsumerWidget {
  const UpdateAvailableDialog({super.key});

  static Future<void> show(BuildContext context) async {
    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Update available',
      transitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (_, __, ___) => const UpdateAvailableDialog(),
      transitionBuilder: (_, animation, __, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final updateAsync = ref.watch(updateProvider);

    return updateAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (state) {
        if (state.status != UpdateStatus.available || state.info == null) {
          return const SizedBox.shrink();
        }
        final info = state.info!;
        final sizeMb = (info.downloadSize / (1024 * 1024)).toStringAsFixed(1);

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
                    color: cs.primaryContainer,
                  ),
                  child: Icon(Icons.system_update_rounded, size: 28, color: cs.primary),
                ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
                const SizedBox(height: 16),
                Text(
                  'Update available',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2, end: 0, delay: 100.ms),
                const SizedBox(height: 4),
                Text(
                  'v${info.version}  •  $sizeMb MB',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.outline),
                ).animate().fadeIn(delay: 150.ms),
                if (info.changelog.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      info.changelog,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.5),
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ).animate().fadeIn(delay: 200.ms),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      ref.read(updateProvider.notifier).download();
                    },
                    icon: const Icon(Icons.download_rounded),
                    label: const Text('Download & Install'),
                  ),
                ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1, end: 0, delay: 300.ms),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Later'),
                ).animate().fadeIn(delay: 350.ms),
              ],
            ),
          ),
        );
      },
    );
  }
}
