class KoreanSentence {
  final String korean;
  final String turkish;

  const KoreanSentence({required this.korean, required this.turkish});

  List<String> get words => korean.split(' ');
}

const koreanSentences = [
  KoreanSentence(korean: '저는 학생입니다', turkish: 'Ben öğrenciyim'),
  KoreanSentence(korean: '오늘 날씨가 좋아요', turkish: 'Bugün hava güzel'),
  KoreanSentence(korean: '이거 얼마예요', turkish: 'Bu kaç para'),
  KoreanSentence(korean: '만나서 반갑습니다', turkish: 'Tanıştığımıza memnun oldum'),
  KoreanSentence(korean: '한국어를 공부해요', turkish: 'Korece çalışıyorum'),
  KoreanSentence(korean: '물을 마시고 싶어요', turkish: 'Su içmek istiyorum'),
  KoreanSentence(korean: '친구를 만나요', turkish: 'Arkadaşla buluşuyorum'),
  KoreanSentence(korean: '학교에 가요', turkish: 'Okula gidiyorum'),
  KoreanSentence(korean: '밥을 먹었어요', turkish: 'Yemek yedim'),
  KoreanSentence(korean: '집에 있어요', turkish: 'Evdeyim'),
];
