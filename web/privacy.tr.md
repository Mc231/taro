---
title: Gizlilik Politikası
locale: tr
version: "1.0"
effective: "2026-10-02"
source: en
translation: machine
review: "MACHINE TRANSLATION of privacy.en.md v1.0: native legal review required before publishing (05 §5.3). The English version prevails."
---

# Taro Gizlilik Politikası

Sürüm 1.0 · Yürürlük tarihi: 2 Ekim 2026

## Biz kimiz

Taro, bireysel geliştirici ve AB Dijital Hizmetler Yasası kapsamında tacir olan Volodymyr Shyrochuk tarafından geliştirilen bir tarot günlüğü uygulamasıdır („biz”). İletişim: volodymyr.shyrochuk@gmail.com. Tacir adresi ve telefonu: [OWNER: fill in before publishing, as shown in the App Store and Google Play listings].

## Özet

- Hesap yoktur. Taro rastgele bir kurulum kimliği oluşturur; adınızı, e-posta adresinizi veya telefon numaranızı asla istemeyiz.
- Günlüğünüz, kartlarınız ve okumalarınız cihazınızda kalır. Günlüğünüz cihaz yedeğinize dahildir.
- Yapay zekâ okuması istediğinizde sorunuz, açılım, çektiğiniz kartlar ve uygulama diliniz sunucumuza gider; sunucumuz yorumu yazması için OpenAI’a başvurur. Sorunuz sunucumuzda saklanmaz.
- Reklamlar Google AdMob tarafından ve yalnızca onay tercihlerinizi yaptıktan sonra gösterilir.
- Verilerinizi istediğiniz zaman uygulamadan dışa aktarabilir ve silebilirsiniz.

## İşlediğimiz veriler

- **Kurulum kimliği:** ilk açılışta oluşturulan rastgele bir kimlik. Okuma kredilerinizi, ücretsiz günlük okumanızı ve dolandırıcılık önlemeyi takip eder.
- **Cihaz anahtarı (yalnızca Android):** Android cihaz kimliğinin tek yönlü özeti; yalnızca ücretsiz okumaların kötüye kullanılmasını önlemek için kullanılır. iOS’ta Apple DeviceCheck aynı amaçla bir bit saklar; bir cihaz tanımlayıcısını asla görmeyiz.
- **Saat dilimi ve uygulama dili:** ücretsiz günlük okumanızı yerel gece yarısında yenilemek ve okumaları dilinizde yazmak için.
- **Satın alma kayıtları:** mağaza işlem kimliği, ürün ve verilen krediler. Ödeme bilgilerinizi asla almayız.
- **Okuma meta verileri:** açılım, kart sayısı, dil, istem sürümü, token sayıları, maliyet, güvenlik kategorisi ve sonuç. Soru metni yoktur.
- **Yapay zekâ okumaları için sorular:** okumayı yazmak üzere yapay zekâ sağlayıcısına gönderilir ve sunucumuzda saklanmaz.
- **Okuma metinleri:** sunucumuzda yalnızca cihazınız onları alana kadar şifreli olarak tutulur.
- **Bildirimler:** bir okumayı bildirirseniz, inceleyebilmemiz için soruyu, okuma metnini ve isteğe bağlı notunuzu şifreli olarak saklarız.
- **Analiz:** uygulamanın nasıl kullanıldığı (örneğin hangi ekranların açıldığı), Google Analytics for Firebase üzerinden, yalnızca onay tercihlerinizden sonra. Sorunuzu, okumanızı veya günlük metninizi analize asla göndermeyiz.
- **Çökme verileri:** Firebase Crashlytics üzerinden çökme raporları ve performans verileri.
- **Reklam verileri:** Google AdMob tarafından işlenir (bkz. Reklamlar).

## Yapay zekâ ile işleme

Yapay zekâ okumalarını, veri işleyenimiz olarak hareket eden **OpenAI** (GPT modelleri) yazar. Aynı sağlayıcı soruları ve okumaları güvenlik açısından denetler (moderasyon). Bir okumayı hangi modelin yazacağı sunucu yapılandırmamıza bağlıdır; bir sağlayıcı ekler veya değiştirirsek bu politikayı günceller ve uygulamada izninizi yeniden isteriz.

- **Gönderilenler:** sorunuz, açılım, çekilen kartlar ve uygulama dili. Adınızı, e-postanızı, kurulum kimliğinizi veya reklam kimliğinizi asla göndermeyiz.
- **Eğitim:** OpenAI’ın API koşullarına göre API üzerinden gönderilen veriler modellerini eğitmek için kullanılmaz.
- **Sağlayıcıda saklama:** OpenAI, kötüye kullanımı tespit etmek için API isteklerini en fazla 30 gün saklayabilir, ardından siler; moderasyon istekleri saklanmaz.
- **Doğruluk:** okumalar yapay zekâ tarafından üretilir. Yanlış veya beklenmedik olabilirler ve yalnızca eğlence ve öz düşünüm içindir.

İlk yapay zekâ okumasından önce uygulama bunu açıklar ve izninizi ister. İzninizi istediğiniz zaman Ayarlar → Yapay zekâ okumaları bölümünden geri alabilirsiniz; klasik okumalar yapay zekâ olmadan çalışmaya devam eder.

## Reklamlar

Taro, Google AdMob’dan banner reklamlar ve isteğe bağlı ödüllü videolar gösterir. Herhangi bir reklam istenmeden önce, Google’ın onay formu (UMP) yasanın gerektirdiği yerlerde tercihlerinizi sorar. iOS’ta ardından Apple’ın App Tracking Transparency özelliğiyle izleme izni isteriz. Reddederseniz kişiselleştirilmemiş reklamlar görürsünüz. Tercihlerinizi istediğiniz zaman Ayarlar → Gizlilik tercihleri bölümünden değiştirebilirsiniz. AdMob, reklam kimliğinizi, IP adresinizden türetilen yaklaşık konumu ve reklam etkileşimlerini Google’ın kendi koşullarına göre işleyebilir. Banner Reklamları Kaldır satın alımı bannerları kaldırır.

## Satın almalar

Satın almalar, kendi koşulları uyarınca Apple (App Store) veya Google (Google Play) tarafından işlenir. Yalnızca okumalarınızı tanımlamak için gereken işlem bilgilerini alırız. Okuma kredileri bu kuruluma bağlıdır: uygulamayı veya verilerini sildikten sonra geri yüklenmez ve dışa aktarma dosyası bunları içermez. Banner Reklamları Kaldır geri yüklenebilir.

## Hukuki dayanaklar (GDPR)

- **Sözleşme:** sorunuzun yapay zekâ sağlayıcısına gönderilmesi dahil, talep ettiğiniz yapay zekâ okumaları; satın almalar ve okuma kredileri.
- **Rıza:** kişiselleştirilmiş reklamlar ve gerektiğinde analiz.
- **Meşru menfaat:** cihaz anahtarı dahil dolandırıcılık önleme; uygulamanın çalışması için çökme verileri.

Uygulamadaki yapay zekâ izni adımı şeffaflık ve tercihiniz içindir; işlemenin hukuki dayanağı değildir.

## Saklama süreleri

- Sorunuz sunucumuzda saklanmaz.
- Okuma metni, cihazınız alındığını onaylayana kadar, en fazla 7 gün şifreli tutulur, sonra silinir.
- Bildirilen okumalar 90 gün saklanır.
- Muhasebe ve satın alma kayıtları 7 yıl (vergi, iadeler ve dolandırıcılık önleme) takma adlı olarak saklanır.
- Okuma meta verileri 13 ay saklanır.
- Ödüllü reklam kayıtları 13 ay saklanır.
- Günlük kullanım sayaçları 90 gün saklanır.
- Cihaz sayaçları (Android’de cihaz anahtarına bağlı) 90 gün saklanır.
- Sunucu günlükleri 7 gün saklanır.
- Etkin olmayan kurulumlar (24 ay boyunca etkinlik yoksa ve kalan kredi yoksa) 24 ay sonra takma adlı hâle getirilir.

## Haklarınız

- **Erişim ve taşınabilirlik:** Ayarlar → Yedeği dışa aktar, günlüğünüzü ve okumalarınızı içeren bir dosya oluşturur.
- **Silme:** Ayarlar → Tüm verileri sil, cihazınızdaki verileri siler ve sunucumuzdan okumalarınızı, bildirimlerinizi ve kullanım geçmişinizi silmesini ister. Kalan okuma kredileriniz ve Banner Reklamları Kaldır, satın alınmış ürünler oldukları için korunur.
- **İtiraz ve rızanın geri alınması:** Ayarlar → Gizlilik tercihleri ve Ayarlar → Yapay zekâ okumaları.
- **Şikâyet:** veri koruma denetim makamınıza şikâyette bulunabilirsiniz.
- **ABD eyaletlerinin gizlilik yasaları:** kişisel bilgilerinizi satmıyoruz. Hedefli reklamcılık için „paylaşmayı”, ABD eyaletlerinde gösterilen gizlilik formuyla reddedebilirsiniz.

Her türlü talep için volodymyr.shyrochuk@gmail.com adresine yazın ve Ayarlar’da gösterilen Destek Kimliği’ni ekleyin.

## Çocuklar

Taro 16 yaşından küçük çocuklara yönelik değildir ve onların verilerini bilerek toplamayız.

## Güvenlik ve uluslararası aktarımlar

Veriler aktarım sırasında şifrelenir (HTTPS). Okuma metinleri ve bildirimler şifreli olarak saklanır. Sunucumuz Cloudflare üzerinde çalışır; veri işleyenlerimiz Cloudflare, OpenAI ve Google’dır (Firebase, AdMob). Verileri, Avrupa Komisyonu’nun Standart Sözleşme Maddeleri veya eşdeğer bir güvence kapsamında, Amerika Birleşik Devletleri dahil ülkeniz dışında işleyebilirler.

## Değişiklikler

İşlememiz değiştiğinde bu politikayı günceller, yeni sürümü ve yürürlük tarihini burada gösteririz. Bir değişiklik yapay zekâ ile işlemeyi etkilerse uygulama izninizi yeniden ister.
