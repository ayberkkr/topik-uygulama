import 'package:flutter/material.dart';
import '../models/question.dart';
import '../services/question_service.dart';
import '../services/stats_service.dart';
import '../services/tts_service.dart';
import '../theme/app_colors.dart';

class FlashcardsScreen extends StatefulWidget {
  final List<Map<String, String>>? customWords;
  final String? title;

  const FlashcardsScreen({
    super.key,
    this.customWords,
    this.title,
  });

  @override
  State<FlashcardsScreen> createState() => _FlashcardsScreenState();
}

class _FlashcardsScreenState extends State<FlashcardsScreen> {
  final QuestionService _questionService = QuestionService();
  List<Question> _questions = [];
  int _currentIndex = 0;
  bool _isLoading = true;
  bool _showAnswer = false;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  void _speak(String text) {
    TtsService.instance.speak(text);
  }

  Future<void> _loadQuestions() async {
    if (widget.customWords != null && widget.customWords!.isNotEmpty) {
      final list = widget.customWords!.map((word) {
        return Question(
          id: 0,
          type: 'Kelime Kartı',
          question: word['korean'] ?? '',
          options: [word['turkish'] ?? '', word['pronunciation'] ?? ''],
          answer: 0,
          explanation: 'Okunuş: ${word['pronunciation'] ?? ''}',
        );
      }).toList()..shuffle();

      setState(() {
        _questions = list;
        _isLoading = false;
      });
      if (list.isNotEmpty) {
        _speak(list[0].question);
      }
      return;
    }

    try {
      final selectedQuestions = await _questionService.fetchShuffled(limit: 20);
      setState(() {
        _questions = selectedQuestions;
        _isLoading = false;
      });
      if (selectedQuestions.isNotEmpty) {
        _speak(selectedQuestions[0].question);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _flipCard() {
    setState(() {
      _showAnswer = !_showAnswer;
    });
    if (_showAnswer && _questions.isNotEmpty) {
      final q = _questions[_currentIndex];
      _speak(q.options[q.answer]);
    }
  }

  void _nextCard() {
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        _showAnswer = false;
      });
      _speak(_questions[_currentIndex].question);
    } else {
      StatsService.record(
        activity: 'Flashcards (Tekrar)',
        correct: _questions.length,
        total: _questions.length,
      );
    }
  }

  void _previousCard() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _showAnswer = false;
      });
      _speak(_questions[_currentIndex].question);
    }
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
          title: const Text('Flashcards'),
          backgroundColor: AppColors.accent(context),
          foregroundColor: AppColors.onAccent(context),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Flashcards'),
          backgroundColor: AppColors.accent(context),
          foregroundColor: AppColors.onAccent(context),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(child: Text('Soru bulunamadı')),
      );
    }

    final currentQuestion = _questions[_currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title ?? 'Flashcards'),
        backgroundColor: AppColors.accent(context),
        foregroundColor: AppColors.onAccent(context),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                '${_currentIndex + 1} / ${_questions.length}',
                style: TextStyle(
                  color: AppColors.onAccent(context),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Flashcard
          Expanded(
            child: Center(
              child: GestureDetector(
                onTap: _flipCard,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: MediaQuery.of(context).size.width * 0.9,
                  height: MediaQuery.of(context).size.height * 0.52,
                  decoration: BoxDecoration(
                    color: AppColors.card(context),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.accent(context),
                      width: 2.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: _showAnswer
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.soft(context),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Cevap',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.accent(context),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                currentQuestion.options[currentQuestion.answer],
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary(context),
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 10),
                              IconButton(
                                icon: Icon(Icons.volume_up,
                                    size: 32, color: AppColors.accent(context)),
                                onPressed: () => _speak(currentQuestion
                                    .options[currentQuestion.answer]),
                              ),
                              const SizedBox(height: 12),
                              if (currentQuestion.explanation.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.soft(context),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    currentQuestion.explanation,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: AppColors.textPrimary(context),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.soft(context),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  currentQuestion.type,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary(context),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 18),
                              Text(
                                currentQuestion.question,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary(context),
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 18),
                              IconButton(
                                icon: Icon(Icons.volume_up,
                                    size: 36, color: AppColors.accent(context)),
                                onPressed: () =>
                                    _speak(currentQuestion.question),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Cevabı görmek için karta dokun',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary(context),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ),

          // Kontrol butonları
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _currentIndex > 0 ? _previousCard : null,
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Önceki'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent(context),
                    foregroundColor: AppColors.onAccent(context),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _flipCard,
                  icon: Icon(_showAnswer
                      ? Icons.visibility_off
                      : Icons.visibility),
                  label: Text(_showAnswer ? 'Soru' : 'Cevap'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent(context),
                    foregroundColor: AppColors.onAccent(context),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _currentIndex < _questions.length - 1
                      ? _nextCard
                      : null,
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Sonraki'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent(context),
                    foregroundColor: AppColors.onAccent(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
