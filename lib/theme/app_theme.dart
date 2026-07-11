import 'package:flutter/material.dart';

class ThemePreset {
  final String id;
  final String name;
  final Color lightSeed;
  final Color darkSeed;

  const ThemePreset({
    required this.id,
    required this.name,
    required this.lightSeed,
    required this.darkSeed,
  });
}

const themePresets = [
  ThemePreset(id: 'aurora', name: 'Aurora', lightSeed: Color(0xFF6750A4), darkSeed: Color(0xFFD0BCFF)),
  ThemePreset(id: 'ocean', name: 'Ocean', lightSeed: Color(0xFF1565C0), darkSeed: Color(0xFF90CAF9)),
  ThemePreset(id: 'sunset', name: 'Sunset', lightSeed: Color(0xFFE65100), darkSeed: Color(0xFFFFAB91)),
  ThemePreset(id: 'forest', name: 'Forest', lightSeed: Color(0xFF2E7D32), darkSeed: Color(0xFFA5D6A7)),
  ThemePreset(id: 'mono', name: 'Mono', lightSeed: Color(0xFF5C5C5C), darkSeed: Color(0xFFBDBDBD)),
  ThemePreset(id: 'rose', name: 'Rose', lightSeed: Color(0xFFC62828), darkSeed: Color(0xFFEF9A9A)),
  ThemePreset(id: 'lavender', name: 'Lavender', lightSeed: Color(0xFF7E57C2), darkSeed: Color(0xFFCE93D8)),
  ThemePreset(id: 'teal', name: 'Teal', lightSeed: Color(0xFF00897B), darkSeed: Color(0xFF80CBC4)),
  ThemePreset(id: 'coral', name: 'Coral', lightSeed: Color(0xFFEF6C00), darkSeed: Color(0xFFFFCC80)),
  ThemePreset(id: 'midnight', name: 'Midnight', lightSeed: Color(0xFF283593), darkSeed: Color(0xFF9FA8DA)),
  ThemePreset(id: 'cherry', name: 'Cherry', lightSeed: Color(0xFFAD1457), darkSeed: Color(0xFFF48FB1)),
  ThemePreset(id: 'emerald', name: 'Emerald', lightSeed: Color(0xFF00695C), darkSeed: Color(0xFF80CBC4)),
  ThemePreset(id: 'slate', name: 'Slate', lightSeed: Color(0xFF455A64), darkSeed: Color(0xFFB0BEC5)),
];

ThemePreset presetById(String id) =>
    themePresets.firstWhere((p) => p.id == id, orElse: () => themePresets.first);

/// Gradient helpers that stay in harmony with the active color scheme.
class AppGradients {
  /// Primary brand gradient derived from the active scheme's primary → tertiary.
  static LinearGradient primary(BuildContext context, {GradientDirection direction = GradientDirection.diagonal}) {
    final cs = Theme.of(context).colorScheme;
    return LinearGradient(
      begin: direction.begin,
      end: direction.end,
      colors: [cs.primary, cs.tertiary],
      stops: const [0.0, 1.0],
    );
  }

  /// Vibrant gradient — mixes the primary with a brighter complementary shade
  /// so it stays rich in both light and dark modes.
  static LinearGradient vibrant(BuildContext context, {GradientDirection direction = GradientDirection.diagonal}) {
    final cs = Theme.of(context).colorScheme;
    final hsl = HSLColor.fromColor(cs.primary);
    final bright = HSLColor.fromAHSL(
      1.0,
      (hsl.hue + 25) % 360,
      (hsl.saturation * 0.9).clamp(0.0, 1.0),
      Theme.of(context).brightness == Brightness.light ? 0.48 : 0.55,
    ).toColor();
    return LinearGradient(
      begin: direction.begin,
      end: direction.end,
      colors: [cs.primary, bright],
      stops: const [0.0, 1.0],
    );
  }

  /// Subtle gradient for chips / small accents.
  static LinearGradient soft(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return LinearGradient(
      colors: [cs.primary.withValues(alpha: 0.85), cs.tertiary.withValues(alpha: 0.85)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }
}

enum GradientDirection { diagonal, vertical, horizontal }

extension _GradientBeginEnd on GradientDirection {
  AlignmentGeometry get begin => switch (this) {
        GradientDirection.vertical => Alignment.topCenter,
        GradientDirection.horizontal => Alignment.centerLeft,
        _ => Alignment.topLeft,
      };
  AlignmentGeometry get end => switch (this) {
        GradientDirection.vertical => Alignment.bottomCenter,
        GradientDirection.horizontal => Alignment.centerRight,
        _ => Alignment.bottomRight,
      };
}

class AppTheme {
  static TextTheme _textTheme(ColorScheme cs) => TextTheme(
        displayLarge: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: -0.5),
        displayMedium: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: -0.5),
        displaySmall: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: -0.25),
        headlineLarge: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: -0.25),
        headlineMedium: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: -0.25),
        headlineSmall: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: -0.15),
        titleLarge: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: -0.1),
        titleMedium: const TextStyle(fontWeight: FontWeight.w600, letterSpacing: -0.1),
        titleSmall: const TextStyle(fontWeight: FontWeight.w600),
        bodyLarge: const TextStyle(fontWeight: FontWeight.w400, letterSpacing: 0.1),
        bodyMedium: const TextStyle(fontWeight: FontWeight.w400, letterSpacing: 0.2),
        bodySmall: const TextStyle(fontWeight: FontWeight.w400, letterSpacing: 0.2),
        labelLarge: const TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.4),
        labelMedium: const TextStyle(fontWeight: FontWeight.w500, letterSpacing: 0.3),
        labelSmall: const TextStyle(fontWeight: FontWeight.w500, letterSpacing: 0.5),
      );

  static ThemeData light([String themeId = 'aurora']) {
    final seed = presetById(themeId).lightSeed;
    final cs = ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.light).copyWith(
      primary: seed,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: 'Poppins',
      colorScheme: cs,
      scaffoldBackgroundColor: const Color(0xFFF6F6FC),
      textTheme: _textTheme(cs),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: cs.onSurface,
        titleTextStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: -0.2),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: cs.surface,
        surfaceTintColor: cs.surfaceTint,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.55),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: cs.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        showDragHandle: true,
        dragHandleColor: cs.outline,
        backgroundColor: cs.surface,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: cs.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        backgroundColor: cs.inverseSurface,
        contentTextStyle: TextStyle(color: cs.onInverseSurface, fontWeight: FontWeight.w500),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        elevation: 0,
        indicatorColor: cs.secondaryContainer,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final active = states.contains(WidgetState.selected);
          return TextStyle(
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            fontSize: 12,
            color: active ? cs.onSecondaryContainer : cs.onSurfaceVariant,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final active = states.contains(WidgetState.selected);
          return IconThemeData(color: active ? cs.onSecondaryContainer : cs.onSurfaceVariant, size: 24);
        }),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        labelStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
      listTileTheme: const ListTileThemeData(contentPadding: EdgeInsets.symmetric(horizontal: 16)),
      dividerTheme: DividerThemeData(color: cs.outlineVariant.withValues(alpha: 0.5), thickness: 1),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: cs.primary),
    );
  }

  static ThemeData dark([String themeId = 'aurora']) {
    final seed = presetById(themeId).darkSeed;
    final cs = ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.dark).copyWith(
      primary: seed,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: 'Poppins',
      colorScheme: cs,
      scaffoldBackgroundColor: const Color(0xFF0E0E16),
      textTheme: _textTheme(cs),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: cs.onSurface,
        titleTextStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: -0.2),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: cs.surface,
        surfaceTintColor: cs.surfaceTint,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.5),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: cs.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        showDragHandle: true,
        dragHandleColor: cs.outline,
        backgroundColor: cs.surface,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: cs.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        backgroundColor: cs.inverseSurface,
        contentTextStyle: TextStyle(color: cs.onInverseSurface, fontWeight: FontWeight.w500),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        elevation: 0,
        indicatorColor: cs.secondaryContainer,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final active = states.contains(WidgetState.selected);
          return TextStyle(
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            fontSize: 12,
            color: active ? cs.onSecondaryContainer : cs.onSurfaceVariant,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final active = states.contains(WidgetState.selected);
          return IconThemeData(color: active ? cs.onSecondaryContainer : cs.onSurfaceVariant, size: 24);
        }),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        labelStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
      listTileTheme: const ListTileThemeData(contentPadding: EdgeInsets.symmetric(horizontal: 16)),
      dividerTheme: DividerThemeData(color: cs.outlineVariant.withValues(alpha: 0.5), thickness: 1),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: cs.primary),
    );
  }
}
