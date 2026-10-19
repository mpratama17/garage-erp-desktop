# star-garage-erp — Progress Snapshot

Last updated: 2026-10-19.

**Apa:** mini-ERP desktop offline (Flutter + SQLite, Windows/macOS) untuk Star Garage (bengkel modif lampu, member Yoong Motor Pasuruan), pengganti Kledo + Google Sheet. Modul: Gudang, Kontak, Penjualan (invoice/kasir, pemesanan+DP), Kas & Bank, Biaya, Insentif & Gaji, Laporan.

**Status:** 🟡 requirement selesai untuk mulai coding — PRD draft 2.1 (`docs/PRD.md`): 6 pertanyaan pemblokir terjawab, 7 klarifikasi lanjutan (§10) tidak menghambat coding. Repo GitHub: `workshop-erp-flutter` (package Dart sudah di-rename).

| Area | Status |
|---|---|
| PRD | Draft 2.0 — ditulis ulang dari 20 bulan pembukuan manual client |
| Kode | Draft awal (`lib/db.dart`, `money.dart`, `invoice_pdf.dart`, `test/core_test.dart`, 2 test lulus) — dibuat sebelum PRD v2, perlu disesuaikan (HPP per baris, payments per rekening, diskon Rp) |
| Skema | `docs/schema.dbml` / `schema.sql` — versi lama, dibuat ulang setelah §10 terjawab |
| Mockup UI | Artifact canvas 4 layar (Kasir, Riwayat, Produk, Laporan) — versi lama, pre-PRD v2 |
| Git | `git init` lokal, belum ada commit/remote. Nama repo GitHub nanti generik/teknikal |

**Menunggu dari client:** angka stok saat ini per barang; status stok vs penjualan Agu–Okt; periode omzet 3% sales; data produk lengkap + daftar jasa; saldo awal 3 rekening; logo versi terang.
