import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../duo_speech_widget.dart';
import '../models/question.dart';
import '../services/daily_exam_service.dart';
import '../services/question_service.dart';
import '../services/stats_service.dart';
import '../services/tts_service.dart';
import '../theme/app_colors.dart';

class DailyExamScreen extends StatefulWidget {
  final bool forcePractice;

  const DailyExamScreen({
    super.key,
    this.forcePractice = false,
  });

  @override
  State<DailyExamScreen> createState() => _DailyExamScreenState();
}

class _DailyExamScreenState extends State<DailyExamScreen> {
  final QuestionService _questionService = QuestionService();
  List<Question> _questions = [];
  int _index = 0;
  int _correctCount = 0;
  bool _loading = true;
  bool _isOfficial = true;
  bool _answered = false;
  int? _selected;
  CatState _catState = CatState.talking;
  int _lastScore = 0;
  int _lastCorrect = 0;
  String _lastLevel = '-';
  Duration _remaining = Duration.zero;
  Timer? _timer;
  bool _showResult = false;
  bool _hasRecordedStats = false;

  @override
  void initState() {
    super.initState();
    _initExam();
  }

  Future<void> _initExam() async {
    final available = await DailyExamService.isAvailableToday();
    _lastScore = await DailyExamService.lastScore();
    _lastLevel = await DailyExamService.lastLevel();
    _lastCorrect = await DailyExamService.lastCorrect();

    if (!available && !widget.forcePractice) {
      _startCountdown();
      setState(() {
        _isOfficial = false;
        _loading = false;
      });
      return;
    }

    _isOfficial = available && !widget.forcePractice;
    await _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    setState(() => _loading = true);
    try {
      // Günlük 20 soruluk karışık sınav
      final questions = await _questionService.fetchShuffled(limit: 20);
      setState(() {
        _questions = questions;
        _index = 0;
        _correctCount = 0;
        _answered = false;
        _selected = null;
        _showResult = false;
        _loading = false;
      });

      if (_questions.isNotEmpty) {
        _speak(_questions[0].question);
      }
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  void _startCountdown() {
    _timer?.cancel();
    _updateRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateRemaining());
  }

  Future<void> _updateRemaining() async {
    final rem = await DailyExamService.getRemainingDuration();
    if (!mounted) return;
    setState(() {
      _remaining = rem;
    });
  }

  void _speak(String text) {
    TtsService.instance.speak(text);
  }

  Future<void> _saveMistake(Question question, int selectedIndex) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final mistakes = prefs.getStringList('mistakes') ?? [];
      mistakes.add(
        '${question.question}|${question.options[selectedIndex]}|${question.options[question.answer]}|${question.explanation}|${DateTime.now().toIso8601String()}',
      );
      await prefs.setStringList('mistakes', mistakes);
    } catch (_) {}
  }

  Future<void> _recordPartialStatsIfNeeded() async {
    if (_hasRecordedStats || _showResult) return;
    final answered = _answered ? _index + 1 : _index;
    if (answered > 0) {
      _hasRecordedStats = true;
      try {
        await StatsService.record(
          activity: _isOfficial ? 'Günlük Sınav (Kısmi)' : 'Günlük Alıştırma (Kısmi)',
          correct: _correctCount,
          total: answered,
        );
      } catch (_) {}
    }
  }

  void _select(int optionIndex) {
    if (_answered) return;

    final question = _questions[_index];
    final isCorrect = optionIndex == question.answer;

    setState(() {
      _selected = optionIndex;
      _answered = true;
      _catState = isCorrect ? CatState.happy : CatState.idle;
      if (isCorrect) _correctCount++;
    });

    _speak(question.options[optionIndex]);

    if (!isCorrect) {
      _saveMistake(question, optionIndex);
    }
  }

  void _next() {
    if (_index < _questions.length - 1) {
      setState(() {
        _index++;
        _answered = false;
        _selected = null;
        _catState = CatState.talking;
      });
      _speak(_questions[_index].question);
    } else {
      _finishExam();
    }
  }

  Future<void> _finishExam() async {
    _hasRecordedStats = true;
    // 20 soru, her biri 10 puan = 200 puan üzerinden
    final score = (_correctCount * 10).clamp(0, 200);
    final level = _topikLevel(score);

    if (_isOfficial) {
      await DailyExamService.saveResult(
        score: score,
        level: level,
        correctCount: _correctCount,
      );
      await StatsService.record(
        activity: 'Günlük Sınav (20 Soru)',
        correct: _correctCount,
        total: _questions.length,
      );
    } else {
      await StatsService.record(
        activity: 'Günlük Sınav (Alıştırma)',
        correct: _correctCount,
        total: _questions.length,
      );
    }

    if (!mounted) return;
    setState(() {
      _lastScore = score;
      _lastLevel = level;
      _lastCorrect = _correctCount;
      _showResult = true;
    });
  }

  String _topikLevel(int score) {
    if (score >= 140) return 'TOPIK I - 2급';
    if (score >= 80) return 'TOPIK I - 1급';
    return 'Hazırlık Düzeyi';
  }

  String _format(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  void dispose() {
    _timer?.cancel();
    TtsService.instance.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Günlük Sınav (20 Soru)'),
          backgroundColor: AppColors.accent(context),
          foregroundColor: AppColors.onAccent(context),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // 24 saat henüz dolmamışsa gösterilen bilgilendirme ekranı
    if (!_isOfficial && _questions.isEmpty && !_showResult) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Günlük Sınav (24 Saat)'),
          backgroundColor: AppColors.accent(context),
          foregroundColor: AppColors.onAccent(context),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/cat_celebrate.png',
                  width: 130,
                  height: 130,
                  errorBuilder: (context, error, stackTrace) =>
                      Icon(Icons.pets, size: 80, color: AppColors.accent(context)),
                ),
                const SizedBox(height: 16),
                Text(
                  'Bugünkü Resmi Sınavını Tamamladın!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary(context),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.card(context),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border(context)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Sonuç: $_lastScore / 200 Puan',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.accent(context),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Seviye: $_lastLevel ($_lastCorrect / 20 Doğru)',
                        style: TextStyle(
                          fontSize: 15,
                          color: AppColors.textSecondary(context),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.soft(context),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.accent(context)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Sonraki Resmi Sınava:',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary(context),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _format(_remaining),
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary(context),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                // Etkinliklerin tamamına girilebilsin: Alıştırma Modu Butonu
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.replay),
                    label: const Text('Alıştırma Olarak Çöz (20 Soru)'),
                    onPressed: () {
                      _loadQuestions();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent(context),
                      foregroundColor: AppColors.onAccent(context),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Ana Sayfaya Dön'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Sonuç Ekranı
    if (_showResult) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Sınav Sonucu'),
          backgroundColor: AppColors.accent(context),
          foregroundColor: AppColors.onAccent(context),
          automaticallyImplyLeading: false,
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  _lastScore >= 120
                      ? 'assets/images/cat_celebrate.png'
                      : 'assets/images/cat_reading.png',
                  width: 140,
                  height: 140,
                  errorBuilder: (context, error, stackTrace) =>
                      Icon(Icons.pets, size: 80, color: AppColors.accent(context)),
                ),
                const SizedBox(height: 16),
                Text(
                  _isOfficial
                      ? '🎉 Günlük Sınav Tamamlandı!'
                      : '📝 Alıştırma Sınavı Tamamlandı!',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary(context),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(20),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.card(context),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border(context)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '$_lastScore / 200',
                        style: TextStyle(
                          fontSize: 38,
                          fontWeight: FontWeight.bold,
                          color: AppColors.accent(context),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Doğru Sayısı: $_lastCorrect / 20',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary(context),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tahmini Seviye: $_lastLevel',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.textSecondary(context),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent(context),
                      foregroundColor: AppColors.onAccent(context),
                    ),
                    child: const Text('Ana Sayfaya Dön', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Günlük Sınav'),
          backgroundColor: AppColors.accent(context),
          foregroundColor: AppColors.onAccent(context),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Sorular yüklenemedi. Lütfen internetinizi kontrol edin.'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadQuestions,
                child: const Text('Tekrar Dene'),
              ),
            ],
          ),
        ),
      );
    }

    final question = _questions[_index];
    final progress = (_index + 1) / _questions.length;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          await _recordPartialStatsIfNeeded();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Günlük Sınav (${_index + 1}/20)'),
          backgroundColor: AppColors.accent(context),
          foregroundColor: AppColors.onAccent(context),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () async {
              await _recordPartialStatsIfNeeded();
              if (context.mounted) Navigator.pop(context);
            },
          ),
        actions: [
          IconButton(
            icon: const Icon(Icons.volume_up),
            tooltip: 'Soruyu Seslendir',
            onPressed: () => _speak(question.question),
          ),
        ],
      ),
      body: Column(
        children: [
          // İlerleme çubuğu
          ClipRRect(
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: AppColors.border(context),
              color: AppColors.accent(context),
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Soru Kategorisi Rozeti
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.soft(context),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.accent(context)),
                      ),
                      child: Text(
                        question.type,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary(context),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Maskot & Soru
                  DuoSpeechWidget(
                    text: question.question,
                    state: _catState,
                    catSize: 100,
                  ),
                  const SizedBox(height: 20),

                  // Şıklar (A, B, C, D)
                  ...List.generate(question.options.length, (i) {
                    final isSelected = _selected == i;
                    final isCorrect = i == question.answer;

                    Color tileBg;
                    Color borderColor;
                    Color textColor;

                    if (_answered) {
                      if (isCorrect) {
                        tileBg = AppColors.accent(context);
                        borderColor = AppColors.accent(context);
                        textColor = AppColors.onAccent(context);
                      } else if (isSelected && !isCorrect) {
                        tileBg = const Color(0xFFFF4B4B);
                        borderColor = const Color(0xFFFF4B4B);
                        textColor = Colors.white;
                      } else {
                        tileBg = AppColors.card(context);
                        borderColor = AppColors.border(context);
                        textColor = AppColors.textPrimary(context);
                      }
                    } else {
                      tileBg = AppColors.card(context);
                      borderColor = AppColors.border(context);
                      textColor = AppColors.textPrimary(context);
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Material(
                        color: tileBg,
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          onTap: () => _select(i),
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: borderColor,
                                width: isSelected || (_answered && isCorrect) ? 2.2 : 1.2,
                              ),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 14,
                                  backgroundColor: AppColors.soft(context),
                                  child: Text(
                                    String.fromCharCode(65 + i),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: AppColors.textPrimary(context),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    question.options[i],
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: textColor,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.volume_up, size: 20, color: textColor),
                                  onPressed: () => _speak(question.options[i]),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),

                  // Açıklama Kutusu
                  if (_answered && question.explanation.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.card(context),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.accent(context)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline, color: AppColors.accent(context)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              question.explanation,
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textPrimary(context),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.volume_up, size: 18),
                            onPressed: () => _speak(question.explanation),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Alt İlerleme Butonu
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _answered ? _next : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent(context),
                  foregroundColor: AppColors.onAccent(context),
                ),
                child: Text(
                  _index < _questions.length - 1 ? 'Sonraki Soru' : 'Sınavı Bitir',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }
}
