import 'package:shared_preferences/shared_preferences.dart';

class ReminderPrefs {
  static const _enabledKey = 'reminder_enabled';
  static const _hourKey = 'reminder_hour';
  static const _minuteKey = 'reminder_minute';
  static const _titleKey = 'reminder_title';
  static const _bodyKey = 'reminder_body';

  static const defaultTitle = 'Daily Savings Reminder';
  static const defaultBody = "Aren't you forgetting something?";

  static Future<bool> getEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_enabledKey) ?? false;
  }

  static Future<int> getHour() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_hourKey) ?? 20;
  }

  static Future<int> getMinute() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_minuteKey) ?? 0;
  }

  static Future<String> getTitle() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_titleKey) ?? defaultTitle;
  }

  static Future<String> getBody() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_bodyKey) ?? defaultBody;
  }

  static Future<void> save({
    required bool enabled,
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, enabled);
    await prefs.setInt(_hourKey, hour);
    await prefs.setInt(_minuteKey, minute);
    await prefs.setString(_titleKey, title);
    await prefs.setString(_bodyKey, body);
  }
}
