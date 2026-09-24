import 'dart:math';
import 'package:flutter/material.dart';
import '../data/korean_sentences.dart';
import '../services/stats_service.dart';
import '../services/tts_service.dart';
import '../theme/app_colors.dart';

class SentenceBuilderScreen extends StatefulWidget {
  final bool recordStats;
  final int sentenceCount;
  final ValueChanged<int>? onCompleted;

  const SentenceBuilderScreen({
    super.key,
    this.recordStats = true,
    this.sentenceCount = 8,
    this.onCompleted,
  });

  @override
  State<SentenceBuilderScreen> createState() => _SentenceBuilderScreenState();
}

class _SentenceBuilderScreenState extends State<SentenceBuilderScreen> {
  late List<KoreanSentence> _sentences;
  int _currentIndex = 0;
  int _score = 0;
  List<String> _bank = [];
  List<String> _built = [];
  bool _hasAnswered = false;
  bool _isCorrect = false;

  @override
  void initState() {
    super.initState();
    final pool = List<KoreanSentence>.from(koreanSentences)..shuffle(Random());
    _sentences = pool.take(widget.sentenceCount).toList();
    _prepareCurrent();
  }

  void _prepareCurrent() {
    final words = List<String>.from(_sentences[_currentIndex].words)..shuffle(Random());
    _bank = words;
    _built = [];
    _hasAnswered = false;
    _isCorrect = false;
  }

  void _speak(String text) {
    TtsService.instance.speak(text);
  }

  void _addWord(String word) {
    if (_hasAnswered) return;
    setState(() {
      _built.add(word);
      _bank.remove(word);
    });
    _speak(word);
  }

  void _removeWord(int index) {
    if (_hasAnswered) return;
    setState(() {
      final word = _built.removeAt(index);
      _bank.add(word);
    });
  }

  void _checkAnswer() {
    final expected = _sentences[_currentIndex].korean;
    final actual = _built.join(' ');
    setState(() {
      _hasAnswered = true;
      _isCorrect = actual == expected;
      if (_isCorrect) _score++;
    });
    _speak(expected);
  }

  Future<void> _next() async {
    if (_currentIndex < _sentences.length - 1) {
      setState(() {
        _currentIndex++;
        _prepareCurrent();
      });
    } else {
      if (widget.recordStats) {
        await StatsService.record(
          activity: 'Cümle Kurucu',
          correct: _score,
          total: _sentences.length,
        );
      }
      if (widget.onCompleted != null) {
        widget.onCompleted!(_score);
        return;
      }
      if (!mounted) return;
      await showDialog<void>(
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
              const Text('Etkinlik Bitti! 🎉'),
            ],
          ),
          content: Text(
            'Toplam Doğru: $_score / ${_sentences.length}',
            style: const TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              child: const Text('Ana Sayfa'),
            ),
          ],
        ),
      );
    }
  }

  @override
  void dispose() {
    TtsService.instance.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sentence = _sentences[_currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cümle Kurucu'),
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
                '${_currentIndex + 1}/${_sentences.length}',
                style: TextStyle(
                  color: AppColors.onAccent(context),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Maskot & Türkçe Cümle
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Image.asset(
                  _hasAnswered
                      ? (_isCorrect
                          ? 'assets/images/cat_celebrate.png'
                          : 'assets/images/cat_idle.png')
                      : 'assets/images/cat_reading.png',
                  width: 70,
                  height: 70,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) =>
                      Icon(Icons.pets, size: 50, color: AppColors.accent(context)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.card(context),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border(context)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hedef Anlam:',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary(context),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          sentence.turkish,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Oluşturulan Cümle Alanı
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            constraints: const BoxConstraints(minHeight: 100),
            decoration: BoxDecoration(
              color: AppColors.card(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _hasAnswered
                    ? (_isCorrect
                        ? AppColors.accent(context)
                        : const Color(0xFFFF4B4B))
                    : AppColors.border(context),
                width: 2,
              ),
            ),
            child: _built.isEmpty
                ? Center(
                    child: Text(
                      'Aşağıdaki kelimelere dokunarak Korece cümleyi kur',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary(context)),
                    ),
                  )
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(_built.length, (index) {
                      return GestureDetector(
                        onTap: () => _removeWord(index),
                        child: _chip(_built[index], filled: true),
                      );
                    }),
                  ),
          ),

          // Doğru cevabın telaffuzu & gösterimi (cevap verilmişse)
          if (_hasAnswered) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Doğru: ${sentence.korean}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: _isCorrect
                            ? AppColors.accent(context)
                            : const Color(0xFFFF4B4B),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.volume_up, color: AppColors.accent(context)),
                    onPressed: () => _speak(sentence.korean),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Kelime Bankası
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SingleChildScrollView(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 10,
                  runSpacing: 10,
                  children: _bank
                      .map(
                        (word) => GestureDetector(
                          onTap: () => _addWord(word),
                          child: _chip(word, filled: false),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          ),

          // Alt Butonlar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed:
                          _built.isNotEmpty && !_hasAnswered ? _checkAnswer : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent(context),
                        foregroundColor: AppColors.onAccent(context),
                      ),
                      child: const Text('Kontrol Et',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _hasAnswered ? _next : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent(context),
                        foregroundColor: AppColors.onAccent(context),
                      ),
                      child: Text(
                        _currentIndex < _sentences.length - 1
                            ? 'Sonraki'
                            : 'Bitir',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String text, {required bool filled}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: filled ? AppColors.accent(context) : AppColors.card(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.accent(context),
          width: 1.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: filled
                  ? AppColors.onAccent(context)
                  : AppColors.textPrimary(context),
            ),
          ),
          if (!filled) ...[
            const SizedBox(width: 4),
            Icon(Icons.volume_up, size: 14, color: AppColors.accent(context)),
          ],
        ],
      ),
    );
  }
}
