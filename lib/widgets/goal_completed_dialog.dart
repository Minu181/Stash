import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class GoalCompletedDialog extends StatefulWidget {
  final String goalName;
  final double amount;
  final String currencySymbol;

  const GoalCompletedDialog({
    super.key,
    required this.goalName,
    required this.amount,
    this.currencySymbol = '\$',
  });

  static Future<void> show(BuildContext context,
      {required String goalName, required double amount, String currencySymbol = '\$'}) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Goal completed',
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (_, __, ___) =>
          GoalCompletedDialog(goalName: goalName, amount: amount, currencySymbol: currencySymbol),
      transitionBuilder: (_, animation, __, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
    );
  }

  @override
  State<GoalCompletedDialog> createState() => _GoalCompletedDialogState();
}

class _GoalCompletedDialogState extends State<GoalCompletedDialog> {
  late final ConfettiController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ConfettiController(duration: const Duration(seconds: 2));
    _controller.play();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final gold = const Color(0xFFF9A825);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Stack(
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _controller,
              blastDirectionality: BlastDirectionality.explosive,
              emissionFrequency: 0.08,
              numberOfParticles: 24,
              maxBlastForce: 18,
              minBlastForce: 6,
              shouldLoop: false,
              colors: const [Color(0xFFF9A825), Colors.green, Colors.blue, Colors.pink, Colors.orange],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [gold, gold.withValues(alpha: 0.6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(color: gold.withValues(alpha: 0.3), blurRadius: 20, spreadRadius: 4),
                    ],
                  ),
                  child: const Icon(Icons.celebration_rounded, size: 40, color: Colors.white),
                )
                    .animate()
                    .scale(duration: 500.ms, curve: Curves.easeOutBack)
                    .then(delay: 200.ms)
                    .shimmer(duration: 800.ms, color: Colors.white.withValues(alpha: 0.4)),
                const SizedBox(height: 20),
                Text(
                  'Goal Reached!',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: gold,
                      ),
                ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0, delay: 300.ms),
                const SizedBox(height: 8),
                Text(
                  widget.goalName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 400.ms),
                const SizedBox(height: 4),
                Text(
                  '${widget.currencySymbol}${widget.amount.toStringAsFixed(2)} saved',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.outline),
                ).animate().fadeIn(delay: 500.ms),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: FilledButton.styleFrom(backgroundColor: gold),
                    child: const Text('Awesome!'),
                  ),
                ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.15, end: 0, delay: 600.ms),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
