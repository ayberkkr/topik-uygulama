import 'dart:math';
import 'package:flutter/material.dart';
import '../data/word_pairs.dart';
import '../services/stats_service.dart';
import '../services/tts_service.dart';
import '../theme/app_colors.dart';

class WordMatchingScreen extends StatefulWidget {
  final bool recordStats;
  final int pairCount;
  final ValueChanged<int>? onCompleted;

  const WordMatchingScreen({
    super.key,
    this.recordStats = true,
    this.pairCount = 5,
    this.onCompleted,
  });

  @override
  State<WordMatchingScreen> createState() => _WordMatchingScreenState();
}

class _WordMatchingScreenState extends State<WordMatchingScreen> {
  late List<Map<String, String>> _pairs;
  late List<Map<String, String>> _koreanCards;
  late List<Map<String, String>> _turkishCards;
  final Set<String> _matchedKoreans = {};
  String? _selectedKorean;
  String? _selectedTurkish;
  bool _isWrongMatch = false;
  int _score = 0;
  int _attempts = 0;
  int _round = 1;
  bool _busy = false;
  String _mascotImage = 'assets/images/cat_idle.png';
  String _mascotSpeech = 'Kelimeleri doğru karşılıklarıyla eşleştir!';

  @override
  void initState() {
    super.initState();
    _setupRound();
  }

  void _setupRound() {
    final pool = List<Map<String, String>>.from(wordPairs)..shuffle(Random());
    // Kesinlikle 5 çift al
    final count = min(widget.pairCount, pool.length);
    _pairs = pool.take(count).toList();
    _koreanCards = List<Map<String, String>>.from(_pairs)..shuffle(Random());
    _turkishCards = List<Map<String, String>>.from(_pairs)..shuffle(Random());
    _matchedKoreans.clear();
    _selectedKorean = null;
    _selectedTurkish = null;
    _isWrongMatch = false;
    _busy = false;
    _mascotImage = 'assets/images/cat_idle.png';
    _mascotSpeech = '5 Korece ve 5 Türkçe kelimeyi eşleştir!';
  }

  void _selectKorean(String korean) {
    if (_busy || _matchedKoreans.contains(korean)) return;

    TtsService.instance.speak(korean);
    setState(() {
      _selectedKorean = korean;
      _isWrongMatch = false;
    });

    if (_selectedTurkish != null) {
      _tryMatch();
    }
  }

  void _selectTurkish(String turkish) {
    if (_busy) return;
    final alreadyMatched = _pairs.any(
      (pair) =>
          pair['turkish'] == turkish && _matchedKoreans.contains(pair['korean']),
    );
    if (alreadyMatched) return;

    setState(() {
      _selectedTurkish = turkish;
      _isWrongMatch = false;
    });

    if (_selectedKorean != null) {
      _tryMatch();
    }
  }

  Future<void> _tryMatch() async {
    final korean = _selectedKorean;
    final turkish = _selectedTurkish;
    if (korean == null || turkish == null) return;

    _busy = true;
    _attempts++;

    final isMatch = _pairs.any(
      (pair) => pair['korean'] == korean && pair['turkish'] == turkish,
    );

    if (isMatch) {
      setState(() {
        _matchedKoreans.add(korean);
        _score += 20;
        _selectedKorean = null;
        _selectedTurkish = null;
        _busy = false;
        _mascotImage = 'assets/images/cat_celebrate.png';
        _mascotSpeech = 'Harika eşleşme! 👏';
      });

      if (_matchedKoreans.length == _pairs.length) {
        await _finishRound();
      }
    } else {
      setState(() {
        _isWrongMatch = true;
        _mascotImage = 'assets/images/cat_reading.png';
        _mascotSpeech = 'Tekrar dene, başarabilirsin!';
      });

      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      setState(() {
        _selectedKorean = null;
        _selectedTurkish = null;
        _isWrongMatch = false;
        _busy = false;
      });
    }
  }

  Future<void> _finishRound() async {
    if (widget.recordStats) {
      await StatsService.record(
        activity: 'Kelime Eşleştirme',
        correct: _matchedKoreans.length,
        total: _attempts == 0 ? _pairs.length : _attempts,
      );
    }

    if (widget.onCompleted != null) {
      widget.onCompleted!(_matchedKoreans.length);
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
            const Text('Tebrikler! 🎉'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '5 kelime çiftinin tamamını başarıyla eşleştirdin!',
              style: TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 12),
            Text(
              'Puan: $_score',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.accent(context),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('Ana Sayfa'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _round++;
                _setupRound();
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent(context),
              foregroundColor: AppColors.onAccent(context),
            ),
            child: const Text('Yeni 5 Kelime'),
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
    final progress = _pairs.isEmpty ? 0.0 : _matchedKoreans.length / _pairs.length;

    return Scaffold(
      appBar: AppBar(
        title: Text('Kelime Eşleştirme (Tur $_round)'),
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
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.onAccent(context).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Puan: $_score',
                  style: TextStyle(
                    color: AppColors.onAccent(context),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // İlerleme Çubuğu
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 10,
                      backgroundColor: AppColors.border(context),
                      color: AppColors.accent(context),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${_matchedKoreans.length} / ${_pairs.length}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary(context),
                  ),
                ),
              ],
            ),
          ),

          // Maskot & Duo Tarzı Konuşma Balonu
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                Image.asset(
                  _mascotImage,
                  width: 56,
                  height: 56,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) =>
                      Icon(Icons.pets, size: 40, color: AppColors.accent(context)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.card(context),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border(context)),
                    ),
                    child: Text(
                      _mascotSpeech,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary(context),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Sütun Başlıkları
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '🇰🇷 Korece',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.textSecondary(context),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '🇹🇷 Türkçe',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.textSecondary(context),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // 5 Korece ve 5 Türkçe Kartlar
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Expanded(child: _buildKoreanList()),
                  const SizedBox(width: 10),
                  Expanded(child: _buildTurkishList()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKoreanList() {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _koreanCards.length,
      itemBuilder: (context, index) {
        final korean = _koreanCards[index]['korean']!;
        final matched = _matchedKoreans.contains(korean);
        final selected = _selectedKorean == korean;
        final isWrong = selected && _isWrongMatch;

        return _buildCardTile(
          text: korean,
          matched: matched,
          selected: selected,
          isWrong: isWrong,
          isKorean: true,
          onTap: () => _selectKorean(korean),
        );
      },
    );
  }

  Widget _buildTurkishList() {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _turkishCards.length,
      itemBuilder: (context, index) {
        final turkish = _turkishCards[index]['turkish']!;
        final matched = _pairs.any(
          (pair) =>
              pair['turkish'] == turkish &&
              _matchedKoreans.contains(pair['korean']),
        );
        final selected = _selectedTurkish == turkish;
        final isWrong = selected && _isWrongMatch;

        return _buildCardTile(
          text: turkish,
          matched: matched,
          selected: selected,
          isWrong: isWrong,
          isKorean: false,
          onTap: () => _selectTurkish(turkish),
        );
      },
    );
  }

  Widget _buildCardTile({
    required String text,
    required bool matched,
    required bool selected,
    required bool isWrong,
    required bool isKorean,
    required VoidCallback onTap,
  }) {
    Color bgColor;
    Color borderColor;
    Color textColor;

    if (matched) {
      bgColor = AppColors.accent(context);
      borderColor = AppColors.accent(context);
      textColor = AppColors.onAccent(context);
    } else if (isWrong) {
      bgColor = const Color(0xFFFF4B4B).withValues(alpha: 0.2);
      borderColor = const Color(0xFFFF4B4B);
      textColor = const Color(0xFFFF4B4B);
    } else if (selected) {
      bgColor = AppColors.soft(context);
      borderColor = AppColors.accent(context);
      textColor = AppColors.textPrimary(context);
    } else {
      bgColor = AppColors.card(context);
      borderColor = AppColors.border(context);
      textColor = AppColors.textPrimary(context);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: matched ? null : onTap,
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: borderColor,
                width: selected || matched || isWrong ? 2.5 : 1.5,
              ),
              boxShadow: selected && !matched
                  ? [
                      BoxShadow(
                        color: AppColors.accent(context).withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isKorean && !matched) ...[
                  Icon(Icons.volume_up, size: 16, color: borderColor),
                  const SizedBox(width: 6),
                ],
                Flexible(
                  child: Text(
                    text,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ),
                if (matched) ...[
                  const SizedBox(width: 6),
                  Icon(Icons.check, size: 16, color: textColor),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
