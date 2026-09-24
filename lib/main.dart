import 'dart:async';
import 'package:flutter/material.dart';
import 'duo_speech_widget.dart';
import 'screens/category_practice_screen.dart';
import 'screens/daily_exam_screen.dart';
import 'screens/dictionary_screen.dart';
import 'screens/flashcards_screen.dart';
import 'screens/listening_quiz_screen.dart';
import 'screens/marathon_screen.dart';
import 'screens/mistakes_screen.dart';
import 'screens/quiz_screen.dart';
import 'screens/sentence_builder_screen.dart';
import 'screens/statistics_screen.dart';
import 'screens/word_matching_screen.dart';
import 'services/daily_exam_service.dart';
import 'services/stats_service.dart';
import 'theme/app_colors.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TopikApp());
}

class TopikApp extends StatefulWidget {
  const TopikApp({super.key});

  @override
  State<TopikApp> createState() => _TopikAppState();
}

class _TopikAppState extends State<TopikApp> {
  bool _isDarkMode = false;

  void toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '한국어 퀴즈 - TOPIK',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF7F8FA),
        colorScheme: ColorScheme.light(
          primary: AppColors.lightAccent,
          onPrimary: AppColors.lightOnAccent,
          surface: Colors.white,
          onSurface: const Color(0xFF1E1E1E),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.lightAccent,
          foregroundColor: AppColors.lightOnAccent,
          elevation: 0,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        colorScheme: ColorScheme.dark(
          primary: AppColors.darkAccent,
          onPrimary: AppColors.darkOnAccent,
          surface: const Color(0xFF1E1E1E),
          onSurface: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.darkAccent,
          foregroundColor: AppColors.darkOnAccent,
          elevation: 0,
        ),
        useMaterial3: true,
      ),
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: HomeScreen(
        isDarkMode: _isDarkMode,
        toggleTheme: toggleTheme,
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback toggleTheme;

  const HomeScreen({
    super.key,
    required this.isDarkMode,
    required this.toggleTheme,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Duration _remaining = Duration.zero;
  bool _dailyAvailable = true;
  int _dailyScore = 0;
  String _dailyLevel = '-';
  int _streak = 1;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _refreshData();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  Future<void> _refreshData() async {
    final available = await DailyExamService.isAvailableToday();
    final score = await DailyExamService.lastScore();
    final level = await DailyExamService.lastLevel();
    final streak = await StatsService.getStreak();
    final rem = await DailyExamService.getRemainingDuration();

    if (!mounted) return;
    setState(() {
      _dailyAvailable = available;
      _dailyScore = score;
      _dailyLevel = level;
      _streak = streak;
      _remaining = rem;
    });
  }

  void _tick() {
    if (!_dailyAvailable && _remaining > Duration.zero) {
      setState(() {
        final next = _remaining - const Duration(seconds: 1);
        _remaining = next.isNegative ? Duration.zero : next;
        if (_remaining == Duration.zero) {
          _dailyAvailable = true;
        }
      });
    }
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
    _pageController.dispose();
    super.dispose();
  }

  void _goToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.accent(context),
        foregroundColor: AppColors.onAccent(context),
        title: Row(
          children: [
            Image.asset(
              'assets/images/cat_idle.png',
              width: 32,
              height: 32,
              errorBuilder: (context, error, stackTrace) => const Icon(Icons.pets, size: 24),
            ),
            const SizedBox(width: 8),
            Text(
              '한국어 퀴즈',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 19,
                color: AppColors.onAccent(context),
              ),
            ),
          ],
        ),
        actions: [
          // Seri Göstergesi
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: AppColors.onAccent(context).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Text('🔥', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 4),
                Text(
                  '$_streak Gün',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppColors.onAccent(context),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              widget.isDarkMode ? Icons.light_mode : Icons.dark_mode,
              color: AppColors.onAccent(context),
            ),
            tooltip: widget.isDarkMode ? 'Gündüz Modu' : 'Gece Modu',
            onPressed: widget.toggleTheme,
          ),
        ],
      ),
      body: Column(
        children: [
          // Sayfa Sekmeleri Göstergesi (Swipeable Tabs)
          Container(
            color: AppColors.accent(context),
            padding: const EdgeInsets.only(bottom: 10, left: 16, right: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _tabItem(0, 'Sınavlar', Icons.assignment_outlined),
                _tabItem(1, 'Oyunlar', Icons.extension_outlined),
                _tabItem(2, 'Sözlük & Tekrar', Icons.menu_book_outlined),
                _tabItem(3, 'İlerleme', Icons.insights_outlined),
              ],
            ),
          ),

          // Kaydırmalı Sayfalar (Swipeable Pages)
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) => setState(() => _currentPage = index),
              children: [
                _buildExamsPage(),
                _buildGamesPage(),
                _buildDictionaryAndReviewPage(),
                _buildProgressPage(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentPage,
        onDestinationSelected: _goToPage,
        backgroundColor: AppColors.card(context),
        indicatorColor: AppColors.accent(context),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment, color: AppColors.onAccent(context)),
            label: 'Sınavlar',
          ),
          NavigationDestination(
            icon: const Icon(Icons.extension_outlined),
            selectedIcon: Icon(Icons.extension, color: AppColors.onAccent(context)),
            label: 'Oyunlar',
          ),
          NavigationDestination(
            icon: const Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book, color: AppColors.onAccent(context)),
            label: 'Sözlük',
          ),
          NavigationDestination(
            icon: const Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights, color: AppColors.onAccent(context)),
            label: 'İlerleme',
          ),
        ],
      ),
    );
  }

  Widget _tabItem(int index, String title, IconData icon) {
    final selected = _currentPage == index;
    return GestureDetector(
      onTap: () => _goToPage(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.onAccent(context).withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 16,
                color: selected
                    ? AppColors.onAccent(context)
                    : AppColors.onAccent(context).withValues(alpha: 0.65)),
            const SizedBox(width: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                color: selected
                    ? AppColors.onAccent(context)
                    : AppColors.onAccent(context).withValues(alpha: 0.65),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // SAYFA 1: Günlük Sınav ve Denemeler
  Widget _buildExamsPage() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Maskot Karşılama
        DuoSpeechWidget(
          text: _dailyAvailable
              ? 'Annyeong! Bugün 20 soruluk sınavına girmeye hazır mısın?'
              : 'Bugünkü sınavını çözdün! İstediğin zaman pratik yapabilirsin.',
          state: _dailyAvailable ? CatState.idle : CatState.happy,
          catSize: 95,
        ),
        const SizedBox(height: 16),

        // 🌟 Günlük Sınav Kartı (20 Soru / 24 Saat)
        Container(
          decoration: BoxDecoration(
            color: AppColors.card(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.accent(context),
              width: 2.2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent(context).withValues(alpha: 0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.accent(context),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '⭐ Günlük Sınav',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.onAccent(context),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.soft(context),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.accent(context)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.schedule,
                              size: 14, color: AppColors.accent(context)),
                          const SizedBox(width: 4),
                          Text(
                            _dailyAvailable
                                ? 'Şimdi Açık!'
                                : _format(_remaining),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Günlük Sınav',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary(context),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '24 saatte bir yenilenen resmi TOPIK seviye belirleme sınavı. Tüm soru kategorilerini içerir.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary(context),
                  ),
                ),
                if (!_dailyAvailable) ...[
                  const SizedBox(height: 10),
                  Text(
                    'Son Puan: $_dailyScore / 200 ($_dailyLevel)',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.accent(context),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const DailyExamScreen(),
                        ),
                      );
                      _refreshData();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent(context),
                      foregroundColor: AppColors.onAccent(context),
                    ),
                    child: Text(
                      _dailyAvailable
                          ? 'Resmi Sınava Başla (20 Soru)'
                          : 'Sınavı Gör / Alıştırma Yap',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),

        // TOPIK Deneme Sınavı Kartı
        _activityCard(
          emoji: '📝',
          title: 'TOPIK Deneme Sınavı',
          subtitle: 'Havuzdan rastgele 20 soruyla sınırsız deneme sınavı',
          actionText: 'Denemeye Başla',
          builder: (_) => const QuizScreen(),
        ),
        const SizedBox(height: 14),

        // 60s Hız Maratonu Kartı
        _activityCard(
          emoji: '⚡',
          title: '60 Saniye Maratonu',
          subtitle: 'Süre bitmeden olabildiğince çok Korece soru çöz',
          actionText: 'Maratona Başla',
          builder: (_) => const MarathonScreen(),
        ),
      ],
    );
  }

  // SAYFA 2: Alıştırmalar ve Duolingo Eşleştirme Oyunu
  Widget _buildGamesPage() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Maskot
        DuoSpeechWidget(
          text: 'Duolingo tarzı eşleştirme ve cümle oyunlarıyla eğlenerek öğren!',
          state: CatState.talking,
          catSize: 90,
        ),
        const SizedBox(height: 16),

        // 🎴 Kelime Eşleştirme Kartı (Duolingo 5x5)
        Container(
          decoration: BoxDecoration(
            color: AppColors.card(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.accent(context),
              width: 2.2,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.accent(context),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '🎮 DUOLINGO TARZI',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.onAccent(context),
                        ),
                      ),
                    ),
                    const Text('🎴 5x5 Eşleştirme',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Kelime Eşleştirmece',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary(context),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '5 Korece ve 5 Türkçe kelime çiftini eşleştir. Her kelimede sesli telaffuz dinle!',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary(context),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const WordMatchingScreen(),
                        ),
                      );
                      _refreshData();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent(context),
                      foregroundColor: AppColors.onAccent(context),
                    ),
                    child: const Text('Eşleştirmeye Başla',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Dinleme Pratiği (듣기)
        _activityCard(
          emoji: '🎧',
          title: 'Dinleme Pratiği (듣기)',
          subtitle: 'Korece soruyu dinle, kulağını alıştır ve doğru seçeneği işaretle',
          actionText: 'Dinlemeye Başla',
          builder: (_) => const ListeningQuizScreen(),
        ),
        const SizedBox(height: 14),

        // Cümle Kurucu
        _activityCard(
          emoji: '🧩',
          title: 'Cümle Kurucu',
          subtitle: 'Kelimeleri sıraya dizerek Korece cümle oluştur ve dinle',
          actionText: 'Cümle Kur',
          builder: (_) => const SentenceBuilderScreen(),
        ),
        const SizedBox(height: 14),

        // Flashcards
        _activityCard(
          emoji: '📇',
          title: 'Flashcards',
          subtitle: 'Kartı çevir, Korece telaffuzunu duy ve anlamını gör',
          actionText: 'Kartları Çevir',
          builder: (_) => const FlashcardsScreen(),
        ),
        const SizedBox(height: 14),

        // Kategori Pratiği
        _activityCard(
          emoji: '🎯',
          title: 'Kategori Pratiği',
          subtitle: 'Dilbilgisi, meslekler, boşluk doldurma konularına göre çalış',
          actionText: 'Kategori Seç',
          builder: (_) => const CategoryPracticeScreen(),
        ),
      ],
    );
  }

  // SAYFA 3: Sözlük ve Yapılan Hatalar
  Widget _buildDictionaryAndReviewPage() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Maskot
        DuoSpeechWidget(
          text: 'Yeni kelimeler keşfet ve geçmişte yaptığın hataları incele!',
          state: CatState.idle,
          catSize: 90,
        ),
        const SizedBox(height: 16),

        // Sözlük Kartı
        _activityCard(
          emoji: '📚',
          title: 'Korece-Türkçe Sözlük',
          subtitle: 'Kelimeleri anında ara, okunuşlarını ve Türkçe anlamlarını sesli dinle',
          actionText: 'Sözlüğü Aç',
          builder: (_) => const DictionaryScreen(),
        ),
        const SizedBox(height: 14),

        // Yapılan Hatalar Kartı
        _activityCard(
          emoji: '❌',
          title: 'Yapılan Hatalar Defteri',
          subtitle: 'Testlerde yanlış işaretlediğin soruların doğru cevaplarını sesli tekrar et',
          actionText: 'Hataları İncele',
          builder: (_) => const MistakesScreen(),
        ),
      ],
    );
  }

  // SAYFA 4: İlerleme ve İstatistikler
  Widget _buildProgressPage() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        DuoSpeechWidget(
          text: 'İlerlemeni takip et, her gün düzenli çalışarak TOPIK seviyeni yükselt!',
          state: CatState.happy,
          catSize: 95,
        ),
        const SizedBox(height: 16),

        // Büyük İstatistik Özeti Kartı
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.card(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.accent(context), width: 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'İlerleme Özeti',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary(context),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.soft(context),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '🔥 $_streak Günlük Seri',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: AppColors.textPrimary(context),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Günlük Sınav Seviyen: $_dailyLevel',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.accent(context),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Son Sınav Puanı: $_dailyScore / 200',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary(context),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.bar_chart),
                  label: const Text('Tüm Detaylı İstatistikleri Gör'),
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const StatisticsScreen(),
                      ),
                    );
                    _refreshData();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent(context),
                    foregroundColor: AppColors.onAccent(context),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _activityCard({
    required String emoji,
    required String title,
    required String subtitle,
    required String actionText,
    required WidgetBuilder builder,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 32)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary(context),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: builder),
                  );
                  _refreshData();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent(context),
                  foregroundColor: AppColors.onAccent(context),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  actionText,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
