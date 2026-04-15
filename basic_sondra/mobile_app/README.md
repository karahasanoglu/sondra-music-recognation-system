# Sondra Mobile — Detaylı README

Sondra Mobile, Flutter ile geliştirilmiş mobil istemci ve Python/FastAPI tabanlı backend kullanan, fingerprint tabanlı bir şarkı tanıma uygulamasıdır.

Bu README, projeyi **sıfırdan kurmak**, **doğru klasörlerde doğru komutları çalıştırmak**, **iki ayrı terminal ile backend + Flutter sürecini yönetmek**, **emulator ve gerçek cihaz farkını anlamak** ve **başka birine projeyi çalıştırması için vermek** amacıyla detaylı şekilde hazırlanmıştır.

---

# 1. Proje Yapısı

Aşağıdaki yapı örnek alınmıştır:

```text
basic-sondra/
├── core/                    # spectrogram, peak detection, fingerprint üretimi
├── scripts/                 # backend API, eşleştirme ve yardımcı scriptler
│   ├── mobile_api.py
│   └── match_song.py
├── web_app/                 # web arayüzü
├── mobile_app/              # Flutter mobil uygulaması
│   ├── lib/
│   ├── android/
│   ├── pubspec.yaml
│   └── ...
├── requirements.txt         # varsa Python bağımlılıkları
└── README.md
```

## Çok önemli klasör ayrımı

Bu projede iki farklı çalışma alanı vardır:

### A) Ana proje klasörü
Bu klasör backend içindir.

Örnek:
```text
C:\Users\ONUR\Downloads\basic-sondra\basic-sondra
```

Bu klasörde şunlar bulunur:
- `scripts/`
- `core/`
- `web_app/`
- `mobile_app/`

### B) Flutter klasörü
Bu klasör yalnızca mobil uygulama içindir.

Örnek:
```text
C:\Users\ONUR\Downloads\basic-sondra\basic-sondra\mobile_app
```

Bu klasörde şunlar bulunur:
- `pubspec.yaml`
- `lib/`
- `android/`

---

# 2. Gereksinimler

## 2.1 Backend için gerekli olanlar

Aşağıdakiler yüklü olmalıdır:

- Python 3.10 veya üstü
- PostgreSQL
- Şarkı veritabanı
- Fingerprint kayıtları
- pip
- Gerekli Python paketleri

## 2.2 Flutter için gerekli olanlar

- Flutter SDK
- Android Studio
- Android SDK
- Android command-line tools
- VS Code veya Android Studio
- USB debugging açık Android telefon veya Android emulator

## 2.3 Veritabanı için gerekli olanlar

Aşağıdaki tabloların dolu olması gerekir:

- `songs`
- `fingerprints`

Eğer bu tablolar boşsa uygulama çalışsa bile şarkı eşleştirme düzgün sonuç vermez.

---

# 3. Kullanılan Temel Teknolojiler

## Backend
- FastAPI
- Uvicorn
- PostgreSQL
- NumPy
- SoundFile
- fingerprint/spectrogram altyapısı

## Mobil taraf
- Flutter
- Dart
- `record`
- `permission_handler`
- `sensors_plus`
- `http`
- `path_provider`

---

# 4. Veritabanı Ayarları

Backend kodunda varsayılan bağlantı ayarları şu şekildedir:

```text
host=127.0.0.1
port=5433
database=mydb
user=postgres
password=1234
```

Kod environment variable da okuyabilir:

- `SONDRA_DB_HOST`
- `SONDRA_DB_PORT`
- `SONDRA_DB_NAME`
- `SONDRA_DB_USER`
- `SONDRA_DB_PASSWORD`

Kendi bilgisayarında veritabanı farklı portta veya farklı kullanıcıyla çalışıyorsa bunu buna göre düzenlemelisin.

---

# 5. Komutları Hangi Klasörde Çalıştıracağım?

Bu en önemli kısım.

## Backend komutları NEREDE çalıştırılır?
**Ana proje klasöründe**

Doğru klasör:
```text
basic-sondra\basic-sondra
```

## Flutter komutları NEREDE çalıştırılır?
**mobile_app klasöründe**

Doğru klasör:
```text
basic-sondra\basic-sondra\mobile_app
```

---

# 6. İki Ayrı Terminal Kullanımı

Bu projede **iki ayrı terminal** kullanman önerilir.

## Terminal 1 — Backend terminali
Bu terminalde Python API çalışır.

Bu terminal:
- ana proje klasöründe olur
- kapanmaz
- Flutter istek attıkça log gösterir

## Terminal 2 — Flutter terminali
Bu terminalde Flutter komutları çalışır.

Bu terminal:
- `mobile_app` klasöründe olur
- uygulamayı telefona veya emulatore yükler
- hot reload/hot restart işlemlerini yapar

## Neden iki terminal?
Çünkü:
- backend ile Flutter aynı anda aktif olmalı
- backend kapalıysa mobil uygulama `/api/match` isteği atamaz
- Flutter açıkken backend loglarını ayrı görmek gerekir

---

# 7. Backend Kurulumu

## 7.1 Doğru klasöre gir

Ana proje klasörüne git:

```bash
cd C:\Users\ONUR\Downloads\basic-sondra\basic-sondra
```

## 7.2 Klasörü doğrula

```bash
dir
```

Şunları görmelisin:
- `scripts`
- `core`
- `mobile_app`

Eğer bunları görmüyorsan yanlış klasördesin.

## 7.3 Python paketlerini kur

Eğer `requirements.txt` varsa:

```bash
pip install -r requirements.txt
```

Eğer yoksa temel kurulum:

```bash
pip install fastapi uvicorn psycopg2-binary numpy soundfile librosa python-multipart
```

Gerekirse ek paketler de kurulabilir:
```bash
pip install scipy
```

## 7.4 Backend'i başlat

```bash
python -m uvicorn scripts.mobile_api:app --host 0.0.0.0 --port 8000 --reload
```

## 7.5 Başarılı açıldığında ne görmelisin?

Terminalde buna benzer çıktı görünür:

```text
Uvicorn running on http://0.0.0.0:8000
Application startup complete.
```

## 7.6 Backend açık mı nasıl kontrol edilir?

Bilgisayarda tarayıcıdan aç:

```text
http://localhost:8000/docs
```

veya:

```text
http://127.0.0.1:8000/docs
```

Swagger açılıyorsa backend çalışıyor.

---

# 8. Flutter Kurulumu ve Çalıştırma

## 8.1 Flutter komutları için doğru klasör

Önce `mobile_app` klasörüne gir:

```bash
cd mobile_app
```

veya tam yol:

```bash
cd C:\Users\ONUR\Downloads\basic-sondra\basic-sondra\mobile_app
```

## 8.2 Klasörü doğrula

```bash
dir
```

Bunları görmelisin:
- `pubspec.yaml`
- `lib`
- `android`

Eğer `pubspec.yaml` görünmüyorsa yanlış klasörde Flutter komutu çalıştırıyorsun.

## 8.3 Bağımlılıkları indir

```bash
flutter pub get
```

## 8.4 Gerekirse temiz kur

```bash
flutter clean
flutter pub get
```

---

# 9. Flutter Cihaz Komutları

## 9.1 Bağlı cihazları listele

```bash
flutter devices
```

Örnek çıktı:
```text
2201117SG (mobile) • 5TE6ZH8XFYMJ7XMJ • android-arm64 • Android 13
Windows (desktop)  • windows
Chrome (web)       • chrome
```

## 9.2 Gerçek telefonda çalıştırma

```bash
flutter run -d 5TE6ZH8XFYMJ7XMJ
```

## 9.3 Emulator'de çalıştırma

```bash
flutter run -d emulator-5554
```

## 9.4 Chrome'da çalıştırma

```bash
flutter run -d chrome
```

---

# 10. Emulator ve Gerçek Telefon Farkı

Bu projede çok önemlidir.

## Emulator
Emulator kullanırken backend adresi genelde şöyledir:

```text
http://10.0.2.2:8000
```

## Gerçek telefon
Gerçek telefonda backend adresi bilgisayarın yerel IP adresi olmalıdır:

```text
http://192.168.1.17:8000
```

Bu örnek IP'dir. Kendi bilgisayar IP adresini öğrenmek için:

```bash
ipconfig
```

`Wi-Fi` altındaki `IPv4 Address` kısmına bak.

Örnek:
```text
IPv4 Address: 192.168.1.17
```

---

# 11. Telefonda Test Etmeden Önce Yapılacaklar

## 11.1 Telefonda geliştirici seçeneklerini aç
- Ayarlar
- Telefon hakkında
- Yapım numarasına 7 kez dokun

## 11.2 USB debugging aç
- Ayarlar
- Geliştirici seçenekleri
- USB Debugging → Açık

## 11.3 Bilgisayara bağla
- USB kablo ile bağla
- Telefonda çıkan güven / hata ayıklama iznine onay ver

## 11.4 Cihazı Flutter ile kontrol et

```bash
flutter devices
```

Telefon görünmelidir.

---

# 12. Telefonda Backend Erişim Kontrolü

Bu adım çok önemlidir.

Telefonun tarayıcısına şu adresi yaz:

```text
http://192.168.1.17:8000/docs
```

## Eğer açılırsa
- Telefon backend'i görüyor
- Aynı ağdasınız
- IP doğru

## Eğer açılmazsa
- Telefon ve bilgisayar aynı Wi-Fi'da olmayabilir
- Güvenlik duvarı engelliyor olabilir
- Backend açık olmayabilir
- IP yanlış olabilir

---

# 13. Flutter'da API Adresi Nerede Ayarlanır?

Dosya:
```text
mobile_app/lib/src/services/song_search_api.dart
```

Gerçek telefon için Android altında şu olmalı:

```dart
return 'http://192.168.1.17:8000';
```

Emulator için:

```dart
return 'http://10.0.2.2:8000';
```

Bu ayrımı doğru yapman gerekir.

---

# 14. Önerilen Çalıştırma Sırası

## Senaryo A — Gerçek telefon ile test

### Terminal 1
Ana klasörde backend aç:
```bash
cd C:\Users\ONUR\Downloads\basic-sondra\basic-sondra
python -m uvicorn scripts.mobile_api:app --host 0.0.0.0 --port 8000 --reload
```

### Terminal 2
Flutter klasörüne gir:
```bash
cd C:\Users\ONUR\Downloads\basic-sondra\basic-sondra\mobile_app
flutter clean
flutter pub get
flutter run -d 5TE6ZH8XFYMJ7XMJ
```

## Senaryo B — Emulator ile test

### Terminal 1
Ana klasörde backend:
```bash
cd C:\Users\ONUR\Downloads\basic-sondra\basic-sondra
python -m uvicorn scripts.mobile_api:app --host 0.0.0.0 --port 8000 --reload
```

### Terminal 2
Flutter klasöründe:
```bash
cd C:\Users\ONUR\Downloads\basic-sondra\basic-sondra\mobile_app
flutter clean
flutter pub get
flutter run -d emulator-5554
```

---

# 15. Manuel Test mi, Shake Test mi?

İlk testlerde önerilen yöntem:

## Önce manuel başlat
Butona basarak kayıt başlat.

Neden?
- Shake sırasında mekanik gürültü oluşur
- El hareketi mikrofona yansıyabilir
- Daha temiz test için önce manuel mod gerekir

## Sonra shake testine geç
Temel doğruluk oturduktan sonra shake özelliğini test et.

---

# 16. Şarkıyı Nasıl Test Etmeliyim?

En doğru test yöntemi:

- Uygulama bir telefonda açık olsun
- Şarkı başka bir telefondan, hoparlörden veya laptop'tan çalsın

Önerilmez:
- Aynı telefondan hem app'i açıp hem şarkı çalmak

Çünkü:
- mikrofon kalitesi düşebilir
- hoparlör-mikrofon ilişkisi farklı olur
- sonuçlar sapabilir

---

# 17. APK Alma

Flutter klasöründe:

```bash
cd mobile_app
flutter build apk --release
```

Çıkan dosya:

```text
build/app/outputs/flutter-apk/app-release.apk
```

Tam yol:
```text
mobile_app/build/app/outputs/flutter-apk/app-release.apk
```

Bu dosyayı başka birine gönderebilirsin.

---

# 18. Sadece APK Yeterli mi?

Genelde hayır.

Çünkü uygulama backend'e bağlı çalışır.

Sadece APK gönderilirse:
- uygulama kurulur
- açılır
- ama API'ye bağlanamazsa şarkı arama çalışmaz

Bir başkasının kendi bilgisayarında çalıştırabilmesi için genelde şunlar gerekir:
- proje kodları
- veritabanı
- Python
- PostgreSQL
- backend komutları
- Flutter tarafında doğru IP ayarı

---

# 19. Başka Birine Projeyi Verme

Bir başkası projeyi çalıştıracaksa aşağıdakiler paylaşılmalıdır:

- proje zip dosyası
- veritabanı export/dump
- bu README
- gerekirse APK

## Onun yapacağı işlemler

### Backend
```bash
cd basic-sondra
pip install -r requirements.txt
python -m uvicorn scripts.mobile_api:app --host 0.0.0.0 --port 8000 --reload
```

### Flutter
```bash
cd mobile_app
flutter pub get
flutter run
```

### API ayarı
`mobile_app/lib/src/services/song_search_api.dart` içinde kendi bilgisayar IP adresini yazmalıdır.

---

# 20. Sık Karşılaşılan Hatalar

## Hata 1
```text
No pubspec.yaml file found
```

### Sebep
Flutter komutunu yanlış klasörde çalıştırıyorsun.

### Çözüm
```bash
cd mobile_app
dir
```

`pubspec.yaml` görünmelidir.

---

## Hata 2
```text
ModuleNotFoundError: No module named 'scripts'
```

### Sebep
Backend komutunu `mobile_app` içindeyken çalıştırıyorsun.

### Çözüm
Ana klasöre geç:
```bash
cd ..
python -m uvicorn scripts.mobile_api:app --host 0.0.0.0 --port 8000 --reload
```

---

## Hata 3
```text
Connection refused
```

### Sebep
- backend kapalı
- port yanlış
- IP yanlış

### Çözüm
Swagger açılıyor mu kontrol et:
```text
http://localhost:8000/docs
```

---

## Hata 4
```text
Sunucu yanit vermedi
```

### Sebep
- backend geç cevap veriyor
- timeout kısa
- işlem uzun sürüyor

### Çözüm
Flutter tarafında timeout artırılır.

---

## Hata 5
Telefon backend'i görmüyor

### Sebep
- aynı Wi-Fi'da değiller
- IP yanlış
- firewall engelliyor

### Çözüm
Telefonda şu adresi aç:
```text
http://BILGISAYAR_IP:8000/docs
```

---

## Hata 6
Uygulama açılıyor ama sonuç bulmuyor

### Muhtemel nedenler
- veritabanı boş
- fingerprint eşleşmesi düşük
- gürültülü kayıt
- yanlış test yöntemi

---

# 21. Önerilen Geliştirme ve Test Sırası

1. Backend'i aç
2. Swagger'ı bilgisayarda kontrol et
3. Telefonda `/docs` aç
4. Flutter'ı telefonda çalıştır
5. Manuel butonla test et
6. Sonra shake testine geç
7. Sonuçları backend loglarıyla izle

---

# 22. Faydalı Komutlar

## Bilgisayar IP adresi
```bash
ipconfig
```

## Bağlı cihazlar
```bash
flutter devices
```

## Flutter bağımlılıkları
```bash
flutter pub get
```

## Flutter temiz kurulum
```bash
flutter clean
flutter pub get
```

## Telefon üzerinde çalıştırma
```bash
flutter run -d TELEFON_ID
```

## Release APK
```bash
flutter build apk --release
```

## Backend başlatma
```bash
python -m uvicorn scripts.mobile_api:app --host 0.0.0.0 --port 8000 --reload
```

---

# 23. Son Özet

## Backend komutları
**Ana klasörde**
```bash
cd basic-sondra
python -m uvicorn scripts.mobile_api:app --host 0.0.0.0 --port 8000 --reload
```

## Flutter komutları
**mobile_app klasöründe**
```bash
cd mobile_app
flutter clean
flutter pub get
flutter run -d TELEFON_ID
```

## İki terminal gerekir mi?
**Evet.**
- Terminal 1 → backend
- Terminal 2 → Flutter

## Gerçek telefon için hangi IP?
Bilgisayarının yerel IP adresi.
Örnek:
```text
http://192.168.1.17:8000
```

## Emulator için hangi IP?
```text
http://10.0.2.2:8000
```

---

# 24. Not

Bu proje fingerprint tabanlı olduğu için sonuç kalitesi şunlardan etkilenir:
- ortam gürültüsü
- telefon mikrofon kalitesi
- kayıt süresi
- veritabanının kalitesi
- fingerprint üretim ayarları
- web ve mobil kayıt farkı

En doğru test yöntemi: **gerçek telefon + başka cihazdan çalınan şarkı**.