# 🇰🇷 TOPIK Korece Hazırlık & Alıştırma Uygulaması

Flutter ile geliştirilmiş, **TOPIK (Test of Proficiency in Korean)** sınavına hazırlananlar ve Korece öğrenmek isteyenler için tasarlanmış kapsamlı, interaktif ve eğlenceli bir mobil öğrenme uygulaması.

---

## 📲 Doğrudan APK İndir & Kur

Uygulamanın hazır derlenmiş Android kurulum dosyasını doğrudan indirip telefonunuza kurabilirsiniz:

👉 **[📥 Android APK İndir (v1.0.0)](https://github.com/ayberkkr/topik-uygulama/releases/download/v1.0.0/topik_korece.apk)** *(Alternatif: [Depo İçi Dosya](./apk/topik_korece.apk))*

### Kurulum Adımları (Android):
1. Yukarıdaki bağlantıdan `topik_korece.apk` dosyasını telefonunuza indirin.
2. İndirilen dosyaya dokunun.
3. Cihazınız uyarı verirse: **Ayarlar ➔ "Bu kaynaktan yüklemeye izin ver"** (Bilinmeyen kaynaklar) seçeneğini aktif edin.
4. **"Yükle"** butonuna basarak kurulumu tamamlayın. Uygulama hemen kullanıma hazırdır!

---

## ✨ Uygulama Ne İşe Yarar? (Özellikler & Modüller)

Uygulama 4 ana sekmeden oluşur ve Korece dil öğrenimini oyunlaştırma ve aralıklı tekrar yöntemiyle destekler:

### 1. 📝 Sınavlar ve Denemeler
*   **⭐ 24 Saatlik Günlük Resmi Sınav:** 24 saatte bir açılan, 20 soruluk resmi TOPIK seviye belirleme sınavı. Gerçekçi puanlama (200 üzerinden) ve TOPIK seviye tahmini sunar.
*   **📝 TOPIK Deneme Sınavı:** Soru havuzundan rastgele 20 soruyla sınırsız deneme çözebileceğiniz pratik modu.
*   **⚡ 60 Saniye Maratonu:** Süre bitmeden olabildiğince çok soruya doğru cevap vererek reflekslerinizi test ettiğiniz hızlı mod.

### 2. 🎮 Oyunlar ve İnteraktif Pratik
*   **🎴 Duolingo Tarzı Kelime Eşleştirme (5x5):** Korece kelimeler ile Türkçe karşılıklarını kartlara dokunarak eşleştirin. Her dokunuşta sesli telaffuz dinletir.
*   **🎧 TOPIK Dinleme Pratiği (듣기):** Korece soruyu TTS ile seslendirir, dinleme kulağınızı geliştirir ve 4 seçenek arasından doğruyu bulmanızı ister (isteğe bağlı metin ipucu içerir).
*   **🧩 Cümle Kurucu:** Dağınık verilen Korece kelimeleri doğru sıraya dizerek anlamlı cümleler oluşturma oyunu.
*   **📇 Flashcards (Kelime & Soru Kartları):** Kartı çevir, Korece telaffuzunu dinle ve Türkçe anlamını gör.
*   **🎯 Kategori Pratiği:** Dilbilgisi, meslekler, boşluk doldurma gibi belirli konulara odaklı çalışma.

### 3. 📚 Sözlük ve Akıllı Tekrar
*   **📖 Korece - Türkçe Sözlük:** Kelimeleri anında arayın, okunuşlarını ve Türkçe karşılıklarını görün, telaffuzlarını dinleyin.
*   **⭐ Favori / Yıldızlı Kelimeler:** İstediğiniz kelimeleri yıldızlayarak favorilerinize ekleyin ve sadece favori kelimelerinizle özel **Flashcard** çalışması yapın.
*   **❌ Yapılan Hatalar Defteri:** Testlerde yanlış işaretlediğiniz tüm sorular burada toplanır.
*   **🔄 "Hataları Tekrar Çöz" Modu:** Yanlışlarınızı tekrar test edin. Doğru bildiğiniz sorular **hata defterinden otomatik olarak silinir**!

### 4. 📊 İlerleme, İstatistikler ve Başarımlar
*   **🔥 Günlük Seri (Streak):** Her gün düzenli çalışarak serinizi koruyun.
*   **📈 Detaylı Performans:** Toplam çözülen soru, doğru/yanlış oranları ve başarı yüzdesi takibi.
*   **🏆 Kazanılan Rozetler (Başarımlar):**
    *   🐣 *İlk Adım:* İlk testi tamamla
    *   🔥 *Seri Ateşi:* 3 gün aralıksız çalış
    *   🎯 *Keskin Göz:* %80+ başarı oranı yakala
    *   📚 *Kelime Kurdu:* 50 soru çöz
    *   👑 *TOPIK Ustası:* 100 soru çöz
    *   ⚡ *Hız Şampiyonu:* 60s maratona katıl
*   **💾 Kısmi İlerleme Koruması:** Testi yarıda bıraksanız bile çözdüğünüz tüm sorular ve doğrular anında istatistiklerinize işlenir.

### 5. 📶 Çevrimdışı (Offline) Desteği
*   Sorular canlı olarak GitHub Gist üzerinden çekilir; ancak internet bağlantısı olmadığında uygulama otomatik olarak yerel yedek soru havuzuna geçer. Metroda, seyahatte veya internetsiz ortamlarda da kesintisiz çalışır.

---

## 🛠️ Geliştiriciler İçin (Kaynak Koddan Çalıştırma)

### Gereksinimler:
*   [Flutter SDK](https://flutter.dev) (>= 3.12.1)
*   Dart SDK
*   Android Studio / VS Code

### Projeyi Çalıştırma:
```bash
# Bağımlılıkları yükleyin
flutter pub get

# Bağlı cihazda debug modunda çalıştırın
flutter run

# Yeni bir Android APK derleyin
flutter build apk --release
```

---

## 📦 Kullanılan Başlıca Paketler
*   `flutter_tts`: Korece seslendirme ve telaffuz motoru
*   `audioplayers`: Ses efektleri
*   `shared_preferences`: İlerleme, favoriler ve hata verilerinin yerel saklanması
*   `http`: Canlı soru havuzunun güncellenmesi
