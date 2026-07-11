import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stash/data/database.dart';

class SettingsState {
  final String themeMode;
  final String currency;
  final bool reduceMotion;
  final String language;
  final String themeId;
  final String? displayName;
  final bool hasOnboarded;

  const SettingsState({
    this.themeMode = 'system',
    this.currency = 'USD',
    this.reduceMotion = false,
    this.language = 'en',
    this.themeId = 'aurora',
    this.displayName,
    this.hasOnboarded = false,
  });

  SettingsState copyWith({
    String? themeMode,
    String? currency,
    bool? reduceMotion,
    String? language,
    String? themeId,
    String? displayName,
    bool? hasOnboarded,
  }) =>
      SettingsState(
        themeMode: themeMode ?? this.themeMode,
        currency: currency ?? this.currency,
        reduceMotion: reduceMotion ?? this.reduceMotion,
        language: language ?? this.language,
        themeId: themeId ?? this.themeId,
        displayName: displayName ?? this.displayName,
        hasOnboarded: hasOnboarded ?? this.hasOnboarded,
      );
}

class SettingsNotifier extends Notifier<SettingsState> {
  @override
  SettingsState build() {
    _load();
    return const SettingsState();
  }

  Future<void> _load() async {
    final s = await appDatabase.getSettings();
    if (s != null) {
      state = state.copyWith(
        themeMode: s.themeMode,
        currency: s.currency,
        reduceMotion: s.reduceMotion,
        language: s.language,
        themeId: s.themeId,
        displayName: s.displayName,
        hasOnboarded: s.hasOnboarded,
      );
    }
  }

  Future<void> _update(AppSettingsCompanion entry) async {
    await appDatabase.updateSettings(entry);
    await _load();
  }

  Future<void> setThemeMode(String mode) async => _update(AppSettingsCompanion(
        id: const Value(0),
        themeMode: Value(mode),
      ));

  Future<void> setCurrency(String currency) async => _update(AppSettingsCompanion(
        id: const Value(0),
        currency: Value(currency),
      ));

  Future<void> setReduceMotion(bool value) async => _update(AppSettingsCompanion(
        id: const Value(0),
        reduceMotion: Value(value),
      ));

  Future<void> setLanguage(String lang) async => _update(AppSettingsCompanion(
        id: const Value(0),
        language: Value(lang),
      ));

  Future<void> setThemeId(String id) async => _update(AppSettingsCompanion(
        id: const Value(0),
        themeId: Value(id),
      ));

  Future<void> setDisplayName(String name) async => _update(AppSettingsCompanion(
        id: const Value(0),
        displayName: Value(name),
      ));

  Future<void> completeOnboarding({
    required String currency,
    required String themeId,
  }) async {
    state = state.copyWith(
      hasOnboarded: true,
      currency: currency,
      themeId: themeId,
    );
    await appDatabase.updateSettings(AppSettingsCompanion(
      id: const Value(0),
      hasOnboarded: const Value(true),
      currency: Value(currency),
      themeId: Value(themeId),
    ));
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, SettingsState>(SettingsNotifier.new);

final databaseProvider = Provider<AppDatabase>((ref) => appDatabase);

String formatCurrency(double amount, String currency) {
  const symbols = {
    'USD': '\$',
    'EUR': '€',
    'GBP': '£',
    'JPY': '¥',
    'PHP': '₱',
    'INR': '₹',
  };
  final symbol = symbols[currency] ?? '\$';
  final formatted = amount.abs().toStringAsFixed(2).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]},',
      );
  return amount < 0 ? '-$symbol$formatted' : '$symbol$formatted';
}
