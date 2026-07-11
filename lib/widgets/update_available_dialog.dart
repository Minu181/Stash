import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stash/providers/update_provider.dart';

class UpdateAvailableDialog extends ConsumerStatefulWidget {
  const UpdateAvailableDialog({super.key});

  static Future<void> show(BuildContext context) async {
    await showGeneralDialog(
      context: context,
      barrierDismissible: false,
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
  ConsumerState<UpdateAvailableDialog> createState() => _UpdateAvailableDialogState();
}

class _UpdateAvailableDialogState extends ConsumerState<UpdateAvailableDialog> {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final updateAsync = ref.watch(updateProvider);

    return updateAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (state) {
        if (state.status == UpdateStatus.idle || state.status == UpdateStatus.checking) {
          return const SizedBox.shrink();
        }

        if (state.status == UpdateStatus.available && state.info != null) {
          return _buildAvailableDialog(context, cs, state);
        }

        if (state.status == UpdateStatus.downloading) {
          return _buildDownloadingDialog(context, cs, state);
        }

        if (state.status == UpdateStatus.downloaded) {
          return _buildDownloadedDialog(context, cs);
        }

        if (state.status == UpdateStatus.error) {
          return _buildErrorDialog(context, cs, state);
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildAvailableDialog(BuildContext context, ColorScheme cs, UpdateState state) {
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
  }

  Widget _buildDownloadingDialog(BuildContext context, ColorScheme cs, UpdateState state) {
    final pct = (state.progress * 100).toInt();
    final receivedMb = (state.receivedBytes / (1024 * 1024)).toStringAsFixed(1);
    final totalMb = (state.totalBytes / (1024 * 1024)).toStringAsFixed(1);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 56,
              height: 56,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: state.progress > 0 ? state.progress : null,
                    strokeWidth: 5,
                    color: cs.primary,
                    backgroundColor: cs.surfaceContainerHighest,
                  ),
                  Center(
                    child: state.progress > 0
                        ? Text(
                            '$pct%',
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: cs.primary,
                                ),
                          )
                        : SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2.5, color: cs.primary),
                          ),
                  ),
                ],
              ),
            ).animate().scale(duration: 300.ms, curve: Curves.easeOutBack),
            const SizedBox(height: 16),
            Text(
              'Downloading update...',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              state.totalBytes > 0 ? '$receivedMb MB / $totalMb MB' : 'Starting download...',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.outline),
            ),
            const SizedBox(height: 20),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: state.progress > 0 ? state.progress : null,
                minHeight: 8,
                color: cs.primary,
                backgroundColor: cs.surfaceContainerHighest,
              ),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                ref.read(updateProvider.notifier).cancelDownload();
              },
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDownloadedDialog(BuildContext context, ColorScheme cs) {
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
                color: Colors.green.withValues(alpha: 0.12),
              ),
              child: const Icon(Icons.check_rounded, size: 28, color: Colors.green),
            ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
            const SizedBox(height: 16),
            Text(
              'Download complete',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Opening installer...',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.outline),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorDialog(BuildContext context, ColorScheme cs, UpdateState state) {
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
                color: cs.errorContainer,
              ),
              child: Icon(Icons.error_outline_rounded, size: 28, color: cs.error),
            ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
            const SizedBox(height: 16),
            Text(
              'Download failed',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              state.error ?? 'An unexpected error occurred.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.outline),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  ref.read(updateProvider.notifier).retry();
                },
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}
