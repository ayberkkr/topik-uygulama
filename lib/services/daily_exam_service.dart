import 'package:shared_preferences/shared_preferences.dart';

class DailyExamService {
  static const lastTimestampKey = 'dailyExamLastTimestamp';
  static const lastScoreKey = 'dailyExamLastScore';
  static const lastLevelKey = 'dailyExamLastLevel';
  static const lastCorrectKey = 'dailyExamLastCorrect';

  /// 24 saatlik süre (milisaniye cinsinden)
  static const int cooldownMs = 24 * 60 * 60 * 1000;

  static Future<bool> isAvailableToday() async {
    final prefs = await SharedPreferences.getInstance();
    final lastMs = prefs.getInt(lastTimestampKey);
    if (lastMs == null) return true;

    final nowMs = DateTime.now().millisecondsSinceEpoch;
    return (nowMs - lastMs) >= cooldownMs;
  }

  static Future<Duration> getRemainingDuration() async {
    final prefs = await SharedPreferences.getInstance();
    final lastMs = prefs.getInt(lastTimestampKey);
    if (lastMs == null) return Duration.zero;

    final nextAvailableMs = lastMs + cooldownMs;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final diffMs = nextAvailableMs - nowMs;
    if (diffMs <= 0) return Duration.zero;

    return Duration(milliseconds: diffMs);
  }

  static Future<int> lastScore() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(lastScoreKey) ?? 0;
  }

  static Future<int> lastCorrect() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(lastCorrectKey) ?? 0;
  }

  static Future<String> lastLevel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(lastLevelKey) ?? '-';
  }

  static Future<void> saveResult({
    required int score,
    required String level,
    int correctCount = 0,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(lastTimestampKey, DateTime.now().millisecondsSinceEpoch);
    await prefs.setInt(lastScoreKey, score);
    await prefs.setString(lastLevelKey, level);
    await prefs.setInt(lastCorrectKey, correctCount);
  }
}
