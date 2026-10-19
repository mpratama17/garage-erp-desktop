# Aturan Desain — garage-erp-desktop

Sumber: `docs/referensi-ui.jpeg` (admin dashboard terang: sidebar putih, menu aktif biru, kartu putih, KPI pastel, tabel dengan pill status), `docs/logo-star-garage.jpeg` (logo saja), screenshot app pusat (tab Barang/Jasa, Template/Import/Export, paginasi).
Platform: Flutter desktop (Windows/macOS), **offline**. Semua aturan di bawah diwujudkan di **satu file `lib/core/theme.dart`** (token + `ThemeData`); layar tidak boleh menulis warna/ukuran mentah.

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
| `field` | `#F2F5FA` | Latar input |
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
- Jendela minimum **1280 × 720**; konten melebar penuh, form dibatasi lebar **720**.

## 5. Kerangka layar

```
┌────────────┬─────────────────────────────────────────────────────┐
│ [logo]     │  Judul halaman                 [periode] [🔒 Owner] │
│ Nama toko  │  subjudul                                           │
│            ├─────────────────────────────────────────────────────┤
│ Penjualan  │  [tab]  [tab]  [tab]                [Import][+ Baru]│
│ Gudang     │  ┌───────────────────────────────────────────────┐  │
│ Kontak     │  │ [cari…]                      [filter status ▾]│  │
│ Kas & Bank │  │ tabel                                         │  │
│ Biaya      │  │                                               │  │
│ Gaji       │  │                       25/halaman  ‹ 1/3 ›     │  │
│ Laporan    │  └───────────────────────────────────────────────┘  │
│            │                                                     │
│ Pengaturan │                                                     │
│ Backup ✓   │                                                     │
└────────────┴─────────────────────────────────────────────────────┘
```

- **Sidebar** 232 px, putih: ikon logo (`logo_icon_path`, PNG tanpa latar) + nama bengkel di atas, menu modul, lalu Pengaturan + status backup di bawah. Item aktif = **blok `primary` solid, teks & ikon putih**; hover = `primarySoft`. Urutan menu = urutan pemakaian harian.
- **Logo**: versi gelap tanpa latar (putih → tinta, oranye tetap) agar terbaca di sidebar putih & nota PDF. Logo penuh = nota, ikon SG = sidebar.
- **Header halaman**: judul + subjudul singkat di kiri, aksi di kanan. **Indikator mode owner** (🔒 terkunci / 🔓 owner) ada di topbar.
- **Tab** di bawah header untuk sub-bagian (Gudang: Barang / Jasa / Ready Stock; Penjualan: Invoice / Pemesanan).
- **Aksi halaman** di kanan baris tab: aksi utama (`+ Invoice Baru`) satu-satunya tombol `primary`; aksi lain (Import, Export, Template) tombol garis.
- **Topbar** di atas konten: cari global (invoice/pemesanan, customer, produk; maks. 5 hasil per kelompok), tanggal hari ini, tombol owner. Subjudul halaman maksimal satu kalimat pendek.

## 6. Komponen

### Tabel (dipakai semua daftar)
- Kartu putih; header `label` di latar `bg`; tinggi baris 48; pemisah 1 px `border`; baris hover `bg`.
- Kolom uang & angka rata kanan, tabular. Kode (SKU/nomor) dengan font tebal 600.
- Kolom status = pill. Aksi baris = ikon (lihat/ubah/…) di kolom terakhir dengan tooltip.
- Di atas tabel: kotak cari + filter. Di bawah: "Menampilkan 1–25 dari 69" + paginasi **25 per halaman**.
- Klik baris = buka detail di **panel kanan** (bukan pindah halaman), supaya daftar tetap terlihat.
- **Empty state**: satu kalimat + satu tombol aksi ("Belum ada invoice. + Invoice Baru").

### Kartu KPI (`KpiCard` + `KpiRow`: Dashboard, Penjualan, Gudang, Biaya, Gaji; Kas = kartu saldo)
- Ikon dalam kotak pastel 40 px + label + angka `kpi` + perubahan vs periode lalu (▲ hijau / ▼ merah, selalu dengan tanda panah, tidak hanya warna).
- Maksimal 4 kartu per baris, tinggi disamakan. Angka owner-only (laba, saldo di Dashboard, nilai stok) tampil `••••` saat terkunci.

### Form
- **Label di atas input** (widget `Labeled`), field **latar abu `#F2F4F7` tanpa garis**; fokus = garis `primary` (biru) 1,5 px; error = garis bahaya. Tidak memakai label melayang Material. Wajib = tanda `*`.
- Teks label & bantuan **singkat** (1–3 kata). Aturan penting yang mencegah salah input tetap ditampilkan, sebagai teks bantuan kecil di bawah field/kartu, bukan di label. Error di bawah input, warna bahaya, kalimat jelas ("No. HP sudah dipakai BUDI").
- **Input Rupiah**: ketik angka polos, tampil `2.250.000` saat fokus hilang; prefix `Rp`. Input diskon menerima `10%` lalu dikonversi ke Rupiah.
- Tanggal: pemilih tanggal format `dd/MM/yyyy`.
- Tombol di kanan bawah: `Batal` (garis) lalu aksi utama (`primary`). Enter = simpan; Esc = batal.
- Form invoice: baris item berupa tabel yang bisa diedit langsung; total + terbilang selalu terlihat di bawah.

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

## 8. Format & bahasa

- Bahasa Indonesia, kalimat pendek, kata kerja di tombol ("Simpan", "Terima Pembayaran", "Kirim WA").
- Uang: `Rp 2.250.000` (tanpa desimal). Ringkas di KPI: `Rp 12,4 jt`.
- Tanggal: tabel `02/10/2026`, judul `Oktober 2026`.
- Nomor HP tampil `0812-3456-7890`; disimpan polos.

## 9. Keyboard (desktop)

| Tombol | Aksi |
|---|---|
| `Ctrl/⌘ + N` | Data baru di halaman aktif |
| `Ctrl/⌘ + F` | Fokus ke kotak cari |
| `Ctrl/⌘ + S` / `Enter` | Simpan form |
| `Esc` | Tutup dialog / panel |
| `Ctrl/⌘ + P` | Cetak/simpan PDF invoice yang dibuka |

Semua elemen bisa dijangkau `Tab`, dengan **cincin fokus 2 px `primary`** yang terlihat.

## 10. Grafik

- Di Dashboard & Laporan: garis (omzet/laba per waktu) dan batang (per kategori/rekening). Tidak ada pie/donut (referensi punya; batang lebih mudah dibandingkan).
- Warna seri: `primary` biru dengan area biru muda; tooltip navy. Sumbu & grid `border`; label `inkMuted`.
- Setiap grafik punya tabel angka di bawahnya (bisa di-export).

## 11. Tidak dipakai (sengaja)

Dark mode, foto/avatar produk & customer, gradien, animasi selain transisi 150 ms, notifikasi lonceng, donut chart, ilustrasi empty state.
