import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:stash/providers/settings_provider.dart';
import 'package:stash/theme/app_theme.dart';
import 'package:stash/widgets/ui.dart';

class ThemePage extends ConsumerWidget {
  const ThemePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.watch(settingsProvider.notifier);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: GradientAppBar(
        title: 'Theme',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Light', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: cs.outline)),
          const SizedBox(height: 10),
          _ThemeGrid(
            presets: lightThemePresets,
            selectedId: settings.themeId,
            onSelect: notifier.setThemeId,
          ),
          const SizedBox(height: 24),
          Text('Dark', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: cs.outline)),
          const SizedBox(height: 10),
          _ThemeGrid(
            presets: darkThemePresets,
            selectedId: settings.themeId,
            onSelect: notifier.setThemeId,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _ThemeGrid extends StatelessWidget {
  final List<ThemePreset> presets;
  final String selectedId;
  final ValueChanged<String> onSelect;

  const _ThemeGrid({
    required this.presets,
    required this.selectedId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: presets.map((preset) {
        final selected = selectedId == preset.id;
        return GestureDetector(
          onTap: () => onSelect(preset.id),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 90,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: selected
                  ? preset.seed.withValues(alpha: 0.12)
                  : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? preset.seed : Theme.of(context).colorScheme.outlineVariant,
                width: selected ? 2.5 : 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: preset.seed,
                    shape: BoxShape.circle,
                    boxShadow: selected
                        ? [BoxShadow(color: preset.seed.withValues(alpha: 0.4), blurRadius: 10)]
                        : null,
                  ),
                  child: selected
                      ? const Icon(Icons.check_rounded, size: 20, color: Colors.white)
                      : null,
                ),
                const SizedBox(height: 8),
                Text(
                  preset.name,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 12,
                    color: selected ? preset.seed : null,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
