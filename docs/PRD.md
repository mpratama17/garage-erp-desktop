# PRD — Star Garage ERP (Penjualan, Inventory, Kas, Biaya, Gaji & Laporan)

| | |
|---|---|
| Client | Star Garage — member Yoong Motor (Pasuruan) |
| Versi | **2.4** · 23 Okt 2026 — disinkronkan dengan build **1.2.0+3** (R1 + upgrade UI + masukan R2 + masukan R3) |
| Status | R1, R2, R3 sudah dikerjakan; build 1.1.0+2 sedang diuji client, 1.2.0+3 diuji owner. Sisa: item di §10 |
| Repo | `garage-erp-desktop` (nama generik; nama bengkel diatur dari Pengaturan) |
| Sumber | `docs/brief-client.txt` (versi 13:08), 2 contoh invoice Kledo (`docs/contoh-*.pdf`), `docs/GUDANG BARANG new.xlsx`, `docs/INSENTIF-DES24.pdf`, logo, screenshot app pusat, Google Sheet customer (~148 baris), **Sheet pembukuan penjualan** (DES24–JULI26 + UANG 2025/2026), **Sheet pengeluaran & insentif** (PENGELUARAN 2025/2026, INSENTIF-DES24 s/d OKT26) |

**Changelog v2.4** (23 Okt) — dokumen disamakan dengan aplikasi yang berjalan. Ringkas:
- **Dari masukan client R2 (20 Okt):** diskon invoice Rp/% + **PPN** per invoice (PPN tidak lagi "selalu 0"); **modal otomatis** dari harga beli terakhir (menggantikan "modal manual per baris"); template pesan WA + rincian barang; pembelian stok punya **no. nota, foto nota, status belum dibayar/lunas**; riwayat stok klik ke pembelian/invoice; **slip gaji PDF**; grafik Dashboard dengan rentang tanggal; **mode terkunci = hanya lihat**, kasir hanya boleh tambah penjualan/customer/biaya (§3a).
- **Dari masukan client R3 (22 Okt):** Split View (jendela min. 640×560); sidebar baru dengan dropdown; menu **Penjualan** (Tagihan, Pemesanan) dan **Pembelian** (Tagihan Pembelian); **Kontak** = Customer / Vendor / Pegawai; **Biaya berulang**; filter kolom + rentang tanggal + export di Biaya & Kas; stempel LUNAS di PDF; **Laporan** diperluas (keuangan, akuntansi dari jurnal turunan, detail penjualan/pembelian).
- **Keputusan owner 23 Okt:** pemesanan lunas → invoice tetap lewat tombol "Buat invoice"; barang/jasa baru dari form invoice **wajib PIN owner**, modal 0 bila harga beli kosong; **invoice baru butuh stok > 0** (barang stok 0 tidak muncul/ditolak); vendor khusus owner.
- Bagian lain yang berubah: §4.1–4.8 (ID baru ditandai **R2**/**R3**), §4.10 Dashboard & cari, §4.11 Pengaturan, §6, §7 (skema v3), §8, §9, §10, §12.

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

### 3a. Mode terkunci (kasir) vs owner — **R2**

Aplikasi terbuka dalam **mode terkunci = hanya lihat**; PIN owner membuka mode owner (sampai app ditutup atau 15 menit tanpa aktivitas). Aturan ini dijaga di **repo/database**, bukan hanya di tombol (tes: `test/akses_test.dart`).

| Boleh tanpa PIN (kasir) | Wajib PIN owner |
|---|---|
| Buat invoice/pemesanan (+ DP), terima pembayaran, buat invoice dari pemesanan | Ubah/batalkan dokumen apa pun, stok opname, ubah produk, **tambah barang/jasa baru** |
| Tambah & ubah customer | Hapus customer, import, tambah/ubah/hapus **vendor** & **pegawai** |
| Catat biaya baru & **biaya berulang** | Ubah/hapus biaya, kategori, templat biaya berulang |
| Lihat Dashboard & grafik, cari global | Harga beli/modal/laba/saldo, **Pembelian**, **Gaji**, **Laporan**, export mutasi Kas, transfer, uang masuk, rekening, Pengaturan |

## 4. Kebutuhan fungsional

Prioritas: **M** = wajib rilis 1 · **S** = sebaiknya rilis 1 · **C** = menyusul bila diminta.

### 4.1 Gudang (Inventory)

| ID | Kebutuhan | Prio |
|---|---|---|
| INV-1 | CRUD item: kode/SKU, nama, kategori, satuan, tipe **Barang/Jasa**, harga beli (**hanya terlihat owner**), harga jual, stok minimal, **tarif insentif**, aktif/nonaktif | M |
| INV-2 | Menu gudang dengan tab **Barang**, **Jasa**, **Ready Stock** (barang stok > 0) | M |
| INV-3 | Stok hanya untuk Barang. Stok berubah dari: pembelian stok (+), invoice (−), void (+), penyesuaian/opname (±, PIN) | M |
| INV-4 | **Pembelian stok** (hanya **owner**) — kini di menu **Pembelian** (§4.1b): tanggal, vendor, barang, qty, harga beli, rekening pembayar, no. nota & foto nota. Menambah stok, memperbarui harga beli produk, mengurangi saldo rekening (bila dibayar), **tidak** dihitung biaya operasional | M |
| INV-5 | Import/export **.xlsx** kompatibel dengan template produk Kledo (`GUDANG BARANG new.xlsx`): kolom akuntansi Kledo diabaikan; ditambah kolom Tipe, Stok Awal, Tarif Insentif. Baris bermasalah (SKU kembar, harga kosong) ditampilkan, tidak dilewati diam-diam. **R3:** satu tombol **Import** bermenu (*Unduh template* / *Pilih file*) | M |
| INV-6 | Peringatan stok di bawah minimal / minus | M |
| INV-7 | Riwayat keluar-masuk stok per barang. **R2:** baris penjualan/batal menampilkan no. invoice · customer · plat dan **klik → buka invoice**; baris pembelian **klik → buka Pembelian** (PIN owner) | S |
| INV-8 | **R3:** kartu info di atas Gudang (bisa digulir mendatar): stok tersedia, hampir habis, habis, total stok, total HPP, total penjualan, total pembelian (HPP & pembelian hanya owner) | S |
| INV-9 | **R2:** kolom **Insentif** tampil di tab Barang & Ready Stock (bukan hanya Jasa); barang juga bisa punya tarif insentif | S |

### 4.1b Pembelian (menu sendiri, **R3**) — khusus owner

| ID | Kebutuhan | Prio |
|---|---|---|
| PEM-1 | Menu **Pembelian** di sidebar (pindah dari tab Gudang): daftar pembelian stok terbaru dulu — **Tgl beli**, Vendor, No. nota, Total, Status (**Lunas / Belum bayar**), **Tgl lunas** (hanya bila beda hari dengan tanggal beli); cari + rentang tanggal; klik baris → rincian barang & harga beli | M |
| PEM-2 | **Pembelian stok**: vendor dipilih/diketik dari daftar Kontak ▸ Vendor (nama baru otomatis membuat vendor; nama disimpan dalam ejaan baku vendor), no. nota, **foto nota**, centang **"Sudah dibayar sekarang"** (mati = belum dibayar: stok & harga beli tetap jalan, tidak ada kas keluar) | M |
| PEM-3 | Client: pembelian selalu **lunas penuh**, kadang beberapa hari kemudian (tidak dicicil) → tombol **Lunasi sekarang** membayar penuh dari rekening yang dipilih saat pembelian dicatat; tanggal lunas tercatat | M |
| PEM-4 | Sub-menu **Tagihan Pembelian** = pembelian yang belum dibayar | M |

Paket (mis. "PAKET REBORN G", "PAKET TRADE ANNIVERSARY") = **item biasa** dengan harga & modal sendiri, isinya ditulis di deskripsi. Mengurangi stok komponen secara otomatis → **C**.

### 4.2 Kontak

| ID | Kebutuhan | Prio |
|---|---|---|
| KON-1 | CRUD customer: nama, no. HP (dinormalisasi `08…`, unik), jenis mobil, plat, catatan | M |
| KON-2 | Import/export .xlsx/.csv sesuai kolom Google Sheet customer; duplikat no. HP digabung dengan laporan | M |
| KON-3 | Detail customer: riwayat invoice/pemesanan, total belanja, kunjungan terakhir | M |
| KON-4 | Statistik: jumlah pelanggan, **% repeat order**, **top pelanggan** per bulan & tahun | M |
| KON-5 | **R3:** Kontak punya tiga tab — **Customer**, **Vendor**, **Pegawai** — supaya penjualan/pembelian berulang cukup mencari/mengetik nama. **Vendor** (tabel `vendors`): nama unik (tanpa beda huruf), no. telp, alamat, catatan; dihapus hanya bila belum punya pembelian; tambah/ubah **khusus owner**. **Pegawai** = data karyawan Gaji + no. HP & catatan (tanpa gaji); tambah/ubah khusus owner | M |
| KON-6 | **R2/R3:** invoice **baru** selalu menimpa mobil & plat customer ke yang terbaru (customer boleh ganti mobil/plat); mengubah invoice lama tidak ikut mengubahnya. Riwayat mobil/plat lama tetap terlihat sebagai label di atas Riwayat belanja (diambil dari invoice). Klik baris **Riwayat belanja → buka invoice** | M |

Definisi: pelanggan aktif = punya ≥ 1 invoice (bukan batal) di periode; % repeat = pelanggan aktif yang punya ≥ 2 invoice sepanjang waktu ÷ pelanggan aktif; top = urut total invoice di periode (10 teratas).

### 4.3 Penjualan

| ID | Kebutuhan | Prio |
|---|---|---|
| PJ-1 | **Invoice** CRUD: customer, mobil & plat (terisi dari customer, bisa diubah), baris item (produk/jasa, deskripsi, qty, harga jual, **diskon Rp**, **teknisi** 0–2 orang), tanggal, jatuh tempo (default +30 hari) | M |
| PJ-1b | **Modal per baris** diisi **otomatis oleh sistem dari harga beli terakhir produk** (Gudang) saat dokumen dibuat — **R2, menggantikan input manual owner**; kolom "Modal/unit" dihapus dari form. Mengubah dokumen mempertahankan modal lama. Produk tanpa harga beli = modal 0 + peringatan di laba rugi; owner melengkapi harga beli di Gudang. Admin/kasir tidak melihat modal | M |
| PJ-2 | **Kasir** = mode cepat dari form invoice: pilih customer & item → terima pembayaran penuh → simpan → PDF. Tidak ada layar POS terpisah (volume ±11 transaksi/bulan) | M |
| PJ-3 | **Pemesanan (Pre Order)** `SO/…` CRUD: item, diskon, **uang muka**, sisa; tombol **Buat Invoice** → invoice `INV/…` mencantumkan nomor SO, DP terbawa sebagai "Pembayaran Diterima". **R3/keputusan owner:** pemesanan yang sudah dijadikan invoice pindah ke daftar **Tagihan** (status "Sudah diinvoice" di Pemesanan); perpindahan **tetap lewat tombol Buat Invoice**, tidak otomatis saat lunas | M |
| PJ-4 | Pembayaran bertahap per invoice/SO; tiap pembayaran: tanggal, nominal, rekening, **bukti**. Tag otomatis **Belum Lunas / Dibayar Sebagian / Lunas**, plus **Batal** (void) | M |
| PJ-5 | Item **bonus** (harga jual 0) tetap tercatat modal & mengurangi stok (mis. Demon Eye gratis — 42 baris seperti ini di data) | M |
| PJ-6 | PDF A4 persis template Kledo: logo, nomor, tanggal, jatuh tempo, pemesanan, info bengkel, tagihan kepada, tabel (produk, deskripsi, kuantitas, harga, diskon, jumlah), subtotal, **diskon & PPN (baris hanya muncul bila ada)**, total, pembayaran diterima, sisa tagihan, rekening BCA, syarat, terbilang, tanda tangan. **R3:** stempel **LUNAS** di pojok kanan bawah blok judul "Invoice" bila lunas | M |
| PJ-7 | **Kirim ke WhatsApp**: tombol membuka chat WA ke no. HP customer dengan pesan siap kirim (ringkasan + **rincian barang/jasa**, diskon/PPN, total, **link review Google Maps**); PDF otomatis disimpan & folder-nya dibuka untuk **diseret** ke chat (WA tidak bisa menerima lampiran otomatis — disetujui client). Tanpa WhatsApp API berbayar. **R2:** 3 template pesan (lunas / belum lunas / pemesanan-DP) di Pengaturan, placeholder `{nama} {toko} {no} {rincian} {total} {dibayar} {sisa} {review}`; kosong = bawaan | M |
| PJ-8 | Nomor otomatis melanjutkan nomor terakhir: `INV/…` dan `SO/…` | M |
| PJ-9 | Void/edit invoice yang sudah ada pembayaran butuh PIN; void tidak menghapus, stok & kas dibalik | M |
| PJ-10 | Cari invoice via nomor / nama / HP / plat (klaim garansi); filter tag status | M |
| PJ-11 | **Input transaksi lama** (Agu–Okt 2026): tanggal bebas di masa lalu, nomor INV/SO diketik manual (nomor asli Kledo), dan opsi **"tidak mengubah stok"** supaya stok yang sudah dihitung tidak terpotong dua kali. Di akuntansi, HPP transaksi lama dilawan **Modal** (bukan Persediaan) | M |
| PJ-12 | **R3 (keputusan owner):** di form invoice/pemesanan ada tombol **Barang/jasa baru** — minta **PIN owner**; isian: jenis (barang/jasa), nama, harga jual, **stok awal ≥ 1** (barang). Harga beli kosong → **modal 0** (dilengkapi di Gudang). Produk langsung masuk ke baris form | M |
| PJ-13 | **Aturan stok (keputusan owner 23 Okt):** **invoice baru** hanya menerima barang dengan **stok > 0** — barang stok 0/minus tidak muncul di pilihan produk dan ditolak oleh repo (termasuk saat *Buat invoice* dari pemesanan). Qty melebihi stok yang masih > 0 tetap boleh dengan peringatan (stok bisa minus). Jasa, **pemesanan**, **transaksi lama**, dan barang yang sudah ada di invoice yang sedang diubah tidak dicek | M |
| PJ-14 | **R2:** **Diskon invoice** (Rp atau %) dan **PPN** dicentang per invoice (tarif di Pengaturan, default 11%); PPN dihitung dari subtotal **setelah diskon**. **Omzet = tanpa PPN** (Dashboard, Laporan, komisi); total tagihan = dengan PPN. Baris Subtotal/Diskon/PPN di layar & PDF hanya muncul bila ada | M |
| PJ-15 | **R3:** menu **Penjualan** dipecah dua halaman lewat dropdown sidebar: **Tagihan** (tombol "+ Tagihan"; invoice tanpa pemesanan atau hasil pemesanan) dan **Pemesanan** (tombol "+ Pemesanan"). Filter status: Belum Lunas, Dibayar Sebagian, Lunas, **Sudah diinvoice**, Batal; plus rentang tanggal | M |

PPN **tidak ada di data lama** (selalu 0 di sheet client) tetapi **bisa dicentang per invoice sejak R2** (PJ-14); invoice lama/tanpa centang tetap PPN 0. e-Faktur di luar lingkup.

### 4.4 Kas & Bank

| ID | Kebutuhan | Prio |
|---|---|---|
| KAS-1 | Daftar rekening dengan saldo awal: **BCA, Mandiri, ShopeePay, Tunai** — keempatnya bisa dipilih di setiap transaksi (bisa tambah/nonaktifkan bila nanti perlu) | M |
| KAS-2 | Semua uang masuk/keluar menempel ke satu rekening dan punya kolom **keterangan**: pembayaran invoice/SO, pembelian stok, biaya, gaji, pribadi, modal masuk | M |
| KAS-3 | **Transfer antar rekening** (mis. top up ShopeePay dari BCA) — tidak dihitung pemasukan/pengeluaran | M |
| KAS-4 | **Modal masuk / pemasukan lain** (setoran owner, dll) dan **pengeluaran pribadi (prive)** | M |
| KAS-5 | Mutasi per rekening + saldo berjalan | M |
| KAS-6 | Laporan **pemasukan, pengeluaran, arus kas bersih** — harian, bulanan, **kuartal**, tahunan | M |
| KAS-7 | **R3:** mutasi Kas & Bank punya **rentang tanggal** (pop-up kecil 2 bulan, default bulan ini), **filter per kolom**, dan **Export** (.xlsx, termasuk saldo berjalan bila satu rekening dipilih) — export khusus owner. **R2:** **saldo rekening khusus owner** (repo menolak tanpa PIN) | M |

### 4.5 Biaya

| ID | Kebutuhan | Prio |
|---|---|---|
| BIA-1 | CRUD biaya: tanggal, nama, kategori, nominal, rekening, keterangan, **bukti** | M |
| BIA-2 | Kategori bisa dikelola. Awal (dari data): Alat & Bahan Bengkel, Listrik, Air, Wifi, Transportasi, Ongkir, Makan & Minum, Tukang/Servis, Iuran/Langganan, Admin Bank, BPJS, Sumbangan, Bonus/THR, Lain-lain. **Gaji** diisi otomatis dari modul Gaji | M |
| BIA-3 | Pengeluaran rumah/pribadi **dicatat sebagai pengeluaran** dengan kategori bertanda **pribadi** (listrik/air/wifi rumah, PDAM langgar, sumbangan, ART). Di laba rugi ditampilkan sebagai baris terpisah di bawah laba bersih usaha (lihat LAP-2) | M |
| BIA-4 | **R3: Biaya berulang** — templat (mis. *Uang transport Rp20.000 per pegawai*): nama, kategori, rekening, nominal, "per pegawai" (aktif/nonaktif). Tombol **Biaya berulang** di Biaya → **Catat**: pilih tanggal + centang pegawai yang masuk → satu biaya per pegawai ("Uang transport — Budi") dicatat sekaligus (semua atau tidak sama sekali). Dicatat manual per klik (tidak otomatis harian); kasir boleh mencatat, **kelola templat khusus owner**; pegawai nonaktif/tak dikenal ditolak | M |
| BIA-5 | **R3:** Biaya punya **rentang tanggal** (default bulan ini) dan **filter per kolom**; **R2:** kolom kategori di form = pilihan **ketik-untuk-cari** | M |

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
| GAJ-9 | **R2:** tombol **Unduh slip** di dialog slip → **PDF A4** per karyawan per periode (gaya sama dengan nota invoice; hanya kolom tanda tangan Finance Star Garage, tanpa kolom tanda terima karyawan; tidak dikirim lewat WA), disimpan ke folder export/Slip. **R3:** slip memakai **tabel** (identitas, komponen, baris total). *Menggantikan jawaban 19 Okt "cukup export Excel"* — export Excel gaji per periode (slip + rincian insentif) tetap ada | M |
| GAJ-10 | **R2:** insentif per baris **dibekukan saat invoice dibuat**; tarif yang baru diisi kemudian tidak mengubah invoice yang sudah ada (belum ada aksi "terapkan ulang tarif") | S |

Di luar lingkup: PPh 21, BPJS otomatis, absensi.

### 4.7 Bukti pembayaran → Google Drive

> **Status build 1.2.0+3:** bukti disimpan **lokal** di `~/Documents/Garage ERP Bukti/` (dan nota/export di folder yang dipilih di Pengaturan); sinkron ke Google Drive **ditunda client** (backlog B2) — cukup menunjuk folder Drive for desktop bila nanti dipakai.

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
| LAP-6 | **R3: Laporan keuangan** (khusus owner, per tanggal/periode, tiap laporan bisa di-export): **Neraca**, **Arus kas**, **Proyeksi arus kas** (saldo kas 3 bulan ke depan = rata-rata masuk/keluar 3 bulan terakhir — metode sederhana, definisi client belum ada), **Laba rugi** (LAP-2), **Perubahan modal** (modal awal + laba + setoran − prive = modal akhir), **Ringkasan eksekutif** | M |
| LAP-7 | **R3: Laporan akuntansi** dari **jurnal turunan** (dibangun ulang dari invoice, kas, pembelian & stok setiap laporan dibuka — **tanpa input jurnal manual** dan tanpa tabel jurnal): **Ringkasan bank**, **Buku besar** (per akun), **Buku besar pembantu** (piutang / utang / persediaan), **Jurnal**, **Trial balance**. Dites seimbang & cocok dengan Kas & Bank dan Laba Rugi (`test/akuntansi_test.dart`) | M |
| LAP-8 | **R3: Laporan penjualan** (Ringkasan, Terlaris, **Detail penjualan** per baris invoice) dan **Laporan pembelian** (**Detail pembelian** per baris: vendor, no. nota, harga beli, status, tgl lunas) | M |

Aturan hitung:
- **Pendapatan** = total invoice (setelah diskon) pada **tanggal invoice**. DP pemesanan masuk kas, tetapi belum dihitung pendapatan sampai dibuatkan invoice.
- **HPP** = Σ (qty × modal per unit yang diisi owner) di baris invoice, termasuk jasa yang punya modal dan item bonus. Baris tanpa modal dihitung 0 dan diberi peringatan.
- **Biaya operasional** = biaya berkategori operasional + gaji. Pembelian stok **tidak** termasuk; pengeluaran pribadi dipisah di baris sendiri.
- "Bulanan" = bulan kalender (1–akhir bulan), kecuali client memilih periode 27–26 (§10).
- **Pendapatan = tanpa PPN** (PJ-14). Laba rugi lama (LAP-2) hanya menghitung **penjualan**; **laba berjalan di Neraca** juga memuat *Pemasukan lain* dan selisih opname — selisihnya dijelaskan di catatan kaki Neraca.
- **Persediaan** di neraca dinilai dari pembelian/modal per baris invoice; stok awal & opname dinilai **harga beli saat ini** → perlu data produk bersih & saldo awal rekening dari client agar neraca akurat.

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

### 4.10 Dashboard & cari global (**R1 upgrade UI + R2/R3**)

| ID | Kebutuhan | Prio |
|---|---|---|
| DSB-1 | **Beranda**: 6 kartu KPI (Omzet hari ini · Omzet bulan ini · Belum lunas · Laba bersih bulan ini · Saldo semua rekening · Stok menipis); laba & saldo **hanya owner** (••••• saat terkunci) | M |
| DSB-2 | Grafik **Omzet** dengan pilihan **Harian / Bulanan / Tahunan** + rentang tanggal bebas (default bulanan 12 bulan) dan grafik **Pemasukan & pengeluaran** (arus kas: penjualan dan pembelian stok sekaligus). **Saldo rekening tidak digrafikkan** — tetap owner-only. Grafik terlihat untuk kasir | M |
| DSB-3 | Daftar ringkas **Belum lunas**, **Terlaris bulan ini**, **Stok menipis** dengan tautan "Lihat semua" | S |
| DSB-4 | **Cari global** di topbar (invoice/pemesanan via no./plat/customer/HP, customer, produk & jasa; maks. 5 per kelompok) → klik membuka record di halamannya | M |

### 4.11 Pengaturan (**R1–R3**)

Tiga tab: **Bengkel & nota** (nama, alamat, telp, email, logo nota & ikon sidebar terpisah, teks syarat nota, link review Google Maps, nomor INV/SO berikutnya, tarif PPN) · **Pesan WhatsApp** (3 template, PJ-7) · **File, backup & PIN** (folder simpan nota PDF `/Nota` & export Excel `/Export`; **jadwal backup**: harian + saat ditutup / harian / mingguan / nonaktif, folder backup; **PIN owner**; periode gaji & persen komisi sales). `setSetting` sengaja tidak dikunci untuk nomor nota kasir dan catatan backup.

## 5. Alur utama

1. **Penjualan langsung**: invoice → pilih customer → item (+ teknisi) → bayar penuh ke rekening + bukti → **Lunas** → stok, kas, insentif tercatat → PDF / kirim WA.
2. **Pemesanan**: Penjualan ▸ Pemesanan → SO → terima DP (+ bukti) → barang datang & dipasang (stok barang harus > 0: catat pembelian dulu bila perlu) → **Buat Invoice** → tampil di **Tagihan** → sisa tagihan → pelunasan → Lunas.
3. **Belanja stok**: Pembelian ▸ Pembelian stok (vendor, no. nota, foto) → stok bertambah, harga beli produk diperbarui, saldo rekening berkurang bila dibayar; belum dibayar → **Tagihan Pembelian** → Lunasi sekarang.
4. **Biaya harian**: catat biaya + bukti (atau **Biaya berulang**: uang transport per pegawai yang masuk) → rekening berkurang → masuk laba rugi (jika operasional).
5. **Top up / pindah uang**: transfer antar rekening.
6. **Gajian (tgl 27)**: buka periode → slip otomatis berisi insentif → isi lembur/bonus/potongan → Bayar → biaya Gaji.
7. **Tutup bulan**: laba rugi + arus kas → cocokkan saldo app vs saldo riil tiap rekening → export Excel.

## 6. Kebutuhan non-fungsional

| Area | Kebutuhan |
|---|---|
| Biaya | **Rp 0 per bulan**: tanpa server, domain, DB berbayar, maupun API berbayar |
| Platform | **macOS** (PC kasir client = MacBook Air M1), 1 perangkat, **offline** (SQLite). Jendela minimum **640×560** (mendukung **Split View**, R3); kode tetap bisa dibuild untuk Windows bila nanti perlu |
| Backup | Salinan database otomatis ke folder **lokal** (default `~/Documents/Garage ERP Backup`, bisa diganti mis. ke flashdisk) dengan **jadwal** yang bisa dipilih (harian + saat ditutup / harian / mingguan / nonaktif), 60 file terbaru. Ke Google Drive: ditunda. Error aplikasi dicatat di `~/Library/Logs/Garage ERP/app.log` |
| Integritas | Transaksi tidak dihapus permanen (void + pembalik); uang disimpan sebagai integer Rupiah; semua total dihitung, tidak diketik |
| Keamanan | PIN owner untuk aksi sensitif; **mode terkunci = hanya lihat** (§3a); aturan dijaga di repo/database, bukan hanya UI |
| Bahasa | Indonesia, format Rp & tanggal Indonesia |

## 7. Model data (konsep)

`products` (tipe, harga beli, harga jual, stok min, tarif insentif, aktif) · `stock_moves` (buku stok) · `purchases` (pembelian stok: **vendor_id**, supplier (salinan nama baku), **bill_no**, bukti) · `customers` (nama, HP unik, mobil, plat) · **`vendors`** (nama unik, telp, alamat, catatan; v3) · `sales_orders` + baris · `invoices` + `invoice_lines` (qty, harga, diskon Rp, **modal**, **tarif insentif**, **teknisi**) · `accounts` (BCA, Mandiri, ShopeePay, Tunai) · `cash_entries` (buku kas: rekening, ±nominal, jenis: pembayaran/pembelian/biaya/gaji/transfer/modal/prive, ref, **path bukti**) · `expenses` + `expense_categories` (operasional/pribadi) · **`recurring_expenses`** (templat biaya berulang; v3) · `employees` · `payslips` · `settings`.

Invoice & pemesanan **satu tabel** (`invoices`, kolom `kind`); `invoices` memuat diskon (Rp/%), PPN, `legacy`, `order_id`. Total/terbayar/status **dihitung, tidak disimpan**. Tidak ada tabel jurnal (jurnal turunan, LAP-7). **Skema DB v3** (v2 = diskon/PPN/nota pembelian; v3 = vendor, biaya berulang, tanggal lunas) — migrasi additive dan dites (`test/r3_test.dart`). `docs/schema.sql` / `schema.dbml` adalah rancangan awal dan **belum diperbarui**; sumber kebenaran = `lib/db/database.dart`.

## 8. Di luar lingkup rilis 1

Multi-PC / cloud sync, multi-cabang & integrasi app pusat Yoong Motor, login per karyawan, printer thermal, barcode, WhatsApp API otomatis, serial number, e-Faktur, PPh 21/BPJS, absensi, import riwayat penjualan per baris, paket dengan pengurangan stok komponen, **jurnal manual** (cukup jurnal otomatis — jawaban client R3), pintasan keyboard global. *(Dulu di sini: "hutang supplier" — sekarang sebagian ada lewat pembelian belum dibayar + Tagihan Pembelian; "PPN" — sekarang ada PJ-14.)*

## 9. Rencana rilis

| Rilis | Isi |
|---|---|
| **R1a** | Gudang + import, Kontak + import, Invoice/Kasir + pembayaran + PDF + WA, Kas & Bank (4 rekening, transfer, saldo awal), input transaksi lama, Biaya, bukti ke Drive, backup |
| **R1b** | Pemesanan/DP, Insentif & Gaji, semua laporan |
| **Upgrade UI** (19 Okt) | Form berlabel di atas, Pengaturan, sidebar, Dashboard, hierarki tombol & notifikasi, kunci saldo, palet biru royal |
| **R2** (20 Okt) — build 1.1.0+2 | Masukan client C1–C18: WA, diskon/PPN, modal otomatis, pembelian nota/belum bayar, riwayat stok, grafik Dashboard, slip PDF, mode terkunci |
| **R3** (22 Okt) — build 1.2.0+3 | Masukan client 23 butir: Split View, sidebar, Tagihan/Pemesanan/Pembelian, Kontak 3 tab, biaya berulang, laporan keuangan/akuntansi, keputusan owner 23 Okt |

Data awal (§4.9) diinput saat R1a dipasang.

## 10. Pertanyaan untuk client

**Sudah dijawab (19 Okt):** mulai pakai stok & nomor yang ada · 3 rekening (BCA, ShopeePay, Tunai) + keterangan · Agu–Okt diinput manual nanti · modal manual, hanya owner · sales 3% omzet per bulan · 2 teknisi → dibagi dua · pengeluaran pribadi tetap dicatat.

**Klarifikasi lanjutan — sudah dijawab (19 Okt):** stok kosong diisi 1 · stok sudah dikurangi penjualan Agu–Okt · 3% sales per periode gaji · pribadi terpisah di bawah laba bersih usaha (setuju) · pembelian stok oleh owner · Mandiri tetap dipakai di setiap transaksi.

**Jawaban 19 Okt (lanjutan):** toko hanya punya **2 teknisi, tidak ada karyawan sales** — owner merangkap sales/marketing/admin (tunjangan 3% hanya berlaku bila ada karyawan berperan Sales) · gaji cukup **export Excel** seperti laporan lain (tanpa slip PDF) — *diubah client di R2: slip PDF per karyawan, lihat GAJ-9*.

**Belum dijawab (pakai default):** kolom keterangan → ada di setiap transaksi kas dan di data rekening.

**Jawaban client R2 (20 Okt):** kirim WA = PDF diseret manual dari Finder · template pesan WA per status · rincian barang di pesan · bagan pemasukan vs pengeluaran dengan rentang tanggal · slip PDF A4 hanya ttd Finance · tarif insentif diisi manual per produk (barang juga bisa) · kasir hanya boleh tambah penjualan/customer/biaya · customer boleh ganti mobil/plat · pembelian selalu lunas penuh (kadang beberapa hari kemudian).

**Jawaban client R3 (22 Okt) & keputusan owner (23 Okt):** pemesanan lunas → jadi invoice di Tagihan **lewat tombol** · biaya berulang dicatat manual per klik · jurnal otomatis cukup · barang/jasa baru dari form invoice **pakai PIN owner**, modal 0 bila harga beli kosong · invoice butuh **stok > 0** · vendor khusus owner.

**Masih menunggu client:** saldo awal 4 rekening · data produk bersih (SKU kembar CB/001, SR800.3 & LED HVT EXPERT H4 dobel, produk belum ada: POWER+, switch, kabel, paket) + daftar jasa (harga, tarif insentif) · definisi **proyeksi arus kas** (sementara rata-rata 3 bulan) · hasil testing build 1.1.0+2 · versi macOS di MacBook Air kasir (minimal 12).

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
| Buka WhatsApp, link Maps, buka folder PDF/bukti | `url_launcher` | 6.3.3 | ✅ terpasang. Flutter Favorite |
| Ukuran jendela minimum **640×560** (Split View) & judul | `window_manager` | 0.5.2 | ✅ terpasang |
| Grafik di **Dashboard** (Laporan = tabel + Excel) | `fl_chart` | 1.2.0 | ✅ terpasang |
| Ikon aplikasi dari logo | `flutter_launcher_icons` (dev) | 0.14.4 | ➕ tambah (saat rilis) |
| State management | `get` (GetX) — **hanya** `GetxController` + `Get.put`/`Get.find` + `Obx`/`.obs`; navigasi tetap sidebar biasa | 4.7.3 | ➕ tambah (keputusan tim) |
| Font | **Inter** (Google Fonts) lewat `fonts:` di pubspec — tanpa package. `google_fonts` 9.0.0 dicoba lalu dilepas: `TextTheme`-nya (dari `material_ui`) tidak kompatibel dengan Flutter 3.47 | — | ✅ |

Sengaja **tidak** dipakai: `sidebarx` (dicoba lalu dilepas R3: tidak mendukung pemisah/dropdown — sidebar buatan sendiri), Riverpod/Bloc (sudah GetX), fitur routing & HTTP GetX & router lain (sidebar + `IndexedStack`), `shared_preferences` (pengaturan di tabel `settings`), `share_plus` / WhatsApp API (cukup link `wa.me` + buka folder PDF), Google Drive API (cukup folder Drive for desktop), `syncfusion_*` (lisensi komersial).

Di luar pub.dev: rilis macOS = `.app` ad-hoc signed dalam `.dmg` (lihat `docs/rilis-macos.md`), tanpa Apple Developer Program.
