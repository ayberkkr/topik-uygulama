import 'package:shared_preferences/shared_preferences.dart';

class StatsService {
  static const _totalQuizzesKey = 'totalQuizzes';
  static const _totalQuestionsKey = 'totalQuestions';
  static const _totalCorrectKey = 'totalCorrect';
  static const _totalMistakesKey = 'totalMistakes';
  static const _averageScoreKey = 'averageScore';
  static const _recentActivityKey = 'recentActivity';
  static const _streakDaysKey = 'streakDays';
  static const _lastActiveDateKey = 'lastActiveDate';
  static const _dailyExamsCompletedKey = 'dailyExamsCompleted';

  static String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(dt.year, dt.month, dt.day);
    final timeStr =
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

    if (date == today) {
      return 'Bugün $timeStr';
    } else if (date == today.subtract(const Duration(days: 1))) {
      return 'Dün $timeStr';
    } else {
      final months = [
        '',
        'Oca',
        'Şub',
        'Mar',
        'Nis',
        'May',
        'Haz',
        'Tem',
        'Ağu',
        'Eyl',
        'Eki',
        'Kas',
        'Ara'
      ];
      return '${dt.day} ${months[dt.month]} $timeStr';
    }
  }

  static Future<void> record({
    required String activity,
    required int correct,
    required int total,
  }) async {
    if (total <= 0) return;

    final prefs = await SharedPreferences.getInstance();
    final totalQuizzes = (prefs.getInt(_totalQuizzesKey) ?? 0) + 1;
    final totalQuestions = (prefs.getInt(_totalQuestionsKey) ?? 0) + total;
    final totalCorrect = (prefs.getInt(_totalCorrectKey) ?? 0) + correct;
    final totalMistakes =
        (prefs.getInt(_totalMistakesKey) ?? 0) + (total - correct);
    final sessionPercent = (correct / total * 100).clamp(0, 100);

    // Günlük sınav sayacı
    if (activity.contains('Günlük Sınav')) {
      final dailyCount = (prefs.getInt(_dailyExamsCompletedKey) ?? 0) + 1;
      await prefs.setInt(_dailyExamsCompletedKey, dailyCount);
    }

    // Seri (streak) hesaplama
    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month}-${now.day}';
    final lastActiveStr = prefs.getString(_lastActiveDateKey);
    var streak = prefs.getInt(_streakDaysKey) ?? 0;

    if (lastActiveStr == null) {
      streak = 1;
    } else if (lastActiveStr != todayStr) {
      final parts = lastActiveStr.split('-').map(int.parse).toList();
      final lastActiveDate = DateTime(parts[0], parts[1], parts[2]);
      final difference = DateTime(now.year, now.month, now.day)
          .difference(lastActiveDate)
          .inDays;

      if (difference == 1) {
        streak += 1;
      } else if (difference > 1) {
        streak = 1;
      }
    }
    await prefs.setString(_lastActiveDateKey, todayStr);
    await prefs.setInt(_streakDaysKey, streak);

    // Ortalama başarı oranı
    final accuracyPercent = totalQuestions > 0
        ? (totalCorrect / totalQuestions * 100)
        : sessionPercent.toDouble();

    await prefs.setInt(_totalQuizzesKey, totalQuizzes);
    await prefs.setInt(_totalQuestionsKey, totalQuestions);
    await prefs.setInt(_totalCorrectKey, totalCorrect);
    await prefs.setInt(_totalMistakesKey, totalMistakes);
    await prefs.setDouble(_averageScoreKey, accuracyPercent);

    // Son aktiviteler
    final activityJson = prefs.getStringList(_recentActivityKey) ?? [];
    final formattedTime = _formatDate(now);
    activityJson.insert(
      0,
      '$activity|${sessionPercent.toInt()}|$formattedTime',
    );
    if (activityJson.length > 20) {
      activityJson.removeLast();
    }
    await prefs.setStringList(_recentActivityKey, activityJson);
  }

  static Future<int> getStreak() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_streakDaysKey) ?? 1;
  }

  static Future<void> resetAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_totalQuizzesKey);
    await prefs.remove(_totalQuestionsKey);
    await prefs.remove(_totalCorrectKey);
    await prefs.remove(_totalMistakesKey);
    await prefs.remove(_averageScoreKey);
    await prefs.remove(_recentActivityKey);
    await prefs.remove(_dailyExamsCompletedKey);
  }
}
