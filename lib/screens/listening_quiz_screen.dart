import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../duo_speech_widget.dart';
import '../models/question.dart';
import '../services/question_service.dart';
import '../services/stats_service.dart';
import '../services/tts_service.dart';
import '../theme/app_colors.dart';

class ListeningQuizScreen extends StatefulWidget {
  const ListeningQuizScreen({super.key});

  @override
  State<ListeningQuizScreen> createState() => _ListeningQuizScreenState();
}

class _ListeningQuizScreenState extends State<ListeningQuizScreen> {
  final QuestionService _questionService = QuestionService();
  List<Question> _questions = [];
  int _currentIndex = 0;
  int _score = 0;
  bool _isLoading = true;
  bool _hasAnswered = false;
  int? _selectedOption;
  bool _showTextHint = false;
  CatState _catState = CatState.talking;
  bool _hasRecordedStats = false;
  bool _isPlayingAudio = false;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _speak(String text) async {
    setState(() => _isPlayingAudio = true);
    await TtsService.instance.speak(text);
    if (mounted) {
      setState(() => _isPlayingAudio = false);
    }
  }

  Future<void> _loadQuestions() async {
    try {
      final all = await _questionService.fetchShuffled(limit: 50);
      all.shuffle(Random());
      final selected = all.take(15).map((q) => _shuffleOptions(q)).toList();

      setState(() {
        _questions = selected;
        _isLoading = false;
      });

      if (selected.isNotEmpty) {
        _playCurrentQuestion();
      }
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Question _shuffleOptions(Question q) {
    final originalOptions = List<String>.from(q.options);
    final correctAnswerText = originalOptions[q.answer];
    final shuffled = List<String>.from(originalOptions)..shuffle(Random());
    return Question(
      id: q.id,
      type: q.type,
      question: q.question,
      options: shuffled,
      answer: shuffled.indexOf(correctAnswerText),
      explanation: q.explanation,
    );
  }

  void _playCurrentQuestion() {
    if (_questions.isNotEmpty && _currentIndex < _questions.length) {
      _speak(_questions[_currentIndex].question);
    }
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
    if (_hasRecordedStats) return;
    final answered = _hasAnswered ? _currentIndex + 1 : _currentIndex;
    if (answered > 0) {
      _hasRecordedStats = true;
      try {
        await StatsService.record(
          activity: 'Dinleme Pratiği (Kısmi)',
          correct: _score,
          total: answered,
        );
      } catch (_) {}
    }
  }

  void _selectOption(int index) async {
    if (_hasAnswered) return;

    final q = _questions[_currentIndex];
    final isCorrect = index == q.answer;

    setState(() {
      _selectedOption = index;
      _hasAnswered = true;
      _showTextHint = true; // Cevap verilince soru metni açılsın
      _catState = isCorrect ? CatState.happy : CatState.idle;
      if (isCorrect) _score++;
    });

    _speak(q.options[index]);

    if (!isCorrect) {
      await _saveMistake(q, index);
    }
  }

  void _nextQuestion() {
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        _hasAnswered = false;
        _selectedOption = null;
        _showTextHint = false;
        _catState = CatState.talking;
      });
      _playCurrentQuestion();
    } else {
      _showResults();
    }
  }

  Future<void> _showResults() async {
    if (!_hasRecordedStats) {
      _hasRecordedStats = true;
      try {
        await StatsService.record(
          activity: 'Dinleme Pratiği',
          correct: _score,
          total: _questions.length,
        );
      } catch (_) {}
    }

    if (!mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('🎧 Dinleme Testi Tamamlandı!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              _score >= (_questions.length * 0.7)
                  ? 'assets/images/cat_celebrate.png'
                  : 'assets/images/cat_reading.png',
              width: 100,
              height: 100,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.headphones, size: 60, color: Colors.blue),
            ),
            const SizedBox(height: 12),
            Text(
              '$_score / ${_questions.length} Doğru',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
            ),
            const SizedBox(height: 8),
            Text(
              _score >= (_questions.length * 0.7)
                  ? 'Kulağın Koreceye harika alışıyor! Tebrikler!'
                  : 'Düzenli dinleme pratiği yaparak daha da hızlanacaksın!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary(context),
                fontSize: 13,
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent(context),
              foregroundColor: AppColors.onAccent(context),
            ),
            child: const Text('Ana Ekrana Dön'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    TtsService.instance.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('TOPIK Dinleme Pratiği'),
          backgroundColor: AppColors.accent(context),
          foregroundColor: AppColors.onAccent(context),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('TOPIK Dinleme Pratiği'),
          backgroundColor: AppColors.accent(context),
          foregroundColor: AppColors.onAccent(context),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Sorular yüklenemedi.'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Geri Dön'),
              ),
            ],
          ),
        ),
      );
    }

    final currentQuestion = _questions[_currentIndex];
    final progress = (_currentIndex + 1) / _questions.length;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          await _recordPartialStatsIfNeeded();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Dinleme Pratiği (${_currentIndex + 1}/${_questions.length})'),
          backgroundColor: AppColors.accent(context),
          foregroundColor: AppColors.onAccent(context),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () async {
              await _recordPartialStatsIfNeeded();
              if (context.mounted) Navigator.pop(context);
            },
          ),
        ),
        body: Column(
          children: [
            // İlerleme çubuğu
            Container(
              height: 6,
              color: AppColors.border(context),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: progress,
                child: Container(color: AppColors.accent(context)),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DuoSpeechWidget(
                      text: _hasAnswered
                          ? (_selectedOption == currentQuestion.answer
                              ? 'Harika duydun ve bildin! 🎉'
                              : 'Yanlış olsa da kulağın alışıyor, devam et!')
                          : 'Korece sesi dikkatle dinle ve doğru seçeneği işaretle!',
                      state: _catState,
                      catSize: 85,
                    ),
                    const SizedBox(height: 16),

                    // Büyük Ses Çalma Kartı
                    Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 24, horizontal: 20),
                      decoration: BoxDecoration(
                        color: AppColors.card(context),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.accent(context),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accent(context)
                                .withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: _playCurrentQuestion,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: _isPlayingAudio
                                    ? AppColors.accent(context)
                                    : AppColors.soft(context),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.accent(context),
                                  width: 2.5,
                                ),
                              ),
                              child: Icon(
                                _isPlayingAudio
                                    ? Icons.volume_up
                                    : Icons.play_arrow_rounded,
                                size: 44,
                                color: _isPlayingAudio
                                    ? AppColors.onAccent(context)
                                    : AppColors.accent(context),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Dinlemek İçin Dokun 🔊',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary(context),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'İstediğin kadar tekrar dinleyebilirsin',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary(context),
                            ),
                          ),

                          // İpucu / Metni Göster Butonu
                          const SizedBox(height: 10),
                          TextButton.icon(
                            icon: Icon(
                              _showTextHint
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              size: 16,
                            ),
                            label: Text(
                              _showTextHint
                                  ? 'Soru Metnini Gizle'
                                  : 'Soru Metnini Göster (İpucu)',
                              style: const TextStyle(fontSize: 12),
                            ),
                            onPressed: () {
                              setState(() {
                                _showTextHint = !_showTextHint;
                              });
                            },
                          ),

                          if (_showTextHint) ...[
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.soft(context),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                currentQuestion.question,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary(context),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Şıklar Listesi
                    ...List.generate(currentQuestion.options.length, (index) {
                      final option = currentQuestion.options[index];
                      final isSelected = _selectedOption == index;
                      final isCorrect = index == currentQuestion.answer;

                      Color borderColor = AppColors.border(context);
                      Color bgColor = AppColors.card(context);
                      Color textColor = AppColors.textPrimary(context);

                      if (_hasAnswered) {
                        if (isCorrect) {
                          borderColor = AppColors.accent(context);
                          bgColor = AppColors.accent(context)
                              .withValues(alpha: 0.12);
                          textColor = AppColors.accent(context);
                        } else if (isSelected) {
                          borderColor = const Color(0xFFFF4B4B);
                          bgColor = const Color(0xFFFF4B4B)
                              .withValues(alpha: 0.12);
                          textColor = const Color(0xFFFF4B4B);
                        }
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _hasAnswered ? null : () => _selectOption(index),
                            borderRadius: BorderRadius.circular(14),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: bgColor,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: borderColor,
                                  width: isSelected || (_hasAnswered && isCorrect)
                                      ? 2
                                      : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 14,
                                    backgroundColor: AppColors.soft(context),
                                    child: Text(
                                      String.fromCharCode(65 + index),
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
                                      option,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: textColor,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.volume_up,
                                        size: 20, color: textColor),
                                    onPressed: () => _speak(option),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),

                    if (_hasAnswered && currentQuestion.explanation.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.card(context),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.accent(context)),
                        ),
                        child: Text(
                          'Açıklama: ${currentQuestion.explanation}',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary(context),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _hasAnswered ? _nextQuestion : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent(context),
                    foregroundColor: AppColors.onAccent(context),
                  ),
                  child: Text(
                    _currentIndex < _questions.length - 1
                        ? 'Sonraki Soru'
                        : 'Sonuçları Gör',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
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
