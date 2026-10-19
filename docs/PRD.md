# PRD — Star Garage ERP (Penjualan, Inventory, Kas, Biaya, Gaji & Laporan)

| | |
|---|---|
| Client | Star Garage — member Yoong Motor (Pasuruan) |
| Versi | **Draft 2.2** · 19 Okt 2026 |
| Status | Requirement lengkap — siap coding (sisa hanya item default di §10) |
| Repo | `garage-erp-desktop` (nama generik; nama bengkel diatur dari Pengaturan) |
| Sumber | `docs/brief-client.txt` (versi 13:08), 2 contoh invoice Kledo (`docs/contoh-*.pdf`), `docs/GUDANG BARANG new.xlsx`, `docs/INSENTIF-DES24.pdf`, logo, screenshot app pusat, Google Sheet customer (~148 baris), **Sheet pembukuan penjualan** (DES24–JULI26 + UANG 2025/2026), **Sheet pengeluaran & insentif** (PENGELUARAN 2025/2026, INSENTIF-DES24 s/d OKT26) |

**Changelog v2.3** (19 Okt):
- PC kasir = **Mac** → target rilis 1 hanya **macOS**; Windows tidak dibangun/diuji (kode tetap lintas-platform).
- **Backup lokal dulu** (default `~/Documents/Garage ERP Backup`); backup ke Google Drive ditunda.

**Changelog v2.2** (klarifikasi client 19 Okt):
- Stok awal: barang yang stoknya kosong diisi **1**.
- Stok dianggap **sudah** dikurangi penjualan Agu–Okt → transaksi lama tidak mengubah stok.
- Tunjangan sales 3% dari omzet **periode gaji** (27–26).
- Pengeluaran pribadi tampil terpisah di bawah laba bersih usaha — disetujui.
- Pembelian stok diinput **owner**.
- Rekening jadi **4: BCA, Mandiri, ShopeePay, Tunai** — Mandiri bisa dipilih di setiap transaksi.

**Changelog v2.1** (jawaban client 19 Okt):
- Rekening cukup **3: BCA, ShopeePay, Tunai**, + kolom keterangan.
- Stok & nomor INV/SO melanjutkan data yang sudah ada.
- Penjualan Agu–Okt 2026 akan diinput manual belakangan → fitur **input transaksi lama** (PJ-11).
- **Modal tidak diisi otomatis**; hanya owner yang bisa melihat & mengisi modal.
- Tunjangan kerja sales = **3% omzet per bulan**.
- 2 teknisi di satu pekerjaan → insentif **dibagi dua**.
- Pengeluaran rumah/pribadi **tetap dicatat sebagai pengeluaran**.

**Changelog v2.0** (dari draft 1.x):
- Ditulis ulang setelah membaca 20 bulan pembukuan manual client.
- Brief baru: invoice dikirim via WA + ajakan review Google Maps; bukti pembayaran di setiap pemasukan/pengeluaran tersimpan ke Google Drive.
- Jawaban client: modul **Insentif & Gaji** masuk (2 teknisi + 1 sales; insentif sesuai pekerjaan masing-masing, tidak dibagi rata).
- Data Kledo **tidak bisa diambil** → migrasi tanpa Kledo (§4.9).
- Model HPP diganti: **harga modal per baris** (bukan rata-rata pembelian). Jasa juga bisa punya modal.
- Rekening jadi **7 akun** sesuai data riil. Diskon dalam **Rupiah**.
- Dibuang (tidak ada di data/brief): PPN, foto produk, filter brand, target performa 10.000 item.

---

## 1. Ringkasan

Star Garage adalah bengkel modifikasi & restorasi lampu mobil (projector, LED, foglamp, custom headlamp, cleaning/coating). Selama ini transaksi dicatat di **Kledo** (invoice) **dan** di beberapa Google Sheet (penjualan, pengeluaran, insentif, gaji). Kledo dihentikan karena **biaya langganan**, dan langganannya sudah berakhir sehingga datanya tidak bisa diambil.

App ini menggantikan Kledo + spreadsheet tersebut dengan **satu aplikasi desktop macOS tanpa biaya bulanan**: data di PC bengkel, backup ke Google Drive.

**Volume nyata** (sheet penjualan Des 2024 – Jul 2026): **224 transaksi / 503 baris dalam 20 bulan ≈ 11 transaksi per bulan**, omzet ≈ Rp 589 jt. Artinya kebutuhan utamanya **pencatatan yang benar dan terhubung**, bukan kasir super cepat.

## 2. Sumber masalah (dari data client)

| # | Masalah | Bukti di data | Dampak | Solusi di app |
|---|---|---|---|---|
| 1 | **Satu transaksi diketik 3 kali**: Kledo, sheet penjualan, sheet insentif | Nota INV/00245 & 00246 ada di Kledo, transaksi yang sama juga di sheet penjualan & insentif | Waktu terbuang, angka antar-sheet tidak sinkron | Satu invoice menjadi sumber untuk stok, kas, laporan, dan insentif |
| 2 | **"Profit" bulanan di sheet pengeluaran salah konsep** | PROFIT = uang masuk − semua uang keluar. "Uang keluar" mencampur **pembelian stok** (kategori PROJECTOR ≈ Rp 39 jt di 2026), **gaji**, dan **pengeluaran rumah/pribadi** (listrik/air/wifi rumah, PDAM langgar, sumbangan, ART) | Banyak bulan tercatat rugi (mis. Feb, Apr, Agu, Sep 2026), padahal sheet penjualan menunjukkan margin positif. Owner tidak tahu laba sebenarnya | Pisahkan jenis uang keluar: **pembelian stok** (jadi HPP saat terjual), **biaya operasional**, **pribadi/prive**. Laba rugi hanya memakai HPP + biaya operasional |
| 3 | **Tidak ada master produk** | ±**210 nama barang berbeda** di sheet penjualan ("SR3 GT" vs "SR3GT", "HYP V3 WHITE" vs "HYP V3 PUTIH"); barang paling laku **POWER+ (82 baris)** tidak ada di `GUDANG BARANG new.xlsx` (69 item); kategori di penjualan (PERKABELAN, FL, MP, SWITCH, CUSTOM HL…) beda dengan kategori gudang (LED, PROJECTOR…) | Stok tidak bisa dihitung, produk terlaris tidak akurat | Satu daftar produk/jasa; invoice hanya memilih dari daftar itu (item baru bisa ditambah langsung dari form invoice) |
| 4 | **Rumus & salin-tempel manual** | INSENTIF-DES24: jumlah baris = Rp **1.505.000**, tertulis **1.455.000** (selisih Rp 50.000). INSENTIF-APRIL26 **isinya identik** dengan MAR26, padahal penjualan April berbeda (5 vs 8 transaksi) — kemungkinan tersalin. Sheet MEI26: kolom total penjualan Rp 12.400.000 vs jumlah baris Rp 12.330.000 | Insentif/gaji berpotensi salah bayar | Semua total dihitung otomatis dari transaksi |
| 5 | **Identitas customer lemah** | Sheet penjualan hanya nama + mobil, **tanpa no. HP**; plat terisi di 3 dari 224 transaksi | Repeat order & top pelanggan tidak bisa dihitung andal; garansi sulit dicari | Customer wajib dipilih (dicari via HP/plat/nama) di setiap invoice |

## 3. Pengguna

| Peran | Jumlah | Kebutuhan |
|---|---|---|
| Owner | 1 | Laporan, harga & modal, biaya, gaji, aksi sensitif |
| Sales / admin | 1 | Buat invoice & pemesanan, terima pembayaran, input biaya, kirim nota WA |
| Teknisi | 2 | Tidak memakai app langsung; namanya dipilih per pekerjaan di invoice untuk insentif |

1 PC di bengkel. Aksi sensitif dikunci **PIN owner**: lihat modal/laba, edit/void invoice yang sudah dibayar, penyesuaian stok, gaji.

## 4. Kebutuhan fungsional

Prioritas: **M** = wajib rilis 1 · **S** = sebaiknya rilis 1 · **C** = menyusul bila diminta.

### 4.1 Gudang (Inventory)

| ID | Kebutuhan | Prio |
|---|---|---|
| INV-1 | CRUD item: kode/SKU, nama, kategori, satuan, tipe **Barang/Jasa**, harga beli (**hanya terlihat owner**), harga jual, stok minimal, **tarif insentif**, aktif/nonaktif | M |
| INV-2 | Menu gudang dengan tab **Barang**, **Jasa**, **Ready Stock** (barang stok > 0) | M |
| INV-3 | Stok hanya untuk Barang. Stok berubah dari: pembelian stok (+), invoice (−), void (+), penyesuaian/opname (±, PIN) | M |
| INV-4 | **Pembelian stok** (hanya **owner**): tanggal, supplier (teks), barang, qty, harga beli, rekening pembayar, bukti. Menambah stok, mengurangi saldo rekening, **tidak** dihitung biaya operasional | M |
| INV-5 | Import/export **.xlsx** kompatibel dengan template produk Kledo (`GUDANG BARANG new.xlsx`): kolom akuntansi Kledo diabaikan; ditambah kolom Tipe, Stok Awal, Tarif Insentif. Baris bermasalah (SKU kembar, harga kosong) ditampilkan, tidak dilewati diam-diam | M |
| INV-6 | Peringatan stok di bawah minimal / minus | M |
| INV-7 | Riwayat keluar-masuk stok per barang | S |

Paket (mis. "PAKET REBORN G", "PAKET TRADE ANNIVERSARY") = **item biasa** dengan harga & modal sendiri, isinya ditulis di deskripsi. Mengurangi stok komponen secara otomatis → **C**.

### 4.2 Kontak

| ID | Kebutuhan | Prio |
|---|---|---|
| KON-1 | CRUD customer: nama, no. HP (dinormalisasi `08…`, unik), jenis mobil, plat, catatan | M |
| KON-2 | Import/export .xlsx/.csv sesuai kolom Google Sheet customer; duplikat no. HP digabung dengan laporan | M |
| KON-3 | Detail customer: riwayat invoice/pemesanan, total belanja, kunjungan terakhir | M |
| KON-4 | Statistik: jumlah pelanggan, **% repeat order**, **top pelanggan** per bulan & tahun | M |

Definisi: pelanggan aktif = punya ≥ 1 invoice (bukan batal) di periode; % repeat = pelanggan aktif yang punya ≥ 2 invoice sepanjang waktu ÷ pelanggan aktif; top = urut total invoice di periode (10 teratas).

### 4.3 Penjualan

| ID | Kebutuhan | Prio |
|---|---|---|
| PJ-1 | **Invoice** CRUD: customer, mobil & plat (terisi dari customer, bisa diubah), baris item (produk/jasa, deskripsi, qty, harga jual, **diskon Rp**, **teknisi** 0–2 orang), tanggal, jatuh tempo (default +30 hari) | M |
| PJ-1b | **Modal per baris diisi owner** (PIN), **tidak otomatis**. Admin tidak melihat kolom modal. App menampilkan daftar "baris belum ada modal" agar owner melengkapinya; laba rugi memberi peringatan bila masih ada baris tanpa modal di periode itu | M |
| PJ-2 | **Kasir** = mode cepat dari form invoice: pilih customer & item → terima pembayaran penuh → simpan → PDF. Tidak ada layar POS terpisah (volume ±11 transaksi/bulan) | M |
| PJ-3 | **Pemesanan (Pre Order)** `SO/…` CRUD: item, diskon, **uang muka**, sisa; tombol **Buat Invoice** → invoice `INV/…` mencantumkan nomor SO, DP terbawa sebagai "Pembayaran Diterima" | M |
| PJ-4 | Pembayaran bertahap per invoice/SO; tiap pembayaran: tanggal, nominal, rekening, **bukti**. Tag otomatis **Belum Lunas / Dibayar Sebagian / Lunas**, plus **Batal** (void) | M |
| PJ-5 | Item **bonus** (harga jual 0) tetap tercatat modal & mengurangi stok (mis. Demon Eye gratis — 42 baris seperti ini di data) | M |
| PJ-6 | PDF A4 persis template Kledo: logo, nomor, tanggal, jatuh tempo, pemesanan, info bengkel, tagihan kepada, tabel (produk, deskripsi, kuantitas, harga, diskon, pajak — kosong, jumlah), subtotal, total, pembayaran diterima, sisa tagihan, rekening BCA, syarat, terbilang, tanda tangan | M |
| PJ-7 | **Kirim ke WhatsApp**: tombol membuka chat WA ke no. HP customer dengan pesan siap kirim (ringkasan invoice + **link review Google Maps**); PDF otomatis disimpan & folder-nya dibuka untuk dilampirkan. Tanpa WhatsApp API berbayar | M |
| PJ-8 | Nomor otomatis melanjutkan nomor terakhir: `INV/…` dan `SO/…` | M |
| PJ-9 | Void/edit invoice yang sudah ada pembayaran butuh PIN; void tidak menghapus, stok & kas dibalik | M |
| PJ-10 | Cari invoice via nomor / nama / HP / plat (klaim garansi); filter tag status | M |
| PJ-11 | **Input transaksi lama** (Agu–Okt 2026): tanggal bebas di masa lalu, nomor INV/SO diketik manual (nomor asli Kledo), dan opsi **"tidak mengubah stok"** supaya stok yang sudah dihitung tidak terpotong dua kali | M |

Kolom pajak tetap ada di PDF (sesuai template) tetapi tidak dihitung — PPN selalu 0 di seluruh data.

### 4.4 Kas & Bank

| ID | Kebutuhan | Prio |
|---|---|---|
| KAS-1 | Daftar rekening dengan saldo awal: **BCA, Mandiri, ShopeePay, Tunai** — keempatnya bisa dipilih di setiap transaksi (bisa tambah/nonaktifkan bila nanti perlu) | M |
| KAS-2 | Semua uang masuk/keluar menempel ke satu rekening dan punya kolom **keterangan**: pembayaran invoice/SO, pembelian stok, biaya, gaji, pribadi, modal masuk | M |
| KAS-3 | **Transfer antar rekening** (mis. top up ShopeePay dari BCA) — tidak dihitung pemasukan/pengeluaran | M |
| KAS-4 | **Modal masuk / pemasukan lain** (setoran owner, dll) dan **pengeluaran pribadi (prive)** | M |
| KAS-5 | Mutasi per rekening + saldo berjalan | M |
| KAS-6 | Laporan **pemasukan, pengeluaran, arus kas bersih** — harian, bulanan, **kuartal**, tahunan | M |

### 4.5 Biaya

| ID | Kebutuhan | Prio |
|---|---|---|
| BIA-1 | CRUD biaya: tanggal, nama, kategori, nominal, rekening, keterangan, **bukti** | M |
| BIA-2 | Kategori bisa dikelola. Awal (dari data): Alat & Bahan Bengkel, Listrik, Air, Wifi, Transportasi, Ongkir, Makan & Minum, Tukang/Servis, Iuran/Langganan, Admin Bank, BPJS, Sumbangan, Bonus/THR, Lain-lain. **Gaji** diisi otomatis dari modul Gaji | M |
| BIA-3 | Pengeluaran rumah/pribadi **dicatat sebagai pengeluaran** dengan kategori bertanda **pribadi** (listrik/air/wifi rumah, PDAM langgar, sumbangan, ART). Di laba rugi ditampilkan sebagai baris terpisah di bawah laba bersih usaha (lihat LAP-2) | M |

### 4.6 Insentif & Gaji

| ID | Kebutuhan | Prio |
|---|---|---|
| GAJ-1 | CRUD karyawan: nama, peran (Teknisi/Sales), gaji pokok, tunjangan makan, aktif | M |
| GAJ-2 | Tarif insentif per item (INV-1) disalin ke baris invoice dan bisa diubah per baris (mis. tarif "jika pemasangan kabel set saja") | M |
| GAJ-3 | Tiap baris invoice dipilih **teknisi yang mengerjakan**; insentif baris jatuh ke teknisi itu (bukan dibagi rata se-bulan). Bila **2 teknisi** di satu baris → insentif **dibagi dua** | M |
| GAJ-4 | Rekap insentif per teknisi per periode, rinci per mobil/invoice (pengganti sheet INSENTIF) | M |
| GAJ-5 | **Slip gaji** per karyawan per periode: gaji pokok + tunjangan makan + insentif/tunjangan kerja (otomatis) + lembur + bonus/THR − potongan (kasbon, dll) = total | M |
| GAJ-6 | Tombol **Bayar** gaji → membuat biaya kategori Gaji dari rekening yang dipilih | M |
| GAJ-7 | Periode gaji mengikuti kebiasaan: **tgl 27 s/d 26 bulan berikutnya** (bisa diatur) | M |
| GAJ-8 | Tunjangan kerja **sales = 3% × omzet bulan itu** (persen bisa diatur), terisi otomatis di slip, bisa dikoreksi owner. Omzet = total invoice (barang + jasa) setelah diskon, tidak termasuk batal, **dalam periode gaji yang sama (27–26)** — dikonfirmasi client | M |

Di luar lingkup: PPh 21, BPJS otomatis, absensi.

### 4.7 Bukti pembayaran → Google Drive

| ID | Kebutuhan | Prio |
|---|---|---|
| BKT-1 | Di setiap pemasukan (pembayaran invoice/SO, modal masuk) dan pengeluaran (biaya, pembelian stok, gaji, transfer) bisa melampirkan foto/PDF bukti | M |
| BKT-2 | File disalin ke folder `Star Garage/Bukti/<tahun>/<bulan>/` di dalam **folder Google Drive yang tersinkron di PC** (Google Drive for desktop), nama file berisi tanggal + nomor transaksi. App menyimpan path-nya; tombol "Buka bukti" | M |
| BKT-3 | Tanpa integrasi API Google (tanpa login, tanpa biaya) — sinkron dilakukan aplikasi Google Drive for desktop | M |

### 4.8 Laporan

| ID | Kebutuhan | Prio |
|---|---|---|
| LAP-1 | **Penjualan** harian, bulanan, tahunan: jumlah invoice, omzet, diskon, per item & per kategori | M |
| LAP-2 | **Laba rugi** harian, bulanan, tahunan: Pendapatan − HPP = Laba kotor − Biaya operasional (termasuk gaji) = **Laba bersih usaha** − Pengeluaran pribadi = **Sisa** | M |
| LAP-3 | **Produk terlaris** bulanan & tahunan (qty & nilai) | M |
| LAP-4 | Arus kas (KAS-6), statistik pelanggan (KON-4), insentif (GAJ-4) | M |
| LAP-5 | Export Excel untuk semua laporan | S |

Aturan hitung:
- **Pendapatan** = total invoice (setelah diskon) pada **tanggal invoice**. DP pemesanan masuk kas, tetapi belum dihitung pendapatan sampai dibuatkan invoice.
- **HPP** = Σ (qty × modal per unit yang diisi owner) di baris invoice, termasuk jasa yang punya modal dan item bonus. Baris tanpa modal dihitung 0 dan diberi peringatan.
- **Biaya operasional** = biaya berkategori operasional + gaji. Pembelian stok **tidak** termasuk; pengeluaran pribadi dipisah di baris sendiri.
- "Bulanan" = bulan kalender (1–akhir bulan), kecuali client memilih periode 27–26 (§10).

### 4.9 Data awal (tanpa Kledo)

Data Kledo tidak bisa diambil, sehingga app mulai dari **saldo awal per tanggal mulai**:

| Data | Sumber | Yang dibutuhkan |
|---|---|---|
| Produk & jasa | `GUDANG BARANG new.xlsx` (69 barang) | Client melengkapi barang yang benar-benar dijual (POWER+, switch, kabel, shroud, paket, dll), daftar **jasa + harga + modal + tarif insentif**, dan membereskan SKU kembar (CB/001) & produk ganda (SR800.3, LED HVT EXPERT H4) |
| Stok | `GUDANG BARANG new.xlsx` | Barang yang stoknya kosong diisi **1** saat import (keputusan client), dikoreksi lewat penyesuaian stok bila perlu. Stok ini dianggap **sudah** dikurangi penjualan Agu–Okt |
| Customer | Google Sheet (~148) | Import + dedupe otomatis |
| Saldo rekening | — | Saldo riil **BCA, Mandiri, ShopeePay, Tunai** di hari mulai (bisa diisi belakangan lewat "saldo awal") |
| Invoice/SO belum lunas | Kledo (hilang) | Diinput lewat PJ-11 bersama penjualan Agu–Okt (contoh: INV/00245 sisa Rp 1.450.000, INV/00246 sisa Rp 2.250.000) |
| Nomor terakhir | Contoh nota: INV/00246, SO/00012 | Default lanjut INV/00247 & SO/00013; bisa diubah di Pengaturan |
| Penjualan Agu–Okt 2026 | Belum diinput di mana pun | Diinput manual oleh client lewat PJ-11 |
| Riwayat penjualan 2024–2026 | Sheet penjualan | **Tidak diimpor per baris** (nama barang tidak seragam, customer tanpa HP) — tetap jadi arsip di Google Sheet. Konsekuensi: laporan tahunan & statistik pelanggan di app dihitung mulai tanggal pakai (§10) |

## 5. Alur utama

1. **Penjualan langsung**: invoice → pilih customer → item (+ teknisi) → bayar penuh ke rekening + bukti → **Lunas** → stok, kas, insentif tercatat → PDF / kirim WA.
2. **Pemesanan**: SO → terima DP (+ bukti) → barang datang & dipasang → Buat Invoice → sisa tagihan → pelunasan → Lunas.
3. **Belanja stok**: pembelian stok → stok bertambah, saldo rekening berkurang.
4. **Biaya harian**: catat biaya + bukti → rekening berkurang → masuk laba rugi (jika operasional).
5. **Top up / pindah uang**: transfer antar rekening.
6. **Gajian (tgl 27)**: buka periode → slip otomatis berisi insentif → isi lembur/bonus/potongan → Bayar → biaya Gaji.
7. **Tutup bulan**: laba rugi + arus kas → cocokkan saldo app vs saldo riil tiap rekening → export Excel.

## 6. Kebutuhan non-fungsional

| Area | Kebutuhan |
|---|---|
| Biaya | **Rp 0 per bulan**: tanpa server, domain, DB berbayar, maupun API berbayar |
| Platform | **macOS** (PC kasir client = Mac), 1 perangkat, **offline** (SQLite). Kode tetap bisa dibuild untuk Windows bila nanti perlu |
| Backup | Salinan database otomatis (harian + saat app ditutup) ke folder **lokal** (default `~/Documents/Garage ERP Backup`, bisa diganti mis. ke flashdisk), 60 file terbaru. Ke Google Drive: ditunda |
| Integritas | Transaksi tidak dihapus permanen (void + pembalik); uang disimpan sebagai integer Rupiah; semua total dihitung, tidak diketik |
| Keamanan | PIN owner untuk aksi sensitif (§3) |
| Bahasa | Indonesia, format Rp & tanggal Indonesia |

## 7. Model data (konsep)

`products` (tipe, harga beli, harga jual, stok min, tarif insentif) · `stock_moves` (buku stok) · `purchases` (pembelian stok) · `customers` (nama, HP unik, mobil, plat) · `sales_orders` + baris · `invoices` + `invoice_lines` (qty, harga, diskon Rp, **modal**, **tarif insentif**, **teknisi**) · `accounts` (BCA, Mandiri, ShopeePay, Tunai) · `cash_entries` (buku kas: rekening, ±nominal, jenis: pembayaran/pembelian/biaya/gaji/transfer/modal/prive, ref, **path bukti**) · `expenses` + `expense_categories` (operasional/pribadi) · `employees` · `payslips` · `settings`.

Skema detail (DBML/SQL) dibuat ulang sekarang — klarifikasi §10 tidak mengubah struktur tabel.

## 8. Di luar lingkup rilis 1

Multi-PC / cloud sync, multi-cabang & integrasi app pusat Yoong Motor, login per karyawan, hutang supplier, printer thermal, barcode, WhatsApp API otomatis, serial number, PPN/e-Faktur, PPh 21/BPJS, absensi, import riwayat penjualan per baris, paket dengan pengurangan stok komponen.

## 9. Rencana rilis

| Rilis | Isi |
|---|---|
| **R1a** | Gudang + import, Kontak + import, Invoice/Kasir + pembayaran + PDF + WA, Kas & Bank (4 rekening, transfer, saldo awal), input transaksi lama, Biaya, bukti ke Drive, backup |
| **R1b** | Pemesanan/DP, Insentif & Gaji, semua laporan |

Data awal (§4.9) diinput saat R1a dipasang.

## 10. Pertanyaan untuk client

**Sudah dijawab (19 Okt):** mulai pakai stok & nomor yang ada · 3 rekening (BCA, ShopeePay, Tunai) + keterangan · Agu–Okt diinput manual nanti · modal manual, hanya owner · sales 3% omzet per bulan · 2 teknisi → dibagi dua · pengeluaran pribadi tetap dicatat.

**Klarifikasi lanjutan — sudah dijawab (19 Okt):** stok kosong diisi 1 · stok sudah dikurangi penjualan Agu–Okt · 3% sales per periode gaji · pribadi terpisah di bawah laba bersih usaha (setuju) · pembelian stok oleh owner · Mandiri tetap dipakai di setiap transaksi.

**Belum dijawab (pakai default):** kolom keterangan → ada di setiap transaksi kas dan di data rekening.

**Bisa pakai default kalau tidak dijawab:**
8. Laporan bulanan pakai **bulan kalender** atau **periode 27–26** seperti sheet? *Default: kalender untuk laporan, 27–26 untuk gaji.*
9. **Link review Google Maps** Star Garage + teks pesan WA yang diinginkan. *Default: teks standar + link dari profil Google Bisnis.*
10. Di PC bengkel sudah terpasang **Google Drive for desktop** dengan akun bengkel? (Dibutuhkan untuk bukti & backup.) *Default: kami bantu pasang.*
11. Diskon di nota dalam **Rupiah** (seperti sheet) — ada kebutuhan diskon persen? *Default: Rupiah, bisa ketik % lalu dikonversi.*
12. Logo versi **latar putih/transparan** untuk header invoice. *Default: versi hitam di atas kotak gelap.*
13. Riwayat penjualan lama perlu ditampilkan di app (mis. ringkasan omzet per bulan 2025–2026 untuk perbandingan)? *Default: tidak, tetap di Google Sheet.*

## 11. Catatan untuk tim (bukan untuk client)

- Draft kode/skema/mockup sebelumnya dibuat sebelum data ini dan akan disesuaikan: model HPP diganti ke modal-per-baris, `pay_method` → `payments` per rekening, diskon % → Rupiah. Yang tetap dipakai: perhitungan terbilang & format Rupiah, buku stok, void dengan pembalik, normalisasi no. HP, layout PDF.
- File sheet client yang diunduh untuk analisis **tidak** disimpan di repo (berisi data gaji & customer).

## 12. Tech stack & package (dicek di pub.dev, 19 Okt 2026)

| Kebutuhan | Package | Versi | Status |
|---|---|---|---|
| Database SQLite + query bertipe + migrasi | `drift`, `drift_flutter` (+ dev: `drift_dev`, `build_runner`) | 2.35.2 / 0.3.1 | ✅ terpasang. Flutter Favorite |
| Folder data aplikasi | `path_provider`, `path` | 2.1.6 / 1.9.1 | ✅ terpasang |
| Format Rupiah & tanggal Indonesia | `intl` + `flutter_localizations` (SDK) | 0.20.3 | ✅ / ➕ SDK |
| PDF invoice, preview & cetak | `pdf`, `printing` | 3.13.1 / 5.15.1 | ✅ terpasang |
| Import/export Excel | `excel` | 4.0.6 | ✅ terpasang. ⚠️ rilis terakhir Agu 2024 — uji dengan file asli client di awal; cadangan: fork `excel_community` |
| Pilih file (import, bukti, folder Drive) | `file_selector` | 1.1.0 | ✅ terpasang. Plugin resmi Flutter |
| Hash PIN owner | `crypto` | 3.0.7 | ✅ terpasang |
| Buka WhatsApp, link Maps, buka folder PDF/bukti | `url_launcher` | 6.3.3 | ➕ tambah. Flutter Favorite |
| Ukuran jendela minimum 1280×720 & judul | `window_manager` | 0.5.2 | ➕ tambah |
| Grafik di Laporan | `fl_chart` | 1.2.0 | ➕ tambah (saat modul Laporan) |
| Ikon aplikasi dari logo | `flutter_launcher_icons` (dev) | 0.14.4 | ➕ tambah (saat rilis) |
| State management | `get` (GetX) — **hanya** `GetxController` + `Get.put`/`Get.find` + `Obx`/`.obs`; navigasi tetap sidebar biasa | 4.7.3 | ➕ tambah (keputusan tim) |
| Font | **Inter** (Google Fonts) lewat `fonts:` di pubspec — tanpa package. `google_fonts` 9.0.0 dicoba lalu dilepas: `TextTheme`-nya (dari `material_ui`) tidak kompatibel dengan Flutter 3.47 | — | ✅ |

Sengaja **tidak** dipakai: Riverpod/Bloc (sudah GetX), fitur routing & HTTP GetX & router lain (sidebar + `IndexedStack`), `shared_preferences` (pengaturan di tabel `settings`), `share_plus` / WhatsApp API (cukup link `wa.me` + buka folder PDF), Google Drive API (cukup folder Drive for desktop), `syncfusion_*` (lisensi komersial).

Di luar pub.dev: rilis macOS = `.app` ad-hoc signed dalam `.dmg` (lihat `docs/rilis-macos.md`), tanpa Apple Developer Program.
