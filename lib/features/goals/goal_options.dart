import 'package:flutter/material.dart';

class CategoryOption {
  final String name;
  final IconData icon;
  final Color color;

  const CategoryOption(this.name, this.icon, this.color);
}

class GoalOptions {
  static const List<Color> palette = [
    Color(0xFF6750A4),
    Color(0xFF03DAC6),
    Color(0xFFEF6C00),
    Color(0xFFD81B60),
    Color(0xFF00897B),
    Color(0xFF3949AB),
    Color(0xFFE53935),
    Color(0xFF43A047),
    Color(0xFF8E24AA),
    Color(0xFFF9A825),
    Color(0xFF1A237E),
    Color(0xFFFF7043),
    Color(0xFF9CCC65),
    Color(0xFF00ACC1),
    Color(0xFF6D4C41),
    Color(0xFF5C6BC0),
  ];

  static const List<IconData> icons = [
    Icons.savings_rounded,
    Icons.flight_rounded,
    Icons.home_rounded,
    Icons.directions_car_rounded,
    Icons.school_rounded,
    Icons.phone_android_rounded,
    Icons.beach_access_rounded,
    Icons.health_and_safety_rounded,
    Icons.camera_alt_rounded,
    Icons.card_giftcard_rounded,
    Icons.laptop_rounded,
    Icons.pets_rounded,
    Icons.fitness_center_rounded,
    Icons.restaurant_rounded,
    Icons.shopping_cart_rounded,
    Icons.movie_rounded,
    Icons.music_note_rounded,
    Icons.coffee_rounded,
    Icons.train_rounded,
    Icons.flight_takeoff_rounded,
    Icons.brush_rounded,
    Icons.code_rounded,
    Icons.build_rounded,
    Icons.eco_rounded,
    Icons.diamond_rounded,
    Icons.workspace_premium_rounded,
    Icons.favorite_rounded,
    Icons.star_rounded,
    Icons.local_grocery_store_rounded,
    Icons.account_balance_rounded,
  ];

  static const List<CategoryOption> categories = [
    CategoryOption('General', Icons.category_rounded, Color(0xFF78909C)),
    CategoryOption('Food', Icons.restaurant_rounded, Color(0xFFFF7043)),
    CategoryOption('Transport', Icons.directions_car_rounded, Color(0xFF42A5F5)),
    CategoryOption('Bills', Icons.receipt_long_rounded, Color(0xFFEF5350)),
    CategoryOption('Shopping', Icons.shopping_bag_rounded, Color(0xFFAB47BC)),
    CategoryOption('Health', Icons.health_and_safety_rounded, Color(0xFF66BB6A)),
    CategoryOption('Education', Icons.school_rounded, Color(0xFF5C6BC0)),
    CategoryOption('Entertainment', Icons.movie_rounded, Color(0xFFEC407A)),
    CategoryOption('Savings', Icons.savings_rounded, Color(0xFF26A69A)),
    CategoryOption('Gift', Icons.card_giftcard_rounded, Color(0xFFFFA726)),
    CategoryOption('Other', Icons.more_horiz_rounded, Color(0xFFBDBDBD)),
  ];

  static String colorToHex(Color c) => '#${c.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase()}';

  static IconData iconForCodePoint(int cp) {
    for (final i in icons) {
      if (i.codePoint == cp) return i;
    }
    return Icons.savings_rounded;
  }

  static CategoryOption categoryByName(String name) {
    for (final c in categories) {
      if (c.name == name) return c;
    }
    return categories.first;
  }
}
