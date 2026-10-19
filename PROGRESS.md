# star-garage-erp (repo: garage-erp-desktop) — Progress Snapshot

Last updated: 2026-10-19.

**Apa:** mini-ERP desktop **macOS** offline (Flutter + SQLite/drift + GetX) untuk Star Garage (bengkel modif lampu, member Yoong Motor Pasuruan), pengganti Kledo + Google Sheet. 7 modul + Pengaturan (`docs/PRD.md` v2.3). Kasir: MacBook Air M1.

**Metode:** vertical slice per modul — skema → logika + test → controller GetX → UI → analyze/test/preview/run → code review → perbaikan → commit.

## Tracking modul

| # | Modul | Isi | Status | Test | Review | Commit |
|---|---|---|---|---|---|---|
| 0 | Fondasi | Tema, sidebar, Pengaturan, PIN owner, 4 rekening, nomor nota, backup lokal, rilis .dmg | ✅ Selesai | 6 | 10 temuan → diperbaiki | `bd24dd9` |
| 1 | Gudang | Barang/Jasa/Ready Stock, CRUD produk, harga beli khusus owner, stok opname, pembelian stok (→ kas), import/export Excel format Kledo (stok kosong = 1), riwayat stok | ✅ Selesai | 9 | 10 temuan → diperbaiki | `5041dcc` |
| 2 | Kontak | CRUD customer (nama, HP unik, mobil, plat, catatan), import Google Sheet client (gabung HP sama + laporan), export, cari via HP/plat. *Riwayat belanja, repeat order & top pelanggan menyusul di Modul 3 (butuh data invoice)* | ✅ Selesai | 5 | 10 temuan → 9 diperbaiki | `c060db3` |
| 3 | Penjualan | Invoice/kasir (bayar langsung), pemesanan + DP → invoice, pembayaran bertahap per rekening + bukti, tag Lunas/Dibayar Sebagian/Belum Lunas/lewat tempo/Batal, batal (stok & uang balik), PDF format Kledo, kirim WA + link review, input transaksi lama (tanpa gerak stok), modal per baris khusus owner, teknisi 0–2 per baris; + riwayat & statistik customer di Kontak | ✅ Selesai | 13 | 10 temuan → diperbaiki | `a8491d8` |
| 4 | Kas & Bank | Mutasi & saldo 4 rekening, transfer, saldo awal, arus kas | ⏭️ Berikutnya | – | – | – |
| 5 | Biaya | Biaya operasional & pribadi, kategori | ⬜ Belum | – | – | – |
| 6 | Gaji | Karyawan, insentif per teknisi (dibagi 2 bila berdua), komisi sales 3%, slip gaji | ⬜ Belum | – | – | – |
| 7 | Laporan | Penjualan, laba rugi, terlaris, export Excel | ⬜ Belum | – | – | – |

Total test saat ini: **33 lulus**. Importer dicoba dengan file asli client: produk 68 masuk / 1 ditolak (SKU kembar CB/001); customer 142 masuk / 6 digabung (no. HP sama: IQBAL–INDRO, JAHLIL×2, JAUHAR–JOHAN, NAFI–NAVI, UMAR×2, YAQIN) — semua sesuai temuan analisis awal.

## Catatan teknis

- **Struktur:** `lib/core/` (theme, format, owner/PIN, ui, table, xlsx), `lib/db/database.dart` (semua tabel), `lib/modules/<modul>/` (repo = aturan bisnis + test, controller GetX, page, dialogs), `lib/shell.dart`.
- **Alat:** preview UI ke PNG `flutter test tool/preview --update-goldens`; cek import file asli `IMPORT_FILE=… flutter test tool/check_import_test.dart`; rilis `sh tool/release_macos.sh` (panduan `docs/rilis-macos.md`).
- **Skema:** schemaVersion tetap 1 sampai terpasang di client; tabel baru otomatis dibuat di DB lama (`CREATE TABLE IF NOT EXISTS`). Perubahan **kolom** = hapus DB dev (`~/Library/Application Support/com.mpratama.garageErp/`) selama belum di client.
- **Aturan bisnis di repo, bukan di UI** (pelajaran sirviu): aturan owner dicek lewat `AppDb.requireOwner()` (sesi PIN) di repo — modal, batal, ubah invoice berbayar, pembelian, opname, import produk; pembelian hanya barang & rekening aktif.
- **Penjualan:** invoice & pemesanan satu tabel (`kind`); total/terbayar/status dihitung (tidak disimpan); DP tetap di pemesanan dan ikut dihitung di invoice turunannya; nomor otomatis melompati nomor yang sudah dipakai transaksi lama; stok boleh minus (dengan peringatan).
- **Log error:** `~/Library/Logs/Garage ERP/app.log`.
- Font Inter via `fonts:` pubspec; App Sandbox mati; bundle id `com.mpratama.garageErp` **tidak boleh berubah**; backup Google Drive ditunda.

**Git:** GitHub **private** [mpratama17/garage-erp-desktop](https://github.com/mpratama17/garage-erp-desktop), branch `main`. File client di `docs/` di-gitignore. Riwayat commit awal masih memuat 1 no. HP customer & 2 nama teknisi asli (sudah diganti di commit terbaru) — jangan jadikan repo ini publik; untuk portofolio buat snapshot bersih terpisah.

**Menunggu dari client:** perbaikan data produk (SKU kembar CB/001, SR800.3 & LED HVT EXPERT H4 dobel, produk yang belum ada: POWER+, switch, kabel, paket) + daftar jasa (harga, tarif insentif); saldo awal 4 rekening; versi macOS di Air M1 (minimal 12); logo versi latar terang.
