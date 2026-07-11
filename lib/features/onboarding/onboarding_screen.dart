import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:stash/data/database.dart';
import 'package:stash/features/goals/goal_options.dart';
import 'package:stash/providers/settings_provider.dart';
import 'package:stash/services/notifications_service.dart';
import 'package:stash/theme/app_theme.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _step = 0;
  static const _totalSteps = 4;

  final _goalController = TextEditingController();
  String _currency = 'USD';
  String _themeId = 'aurora';
  bool _notifGranted = false;

  @override
  void dispose() {
    _pageController.dispose();
    _goalController.dispose();
    super.dispose();
  }

  void _next() {
    if (_step < _totalSteps - 1) {
      setState(() => _step++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    final goalName = _goalController.text.trim();
    if (goalName.isNotEmpty) {
      await appDatabase.createGoal(
        GoalsCompanion.insert(
          name: goalName,
          targetAmount: 0,
          color: GoalOptions.palette.first.toARGB32(),
        ),
      );
    }
    await ref.read(settingsProvider.notifier).completeOnboarding(
          currency: _currency,
          themeId: _themeId,
        );
    if (mounted) context.go('/');
  }

  Widget _stepIcon(IconData icon) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        gradient: AppGradients.primary(context),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: cs.primary.withValues(alpha: 0.3), blurRadius: 14, offset: const Offset(0, 6)),
        ],
      ),
      child: Icon(icon, size: 48, color: Colors.white),
    ).animate().scale(duration: 500.ms, delay: 200.ms, curve: Curves.easeOutBack);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  Text(
                    '${_step + 1} / $_totalSteps',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(color: cs.outline),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _finish,
                    child: Text('Skip', style: TextStyle(color: cs.outline)),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: (_step + 1) / _totalSteps,
                  minHeight: 4,
                ),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildGoalStep(cs),
                  _buildCurrencyStep(cs),
                  _buildThemeStep(cs),
                  _buildPermissionsStep(cs),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: InkWell(
                  onTap: _next,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: AppGradients.primary(context),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: cs.primary.withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        _step == _totalSteps - 1 ? "Let's go!" : 'Next',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ).animate().scale(duration: 200.ms, curve: Curves.easeOutBack),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalStep(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(),
          _stepIcon(Icons.savings_rounded),
          const SizedBox(height: 24),
          Text(
            "What are you saving for?",
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0, delay: 300.ms),
          const SizedBox(height: 8),
          Text(
            "We'll create your first goal right away.",
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.outline),
          ).animate().fadeIn(delay: 400.ms),
          const SizedBox(height: 32),
          TextField(
            controller: _goalController,
            decoration: const InputDecoration(
              labelText: 'e.g. New laptop, Vacation, Emergency fund',
              prefixIcon: Icon(Icons.edit_rounded),
            ),
            textCapitalization: TextCapitalization.sentences,
          ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.15, end: 0, delay: 500.ms),
          const Spacer(flex: 3),
        ],
      ),
    );
  }

  Widget _buildCurrencyStep(ColorScheme cs) {
    const currencies = ['USD', 'EUR', 'GBP', 'JPY', 'PHP', 'INR'];
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(),
          _stepIcon(Icons.attach_money_rounded),
          const SizedBox(height: 24),
          Text(
            "Pick your currency",
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0, delay: 300.ms),
          const SizedBox(height: 24),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: currencies.map((c) {
              final selected = _currency == c;
              final symbols = {'USD': '\$', 'EUR': '€', 'GBP': '£', 'JPY': '¥', 'PHP': '₱', 'INR': '₹'};
              return ChoiceChip(
                label: Text('${symbols[c]} $c'),
                selected: selected,
                onSelected: (_) => setState(() => _currency = c),
              );
            }).toList(),
          ).animate().fadeIn(delay: 400.ms),
          const Spacer(flex: 3),
        ],
      ),
    );
  }

  Widget _buildThemeStep(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(),
          _stepIcon(Icons.palette_rounded),
          const SizedBox(height: 24),
          Text(
            "Choose a theme",
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0, delay: 300.ms),
          const SizedBox(height: 8),
          Text(
            "Pick a color palette for your app.",
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.outline),
          ).animate().fadeIn(delay: 400.ms),
          const SizedBox(height: 24),
          Wrap(
            spacing: 14,
            runSpacing: 14,
            children: themePresets.map((preset) {
              final selected = _themeId == preset.id;
              return GestureDetector(
                onTap: () => setState(() => _themeId = preset.id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: selected ? preset.lightSeed.withValues(alpha: 0.15) : Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: selected ? preset.lightSeed : Theme.of(context).colorScheme.outlineVariant,
                      width: selected ? 2.5 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [preset.lightSeed, preset.darkSeed],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        preset.name,
                        style: TextStyle(
                          fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                          color: selected ? preset.lightSeed : null,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ).animate().fadeIn(delay: 500.ms),
          const Spacer(flex: 3),
        ],
      ),
    );
  }

  Widget _buildPermissionsStep(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(),
          _stepIcon(Icons.notifications_active_rounded),
          const SizedBox(height: 24),
          Text(
            "Stay on track",
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0, delay: 300.ms),
          const SizedBox(height: 8),
          Text(
            "Allow notifications so we can remind you to save daily.",
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.outline),
          ).animate().fadeIn(delay: 400.ms),
          const SizedBox(height: 32),
          GestureDetector(
            onTap: () async {
              final granted = await NotificationsService.requestPermission();
              if (mounted) setState(() => _notifGranted = granted);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _notifGranted
                    ? Colors.green.withValues(alpha: 0.1)
                    : cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _notifGranted ? Colors.green : cs.outlineVariant,
                  width: _notifGranted ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _notifGranted ? Icons.check_circle_rounded : Icons.notifications_none_rounded,
                    color: _notifGranted ? Colors.green : cs.outline,
                    size: 28,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Daily reminders',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _notifGranted ? 'Notifications enabled' : 'Tap to enable notifications',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.outline),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.15, end: 0, delay: 500.ms),
          const Spacer(flex: 3),
        ],
      ),
    );
  }
}
