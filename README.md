# Sondra — Müzik Tanıma Sistemi
Müziği saniyeler içinde tanımlamak için tasarlanmış, yüksek performanslı, açık kaynaklı bir ses tanıma motoru.

---

## 📖 Sondra Hakkında

**Sondra**, müziği saniyeler içinde tanımlamak için tasarlanmış, yüksek performanslı, açık kaynaklı bir ses tanıma motorudur. Shazam'ın mimarisinden ilham alarak, ham ses ile dijital meta veri arasındaki köprüyü kurmak için gelişmiş ses parmak izi (audio fingerprinting) teknolojisini kullanır. Akustik sinyalleri hash'leyerek, gürültülü ortamlarda bile yüksek hassasiyette eşleşme sağlar.

Bu depo, hem **Flutter Mobil Uygulamasını** hem de **Python Backend Motorunu** içerir.

## ✨ Özellikler

- **Hızlı ve Doğru Tanıma:** Ses parmak izi ve spektrogram analizi kullanarak şarkıları saniyeler içinde tanır.
- **Sallayarak Arama (Shake-to-Search):** Mobil uygulamada `sensors_plus` kullanılarak tetiklenen sallama ile arama mekanizması.
- **Mikrofon Entegrasyonu:** Mobil istemciden doğrudan backend'e yüksek kaliteli ses kaydı ve iletimi.
- **Çapraz Platform İstemci:** Flutter ile geliştirilmiş, akıcı ve duyarlı kullanıcı arayüzüne sahip Android ve iOS desteği.
- **Güçlü Backend API:** FastAPI ile güçlendirilmiş, paralel istekleri ve hızlı ses hash'lemeyi kaldıracak şekilde tasarlanmıştır.

## 🛠️ Kullanılan Teknolojiler

### Mobil Uygulama (Frontend)
- **Çerçeve:** [Flutter](https://flutter.dev/) (Dart)
- **Ses Kaydı:** `record` / `just_audio`
- **Sensörler:** `sensors_plus` (Sallama algılama)
- **İzinler:** `permission_handler`
- **Ağ İletişimi:** `http` (REST API entegrasyonu)
- **Depolama:** `path_provider`

### Backend (Ses İşleme ve Motor)
- **Çerçeve:** [FastAPI](https://fastapi.tiangolo.com/) & Uvicorn
- **Veritabanı:** PostgreSQL (`psycopg2-binary`)
- **Ses İşleme:** `librosa`, `soundfile`, `scipy`
- **Matematik ve Algoritmalar:** `numpy`
- **Veri Yönetimi:** `python-multipart`

## ⚙️ Gereksinimler

Başlamadan önce aşağıdakilerin yüklü olduğundan emin olun:

- **Flutter SDK** (v3.4.0 veya üzeri)
- **Python** (v3.10 veya üzeri)
- **PostgreSQL** Veritabanı (Çalışır durumda ve yapılandırılmış)
- Flutter eklentileri kurulu **Android Studio** veya **VS Code**
- Test için Android cihaz veya Emülatör (Mikrofon kullanımı için fiziksel cihaz önerilir)

## 🚀 Kurulum ve Başlangıç

### 1. Veritabanı Kurulumu
PostgreSQL'in çalıştığından ve `songs` ile `fingerprints` tablolarının oluşturulduğundan emin olun. Motorun eşleşme bulabilmesi için veritabanını şarkı parmak izleriyle doldurmanız gerekecektir.

### 2. Backend Kurulumu
Backend dizinine gidin ve gereksinimleri yükleyin:

```bash
cd basic_sondra
pip install -r requirements.txt
```

Backend sunucusunu başlatın:

```bash
python -m uvicorn scripts.mobile_api:app --host 0.0.0.0 --port 8000 --reload
```
*Not: Çevre değişkenlerinizde veya backend yapılandırmalarınızda PostgreSQL veritabanı ayarlarınızın doğru yapıldığından emin olun.*

### 3. Mobil Uygulama Kurulumu
Mobil uygulama dizinine gidin:

```bash
cd basic_sondra/mobile_app
flutter pub get
```

#### API Uç Noktasını Güncelleyin:
Fiziksel bir cihazda test yapıyorsanız, `lib/src/services/song_search_api.dart` dosyasındaki backend API adresini bilgisayarınızın yerel IP adresiyle değiştirin. Emülatörler için genellikle `10.0.2.2` kullanılır.

#### Uygulamayı Çalıştırın:
```bash
flutter run
```

## 📱 Kullanım
1. Cihazınızda Sondra uygulamasını açın.
2. Harici bir kaynaktan (örn. dizüstü bilgisayar veya başka bir telefon) bir şarkı çalın.
3. Kayda başlamak için **dinle butonuna dokunun** veya **telefonunuzu sallayın**.
4. Uygulama sesin kısa bir bölümünü kaydedip backend'e gönderecektir.
5. Backend akustik sinyali hash'leyecek, veritabanında arayacak ve eşleşen şarkı detaylarını size sunacaktır!

## 🧠 Nasıl Çalışır
Sondra, ham sesi bir spektrograma dönüştürür, takım yıldızı noktalarını (genlikteki zirveler) bulur ve bu noktaların hash'lenmiş çiftlerini oluşturur. Bu hash'ler (parmak izleri) arka plan gürültüsüne ve ufak zaman değişimlerine karşı oldukça dirençlidir ve motorun PostgreSQL'deki milyonlarca hash'i hızla aramasına olanak tanır.

## 👨‍💻 Geliştiriciler

* **Emir Furkan:** Veri setinin oluşturulması ve backend tarafında şarkı eşleştirme algoritmalarının geliştirilmesi.
* **Onur Nural:** Flutter tabanlı arayüzün kodlanması ve sistemin mobil ortama entegrasyonu.

---
*Sondra Ekibi tarafından ❤️ ile geliştirildi.*
