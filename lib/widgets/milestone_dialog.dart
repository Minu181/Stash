import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class MilestoneDialog extends StatefulWidget {
  final String goalName;
  final int percent;

  const MilestoneDialog({super.key, required this.goalName, required this.percent});

  static Future<void> show(BuildContext context, {required String goalName, required int percent}) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Milestone reached',
      transitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (_, __, ___) => MilestoneDialog(goalName: goalName, percent: percent),
      transitionBuilder: (_, animation, __, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
    );
  }

  @override
  State<MilestoneDialog> createState() => _MilestoneDialogState();
}

class _MilestoneDialogState extends State<MilestoneDialog> {
  late final ConfettiController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ConfettiController(duration: const Duration(seconds: 1));
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
    final color = switch (widget.percent) {
      25 => const Color(0xFF42A5F5),
      50 => const Color(0xFFFFA726),
      _ => const Color(0xFFAB47BC),
    };
    final emoji = switch (widget.percent) {
      25 => Icons.savings_rounded,
      50 => Icons.trending_up_rounded,
      _ => Icons.local_fire_department_rounded,
    };
    final message = switch (widget.percent) {
      25 => 'Quarter way there!',
      50 => 'Halfway to your goal!',
      _ => 'Almost there!',
    };

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Stack(
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _controller,
              blastDirectionality: BlastDirectionality.explosive,
              emissionFrequency: 0.1,
              numberOfParticles: 14,
              maxBlastForce: 12,
              minBlastForce: 4,
              shouldLoop: false,
              colors: [color, Colors.white, color.withValues(alpha: 0.5)],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [color, color.withValues(alpha: 0.6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Icon(emoji, size: 32, color: Colors.white),
                ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
                const SizedBox(height: 16),
                Text(
                  '${widget.percent}% reached!',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0, delay: 200.ms),
                const SizedBox(height: 6),
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.outline),
                ).animate().fadeIn(delay: 300.ms),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: FilledButton.styleFrom(backgroundColor: color),
                    child: const Text('Keep going!'),
                  ),
                ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1, end: 0, delay: 400.ms),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
