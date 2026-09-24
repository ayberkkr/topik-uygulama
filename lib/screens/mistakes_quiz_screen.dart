import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../duo_speech_widget.dart';
import '../models/question.dart';
import '../services/question_service.dart';
import '../services/stats_service.dart';
import '../services/tts_service.dart';
import '../theme/app_colors.dart';

class MistakesQuizScreen extends StatefulWidget {
  final List<Map<String, dynamic>> mistakes;

  const MistakesQuizScreen({super.key, required this.mistakes});

  @override
  State<MistakesQuizScreen> createState() => _MistakesQuizScreenState();
}

class _MistakesQuizScreenState extends State<MistakesQuizScreen> {
  final QuestionService _questionService = QuestionService();
  List<Question> _quizQuestions = [];
  int _currentIndex = 0;
  int _score = 0;
  bool _isLoading = true;
  bool _hasAnswered = false;
  int? _selectedOption;
  CatState _catState = CatState.talking;
  final Set<String> _clearedQuestionTexts = {};
  bool _hasRecordedStats = false;

  @override
  void initState() {
    super.initState();
    _prepareQuestions();
  }

  void _speak(String text) {
    TtsService.instance.speak(text);
  }

  Future<void> _prepareQuestions() async {
    try {
      final allQuestions = await _questionService.fetchQuestions();
      final questionMap = {for (var q in allQuestions) q.question: q};
      final fallbackOptions = allQuestions.isNotEmpty
          ? allQuestions.expand((q) => q.options).toSet().toList()
          : ['네', '아니요', '감사합니다', '안녕하세요'];

      final List<Question> prepared = [];
      final random = Random();

      for (var mistake in widget.mistakes) {
        final qText = mistake['question'] as String? ?? '';
        final correctAns = mistake['correctAnswer'] as String? ?? '';
        final explanation = mistake['explanation'] as String? ?? '';

        if (questionMap.containsKey(qText)) {
          final original = questionMap[qText]!;
          // Şıkları karıştır
          final options = List<String>.from(original.options)..shuffle(random);
          prepared.add(
            Question(
              id: original.id,
              type: original.type,
              question: original.question,
              options: options,
              answer: options.indexOf(original.options[original.answer]),
              explanation: original.explanation,
            ),
          );
        } else if (qText.isNotEmpty && correctAns.isNotEmpty) {
          // Gist'te bulunamazsa yedek şıklar türet
          final otherOptions = fallbackOptions
              .where((opt) => opt != correctAns)
              .toList()
            ..shuffle(random);
          final options = [correctAns, ...otherOptions.take(3)]..shuffle(random);
          prepared.add(
            Question(
              id: 0,
              type: 'Hata Tekrarı',
              question: qText,
              options: options,
              answer: options.indexOf(correctAns),
              explanation: explanation,
            ),
          );
        }
      }

      prepared.shuffle(random);

      if (!mounted) return;
      setState(() {
        _quizQuestions = prepared;
        _isLoading = false;
      });

      if (prepared.isNotEmpty) {
        _speak(prepared[0].question);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _removeMistakeFromStorage(String questionText) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final mistakes = prefs.getStringList('mistakes') ?? [];
      mistakes.removeWhere((item) => item.startsWith('$questionText|'));
      await prefs.setStringList('mistakes', mistakes);
      _clearedQuestionTexts.add(questionText);
    } catch (_) {}
  }

  Future<void> _recordPartialStatsIfNeeded() async {
    if (_hasRecordedStats) return;
    final answered = _hasAnswered ? _currentIndex + 1 : _currentIndex;
    if (answered > 0) {
      _hasRecordedStats = true;
      try {
        await StatsService.record(
          activity: 'Hata Tekrarı (Kısmi)',
          correct: _score,
          total: answered,
        );
      } catch (_) {}
    }
  }

  void _selectOption(int index) async {
    if (_hasAnswered) return;

    final q = _quizQuestions[_currentIndex];
    final isCorrect = index == q.answer;

    setState(() {
      _selectedOption = index;
      _hasAnswered = true;
      _catState = isCorrect ? CatState.happy : CatState.idle;
      if (isCorrect) _score++;
    });

    _speak(q.options[index]);

    if (isCorrect) {
      await _removeMistakeFromStorage(q.question);
    }
  }

  void _nextQuestion() {
    if (_currentIndex < _quizQuestions.length - 1) {
      setState(() {
        _currentIndex++;
        _hasAnswered = false;
        _selectedOption = null;
        _catState = CatState.talking;
      });
      _speak(_quizQuestions[_currentIndex].question);
    } else {
      _showResults();
    }
  }

  Future<void> _showResults() async {
    if (!_hasRecordedStats) {
      _hasRecordedStats = true;
      try {
        await StatsService.record(
          activity: 'Hata Tekrarı',
          correct: _score,
          total: _quizQuestions.length,
        );
      } catch (_) {}
    }

    if (!mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('🎉 Hata Tekrarı Tamamlandı!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/cat_celebrate.png',
              width: 90,
              height: 90,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.check_circle, size: 60, color: Colors.green),
            ),
            const SizedBox(height: 12),
            Text(
              '$_score / ${_quizQuestions.length} soru doğru cevaplandı.',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text(
              _clearedQuestionTexts.isNotEmpty
                  ? '${_clearedQuestionTexts.length} soru hata listenden başarıyla silindi!'
                  : 'Hatalarını tekrar etmek için harika bir çalışma oldu!',
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
              Navigator.pop(context, true); // MistakesScreen'i yenilemek için true döndür
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent(context),
              foregroundColor: AppColors.onAccent(context),
            ),
            child: const Text('Tamam'),
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
          title: const Text('Hata Tekrarı Testi'),
          backgroundColor: AppColors.accent(context),
          foregroundColor: AppColors.onAccent(context),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_quizQuestions.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Hata Tekrarı Testi'),
          backgroundColor: AppColors.accent(context),
          foregroundColor: AppColors.onAccent(context),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Tekrar edilecek soru bulunamadı.'),
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

    final currentQuestion = _quizQuestions[_currentIndex];
    final progress = (_currentIndex + 1) / _quizQuestions.length;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          await _recordPartialStatsIfNeeded();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Hata Tekrarı (${_currentIndex + 1}/${_quizQuestions.length})'),
          backgroundColor: AppColors.accent(context),
          foregroundColor: AppColors.onAccent(context),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () async {
              await _recordPartialStatsIfNeeded();
              if (context.mounted) Navigator.pop(context, true);
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.volume_up),
              tooltip: 'Soruyu Seslendir',
              onPressed: () => _speak(currentQuestion.question),
            ),
          ],
        ),
        body: Column(
          children: [
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
                              ? 'Tebrikler! Hatırladın ve doğru çözdün! 🌟'
                              : 'Olsun, doğru cevabı dinle ve incele! 💪')
                          : 'Daha önce yanlış çözdüğün bu soruyu şimdi doğru yapabilirsin!',
                      state: _catState,
                      catSize: 85,
                    ),
                    const SizedBox(height: 16),

                    // Soru Kutusu
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.card(context),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.border(context)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF4B4B)
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  '❌ Geçmiş Hata',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFFF4B4B),
                                  ),
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                icon: Icon(Icons.volume_up,
                                    color: AppColors.accent(context)),
                                onPressed: () =>
                                    _speak(currentQuestion.question),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            currentQuestion.question,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Şıklar
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
                    _currentIndex < _quizQuestions.length - 1
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
