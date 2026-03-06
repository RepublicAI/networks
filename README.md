# 🚀 RepublicAI Node Operations & Monitoring - goldify

Bu klasör, **RepublicAI** ağında node işleten kullanıcıların işini kolaylaştırmak için **goldify** tarafından hazırlanmış bir teknik araç ve rapor setidir. "Developer" rolü kapsamında topluluğa katkı sağlamak amacıyla oluşturulmuştur.

---

## 🛠 Neyi Geliştirdik? (Node Sağlık Kontrol Aracı)

Sunucunuzun ve node'unuzun durumunu saniyeler içinde görmeniz için `check_health.sh` adında bir izleme aracı hazırladım. Bu araç şunları raporlar:

* **Sistem Kaynakları:** İşlemci (CPU) ne kadar yoruluyor? RAM doldu mu? Disk alanınız bitti mi?
* **Blockchain Senkronizasyonu:** Node'unuz ağdaki en son bloğa ulaştı mı (`catching_up` kontrolü)?
* **Blok Yüksekliği:** Şu an kaçıncı bloktasınız?

---

## 🚀 Nasıl Kullanılır? (Adım Adım Rehber)

Hiç kod bilmeseniz bile sunucunuzda aşağıdaki 3 adımı sırayla uygulayarak bu aracı çalıştırabilirsiniz:

### 1. Aracı Sunucunuza İndirin
Hazırladığım kodu kendi sunucunuza çekmek için bu komutu yapıştırın:
```bash
wget [https://raw.githubusercontent.com/RepublicAI/networks/main/testnet/goldify/check_health.sh](https://raw.githubusercontent.com/RepublicAI/networks/main/testnet/goldify/check_health.sh)

2. Çalıştırma İzni Verin
Dosyayı bir program gibi çalışabilir hale getirmek için bu izni verin:

chmod +x check_health.sh

3. Aracı Başlatın
Tüm verileri görmek için bu komutu yazın:

./check_health.sh

📊 Doğrulayıcı (Validator) Bilgileri
Bu node ve araç seti aşağıdaki kimlik bilgileriyle yönetilmektedir:

Moniker (Takma Ad): goldify

Cüzdan Adresi: rai1kyvgpy7yt6350xkh3h4s5cdm8uhuj3sqhjds9t

Node Tipi: Validator Candidate (Testnet)

📝 Teknik Rapor (report.md)
Sunucunun donanım özellikleri, çalışma stabilitesi ve ağ performansı hakkındaki detaylı teknik verilere bu klasördeki report.md dosyasından ulaşabilirsiniz.

Developed as a contribution to the RepublicAI Developer Community by goldify.

