# Aturan Desain — garage-erp-desktop

> Status: disinkronkan dengan UI **build 1.2.0+3** (23 Okt 2026, setelah masukan client R3). Bagian yang berubah sejak draft awal: sidebar (§5), responsif/Split View (§4a), pemilih rentang tanggal (§6), tabel, form invoice, grafik, keyboard (§9: belum dibuat).

Sumber: `docs/referensi-ui.jpeg` (admin dashboard terang: sidebar putih, menu aktif biru, kartu putih, KPI pastel, tabel dengan pill status), `docs/logo-star-garage.jpeg` (logo saja), screenshot app pusat (tab Barang/Jasa, Template/Import/Export, paginasi).
Platform: Flutter desktop (**macOS** — PC kasir Mac; kode tetap lintas-platform), **offline**. Semua aturan di bawah diwujudkan di **satu file `lib/core/theme.dart`** (token + `ThemeData`); layar tidak boleh menulis warna/ukuran mentah.

## 1. Prinsip

1. **Ikuti referensi untuk layout & rasa**: terang, lega, kartu putih di atas latar abu sangat muda, banyak whitespace.
2. **Palet mengikuti referensi** (keputusan owner 19 Okt): biru royal sebagai warna utama, teks navy/slate, KPI pastel. Oranye brand **hanya di logo**. **Merah hanya untuk bahaya/error** — tidak pernah untuk menu aktif atau tombol simpan.
3. **Data dulu**: angka (Rupiah, stok, status) harus terbaca sekilas. Tidak ada dekorasi yang tidak membawa informasi (tanpa foto produk, ilustrasi, gradien).
4. **Satu cara untuk satu hal**: satu jenis tabel, satu jenis form, satu jenis dialog di semua modul.
5. **Hanya mode terang.** Dark mode tidak dibuat (bengkel siang hari, 1 PC).

## 2. Warna (token)

| Token | Hex | Pakai untuk |
|---|---|---|
| `bg` | `#F4F6FB` | Latar aplikasi (abu kebiruan) |
| `surface` | `#FFFFFF` | Kartu, sidebar, tabel, dialog |
| `border` | `#E5E9F2` | Garis kartu, pemisah baris tabel |
| `field` | `#F2F5FA` | Latar input & tombol pemilih teknisi |
| `ink` | `#0F172A` | Teks utama, angka (navy) |
| `inkMuted` | `#64748B` | Label, subjudul, teks sekunder (slate; kontras ≥ 4.5:1 di `surface`) |
| `primary` | `#2F5BEA` | Tombol utama, menu aktif (blok solid, teks putih), link, fokus, garis grafik. Teks putih di atasnya ≥ 4.5:1 |
| `primarySoft` | `#EEF3FF` | Hover menu, baris terpilih, segmen tab terpilih |
| `danger` | `#B42318` | **Hanya** aksi destruktif, error, lewat jatuh tempo, stok minus |

Nada pastel (`Tone`) — pill status & kartu KPI (kartu = latar pastel penuh, ikon di kotak pastel lebih tua):

| Arti | Latar | Teks | Dipakai untuk |
|---|---|---|---|
| Sukses (mint) | `#E6F7EF` | `#0F7A4D` | Lunas, Ready Stock, Aktif; KPI stok/laba |
| Peringatan (kuning) | `#FFF4DC` | `#8F5B00` | Dibayar Sebagian, Stok menipis; KPI belum lunas/belum dibayar |
| Bahaya (merah) | `#FDECEC` | `#B42318` | Lewat jatuh tempo, Stok habis/minus |
| Info (biru) | `#EAF1FF` | `#2F5BEA` | Belum Lunas (belum jatuh tempo), Pemesanan terbuka; KPI omzet hari ini, saldo |
| Ungu | `#F1EDFE` | `#6A47E0` | KPI omzet bulan ini, insentif, pribadi (variasi seperti referensi) |
| Netral | `#EEF1F6` | `#475569` | Batal, Nonaktif, Jasa |

Status **tidak boleh dibedakan hanya dengan warna**: pill selalu berisi teks ("Lunas", "Habis").

## 3. Tipografi

- Font: **Inter** (Google Fonts, OFL). File `.ttf` 400/500/600/700 ada di `assets/fonts/` dan didaftarkan di `pubspec.yaml` (`fonts:`) — offline, ketebalan otomatis benar. Package `google_fonts` tidak dipakai: versi 9 memakai `material_ui` sehingga `TextTheme`-nya tidak kompatibel dengan Flutter 3.47, dan pengunduhan runtime tidak berguna untuk app offline.
- Angka uang & stok memakai **tabular figures** (`FontFeature.tabularFigures()`) dan **rata kanan** di tabel.

| Gaya | Ukuran / tebal | Pakai |
|---|---|---|
| `pageTitle` | 24 / 700 | Judul halaman ("Invoice") |
| `pageSubtitle` | 14 / 400, `inkMuted` | Kalimat di bawah judul |
| `section` | 16 / 600 | Judul kartu |
| `body` | 14 / 400 | Isi tabel, form |
| `label` | 12 / 600, `inkMuted` | Header tabel, teks kecil |
| `fieldLabel` | 13 / 600, `ink` | Label di atas input |
| `kpi` | 28 / 700 | Angka besar di kartu ringkasan |

Ukuran minimum teks 12. Tidak ada huruf kapital semua kecuali kode (SKU, nomor plat, `INV/00247`).

## 4. Spasi, ukuran, bentuk

- Grid **8 px**: jarak yang dipakai hanya 4, 8, 12, 16, 24, 32.
- Radius: kartu & dialog **14**, input & tombol **8**, pill **999**.
- Kartu: **bayangan lembut** (elevation 1, `#101828` 12%) + garis sangat tipis `#EEF0F3` — seperti referensi, tetap tegas di layar murah. Diatur di `cardTheme`; layar memakai `Card`, bukan `Container` berbayangan sendiri.
- Target klik minimum **40 px** tinggi (tombol, baris menu, ikon aksi).
- Jendela minimum **640 × 560** (sejak R3; dulu 1280 × 720) supaya muat **Split View** setengah layar MacBook. Ukuran awal 1440 × 900. Konten melebar penuh, form dibatasi lebar **720**.

### 4a. Responsif / Split View

| Lebar jendela | Perilaku |
|---|---|
| ≥ 1000 px | Sidebar lebar (232 px, bisa diciutkan manual); panel rincian di kanan daftar |
| < 1000 px | Sidebar **otomatis ciut** ke rail ikon 76 px (tombol ciut/lebar disembunyikan); anak menu (Tagihan, Pemesanan, …) tidak tampil |
| lebar daftar < lebar panel + 360 | `MasterDetail`: **panel menggantikan daftar** (panel punya tombol tutup ✕) |
| < 900 px | Baris KPI & grafik Dashboard/Laporan menumpuk vertikal; baris kartu KPI Gudang & Kas bisa digulir mendatar |
| tinggi pendek | Halaman Kas & Laporan digulir seluruhnya (tabel tidak terjepit) |

Toolbar tabel dan header halaman **membungkus** (`Wrap`) alih-alih meluap. Dijaga `test/layout_test.dart`: semua halaman & sub-halaman diuji tanpa overflow di lebar **720** dan **1440**.

## 5. Kerangka layar

```
┌────────────┬─────────────────────────────────────────────────────┐
│ [logo]     │  Judul halaman                 [periode] [🔒 Owner] │
│ Nama toko  │  subjudul                                           │
│            ├─────────────────────────────────────────────────────┤
│ Beranda    │  [tab]  [tab]  [tab]                [Import][+ Baru]│
│ ────────── │  ┌───────────────────────────────────────────────┐  │
│ Penjualan ▾│  │ [cari…]  [rentang tanggal]   [filter status ▾]│  │
│  Tagihan   │  │ header kolom                                  │  │
│  Pemesanan │  │                                               │  │
│ Pembelian ▾│  │ tabel                                         │  │
│ ────────── │  │                       25/halaman  ‹ 1/3 ›     │  │
│ Gudang     │  └───────────────────────────────────────────────┘  │
│ Biaya      │                                                     │
│ ────────── │                                                     │
│ Kontak     │                                                     │
│ Kas & Bank │                                                     │
│ Gaji       │                                                     │
│ ────────── │                                                     │
│ Laporan    │                                                     │
│ Pengaturan │                                                     │
│ Backup ✓   │                                                     │
└────────────┴─────────────────────────────────────────────────────┘
```

- **Sidebar** = widget sendiri di `lib/shell.dart` (`_Sidebar`; paket `sidebarx` **dilepas** — tidak mendukung pemisah/dropdown). Lebar **232 px** (lebar) atau **76 px** (ciut: ikon saja); tombol panah di bawah mengciutkan/melebarkan, otomatis ciut < 1000 px (§4a). Isi: header (ikon sidebar + nama bengkel), menu, Pengaturan, kartu status backup.
  - **Urutan & pemisah** (garis tipis, tanpa judul grup): `Beranda` │ `Penjualan ▾` `Pembelian ▾` │ `Gudang` `Biaya` │ `Kontak` `Kas & Bank` `Gaji` │ `Laporan`; **Pengaturan** item biasa paling bawah, status backup di bawahnya.
  - **Dropdown** (anak menu muncul saat induknya aktif & sidebar lebar): Penjualan ▸ **Tagihan**, **Pemesanan**; Pembelian ▸ **Tagihan Pembelian** (pembelian yang belum dibayar). Induk tanpa anak terpilih = baris induk disorot.
  - **Ikon berwarna per menu** (biru Beranda, hijau Penjualan, oranye Pembelian, ungu Gudang, merah muda Biaya, tosca Kontak, hijau tua Kas & Bank, kuning tua Gaji, biru Laporan, abu Pengaturan) — hanya ikon; teks tetap `ink`.
  - **Item aktif = pil lembut `primarySoft`, teks `primary`** (bukan blok solid — diubah dari draft awal mengikuti referensi); hover = `bg`.
  - Tidak ada notifikasi lonceng (sengaja). Cari global ada di topbar, bukan di sidebar.
- **Logo**: versi gelap tanpa latar (putih → tinta, oranye tetap) agar terbaca di sidebar putih & nota PDF. Logo penuh = nota, ikon SG = sidebar.
- **Header halaman**: judul + subjudul singkat di kiri, aksi di kanan. **Indikator mode owner** (🔒 terkunci / 🔓 owner) ada di topbar.
- **Tab** (`SegmentedButton`) di bawah header untuk sub-bagian: Gudang: Barang / Jasa / Ready Stock · Kontak: Customer / Vendor / Pegawai · Kas & Bank: Mutasi / Arus kas · Gaji: Slip gaji / Karyawan · Pengaturan: Bengkel & nota / Pesan WhatsApp / File, backup & PIN · Laporan: Keuangan / Akuntansi / Penjualan / Pembelian (lalu pilihan laporan di bawahnya). **Penjualan dan Pembelian tidak memakai tab** — Tagihan/Pemesanan dipilih lewat dropdown sidebar.
- **Aksi halaman** di kanan baris tab: aksi utama (`+ Invoice Baru`) satu-satunya tombol `primary`; aksi lain (Import, Export, Biaya berulang, Kategori, …) tombol garis. **Import** = satu tombol bermenu (*Unduh template* / *Pilih file*; `ImportButton`) di Gudang & Kontak.
- **Topbar** di atas konten: cari global (invoice/pemesanan, customer, produk; maks. 5 hasil per kelompok), tanggal hari ini, tombol owner. Subjudul halaman maksimal satu kalimat pendek.

## 6. Komponen

### Tabel (dipakai semua daftar)
- Kartu putih; header `label` di latar `bg`; tinggi baris 48; pemisah 1 px `border`; baris hover `bg`.
- Kolom uang & angka rata kanan, tabular. Kode (SKU/nomor) dengan font tebal 600.
- Kolom status = pill. Aksi baris = ikon (lihat/ubah/…) di kolom terakhir dengan tooltip.
- Di atas tabel: kotak cari + **tombol rentang tanggal** (bila daftar berbasis tanggal) + filter status. Di bawah: "Menampilkan 1–25 dari 69" + paginasi **25 per halaman**.
- **Urut per kolom** (`Col.sort`): klik judul kolom → **naik ↑ → turun ↓ → urutan bawaan**; kolom yang bisa diurutkan menampilkan ikon ⇅ (abu), kolom aktif berpanah biru. Pengurut memakai **nilai asli** (angka, tanggal, teks tanpa beda huruf besar/kecil), bukan teks tampilan; nilai kosong selalu di akhir; baris Total/pin (`AppTable.pinned`) tetap di akhir. Kolom aksi/ikon tidak bisa diurutkan, begitu juga kolom periode (Per hari/bulan) yang sudah kronologis.
- **Tombol Reset** (ikon ↻ + "Reset", di sebelah kotak cari) muncul hanya bila ada kata kunci cari atau urutan aktif; mengosongkan **kotak cari + urutan tabel itu saja** — rentang tanggal dan dropdown/tab status halaman tidak ikut. Di Laporan, ganti laporan = tabel mulai bersih.
- Laporan yang bisa diurutkan hanya yang berbentuk daftar (Ringkasan bank, Buku besar pembantu, Trial balance, Detail penjualan, Detail pembelian). Neraca, Perubahan modal, Ringkasan eksekutif, Proyeksi, Jurnal (entri berkelompok), dan Buku besar (saldo berjalan) **tidak** — urutannya bagian dari artinya.
- *(Filter teks per kolom sempat dibuat di R3 lalu **dihapus** 23 Okt — tidak sesuai maksud owner.)*
- Klik baris = buka detail di **panel kanan** (bukan pindah halaman), supaya daftar tetap terlihat.
- **Empty state**: satu kalimat + satu tombol aksi ("Belum ada invoice. + Invoice Baru").

### Kartu KPI (`KpiCard` + `KpiRow`: Dashboard, Penjualan, Gudang, Biaya, Gaji; Kas = kartu saldo)
- Ikon dalam kotak pastel 40 px + label + angka `kpi` + perubahan vs periode lalu (▲ hijau / ▼ merah, selalu dengan tanda panah, tidak hanya warna).
- **Dashboard 2 baris × 3 kartu** (Omzet hari ini · Omzet bulan ini · Belum lunas / Laba bersih bulan ini · Saldo semua rekening · Stok menipis); **Gudang 7 kartu** dalam satu baris yang bisa digulir mendatar (Stok tersedia · Hampir habis · Habis · Total stok · Total HPP · Total penjualan · Total pembelian); halaman lain maks. 4 kartu per baris. Tinggi disamakan; angka besar mengecil (`FittedBox`) di kartu sempit. Angka owner-only (laba, saldo di Dashboard, nilai stok) tampil `••••` saat terkunci.

### Form
- **Label di atas input** (widget `Labeled`), field **latar abu `field` tanpa garis**; fokus = garis `primary` (biru) 1,5 px; error = garis bahaya. Tidak memakai label melayang Material. Wajib = tanda `*`.
- Teks label & bantuan **singkat** (1–3 kata). Aturan penting yang mencegah salah input tetap ditampilkan, sebagai teks bantuan kecil di bawah field/kartu, bukan di label. Error di bawah input, warna bahaya, kalimat jelas ("No. HP sudah dipakai BUDI").
- **Input Rupiah**: ketik angka polos, tampil `2.250.000` saat fokus hilang; prefix `Rp`. Input diskon menerima `10%` lalu dikonversi ke Rupiah.
- Tanggal: pemilih tanggal format `dd/MM/yyyy`. **Rentang tanggal** (filter daftar & grafik) memakai **pop-up kecil** `pickRange` (`lib/core/range_picker.dart`): **dua bulan berdampingan** (satu bulan bila sempit) + **pilihan cepat** di kiri — Kemarin, Hari ini, Bulan ini, Bulan lalu, 7/30 hari terakhir, Tahun ini, Tahun lalu, 1/2 tahun terakhir (di jendela sempit pilihan cepat pindah ke atas kalender). Tombolnya `RangeButton` (ikon kalender + `dd/MM/yyyy – dd/MM/yyyy`; "Semua tanggal" bila kosong). Dipakai Dashboard, Penjualan, Pembelian, Biaya, Kas & Bank, Laporan.
- Tombol di kanan bawah: `Batal` (garis) lalu aksi utama (`primary`). Enter = simpan; Esc = batal.
- **Form invoice/pemesanan** (dialog 1180 px): field memakai **ikon + contoh isian** supaya fungsinya jelas — tanggal/jatuh tempo (ikon kalender), customer (ikon cari, "Nama / HP / plat · kosong = UMUM"), mobil (ikon mobil, "mis. Honda Jazz"), plat ("N 1234 AB"), catatan ("Opsional — tampil di nota"). **Rincian** = satu kotak berbingkai (`border`, radius 16): judul kolom (Produk / jasa · Keterangan · Qty · Harga satuan · Diskon · Teknisi · Jumlah; angka rata kanan, sejajar isi field), tiap baris dipisah garis tipis; kolom produk = Autocomplete dengan ikon cari ("Cari barang / jasa…", tampil harga & stok); harga berprefix `Rp`; teknisi = tombol ber-ikon ("Pilih teknisi" + panah, maks. 2). Di bawah rincian: **Tambah baris** dan **Barang/jasa baru** (minta PIN owner; lihat PRD PJ-12). Panel kanan bawah: subtotal, diskon (Rp/%), PPN (centang), total + terbilang, dan "Terima pembayaran sekarang".
- **Aturan stok di form invoice baru**: barang berstok 0/minus **tidak ditawarkan** di pilihan produk (jasa selalu tampil); pemesanan & transaksi lama menampilkan semua barang aktif. Qty melebihi stok yang masih > 0 → peringatan merah "stok tersedia N" (tetap boleh).

### Dialog
- Hanya untuk konfirmasi & PIN. Aksi berbahaya (void, hapus) memakai tombol warna bahaya dan menyebut objeknya ("Batalkan INV/00247?"), plus kolom alasan.

### Notifikasi (`notify` / `warn` / `runAction`)
- Kartu kecil di bawah tengah, di **overlay paling atas** (tetap terang walau dialog terbuka), dengan ikon + warna + judul:
  **Berhasil** (hijau, 3 dtk) · **Periksa lagi** (kuning, 5 dtk — isian/aturan yang bisa diperbaiki user) ·
  **Gagal** (merah, 8 dtk — masalah sistem; pesan ramah, detail teknis ke log, bukan ditampilkan mentah) · **Info** (biru).
  Selalu bisa ditutup (✕).
- Aksi penting yang selesai (invoice/pemesanan baru) memakai **dialog sukses** berisi langkah berikutnya (Buka PDF, Kirim WA, Selesai).

### Tombol
- **Utama** (`FilledButton` biru): maks. **satu per layar/dialog**, untuk aksi paling sering (Simpan, Kasir/Invoice, Bayar). Paling kanan.
- **Sekunder** (`OutlinedButton` netral): aksi lain, termasuk aksi owner yang jarang (+ Rekening, Backup sekarang, Export).
- **Tersier** (`TextButton` biru): tautan ringan (Lihat semua, Tambah baris).
- **Destruktif** (`DangerButton`, garis merah): di **kiri, terpisah** dari Batal/Simpan (`dialogActions`), selalu lewat `confirmAction`.
  Di konfirmasi: tombol merah penuh dengan **kata kerja + objek** ("Hapus biaya", "Batalkan pembayaran"), bukan "Ya/Tidak".
- Controller teks lokal di dialog **tidak di-dispose manual** setelah `showDialog`: dialog masih beranimasi menutup dan bisa dibangun ulang.

## 7. Data owner-only

- Harga beli, modal per baris, laba, dan menu Gaji: saat mode terkunci tampil **`••••`** dengan ikon gembok; klik = minta PIN.
- Mode owner terbuka sampai app ditutup atau 15 menit tanpa aktivitas.
- Kolom tetap ada di layout (tidak disembunyikan), supaya tata letak tidak lompat saat PIN dimasukkan.
- **Mode terkunci = hanya lihat** (R2 C18): tombol yang butuh owner (tambah/ubah produk & vendor & pegawai, import, transfer, uang masuk, ubah/hapus biaya, kategori, gaji, pengaturan, export mutasi Kas, semua Laporan, **Barang/jasa baru** di form invoice) **meminta PIN dulu**. Kasir tanpa PIN boleh: invoice/pemesanan + DP, pembayaran, buat invoice dari pemesanan, tambah & ubah customer, catat biaya baru (termasuk **Biaya berulang**), lihat grafik. Aturan sebenarnya dijaga di repo (`requireOwner()`), bukan hanya di tombol.

## 8. Format & bahasa

- Bahasa Indonesia, kalimat pendek, kata kerja di tombol ("Simpan", "Terima Pembayaran", "Kirim WA").
- Uang: `Rp 2.250.000` (tanpa desimal). Ringkas di KPI: `Rp 12,4 jt`.
- Tanggal: tabel `02/10/2026`, judul `Oktober 2026`.
- Nomor HP tampil `0812-3456-7890`; disimpan polos.

## 9. Keyboard (desktop)

> **Belum dibuat** (per 1.2.0+3): tidak ada pintasan global. Yang berlaku hanya bawaan Flutter — `Tab` berpindah field, `Enter` menekan tombol terfokus, `Esc` menutup dialog/pop-up. Tabel di bawah = **target** (belum diminta client).

| Tombol | Aksi |
|---|---|
| `Ctrl/⌘ + N` | Data baru di halaman aktif |
| `Ctrl/⌘ + F` | Fokus ke kotak cari |
| `Ctrl/⌘ + S` / `Enter` | Simpan form |
| `Esc` | Tutup dialog / panel |
| `Ctrl/⌘ + P` | Cetak/simpan PDF invoice yang dibuka |

Semua elemen bisa dijangkau `Tab`; field yang fokus berbingkai `primary` 1,5 px.

## 10. Grafik

- Hanya di **Dashboard**: garis (omzet per waktu) dan batang (pemasukan vs pengeluaran). Tidak ada pie/donut (referensi punya; batang lebih mudah dibandingkan).
- Warna seri **soft/pastel** (sejak R3): `primary` dengan area biru muda untuk omzet; pemasukan = hijau pastel, pengeluaran = merah pastel (batang); tooltip navy. Sumbu & grid `border`; label `inkMuted`. Label sumbu yang terlalu dekat dengan titik akhir dilewati (tidak tabrakan).
- **Dashboard**: pilihan periode **Harian / Bulanan / Tahunan** + `RangeButton` rentang bebas (default bulanan 12 bulan); dua grafik — *Omzet* (garis) dan *Pemasukan & pengeluaran* (batang); lalu tiga daftar (Belum lunas, Terlaris bulan ini, Stok menipis) dengan tautan "Lihat semua". Grafik terlihat untuk semua pengguna; saldo & laba tetap owner-only.
- Laporan tidak memakai grafik: tabel angka + **Export Excel** tiap laporan (Dashboard saja yang bergrafik).

## 11. Tidak dipakai (sengaja)

Dark mode, foto/avatar produk & customer, gradien, animasi selain transisi 150 ms, notifikasi lonceng, donut chart, ilustrasi empty state, pintasan keyboard global (belum diminta).
