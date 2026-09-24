import 'dart:async';
import 'package:flutter/material.dart';
import '../models/question.dart';
import '../services/question_service.dart';
import '../services/stats_service.dart';
import '../services/tts_service.dart';
import '../theme/app_colors.dart';

class MarathonScreen extends StatefulWidget {
  const MarathonScreen({super.key});

  @override
  State<MarathonScreen> createState() => _MarathonScreenState();
}

class _MarathonScreenState extends State<MarathonScreen> {
  final QuestionService _questionService = QuestionService();
  List<Question> _questions = [];
  int _currentQuestionIndex = 0;
  int _score = 0;
  int _correctAnswers = 0;
  bool _isLoading = true;
  bool _hasAnswered = false;
  int? _selectedOption;
  Timer? _timer;
  int _timeLeft = 60;
  bool _gameStarted = false;
  bool _gameEnded = false;

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
      final shuffledQuestions = await _questionService.fetchShuffled();
      setState(() {
        _questions = shuffledQuestions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _startGame() {
    setState(() {
      _gameStarted = true;
      _currentQuestionIndex = 0;
      _score = 0;
      _correctAnswers = 0;
      _timeLeft = 60;
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _timeLeft--;
        if (_timeLeft <= 0) {
          _endGame();
        }
      });
    });

    if (_questions.isNotEmpty) {
      _speak(_questions[0].question);
    }
  }

  void _endGame() {
    _timer?.cancel();
    setState(() {
      _gameEnded = true;
    });
    final solved = _currentQuestionIndex + (_hasAnswered ? 1 : 0);
    StatsService.record(
      activity: '60s Maratonu',
      correct: _correctAnswers,
      total: solved == 0 ? 1 : solved,
    );
    _showResults();
  }

  void _selectOption(int index) {
    if (_hasAnswered || _gameEnded) return;

    final currentQuestion = _questions[_currentQuestionIndex];
    final isCorrect = index == currentQuestion.answer;

    setState(() {
      _selectedOption = index;
      _hasAnswered = true;
      if (isCorrect) {
        _score += 10;
        _correctAnswers++;
      }
    });

    _speak(currentQuestion.options[index]);

    Future.delayed(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      if (_currentQuestionIndex < _questions.length - 1) {
        setState(() {
          _currentQuestionIndex++;
          _hasAnswered = false;
          _selectedOption = null;
        });
        _speak(_questions[_currentQuestionIndex].question);
      } else {
        _endGame();
      }
    });
  }

  void _showResults() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Image.asset(
              'assets/images/cat_celebrate.png',
              width: 50,
              height: 50,
              errorBuilder: (context, error, stackTrace) => const Icon(Icons.pets, size: 40),
            ),
            const SizedBox(width: 12),
            const Text('Süre Doldu! ⏱️'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Doğru Cevap: $_correctAnswers',
                style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 6),
            Text('Toplam Skor: $_score Puan',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.accent(context))),
            const SizedBox(height: 6),
            Text('Çözülen Soru: ${_currentQuestionIndex + 1}',
                style: const TextStyle(fontSize: 14)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('Ana Sayfaya Dön'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _gameStarted = false;
                _gameEnded = false;
                _currentQuestionIndex = 0;
                _score = 0;
                _correctAnswers = 0;
                _timeLeft = 60;
              });
              _startGame();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent(context),
              foregroundColor: AppColors.onAccent(context),
            ),
            child: const Text('Tekrar Oyna'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    TtsService.instance.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('60s Maratonu'),
          backgroundColor: AppColors.accent(context),
          foregroundColor: AppColors.onAccent(context),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (!_gameStarted) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('60s Maratonu'),
          backgroundColor: AppColors.accent(context),
          foregroundColor: AppColors.onAccent(context),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/cat_idle.png',
                  width: 120,
                  height: 120,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.timer,
                    size: 80,
                    color: AppColors.accent(context),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  '60 Saniye Hız Maratonu',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary(context),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Süre dolmadan önce olabildiğince çok soruya doğru cevap ver!',
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.textSecondary(context),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _startGame,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent(context),
                      foregroundColor: AppColors.onAccent(context),
                    ),
                    child: const Text('Maratona Başla',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_gameEnded) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final currentQuestion = _questions[_currentQuestionIndex];

    return Scaffold(
      appBar: AppBar(
        title: const Text('60s Maratonu'),
        backgroundColor: AppColors.accent(context),
        foregroundColor: AppColors.onAccent(context),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            _timer?.cancel();
            Navigator.pop(context);
          },
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: _timeLeft <= 10
                  ? const Color(0xFFFF4B4B)
                  : AppColors.onAccent(context).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.timer,
                  size: 18,
                  color: _timeLeft <= 10
                      ? Colors.white
                      : AppColors.onAccent(context),
                ),
                const SizedBox(width: 6),
                Text(
                  '$_timeLeft s',
                  style: TextStyle(
                    color: _timeLeft <= 10
                        ? Colors.white
                        : AppColors.onAccent(context),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Skor Başlığı
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _metric(context, 'Puan', '$_score'),
                _metric(context, 'Doğru', '$_correctAnswers'),
                _metric(context, 'Soru', '${_currentQuestionIndex + 1}'),
              ],
            ),
          ),

          // Soru Kartı
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.card(context),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.accent(context), width: 2),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            currentQuestion.question,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary(context),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.volume_up,
                              color: AppColors.accent(context)),
                          onPressed: () => _speak(currentQuestion.question),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Seçenekler
                  ...List.generate(currentQuestion.options.length, (index) {
                    final option = currentQuestion.options[index];
                    final isSelected = _selectedOption == index;
                    final isCorrect = index == currentQuestion.answer;

                    Color tileBg;
                    Color textColor;

                    if (_hasAnswered) {
                      if (isCorrect) {
                        tileBg = AppColors.accent(context);
                        textColor = AppColors.onAccent(context);
                      } else if (isSelected && !isCorrect) {
                        tileBg = const Color(0xFFFF4B4B);
                        textColor = Colors.white;
                      } else {
                        tileBg = AppColors.card(context);
                        textColor = AppColors.textPrimary(context);
                      }
                    } else {
                      tileBg = AppColors.card(context);
                      textColor = AppColors.textPrimary(context);
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Material(
                        color: tileBg,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          onTap: () => _selectOption(index),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected || (_hasAnswered && isCorrect)
                                    ? AppColors.accent(context)
                                    : AppColors.border(context),
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              children: [
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
                                      size: 18, color: textColor),
                                  onPressed: () => _speak(option),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metric(BuildContext context, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 12, color: AppColors.textSecondary(context))),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.accent(context),
            ),
          ),
        ],
      ),
    );
  }
}
