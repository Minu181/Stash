import 'package:flutter/material.dart';

class AchievementDef {
  final String type;
  final String label;
  final String description;
  final IconData icon;
  final Color color;

  const AchievementDef(this.type, this.label, this.description, this.icon, this.color);
}

const List<AchievementDef> achievementDefs = [
  AchievementDef(
    'first_deposit',
    'First Step',
    'Made your first deposit',
    Icons.savings_rounded,
    Color(0xFF26A69A),
  ),
  AchievementDef(
    'first_goal_completed',
    'Goal Getter',
    'Completed your first goal',
    Icons.emoji_events_rounded,
    Color(0xFFF9A825),
  ),
  AchievementDef(
    'hundred_dollar_saved',
    'Century Club',
    'Saved over \$100 total',
    Icons.stars_rounded,
    Color(0xFFAB47BC),
  ),
  AchievementDef(
    'five_hundred_saved',
    'Halfway There',
    'Saved over \$500 total',
    Icons.trending_up_rounded,
    Color(0xFF00897B),
  ),
  AchievementDef(
    'thousand_dollar_saved',
    'Big Saver',
    'Saved over \$1,000 total',
    Icons.account_balance_rounded,
    Color(0xFF1565C0),
  ),
  AchievementDef(
    'five_thousand_saved',
    'Money Bags',
    'Saved over \$5,000 total',
    Icons.monetization_on_rounded,
    Color(0xFF2E7D32),
  ),
  AchievementDef(
    'ten_thousand_saved',
    'Wealthy',
    'Saved over \$10,000 total',
    Icons.diamond_rounded,
    Color(0xFF6A1B9A),
  ),
  AchievementDef(
    'five_goals_completed',
    'High Achiever',
    'Completed 5 goals',
    Icons.military_tech_rounded,
    Color(0xFFEF6C00),
  ),
  AchievementDef(
    'ten_transactions',
    'Active Saver',
    'Made 10 transactions',
    Icons.receipt_long_rounded,
    Color(0xFF42A5F5),
  ),
  AchievementDef(
    'fifty_transactions',
    'Committed Saver',
    'Made 50 transactions',
    Icons.receipt_long_rounded,
    Color(0xFF0277BD),
  ),
  AchievementDef(
    'five_deposits',
    'Regular Saver',
    'Made 5 deposits',
    Icons.savings_rounded,
    Color(0xFF66BB6A),
  ),
  AchievementDef(
    'twentyfive_deposits',
    'Dedicated',
    'Made 25 deposits',
    Icons.workspace_premium_rounded,
    Color(0xFF7E57C2),
  ),
  AchievementDef(
    'first_withdrawal',
    'Cash Out',
    'Made your first withdrawal',
    Icons.payments_rounded,
    Color(0xFFFF7043),
  ),
  AchievementDef(
    'streak_7_days',
    'On Fire',
    '7-day saving streak',
    Icons.local_fire_department_rounded,
    Color(0xFFFF6B35),
  ),
  AchievementDef(
    'streak_14_days',
    'Committed',
    '14-day saving streak',
    Icons.local_fire_department_rounded,
    Color(0xFFFF8F00),
  ),
  AchievementDef(
    'streak_30_days',
    'Unstoppable',
    '30-day saving streak',
    Icons.whatshot_rounded,
    Color(0xFFE53935),
  ),
  AchievementDef(
    'all_goals_completed',
    'Completionist',
    'Completed every goal',
    Icons.workspace_premium_rounded,
    Color(0xFFD4AF37),
  ),
];

AchievementDef getAchievementDef(String type) {
  for (final a in achievementDefs) {
    if (a.type == type) return a;
  }
  return achievementDefs.first;
}
