import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/tts_service.dart';
import '../theme/app_colors.dart';
import 'mistakes_quiz_screen.dart';

class MistakesScreen extends StatefulWidget {
  const MistakesScreen({super.key});

  @override
  State<MistakesScreen> createState() => _MistakesScreenState();
}

class _MistakesScreenState extends State<MistakesScreen> {
  List<Map<String, dynamic>> _mistakes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMistakes();
  }

  void _speak(String text) {
    TtsService.instance.speak(text);
  }

  Future<void> _loadMistakes() async {
    final prefs = await SharedPreferences.getInstance();
    final mistakesJson = prefs.getStringList('mistakes') ?? [];

    setState(() {
      _mistakes = mistakesJson.map((json) {
        final parts = json.split('|');
        return {
          'question': parts[0],
          'selectedAnswer': parts.length > 1 ? parts[1] : '',
          'correctAnswer': parts.length > 2 ? parts[2] : '',
          'explanation': parts.length > 3 ? parts[3] : '',
          'timestamp': parts.length > 4 ? parts[4] : '',
        };
      }).toList().reversed.toList();
      _isLoading = false;
    });
  }

  Future<void> _clearMistakes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('mistakes');
    setState(() {
      _mistakes = [];
    });
  }

  @override
  void dispose() {
    TtsService.instance.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yapılan Hatalar'),
        backgroundColor: AppColors.accent(context),
        foregroundColor: AppColors.onAccent(context),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_mistakes.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Hataları Temizle',
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Hataları Temizle'),
                    content: const Text(
                        'Tüm kayıtlı hataları silmek istediğinize emin misiniz?'),
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
                        child: const Text('Sil'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  _clearMistakes();
                }
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _mistakes.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/images/cat_celebrate.png',
                          width: 130,
                          height: 130,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.check_circle_outline,
                            size: 80,
                            color: AppColors.accent(context),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Harika! Kayıtlı hata yok!',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary(context),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Test çözerken yanlış cevapladığın sorular burada listelenecek.',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary(context),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _mistakes.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.card(context),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.accent(context),
                            width: 1.8,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: AppColors.soft(context),
                                  child: Icon(Icons.school,
                                      color: AppColors.accent(context)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Hatalarından Öğren!',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textPrimary(context),
                                        ),
                                      ),
                                      Text(
                                        '${_mistakes.length} yanlış soruyu tekrar çözerek listeden temizle.',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color:
                                              AppColors.textSecondary(context),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              height: 44,
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.play_arrow),
                                label: const Text(
                                  'Hataları Tekrar Çöz',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold),
                                ),
                                onPressed: () async {
                                  final refreshed = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => MistakesQuizScreen(
                                          mistakes: _mistakes),
                                    ),
                                  );
                                  if (refreshed == true) {
                                    _loadMistakes();
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.accent(context),
                                  foregroundColor:
                                      AppColors.onAccent(context),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    final mistake = _mistakes[index - 1];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: AppColors.card(context),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border(context)),
                      ),
                      child: ExpansionTile(
                        shape: const Border(),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                mistake['question'] as String,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary(context),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.volume_up,
                                  size: 20, color: AppColors.accent(context)),
                              onPressed: () =>
                                  _speak(mistake['question'] as String),
                            ),
                          ],
                        ),
                        subtitle: Text(
                          'Kayıt: ${mistake['timestamp']}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary(context),
                          ),
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Yanlış Seçilen Cevap
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFF4B4B)
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                        color: const Color(0xFFFF4B4B)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.close,
                                          color: Color(0xFFFF4B4B), size: 20),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Senin Cevabın:',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFFFF4B4B),
                                              ),
                                            ),
                                            Text(
                                              mistake['selectedAnswer']
                                                  as String,
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: AppColors.textPrimary(
                                                    context),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 10),

                                // Doğru Cevap
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.accent(context)
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                        color: AppColors.accent(context)),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.check,
                                          color: AppColors.accent(context),
                                          size: 20),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Doğru Cevap:',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.accent(context),
                                              ),
                                            ),
                                            Text(
                                              mistake['correctAnswer']
                                                  as String,
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.textPrimary(
                                                    context),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.volume_up,
                                            size: 20),
                                        onPressed: () => _speak(
                                            mistake['correctAnswer'] as String),
                                      ),
                                    ],
                                  ),
                                ),

                                // Açıklama
                                if ((mistake['explanation'] as String)
                                    .isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppColors.soft(context),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      'Açıklama: ${mistake['explanation']}',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textPrimary(context),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
