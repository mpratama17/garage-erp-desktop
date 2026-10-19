# star-garage-erp (repo: workshop-erp-flutter) — Progress Snapshot

Last updated: 2026-10-19.

**Apa:** mini-ERP desktop **macOS** offline (Flutter + SQLite/drift + GetX) untuk Star Garage (bengkel modif lampu, member Yoong Motor Pasuruan), pengganti Kledo + Google Sheet. 7 modul + Pengaturan (lihat `docs/PRD.md` v2.3).

**Metode:** vertical slice per modul (skema → logika + test → controller GetX → UI → analyze/test/run → review → commit).

| Modul | Status |
|---|---|
| 0. Fondasi (tema, shell/sidebar, Pengaturan, PIN owner, 4 rekening seed, nomor nota, backup lokal, rilis .dmg) | ✅ selesai — 5 test, analyze bersih, build rilis universal 23 MB diuji |
| 1. Gudang | ⏭️ berikutnya |
| 2. Kontak · 3. Penjualan · 4. Kas & Bank · 5. Biaya · 6. Gaji · 7. Laporan | belum |

**Struktur:** `lib/core/` (theme, format, owner/PIN, ui), `lib/db/database.dart` (drift, schemaVersion 1 sampai terpasang di client), `lib/modules/<modul>/`, `lib/shell.dart`. Preview UI ke PNG: `flutter test tool/preview --update-goldens`. Rilis: `sh tool/release_macos.sh` (panduan instal: `docs/rilis-macos.md`).

**Keputusan teknis penting:** font Inter via `fonts:` pubspec (bukan `google_fonts` — v9 tidak kompatibel Flutter 3.47); macOS App Sandbox dimatikan (akses folder backup/bukti); bundle id `com.mpratama.workshopErp` **tidak boleh berubah** setelah instal; backup ke Google Drive ditunda (lokal dulu).

**Git:** lokal, belum ada remote. File client di `docs/` di-gitignore. Push ke GitHub menunggu konfirmasi.

**Menunggu dari client:** data produk lengkap + daftar jasa (harga, tarif insentif); saldo awal 4 rekening; versi macOS & tipe Mac kasir (minimal macOS 12); logo versi latar terang.
