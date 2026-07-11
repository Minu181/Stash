import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stash/providers/update_provider.dart';
import 'package:stash/widgets/ui.dart';

class UpdatePage extends ConsumerWidget {
  const UpdatePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final updateAsync = ref.watch(updateProvider);

    return Scaffold(
      appBar: const GradientAppBar(title: 'App Updates', subtitle: 'Keep Stash up to date'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          updateAsync.when(
            loading: () => const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
            error: (e, _) => Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    Text('Update check failed', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text(e.toString(), style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () => ref.invalidate(updateProvider),
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Try again'),
                    ),
                  ],
                ),
              ),
            ),
            data: (state) {
              switch (state.status) {
                case UpdateStatus.idle:
                case UpdateStatus.checking:
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Icon(Icons.check_circle_outline_rounded, color: Theme.of(context).colorScheme.primary, size: 48),
                          const SizedBox(height: 16),
                          Text('You\'re up to date', style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 8),
                          Text(
                            'Current version is the latest available',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.outline),
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: () => ref.invalidate(updateProvider),
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Check again'),
                          ),
                        ],
                      ),
                    ),
                  );
                case UpdateStatus.available:
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(Icons.system_update_rounded, color: Theme.of(context).colorScheme.primary),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Update available', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                                    Text('v${state.info!.version}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.outline)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (state.info!.changelog.isNotEmpty) ...[
                            const SizedBox(height: 20),
                            Text('Changelog', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Text(
                                state.info!.changelog,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.6),
                              ),
                            ),
                          ],
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: () => ref.read(updateProvider.notifier).download(),
                              icon: const Icon(Icons.download_rounded),
                              label: const Text('Download & Install'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                case UpdateStatus.downloading:
                  final received = state.receivedBytes / (1024 * 1024);
                  final total = state.totalBytes / (1024 * 1024);
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5)),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Downloading...', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                                    Text(
                                      '${(state.progress * 100).toStringAsFixed(1)}% — ${received.toStringAsFixed(1)} MB / ${total.toStringAsFixed(1)} MB',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.outline),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(value: state.progress, minHeight: 10),
                          ),
                        ],
                      ),
                    ),
                  );
                case UpdateStatus.downloaded:
                  return Card(
                    child: ListTile(
                      leading: Icon(Icons.check_circle_rounded, color: Theme.of(context).colorScheme.primary),
                      title: const Text('Download complete'),
                      subtitle: const Text('Opening installer...'),
                    ),
                  );
                case UpdateStatus.error:
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          const Icon(Icons.error_outline_rounded, color: Colors.red, size: 48),
                          const SizedBox(height: 16),
                          Text('Update failed', style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 8),
                          Text(state.error ?? 'Unknown error', style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: () => ref.invalidate(updateProvider),
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Try again'),
                          ),
                        ],
                      ),
                    ),
                  );
              }
            },
          ),
        ],
      ),
    );
  }
}
