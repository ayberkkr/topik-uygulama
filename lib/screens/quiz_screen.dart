import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../duo_speech_widget.dart';
import '../models/question.dart';
import '../services/question_service.dart';
import '../services/stats_service.dart';
import '../services/tts_service.dart';
import '../theme/app_colors.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final QuestionService _questionService = QuestionService();
  List<Question> _questions = [];
  int _currentQuestionIndex = 0;
  int _score = 0;
  bool _isLoading = true;
  bool _hasAnswered = false;
  int? _selectedOption;
  CatState _catState = CatState.talking;
  bool _hasRecordedStats = false;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  void _speak(String text) {
    TtsService.instance.speak(text);
  }

  Future<void> _loadQuestions() async {
    try {
      List<Question> allQuestions =
          await _questionService.fetchShuffled(limit: 300);
      allQuestions.shuffle(Random());

      final count = min(20, allQuestions.length);
      final selectedList =
          allQuestions.take(count).map((q) => _shuffleOptions(q)).toList();

      setState(() {
        _questions = selectedList;
        _isLoading = false;
        _catState = CatState.talking;
      });

      if (_questions.isNotEmpty) {
        _speak(_questions[0].question);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Soru yükleme hatası: $e')),
        );
      }
    }
  }

  Question _shuffleOptions(Question q) {
    final originalAnswerText = q.options[q.answer];
    final shuffledOptions = List<String>.from(q.options)..shuffle(Random());
    final newAnswerIndex = shuffledOptions.indexOf(originalAnswerText);

    return Question(
      id: q.id,
      type: q.type,
      question: q.question,
      options: shuffledOptions,
      answer: newAnswerIndex,
      explanation: q.explanation,
    );
  }

  Future<void> _selectOption(int index) async {
    if (_hasAnswered) return;

    final currentQuestion = _questions[_currentQuestionIndex];
    final isCorrect = index == currentQuestion.answer;

    setState(() {
      _selectedOption = index;
      _hasAnswered = true;
      _catState = isCorrect ? CatState.happy : CatState.idle;
      if (isCorrect) _score++;
    });

    _speak(currentQuestion.options[index]);

    if (!isCorrect) {
      await _saveMistake(currentQuestion, index);
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

  void _nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _hasAnswered = false;
        _selectedOption = null;
        _catState = CatState.talking;
      });
      _speak(_questions[_currentQuestionIndex].question);
    } else {
      _showResults();
    }
  }

  Future<void> _recordPartialStatsIfNeeded() async {
    if (_hasRecordedStats) return;
    final answered = _hasAnswered ? _currentQuestionIndex + 1 : _currentQuestionIndex;
    if (answered > 0) {
      _hasRecordedStats = true;
      try {
        await StatsService.record(
          activity: 'TOPIK Deneme (Kısmi)',
          correct: _score,
          total: answered,
        );
      } catch (_) {}
    }
  }

  Future<void> _showResults() async {
    if (!_hasRecordedStats) {
      _hasRecordedStats = true;
      try {
        await StatsService.record(
          activity: 'TOPIK Deneme',
          correct: _score,
          total: _questions.length,
        );
      } catch (e) {
        debugPrint('İstatistik kaydetme hatası: $e');
      }
    }

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ResultScreen(
          score: _score,
          totalQuestions: _questions.length,
        ),
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
          title: const Text('TOPIK Deneme'),
          backgroundColor: AppColors.accent(context),
          foregroundColor: AppColors.onAccent(context),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('TOPIK Deneme'),
          backgroundColor: AppColors.accent(context),
          foregroundColor: AppColors.onAccent(context),
        ),
        body: const Center(child: Text('Sorular yüklenemedi')),
      );
    }

    final currentQuestion = _questions[_currentQuestionIndex];
    final progress = (_currentQuestionIndex + 1) / _questions.length;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          await _recordPartialStatsIfNeeded();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('TOPIK Deneme (${_currentQuestionIndex + 1}/${_questions.length})'),
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
                  // Soru Türü Rozeti
                  if (currentQuestion.type.isNotEmpty)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.soft(context),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.accent(context)),
                        ),
                        child: Text(
                          currentQuestion.type,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary(context),
                          ),
                        ),
                      ),
                    ),

                  DuoSpeechWidget(
                    text: currentQuestion.question,
                    state: _catState,
                    catSize: 95,
                  ),
                  const SizedBox(height: 20),

                  ...List.generate(currentQuestion.options.length, (index) {
                    final option = currentQuestion.options[index];
                    final isSelected = _selectedOption == index;
                    final isCorrect = index == currentQuestion.answer;

                    Color? backgroundColor;
                    Color? textColor;
                    Color borderColor;

                    if (_hasAnswered) {
                      if (isCorrect) {
                        backgroundColor = AppColors.accent(context);
                        textColor = AppColors.onAccent(context);
                        borderColor = AppColors.accent(context);
                      } else if (isSelected && !isCorrect) {
                        backgroundColor = const Color(0xFFFF4B4B);
                        textColor = Colors.white;
                        borderColor = const Color(0xFFFF4B4B);
                      } else {
                        backgroundColor = AppColors.card(context);
                        textColor = AppColors.textPrimary(context);
                        borderColor = AppColors.border(context);
                      }
                    } else {
                      backgroundColor = AppColors.card(context);
                      textColor = AppColors.textPrimary(context);
                      borderColor = isSelected
                          ? AppColors.accent(context)
                          : AppColors.border(context);
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Material(
                        color: backgroundColor,
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          onTap: () => _selectOption(index),
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: borderColor,
                                width: isSelected || (_hasAnswered && isCorrect)
                                    ? 2.2
                                    : 1.2,
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

                  if (_hasAnswered) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.card(context),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.accent(context)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _selectedOption == currentQuestion.answer
                                ? Icons.check_circle
                                : Icons.info,
                            color: AppColors.accent(context),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              currentQuestion.explanation,
                              style: TextStyle(
                                color: AppColors.textPrimary(context),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.volume_up, size: 20),
                            onPressed: () =>
                                _speak(currentQuestion.explanation),
                          ),
                        ],
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
                  _currentQuestionIndex < _questions.length - 1
                      ? 'Sonraki Soru'
                      : 'Sonuçları Gör',
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

class ResultScreen extends StatelessWidget {
  final int score;
  final int totalQuestions;

  const ResultScreen({
    super.key,
    required this.score,
    required this.totalQuestions,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = totalQuestions == 0
        ? 0
        : (score / totalQuestions * 100).toInt();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sonuçlar'),
        backgroundColor: AppColors.accent(context),
        foregroundColor: AppColors.onAccent(context),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                percentage >= 60
                    ? 'assets/images/cat_celebrate.png'
                    : 'assets/images/cat_reading.png',
                width: 140,
                height: 140,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.pets, size: 80),
              ),
              const SizedBox(height: 16),
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.accent(context),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '%$percentage',
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      color: AppColors.onAccent(context),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Doğru: $score / $totalQuestions',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary(context),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent(context),
                    foregroundColor: AppColors.onAccent(context),
                  ),
                  child: const Text('Ana Sayfaya Dön',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}