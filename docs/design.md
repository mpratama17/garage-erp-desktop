# Aturan Desain — garage-erp-desktop

Sumber: `docs/referensi-ui.jpeg` (admin dashboard terang: sidebar putih, kartu putih, KPI pastel, tabel dengan pill status), `docs/logo-star-garage.jpeg` (oranye + hitam), screenshot app pusat (tab Barang/Jasa, Template/Import/Export, paginasi).
Platform: Flutter desktop (Windows/macOS), **offline**. Semua aturan di bawah diwujudkan di **satu file `lib/core/theme.dart`** (token + `ThemeData`); layar tidak boleh menulis warna/ukuran mentah.

## 1. Prinsip

1. **Ikuti referensi untuk layout & rasa**: terang, lega, kartu putih di atas latar abu sangat muda, banyak whitespace.
2. **Warna brand dari logo**, bukan biru referensi: oranye sebagai aksen, hitam untuk teks. Nama bengkel & logo berasal dari Pengaturan, sehingga app tetap generik.
3. **Data dulu**: angka (Rupiah, stok, status) harus terbaca sekilas. Tidak ada dekorasi yang tidak membawa informasi (tanpa foto produk, ilustrasi, gradien).
4. **Satu cara untuk satu hal**: satu jenis tabel, satu jenis form, satu jenis dialog di semua modul.
5. **Hanya mode terang.** Dark mode tidak dibuat (bengkel siang hari, 1 PC).

## 2. Warna (token)

| Token | Hex | Pakai untuk |
|---|---|---|
| `bg` | `#F5F6F8` | Latar aplikasi |
| `surface` | `#FFFFFF` | Kartu, sidebar, tabel, dialog |
| `border` | `#E4E7EC` | Garis kartu, pemisah baris tabel, input |
| `ink` | `#111318` | Teks utama, angka |
| `inkMuted` | `#5B6170` | Label, subjudul, teks sekunder (kontras ≥ 4.5:1 di `surface`) |
| `primary` | `#C2410C` | Tombol utama, item sidebar aktif, link, fokus. Teks putih di atasnya = kontras ≥ 4.5:1 |
| `primarySoft` | `#FFF1E8` | Latar item sidebar aktif, baris terpilih |
| `brandOrange` | `#F07A1E` | **Hanya** aksen non-teks (ikon KPI, garis grafik) — tidak untuk latar teks putih |

Status (pill = teks gelap di latar pastel):

| Arti | Latar | Teks | Dipakai untuk |
|---|---|---|---|
| Sukses | `#E7F6EC` | `#1B6B3A` | Lunas, Ready Stock, Aktif |
| Peringatan | `#FFF4DB` | `#8A5A00` | Dibayar Sebagian, Stok menipis |
| Bahaya | `#FDECEC` | `#B42318` | Belum Lunas (lewat jatuh tempo), Stok habis/minus |
| Info | `#EAF1FF` | `#1D4ED8` | Belum Lunas (belum jatuh tempo), Pemesanan terbuka |
| Netral | `#EEF0F3` | `#475467` | Batal, Nonaktif, Jasa |

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
| `label` | 12 / 600, `inkMuted` | Label input, header tabel |
| `kpi` | 28 / 700 | Angka besar di kartu ringkasan |

Ukuran minimum teks 12. Tidak ada huruf kapital semua kecuali kode (SKU, nomor plat, `INV/00247`).

## 4. Spasi, ukuran, bentuk

- Grid **8 px**: jarak yang dipakai hanya 4, 8, 12, 16, 24, 32.
- Radius: kartu & dialog **12**, input & tombol **8**, pill **999**.
- Bayangan: tidak ada; pakai `border` 1 px. (Referensi memakai bayangan lembut, tapi garis lebih tajam di layar kantor yang murah.)
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

- **Sidebar** 232 px, putih: logo + nama bengkel di atas, menu modul, lalu Pengaturan + status backup terakhir di bawah. Item aktif = latar `primarySoft`, teks & ikon `primary`. Urutan menu = urutan pemakaian harian (Penjualan dulu).
- **Header halaman**: judul + subjudul di kiri; di kanan pemilih periode (hanya di layar yang punya data per tanggal) dan **indikator mode owner** (🔒 terkunci / 🔓 owner, klik = masukkan PIN).
- **Tab** di bawah header untuk sub-bagian (Gudang: Barang / Jasa / Ready Stock; Penjualan: Invoice / Pemesanan).
- **Aksi halaman** di kanan baris tab: aksi utama (`+ Invoice Baru`) satu-satunya tombol `primary`; aksi lain (Import, Export, Template) tombol garis.
- Tidak ada pencarian global di header (referensi punya; volume data kecil, cukup cari per tabel).

## 6. Komponen

### Tabel (dipakai semua daftar)
- Kartu putih; header `label` di latar `bg`; tinggi baris 48; pemisah 1 px `border`; baris hover `bg`.
- Kolom uang & angka rata kanan, tabular. Kode (SKU/nomor) dengan font tebal 600.
- Kolom status = pill. Aksi baris = ikon (lihat/ubah/…) di kolom terakhir dengan tooltip.
- Di atas tabel: kotak cari + filter. Di bawah: "Menampilkan 1–25 dari 69" + paginasi **25 per halaman**.
- Klik baris = buka detail di **panel kanan** (bukan pindah halaman), supaya daftar tetap terlihat.
- **Empty state**: satu kalimat + satu tombol aksi ("Belum ada invoice. + Invoice Baru").

### Kartu KPI (Laporan & atas halaman Kas)
- Ikon dalam kotak pastel 40 px + label + angka `kpi` + perubahan vs periode lalu (▲ hijau / ▼ merah, selalu dengan tanda panah, tidak hanya warna).
- Maksimal 4 kartu per baris.

### Form
- Label di atas input; wajib = tanda `*`. Error di bawah input, warna bahaya, kalimat jelas ("No. HP sudah dipakai BUDI").
- **Input Rupiah**: ketik angka polos, tampil `2.250.000` saat fokus hilang; prefix `Rp`. Input diskon menerima `10%` lalu dikonversi ke Rupiah.
- Tanggal: pemilih tanggal format `dd/MM/yyyy`.
- Tombol di kanan bawah: `Batal` (garis) lalu aksi utama (`primary`). Enter = simpan; Esc = batal.
- Form invoice: baris item berupa tabel yang bisa diedit langsung; total + terbilang selalu terlihat di bawah.

### Dialog
- Hanya untuk konfirmasi & PIN. Aksi berbahaya (void, hapus) memakai tombol warna bahaya dan menyebut objeknya ("Batalkan INV/00247?"), plus kolom alasan.

### Notifikasi
- Snackbar di bawah tengah, 4 detik, untuk hasil aksi ("INV/00247 tersimpan · Buka PDF").

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

- Hanya di Laporan: garis (omzet/laba per waktu) dan batang (per kategori/rekening). Tidak ada pie/donut (referensi punya; batang lebih mudah dibandingkan).
- Warna seri: `brandOrange` (utama), `#1D4ED8` (pembanding). Sumbu & grid `border`; label `inkMuted`.
- Setiap grafik punya tabel angka di bawahnya (bisa di-export).

## 11. Tidak dipakai (sengaja)

Dark mode, foto/avatar produk & customer, gradien, bayangan, animasi selain transisi 150 ms, pencarian global, notifikasi lonceng, donut chart, ilustrasi empty state.
