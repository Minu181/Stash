import 'package:shared_preferences/shared_preferences.dart';

/// Persists lightweight UI state that should survive a full app kill
/// (e.g. which tab the user was last on).
class AppPrefs {
  static const _lastTabKey = 'last_tab_index';

  /// Returns the last selected tab index, clamped to a valid range.
  static Future<int> getLastTab() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getInt(_lastTabKey);
    if (value == null || value < 0 || value > 3) return 0;
    return value;
  }

  static Future<void> setLastTab(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastTabKey, index);
  }
}
