import 'package:flutter/material.dart';

class ThemePreset {
  final String id;
  final String name;
  final Color seed;
  final bool isDark;

  const ThemePreset({
    required this.id,
    required this.name,
    required this.seed,
    this.isDark = false,
  });
}

const lightThemePresets = [
  ThemePreset(id: 'indigo', name: 'Indigo', seed: Color(0xFF5C6BC0)),
  ThemePreset(id: 'teal', name: 'Teal', seed: Color(0xFF00897B)),
  ThemePreset(id: 'rose', name: 'Rose', seed: Color(0xFFC62828)),
  ThemePreset(id: 'amber', name: 'Amber', seed: Color(0xFFF57F17)),
  ThemePreset(id: 'sage', name: 'Sage', seed: Color(0xFF558B2F)),
  ThemePreset(id: 'graphite', name: 'Graphite', seed: Color(0xFF546E7A)),
  ThemePreset(id: 'coral', name: 'Coral', seed: Color(0xFFFF6F61)),
  ThemePreset(id: 'violet', name: 'Violet', seed: Color(0xFF7E57C2)),
  ThemePreset(id: 'ocean', name: 'Ocean', seed: Color(0xFF0277BD)),
  ThemePreset(id: 'forest', name: 'Forest', seed: Color(0xFF2E7D32)),
  ThemePreset(id: 'sunset', name: 'Sunset', seed: Color(0xFFE65100)),
  ThemePreset(id: 'lavender', name: 'Lavender', seed: Color(0xFF9575CD)),
];

const darkThemePresets = [
  ThemePreset(id: 'cyan', name: 'Cyan', seed: Color(0xFF22D3EE), isDark: true),
  ThemePreset(id: 'lime', name: 'Lime', seed: Color(0xFF84CC16), isDark: true),
  ThemePreset(id: 'fuchsia', name: 'Fuchsia', seed: Color(0xFFD946EF), isDark: true),
  ThemePreset(id: 'gold', name: 'Gold', seed: Color(0xFFFBBF24), isDark: true),
  ThemePreset(id: 'ice', name: 'Ice', seed: Color(0xFF93C5FD), isDark: true),
  ThemePreset(id: 'silver', name: 'Silver', seed: Color(0xFFCBD5E1), isDark: true),
  ThemePreset(id: 'neon', name: 'Neon', seed: Color(0xFF00E5FF), isDark: true),
  ThemePreset(id: 'magenta', name: 'Magenta', seed: Color(0xFFFF4081), isDark: true),
  ThemePreset(id: 'emerald', name: 'Emerald', seed: Color(0xFF00E676), isDark: true),
  ThemePreset(id: 'flame', name: 'Flame', seed: Color(0xFFFF6D00), isDark: true),
  ThemePreset(id: 'aurora', name: 'Aurora', seed: Color(0xFF7C4DFF), isDark: true),
  ThemePreset(id: 'mint', name: 'Mint', seed: Color(0xFF69F0AE), isDark: true),
];

const themePresets = [...lightThemePresets, ...darkThemePresets];

ThemePreset presetById(String id) =>
    themePresets.firstWhere((p) => p.id == id, orElse: () => themePresets.first);

class AppGradients {
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
        displayLarge: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: -1.0),
        displayMedium: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: -0.75),
        displaySmall: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: -0.5),
        headlineLarge: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: -0.5),
        headlineMedium: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: -0.25),
        headlineSmall: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: -0.25),
        titleLarge: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: -0.15),
        titleMedium: const TextStyle(fontWeight: FontWeight.w600, letterSpacing: -0.15),
        titleSmall: const TextStyle(fontWeight: FontWeight.w600, letterSpacing: -0.1),
        bodyLarge: const TextStyle(fontWeight: FontWeight.w400, letterSpacing: 0.15),
        bodyMedium: const TextStyle(fontWeight: FontWeight.w400, letterSpacing: 0.25),
        bodySmall: const TextStyle(fontWeight: FontWeight.w400, letterSpacing: 0.25),
        labelLarge: const TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.5),
        labelMedium: const TextStyle(fontWeight: FontWeight.w500, letterSpacing: 0.4),
        labelSmall: const TextStyle(fontWeight: FontWeight.w500, letterSpacing: 0.6),
      );

  static ThemeData light([String themeId = 'indigo']) {
    final seed = presetById(themeId).seed;
    final cs = ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.light).copyWith(
      primary: seed,
    );
    return _buildLight(cs);
  }

  static ThemeData dark([String themeId = 'cyan']) {
    final seed = presetById(themeId).seed;
    final cs = ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.dark).copyWith(
      primary: seed,
    );
    return _buildDark(cs);
  }

  static ThemeData _buildLight(ColorScheme cs) => ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: 'Poppins',
      colorScheme: cs,
      scaffoldBackgroundColor: cs.surface,
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.55),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: cs.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        showDragHandle: true,
        dragHandleColor: cs.outline,
        backgroundColor: cs.surface,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: cs.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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

  static ThemeData _buildDark(ColorScheme cs) => ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: 'Poppins',
      colorScheme: cs,
      scaffoldBackgroundColor: cs.surface,
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.5),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: cs.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        showDragHandle: true,
        dragHandleColor: cs.outline,
        backgroundColor: cs.surface,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: cs.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
