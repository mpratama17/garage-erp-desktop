# Garage ERP

Aplikasi desktop **macOS** untuk bengkel: kasir & invoice, stok, kas 4 rekening, biaya, gaji & insentif teknisi, dan laporan laba rugi. Dibangun untuk **Star Garage** (bengkel modifikasi & restorasi lampu mobil, member Yoong Motor Pasuruan) sebagai pengganti Kledo + beberapa Google Sheet.

**Offline, satu PC kasir, Rp 0/bulan:** tanpa server, domain, database berbayar, maupun langganan. Data tersimpan di SQLite lokal dengan backup otomatis.

![Dashboard](docs/screenshots/dashboard-owner.png)

## Masalah yang diselesaikan

| Sebelumnya | Sekarang |
|---|---|
| Satu transaksi diketik 3 kali (Kledo, sheet penjualan, sheet insentif) | Satu invoice menjadi sumber stok, kas, laporan, dan insentif |
| "Profit" bulanan mencampur pembelian stok, gaji, dan pengeluaran pribadi | Laba rugi yang benar: Pendapatan − HPP − biaya operasional (termasuk gaji) = laba bersih usaha; pengeluaran pribadi dipisah di bawahnya |
| Tidak ada master produk (±210 nama barang berbeda untuk barang yang sama) | Satu daftar produk & jasa; invoice hanya memilih dari daftar |
| Rumus manual & salin-tempel (mis. total insentif Rp 1.505.000 tertulis 1.455.000) | Semua total dihitung dari transaksi, tidak disimpan |
| Langganan Kledo mahal, data tidak bisa diekspor | Gratis, data milik bengkel sendiri (SQLite + Excel) |

## Fitur

| Modul | Isi |
|---|---|
| **Dashboard** | Omzet hari/bulan ini (dibanding periode yang sama bulan lalu), invoice belum lunas & lewat tempo, stok menipis, grafik omzet 12 bulan, produk terlaris. Laba & saldo hanya untuk owner |
| **Penjualan** | Kasir/invoice, pemesanan + DP → invoice, pembayaran bertahap per rekening + bukti, status Lunas/Dibayar Sebagian/Belum Lunas/Lewat tempo/Batal, nota PDF A4, kirim WhatsApp + link review Google Maps, input transaksi lama |
| **Gudang** | Barang & jasa, stok dari buku stok (bukan angka yang diketik), pembelian stok, stok opname, import/export Excel format Kledo |
| **Kontak** | Customer (nama, HP unik, mobil, plat), import Google Sheet dengan penggabungan HP sama, riwayat belanja, repeat order, top pelanggan |
| **Kas & Bank** | Saldo BCA / Mandiri / ShopeePay / Tunai (khusus owner), mutasi + saldo berjalan, transfer antar rekening, modal masuk, arus kas harian–tahunan |
| **Biaya** | Biaya operasional & pribadi per kategori, bukti pembayaran |
| **Gaji** | Slip per periode (27–26), insentif per pekerjaan teknisi (dibagi dua bila dikerjakan berdua), tunjangan kerja sales % omzet, bayar → kas, export Excel |
| **Laporan** | Laba rugi, penjualan per kategori, terlaris, arus kas; bulanan/tahunan; export Excel |
| **Pengaturan** | Data bengkel & logo nota, nomor nota, folder simpan file, jadwal backup otomatis, PIN owner |

Fitur lintas modul: **cari global** (no. invoice, nama, HP, plat, produk), **PIN owner** untuk data sensitif (harga beli, modal, laba, saldo, gaji), dan notifikasi yang jelas (berhasil / periksa lagi / gagal).

| | |
|---|---|
| ![Penjualan](docs/screenshots/penjualan.png) | ![Kasir](docs/screenshots/penjualan-kasir.png) |
| ![Kas & Bank](docs/screenshots/kas.png) | ![Laporan](docs/screenshots/laporan.png) |

## Teknologi

- **Flutter 3.47** desktop (macOS; target Windows tersedia, belum dirilis)
- **SQLite via [drift](https://drift.simonbinder.eu/)**: query bertipe, stream reaktif, migrasi
- **GetX**: state & dependency injection
- `pdf` (nota), `excel` (import/export), `fl_chart` (grafik), `file_selector`, `url_launcher`, `window_manager`
- Font **Inter** dibundel (offline)

## Prinsip desain kode

- **Angka turunan tidak disimpan.** Stok = Σ buku stok, saldo = saldo awal + Σ kas, total/terbayar/status invoice dihitung dengan SQL. Tidak ada angka yang bisa "tidak sinkron".
- **Aturan bisnis di repo, bukan di UI.** Akses owner (`requireOwner()`), rekening aktif, invoice terbayar, periode gaji, dan seterusnya dicek di lapisan data. Tombol yang disembunyikan bukan pengaman.
- **Vertical slice per modul:** `lib/modules/<modul>/` berisi `*_repo.dart` (aturan + query, diuji), `*_controller.dart` (GetX), dan `*_page.dart` (UI).
- **Satu sumber gaya.** Token warna, ukuran, dan komponen ada di `lib/core/` (`theme.dart`, `ui.dart`, `table.dart`); aturannya di [`docs/design.md`](docs/design.md).

```
lib/
├── main.dart              # inisialisasi, jendela, backup saat ditutup
├── shell.dart             # sidebar, topbar, cari global
├── core/                  # tema, komponen UI, format Rupiah/tanggal, PIN owner, Excel, log error
├── db/database.dart       # semua tabel drift + pengaturan + backup
└── modules/               # dashboard, penjualan, gudang, kontak, kas, biaya, gaji, laporan, pengaturan
test/                      # test logika bisnis (drift in-memory)
tool/preview/              # render layar ke PNG (golden) untuk cek UI tanpa menjalankan app
tool/release_macos.sh      # build rilis + .dmg
docs/                      # PRD, aturan desain, panduan rilis
```

## Menjalankan

Kebutuhan: macOS, Flutter 3.47+, Xcode (untuk build macOS).

```sh
flutter pub get
dart run build_runner build -d   # hanya bila skema di lib/db/database.dart diubah
flutter run -d macos
```

Saat pertama kali membuka data owner, app meminta **membuat PIN owner**.

```sh
flutter analyze
flutter test                                          # logika bisnis
flutter test tool/preview --update-goldens            # render layar ke tool/preview/*.png
```

## Rilis

```sh
sh tool/release_macos.sh   # → dist/Garage-ERP-<versi>.dmg (universal, ad-hoc signed)
```

Tanpa Apple Developer account. Pemasangan di Mac client: buka `.dmg` → seret ke Applications → pertama kali buka lewat *System Settings → Privacy & Security → Open Anyway*. Lihat [`docs/rilis-macos.md`](docs/rilis-macos.md).

## Data & backup

| Apa | Lokasi |
|---|---|
| Database | `~/Library/Application Support/com.mpratama.garageErp/garage_erp.sqlite` |
| Backup otomatis | `~/Documents/Garage ERP Backup/` (bisa diganti, mis. ke flashdisk); 60 file terbaru; jadwal: harian + saat ditutup / harian / mingguan / nonaktif |
| Nota PDF & export Excel | `~/Documents/Garage ERP/Nota` dan `/Export` (bisa diganti di Pengaturan) |
| Bukti pembayaran | `~/Documents/Garage ERP Bukti/<tahun>/<bulan>/` |
| Log error | `~/Library/Logs/Garage ERP/app.log` |

> Bundle id `com.mpratama.garageErp` tidak boleh diganti setelah app terpasang di client (lokasi database mengikuti bundle id).

## Status

Semua modul rilis pertama selesai; detail per modul, jumlah test, dan backlog ada di [`PROGRESS.md`](PROGRESS.md). Kebutuhan lengkap ada di [`docs/PRD.md`](docs/PRD.md).

---

Proyek klien (privat). Data customer di test & screenshot adalah data fiktif.
