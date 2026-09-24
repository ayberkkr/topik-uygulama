import 'package:flutter/material.dart';
import '../models/question.dart';
import '../services/question_service.dart';
import '../services/tts_service.dart';
import '../theme/app_colors.dart';

class CategoryPracticeScreen extends StatefulWidget {
  const CategoryPracticeScreen({super.key});

  @override
  State<CategoryPracticeScreen> createState() => _CategoryPracticeScreenState();
}

class _CategoryPracticeScreenState extends State<CategoryPracticeScreen> {
  final QuestionService _questionService = QuestionService();
  Map<String, List<Question>> _categories = {};
  bool _isLoading = true;
  String? _selectedCategory;

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
      final questions = await _questionService.fetchQuestions();
      final categories = <String, List<Question>>{};
      for (var question in questions) {
        final category = question.type.trim().isEmpty ? 'Genel' : question.type;
        if (!categories.containsKey(category)) {
          categories[category] = [];
        }
        categories[category]!.add(question);
      }

      setState(() {
        _categories = categories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _selectCategory(String category) {
    setState(() {
      _selectedCategory = category;
    });
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
          title: const Text('Kategori Pratiği'),
          backgroundColor: AppColors.accent(context),
          foregroundColor: AppColors.onAccent(context),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_selectedCategory == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Kategori Pratiği'),
          backgroundColor: AppColors.accent(context),
          foregroundColor: AppColors.onAccent(context),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _categories.length,
          itemBuilder: (context, index) {
            final category = _categories.keys.elementAt(index);
            final questionCount = _categories[category]!.length;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppColors.card(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border(context)),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.soft(context),
                  child: Icon(Icons.category, color: AppColors.accent(context)),
                ),
                title: Text(
                  category,
                  style: TextStyle(
                    color: AppColors.textPrimary(context),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  '$questionCount soru',
                  style: TextStyle(color: AppColors.textSecondary(context)),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _selectCategory(category),
              ),
            );
          },
        ),
      );
    }

    final categoryQuestions = _categories[_selectedCategory]!;

    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedCategory!),
        backgroundColor: AppColors.accent(context),
        foregroundColor: AppColors.onAccent(context),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            setState(() {
              _selectedCategory = null;
            });
          },
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: categoryQuestions.length,
        itemBuilder: (context, index) {
          final question = categoryQuestions[index];

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
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
                      question.question,
                      style: TextStyle(
                        color: AppColors.textPrimary(context),
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.volume_up,
                        size: 20, color: AppColors.accent(context)),
                    onPressed: () => _speak(question.question),
                  ),
                ],
              ),
              subtitle: Text(
                'Doğru Cevap: ${question.options[question.answer]}',
                style: TextStyle(
                  color: AppColors.textSecondary(context),
                  fontWeight: FontWeight.w500,
                ),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Şıkların listesi
                      ...List.generate(question.options.length, (optIdx) {
                        final isAnswer = optIdx == question.answer;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 10,
                                backgroundColor: isAnswer
                                    ? AppColors.accent(context)
                                    : AppColors.soft(context),
                                child: Text(
                                  String.fromCharCode(65 + optIdx),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isAnswer
                                        ? AppColors.onAccent(context)
                                        : AppColors.textPrimary(context),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  question.options[optIdx],
                                  style: TextStyle(
                                    fontWeight: isAnswer
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: isAnswer
                                        ? AppColors.accent(context)
                                        : AppColors.textPrimary(context),
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.volume_up, size: 16),
                                onPressed: () =>
                                    _speak(question.options[optIdx]),
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 8),
                      // Açıklama
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.soft(context),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          question.explanation,
                          style: TextStyle(
                            color: AppColors.textPrimary(context),
                            fontSize: 13,
                          ),
                        ),
                      ),
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
