import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/stats_service.dart';
import '../theme/app_colors.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  int _totalQuizzes = 0;
  int _totalQuestions = 0;
  int _totalCorrect = 0;
  int _totalMistakes = 0;
  double _averageScore = 0.0;
  int _streak = 1;
  List<Map<String, dynamic>> _recentActivity = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    final prefs = await SharedPreferences.getInstance();
    final streak = prefs.getInt('streakDays') ?? 1;

    final activityJson = prefs.getStringList('recentActivity') ?? [];
    final recent = activityJson.map((json) {
      final parts = json.split('|');
      if (parts.length < 3) {
        return {'type': json, 'score': 0, 'timestamp': ''};
      }
      return {
        'type': parts[0],
        'score': int.tryParse(parts[1]) ?? 0,
        'timestamp': parts.sublist(2).join('|'),
      };
    }).toList();

    setState(() {
      _totalQuizzes = prefs.getInt('totalQuizzes') ?? 0;
      _totalQuestions = prefs.getInt('totalQuestions') ?? 0;
      _totalCorrect = prefs.getInt('totalCorrect') ?? 0;
      _totalMistakes = prefs.getInt('totalMistakes') ?? 0;
      _averageScore = prefs.getDouble('averageScore') ?? 0.0;
      _streak = streak;
      _recentActivity = recent;
      _loading = false;
    });
  }

  Future<void> _confirmReset() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('İstatistikleri Sıfırla'),
        content: const Text(
            'Tüm çalışma geçmişiniz ve istatistikleriniz sıfırlanacak. Emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF4B4B),
              foregroundColor: Colors.white,
            ),
            child: const Text('Sıfırla'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await StatsService.resetAll();
      await _loadStatistics();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('İstatistikler sıfırlandı')),
        );
      }
    }
  }

  String _getMascotImage() {
    if (_totalQuestions == 0) return 'assets/images/cat_idle.png';
    if (_averageScore >= 70) return 'assets/images/cat_celebrate.png';
    if (_averageScore >= 40) return 'assets/images/cat_reading.png';
    return 'assets/images/cat_idle.png';
  }

  String _getMascotMessage() {
    if (_totalQuestions == 0) {
      return 'Henüz pratik yapmadın. Bugün bir etkinlikle başla!';
    }
    if (_averageScore >= 80) {
      return 'Muhteşem bir performans! TOPIK sınavına hazırsın!';
    }
    if (_averageScore >= 60) {
      return 'Harika gidiyorsun! Düzenli tekrarlarla daha da yükseleceksin.';
    }
    return 'Adım adım ilerliyoruz. Hatalarından öğrenerek devam et!';
  }

  String _topikPrediction() {
    if (_totalQuestions < 10) return 'Yetersiz Veri';
    if (_averageScore >= 80 && _totalQuestions >= 40) return 'TOPIK I - 2급';
    if (_averageScore >= 50) return 'TOPIK I - 1급';
    return 'Başlangıç Düzeyi';
  }

  IconData _getActivityIcon(String type) {
    if (type.contains('Günlük')) return Icons.calendar_today;
    if (type.contains('Deneme') || type.contains('Quiz')) return Icons.school;
    if (type.contains('Eşleştirme')) return Icons.extension;
    if (type.contains('Cümle')) return Icons.text_fields;
    if (type.contains('Maraton')) return Icons.flash_on;
    if (type.contains('Flashcards')) return Icons.style;
    return Icons.check_circle_outline;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('İstatistikler & İlerleme'),
        backgroundColor: AppColors.accent(context),
        foregroundColor: AppColors.onAccent(context),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'İstatistikleri Sıfırla',
            onPressed: _confirmReset,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStatistics,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Maskot Geri Bildirim Kartı
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.card(context),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border(context), width: 2),
                      ),
                      child: Row(
                        children: [
                          Image.asset(
                            _getMascotImage(),
                            width: 80,
                            height: 80,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              Icons.pets,
                              size: 50,
                              color: AppColors.accent(context),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'TOPIK Seviyesi: ${_topikPrediction()}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: AppColors.textPrimary(context),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _getMascotMessage(),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary(context),
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Temel Metrikler Izgarası
                    Row(
                      children: [
                        Expanded(
                          child: _statCard(
                            title: 'Başarı Oranı',
                            value: '%${_averageScore.toStringAsFixed(1)}',
                            icon: Icons.pie_chart,
                            color: AppColors.accent(context),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _statCard(
                            title: 'Günlük Seri',
                            value: '$_streak Gün',
                            icon: Icons.local_fire_department,
                            color: const Color(0xFFFF9800),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _statCard(
                            title: 'Toplam Soru',
                            value: '$_totalQuestions',
                            icon: Icons.format_list_numbered,
                            color: const Color(0xFF2196F3),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _statCard(
                            title: 'Toplam Aktivite',
                            value: '$_totalQuizzes Kez',
                            icon: Icons.event_available,
                            color: const Color(0xFF9C27B0),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Doğru / Yanlış Dağılım Çubuğu
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.card(context),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border(context)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Cevap Dağılımı',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: AppColors.textPrimary(context),
                                ),
                              ),
                              Text(
                                '$_totalCorrect Doğru / $_totalMistakes Yanlış',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary(context),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: SizedBox(
                              height: 12,
                              child: _totalQuestions == 0
                                  ? Container(color: AppColors.border(context))
                                  : Row(
                                      children: [
                                        Expanded(
                                          flex: _totalCorrect,
                                          child: Container(
                                            color: AppColors.accent(context),
                                          ),
                                        ),
                                        if (_totalMistakes > 0)
                                          Expanded(
                                            flex: _totalMistakes,
                                            child: Container(
                                              color: const Color(0xFFFF4B4B),
                                            ),
                                          ),
                                      ],
                                    ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: AppColors.accent(context),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Doğru: $_totalCorrect',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary(context),
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFFF4B4B),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Yanlış: $_totalMistakes',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary(context),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Başarımlar Bölümü
                    _buildAchievementsSection(),
                    const SizedBox(height: 20),

                    // Son Aktiviteler Başlığı
                    Text(
                      'Son Aktiviteler',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary(context),
                      ),
                    ),
                    const SizedBox(height: 10),

                    if (_recentActivity.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(24),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.card(context),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border(context)),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.history,
                                size: 48, color: AppColors.textSecondary(context)),
                            const SizedBox(height: 8),
                            Text(
                              'Henüz bir aktivite kaydı yok',
                              style: TextStyle(
                                color: AppColors.textSecondary(context),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _recentActivity.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final item = _recentActivity[index];
                          final icon = _getActivityIcon(item['type'] as String);
                          final score = item['score'] as int;

                          return Container(
                            decoration: BoxDecoration(
                              color: AppColors.card(context),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border(context)),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppColors.soft(context),
                                child: Icon(icon, color: AppColors.accent(context), size: 20),
                              ),
                              title: Text(
                                item['type'] as String,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: AppColors.textPrimary(context),
                                ),
                              ),
                              subtitle: Text(
                                item['timestamp'] as String,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary(context),
                                ),
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.accent(context).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: AppColors.accent(context).withValues(alpha: 0.4)),
                                ),
                                child: Text(
                                  '%$score',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: AppColors.accent(context),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _statCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary(context),
                ),
              ),
              Icon(icon, size: 18, color: color),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementsSection() {
    final marathonCompleted = _recentActivity.any(
        (a) => (a['type'] as String).toLowerCase().contains('maraton'));

    final achievements = [
      {
        'emoji': '🐣',
        'title': 'İlk Adım',
        'desc': 'İlk testini tamamla',
        'unlocked': _totalQuizzes >= 1,
        'progress': '${min(_totalQuizzes, 1)} / 1',
      },
      {
        'emoji': '🔥',
        'title': 'Seri Ateşi',
        'desc': '3 gün üst üste çalış',
        'unlocked': _streak >= 3,
        'progress': '$_streak / 3 gün',
      },
      {
        'emoji': '🎯',
        'title': 'Keskin Göz',
        'desc': '%80+ ortalama başarı',
        'unlocked': _totalQuestions >= 10 && _averageScore >= 80,
        'progress': '%${_averageScore.toStringAsFixed(0)}',
      },
      {
        'emoji': '📚',
        'title': 'Kelime Kurdu',
        'desc': '50 soru çöz',
        'unlocked': _totalQuestions >= 50,
        'progress': '${min(_totalQuestions, 50)} / 50',
      },
      {
        'emoji': '👑',
        'title': 'TOPIK Ustası',
        'desc': '100 soru çöz',
        'unlocked': _totalQuestions >= 100,
        'progress': '${min(_totalQuestions, 100)} / 100',
      },
      {
        'emoji': '⚡',
        'title': 'Hız Şampiyonu',
        'desc': '60s Maratona katıl',
        'unlocked': marathonCompleted,
        'progress': marathonCompleted ? 'Kazanıldı' : 'Bekliyor',
      },
    ];

    final unlockedCount =
        achievements.where((a) => a['unlocked'] as bool).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Kazanılan Başarımlar',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary(context),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.soft(context),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '🏆 $unlockedCount / ${achievements.length}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.accent(context),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 130,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: achievements.length,
            separatorBuilder: (context, index) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final ach = achievements[index];
              final unlocked = ach['unlocked'] as bool;

              return Container(
                width: 135,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.card(context),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: unlocked
                        ? AppColors.accent(context)
                        : AppColors.border(context),
                    width: unlocked ? 2 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          ach['emoji'] as String,
                          style: TextStyle(
                            fontSize: 26,
                            color: unlocked ? null : Colors.grey,
                          ),
                        ),
                        if (unlocked)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.accent(context),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Açıldı',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      ach['title'] as String,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: unlocked
                            ? AppColors.textPrimary(context)
                            : AppColors.textSecondary(context),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      ach['desc'] as String,
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary(context),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ach['progress'] as String,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: unlocked
                            ? AppColors.accent(context)
                            : AppColors.textSecondary(context),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
