import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/tts_service.dart';
import '../theme/app_colors.dart';
import 'flashcards_screen.dart';

class DictionaryScreen extends StatefulWidget {
  const DictionaryScreen({super.key});

  @override
  State<DictionaryScreen> createState() => _DictionaryScreenState();
}

class _DictionaryScreenState extends State<DictionaryScreen> {
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _favoriteWords = {};
  bool _favoritesOnly = false;
  final List<Map<String, String>> _dictionary = [
    {'korean': '안녕하세요', 'turkish': 'Merhaba', 'pronunciation': 'Annyeonghaseyo'},
    {'korean': '감사합니다', 'turkish': 'Teşekkür ederim', 'pronunciation': 'Gamsahamnida'},
    {'korean': '죄송합니다', 'turkish': 'Özür dilerim', 'pronunciation': 'Joesonghamnida'},
    {'korean': '사랑해요', 'turkish': 'Seni seviyorum', 'pronunciation': 'Saranghaeyo'},
    {'korean': '좋아요', 'turkish': 'Seviyorum / Beğeniyorum', 'pronunciation': 'Joayo'},
    {'korean': '싫어요', 'turkish': 'Nefret ediyorum / Sevmiyorum', 'pronunciation': 'Sireoyo'},
    {'korean': '배고파요', 'turkish': 'Açım', 'pronunciation': 'Baegopayo'},
    {'korean': '목말라요', 'turkish': 'Susuzum', 'pronunciation': 'Mokmalla-yo'},
    {'korean': '피곤해요', 'turkish': 'Yorgunum', 'pronunciation': 'Pigonhaeyo'},
    {'korean': '기분이 좋아요', 'turkish': 'Keyfim yerinde', 'pronunciation': 'Gibuni joayo'},
    {'korean': '아파요', 'turkish': 'Ağrıyor / Hastayım', 'pronunciation': 'Apayo'},
    {'korean': '학생', 'turkish': 'Öğrenci', 'pronunciation': 'Haksaeng'},
    {'korean': '선생님', 'turkish': 'Öğretmen', 'pronunciation': 'Seonsaengnim'},
    {'korean': '의사', 'turkish': 'Doktor', 'pronunciation': 'Uisa'},
    {'korean': '간호사', 'turkish': 'Hemşire', 'pronunciation': 'Ganhosa'},
    {'korean': '경찰', 'turkish': 'Polis', 'pronunciation': 'Gyeongchal'},
    {'korean': '병원', 'turkish': 'Hastane', 'pronunciation': 'Byeongwon'},
    {'korean': '학교', 'turkish': 'Okul', 'pronunciation': 'Hakgyo'},
    {'korean': '집', 'turkish': 'Ev', 'pronunciation': 'Jip'},
    {'korean': '가족', 'turkish': 'Aile', 'pronunciation': 'Gajok'},
    {'korean': '친구', 'turkish': 'Arkadaş', 'pronunciation': 'Chingu'},
    {'korean': '음식', 'turkish': 'Yemek', 'pronunciation': 'Eumsik'},
    {'korean': '물', 'turkish': 'Su', 'pronunciation': 'Mul'},
    {'korean': '밥', 'turkish': 'Pirinç / Yemek', 'pronunciation': 'Bap'},
    {'korean': '사과', 'turkish': 'Elma', 'pronunciation': 'Sagwa'},
    {'korean': '바나나', 'turkish': 'Muz', 'pronunciation': 'Banana'},
    {'korean': '자동차', 'turkish': 'Otomobil / Araba', 'pronunciation': 'Jadongcha'},
    {'korean': '버스', 'turkish': 'Otobüs', 'pronunciation': 'Beoseu'},
    {'korean': '지하철', 'turkish': 'Metro', 'pronunciation': 'Jihacheol'},
    {'korean': '비행기', 'turkish': 'Uçak', 'pronunciation': 'Bihaenggi'},
    {'korean': '시간', 'turkish': 'Zaman / Saat', 'pronunciation': 'Sigan'},
    {'korean': '날씨', 'turkish': 'Hava durumu', 'pronunciation': 'Nalssi'},
    {'korean': '봄', 'turkish': 'İlkbahar', 'pronunciation': 'Bom'},
    {'korean': '여름', 'turkish': 'Yaz', 'pronunciation': 'Yeoreum'},
    {'korean': '가을', 'turkish': 'Sonbahar', 'pronunciation': 'Gaeul'},
    {'korean': '겨울', 'turkish': 'Kış', 'pronunciation': 'Gyeoul'},
    {'korean': '책', 'turkish': 'Kitap', 'pronunciation': 'Chaek'},
    {'korean': '고양이', 'turkish': 'Kedi', 'pronunciation': 'Goyangi'},
    {'korean': '강아지', 'turkish': 'Köpek yavrusu / Köpek', 'pronunciation': 'Gang-aji'},
    {'korean': '돈', 'turkish': 'Para', 'pronunciation': 'Don'},
    {'korean': '가방', 'turkish': 'Çanta', 'pronunciation': 'Gabang'},
    {'korean': '옷', 'turkish': 'Kıyafet', 'pronunciation': 'Ot'},
    {'korean': '한국', 'turkish': 'Güney Kore', 'pronunciation': 'Hanguk'},
    {'korean': '터키', 'turkish': 'Türkiye', 'pronunciation': 'Teoki'},
  ];

  List<Map<String, String>> _filteredDictionary = [];

  @override
  void initState() {
    super.initState();
    _filteredDictionary = _dictionary;
    _searchController.addListener(_filterDictionary);
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favList = prefs.getStringList('favorite_words') ?? [];
    if (!mounted) return;
    setState(() {
      _favoriteWords.addAll(favList);
    });
    _filterDictionary();
  }

  Future<void> _toggleFavorite(String korean) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      if (_favoriteWords.contains(korean)) {
        _favoriteWords.remove(korean);
      } else {
        _favoriteWords.add(korean);
      }
    });
    await prefs.setStringList('favorite_words', _favoriteWords.toList());
    _filterDictionary();
  }

  void _speakKorean(String text) {
    TtsService.instance.speak(text);
  }

  void _filterDictionary() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      var list = _dictionary;
      if (_favoritesOnly) {
        list = list.where((w) => _favoriteWords.contains(w['korean'])).toList();
      }
      if (query.isNotEmpty) {
        list = list.where((word) {
          return word['korean']!.toLowerCase().contains(query) ||
              word['turkish']!.toLowerCase().contains(query) ||
              word['pronunciation']!.toLowerCase().contains(query);
        }).toList();
      }
      _filteredDictionary = list;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    TtsService.instance.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Korece-Türkçe Sözlük'),
        backgroundColor: AppColors.accent(context),
        foregroundColor: AppColors.onAccent(context),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Arama Kutusu
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Korece, Türkçe veya okunuşla ara...',
                prefixIcon: Icon(Icons.search, color: AppColors.accent(context)),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.card(context),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: AppColors.border(context)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: AppColors.border(context)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: AppColors.accent(context), width: 2),
                ),
              ),
            ),
          ),

          // Filtre Seçenekleri
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                FilterChip(
                  label: Text('Tümü (${_dictionary.length})'),
                  selected: !_favoritesOnly,
                  onSelected: (val) {
                    setState(() {
                      _favoritesOnly = false;
                      _filterDictionary();
                    });
                  },
                  selectedColor: AppColors.accent(context).withValues(alpha: 0.2),
                  checkmarkColor: AppColors.accent(context),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  avatar: Icon(
                    Icons.star,
                    size: 16,
                    color: _favoritesOnly ? Colors.amber : AppColors.textSecondary(context),
                  ),
                  label: Text('Favorilerim (${_favoriteWords.length})'),
                  selected: _favoritesOnly,
                  onSelected: (val) {
                    setState(() {
                      _favoritesOnly = true;
                      _filterDictionary();
                    });
                  },
                  selectedColor: AppColors.accent(context).withValues(alpha: 0.2),
                  checkmarkColor: AppColors.accent(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Favorilerle Flashcard Çalış Butonu
          if (_favoritesOnly && _favoriteWords.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.style),
                  label: const Text('Favori Kelimelerle Flashcard Çalış'),
                  onPressed: () {
                    final favList = _dictionary
                        .where((w) => _favoriteWords.contains(w['korean']))
                        .toList();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FlashcardsScreen(
                          customWords: favList,
                          title: 'Favori Kelimeler',
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent(context),
                    foregroundColor: AppColors.onAccent(context),
                  ),
                ),
              ),
            ),

          // Sözlük Listesi
          Expanded(
            child: _filteredDictionary.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        _favoritesOnly
                            ? 'Henüz favori kelime eklemediniz.\nKelimelerin yanındaki yıldıza dokunarak favorilerinize ekleyebilirsiniz!'
                            : 'Aramanıza uygun kelime bulunamadı',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textSecondary(context)),
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: _filteredDictionary.length,
                    itemBuilder: (context, index) {
                      final word = _filteredDictionary[index];
                      final isFav = _favoriteWords.contains(word['korean']);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: AppColors.card(context),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border(context)),
                        ),
                        child: ListTile(
                          title: Row(
                            children: [
                              Text(
                                word['korean']!,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary(context),
                                ),
                              ),
                              const SizedBox(width: 4),
                              IconButton(
                                icon: Icon(Icons.volume_up,
                                    size: 20, color: AppColors.accent(context)),
                                onPressed: () => _speakKorean(word['korean']!),
                              ),
                              const Spacer(),
                              IconButton(
                                icon: Icon(
                                  isFav ? Icons.star : Icons.star_border,
                                  color: isFav ? Colors.amber : AppColors.textSecondary(context),
                                  size: 22,
                                ),
                                onPressed: () => _toggleFavorite(word['korean']!),
                              ),
                            ],
                          ),
                          subtitle: Text(
                            'Okunuş: ${word['pronunciation']!}',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary(context),
                            ),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.soft(context),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              word['turkish']!,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary(context),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
