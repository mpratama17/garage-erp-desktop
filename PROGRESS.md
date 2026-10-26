# star-garage-erp (repo: garage-erp-desktop) — Progress Snapshot

Last updated: 2026-10-26 (build **1.2.0+5** di `dist/`: logo nota/slip kini dipotong otomatis dari padding polos — sebelumnya `logo-star-baru.png` 500×500 tercetak kecil di nota client; .dmg diunggah manual ke Drive).

**Apa:** mini-ERP desktop **macOS** offline (Flutter + SQLite/drift + GetX) untuk Star Garage (bengkel modif lampu, member Yoong Motor Pasuruan), pengganti Kledo + Google Sheet. Dashboard + 7 modul + Pengaturan (`docs/PRD.md` v2.3). Kasir: MacBook Air M1. Ringkasan untuk GitHub: `README.md`.

**Metode:** vertical slice per modul — skema → logika + test → controller GetX → UI → analyze/test/preview/run → code review → perbaikan → commit.

## Tracking modul

| # | Modul | Isi | Status | Test | Review | Commit |
|---|---|---|---|---|---|---|
| 0 | Fondasi | Tema, sidebar, Pengaturan, PIN owner, 4 rekening, nomor nota, backup lokal, rilis .dmg | ✅ Selesai | 6 | 10 temuan → diperbaiki | `bd24dd9` |
| 1 | Gudang | Barang/Jasa/Ready Stock, CRUD produk, harga beli khusus owner, stok opname, pembelian stok (→ kas), import/export Excel format Kledo (stok kosong = 1), riwayat stok | ✅ Selesai | 9 | 10 temuan → diperbaiki | `5041dcc` |
| 2 | Kontak | CRUD customer (nama, HP unik, mobil, plat, catatan), import Google Sheet client (gabung HP sama + laporan), export, cari via HP/plat. *Riwayat belanja, repeat order & top pelanggan menyusul di Modul 3 (butuh data invoice)* | ✅ Selesai | 5 | 10 temuan → 9 diperbaiki | `c060db3` |
| 3 | Penjualan | Invoice/kasir (bayar langsung), pemesanan + DP → invoice, pembayaran bertahap per rekening + bukti, tag Lunas/Dibayar Sebagian/Belum Lunas/lewat tempo/Batal, batal (stok & uang balik), PDF format Kledo, kirim WA + link review, input transaksi lama (tanpa gerak stok), modal per baris khusus owner, teknisi 0–2 per baris; + riwayat & statistik customer di Kontak | ✅ Selesai | 13 | 10 temuan → diperbaiki | `a8491d8` |
| 4 | Kas & Bank | Saldo per rekening (saldo awal + semua transaksi), mutasi per bulan + saldo berjalan, transfer antar rekening (tidak dihitung arus kas), modal masuk/pemasukan lain + bukti, hapus transaksi manual (owner), kelola rekening (owner), arus kas harian/bulanan/kuartal/tahunan | ✅ Selesai | 5 | 10 temuan → 8 diperbaiki | `3012c0a` |
| 5 | Biaya | Catat biaya (siapa saja) + bukti, ubah/hapus (owner), filter operasional/pribadi per bulan + total, kategori kelola owner (18 awal dari sheet client; tanda pribadi, nonaktif) | ✅ Selesai | 4 | 10 temuan → 8 diperbaiki | `de361cf` |
| 6 | Gaji | Khusus owner (PIN). Karyawan (teknisi/sales, gaji pokok, makan, aktif), slip per periode 27–26: pokok + makan + insentif per pekerjaan (berdua = ½) + tunjangan kerja sales 3% omzet (bisa dikoreksi) + lembur + bonus − potongan, rincian insentif per invoice/mobil, bayar dari rekening + bukti (slip dibeku), batalkan pembayaran | ✅ Selesai | 7 | 8 temuan → 6 diperbaiki | `fd854d9` |
| 7 | Laporan | Khusus owner (dicek di repo). Bulanan (per hari) / tahunan (per bulan): laba rugi (pendapatan − HPP − biaya − gaji = laba bersih usaha − pribadi = sisa, rincian biaya per kategori, peringatan modal kosong), penjualan (invoice, bruto, diskon, omzet, per kategori), terlaris, arus kas; export Excel tiap tab. + Export Excel gaji per periode (slip + rincian insentif) | ✅ Selesai | 3 | 10 temuan → 9 diperbaiki | `99b7120` |

## Upgrade UI/UX (permintaan 19 Okt, setelah R1)

| Fase | Isi | Commit |
|---|---|---|
| Form | Label di atas field, field abu tanpa garis (`Labeled`), kartu berbayangan lembut | `0708049` |
| Pengaturan | Folder simpan nota & export, jadwal backup (harian+tutup / harian / mingguan / nonaktif), 2 kolom, logo nota & ikon sidebar terpisah | `cbf9028` |
| Shell | Sidebar aktif solid, topbar + **cari global** (invoice/customer/produk → buka record), logo tanpa latar | `a69d3d4` |
| Dashboard | KPI, grafik omzet 12 bulan (fl_chart), belum lunas, terlaris, stok menipis; laba & saldo khusus owner | `8120669` |
| KPI & teks | Kartu KPI di Penjualan/Gudang/Biaya/Gaji; label & subjudul dipangkas | `9076e8b` |
| Tombol & feedback | Hierarki tombol (1 utama/layar, destruktif terpisah di kiri), konfirmasi berlabel kata kerja, notifikasi Berhasil/Periksa lagi/Gagal di overlay, dialog sukses invoice (PDF/WA) | `00bc081` |
| Kunci saldo | Saldo Kas & Bank khusus owner (repo menolak tanpa PIN); perbaikan urutan buka PIN (bug: PIN benar tidak membuka modul owner) | `c747716` |
| Sidebar | Layout rail ikon + panel menu (paket `sidebarx` 0.17.2, pub points 160 / 783 likes); panel bisa diciutkan; status backup di panel; notifikasi belum dibuat (sengaja) | (commit ini) |
| Sidebar v2 | Pengelompokan menu (Transaksi/Keuangan/Analisis), gaya pil lembut mengikuti referensi; paket `sidebarx` dilepas (tidak mendukung section header) — diganti widget sidebar sendiri, lebih ringkas | `724c7f5`+ |
| Palet | Ikuti referensi: biru royal `#2F5BEA` (menu aktif, tombol utama, link, grafik), navy/slate, latar abu kebiruan, KPI pastel penuh (biru/ungu/kuning/mint); oranye hanya di logo; merah hanya bahaya | (commit ini) |

Total test saat ini: **87 lulus** (per R3). **Semua modul R1 + upgrade UI selesai** — berikutnya: uji manual end-to-end di Mac, backlog B3, rilis .dmg pertama ke client. Importer dicoba dengan file asli client: produk 68 masuk / 1 ditolak (SKU kembar CB/001); customer 142 masuk / 6 digabung (no. HP sama) — semua sesuai temuan analisis awal.

## Backlog (diminta, belum dikerjakan)

| # | Fitur | Asal | Catatan |
|---|---|---|---|
| B1 | ~~Pilih lokasi simpan file nota/invoice~~ ✅ | Permintaan 19 Okt | Selesai: Pengaturan → Folder file (nota PDF di `/Nota`, export Excel mulai di `/Export`) + jadwal backup otomatis (harian+tutup / harian / mingguan / nonaktif). |
| B2 | Backup & bukti pembayaran ke Google Drive | Brief client, ditunda client | Sekarang lokal (`Garage ERP Backup/`, `Garage ERP Bukti/`). |
| B3 | Error import Gudang saat testing manual | Testing 19 Okt | Belum tereproduksi (import ulang di salinan DB berhasil). Tunggu isi `~/Library/Logs/Garage ERP/app.log`. |

## Masukan client R2 (20 Okt) — belum dikerjakan

Jenis: 🐞 bug/salah paham · ✨ fitur · ❓ pertanyaan (cukup dijawab / mungkin ubah UI).

| # | Modul | Masukan | Jenis | Catatan triase |
|---|---|---|---|---|
| C1 | Penjualan | Kirim WA: PDF tidak terlampir | 🐞 | ✅ Client setuju alur seret PDF dari Finder; pesan WA sekarang juga memuat rincian barang/jasa + diskon/PPN + total (`{rincian}`). |
| C2 | Penjualan | Template pesan WA customer | ✨ | ✅ 3 template (lunas / belum lunas / pemesanan-DP) di Pengaturan → Pesan WhatsApp, placeholder `{nama} {toko} {no} {rincian} {total} {dibayar} {sisa} {review}`; kosong = bawaan. |
| C3 | Penjualan | Diskon & pajak di bawah total invoice; sembunyikan bila 0 | ✨ | ✅ Diskon invoice Rp atau %, PPN dicentang per invoice (tarif di Pengaturan, default 11%). Disimpan di `invoices` (skema v2 + migrasi). PPN dari subtotal setelah diskon; **omzet = tanpa PPN** (Dashboard, Laporan, komisi), total tagihan = dengan PPN; Laporan Penjualan punya kolom PPN. Layar & PDF: baris Subtotal/Diskon/PPN hanya muncul bila ada. |
| C4 | Penjualan | "Modal/unit" di rincian invoice untuk apa? | ❓ | ✅ Modal diisi otomatis di repo dari harga beli terakhir produk (Gudang); baris "Modal/unit" & isi manual dihapus. Ubah dokumen = modal lama tetap. Migrasi v2 mengisi modal kosong di baris lama. |
| C5 | Penjualan→Kontak | Mobil & plat customer baru dari Penjualan tidak masuk Kontak | 🐞 | ✅ Jawaban client: bisa ganti mobil/plat. Sekarang invoice **baru** selalu menimpa mobil/plat customer ke yang terbaru (bukan cuma isi-bila-kosong); mengubah invoice lama tidak ikut mengubah. Riwayat mobil/plat lama tetap terlihat sebagai label di atas Riwayat belanja (diambil dari invoice, tanpa tabel baru). |
| C6 | Gaji | Insentif/tunjangan kerja teknisi masih 0 | ❓/🐞 | Jawaban client: tarif akan diisi manual, barang juga bisa dapat insentif, insentif tergantung barang yang dipasang — ini sudah cara kerja sistem sekarang (tarif per produk, disalin ke tiap baris invoice). ✅ Kolom Insentif sekarang juga tampil di tab Barang & Ready Stock (sebelumnya cuma Jasa). **Perlu diketahui:** insentif per baris dibekukan saat invoice dibuat — kalau client mengisi tarif baru nanti, invoice yang SUDAH dibuat sebelum tarif diisi tetap bernilai insentif 0 (tidak otomatis ikut naik). Belum dibuat aksi "terapkan ulang tarif" karena belum diminta. |
| C7 | Biaya | Cari di pilihan kategori | ✨ | ✅ Kategori = `DropdownMenu` ketik-untuk-cari. |
| C8 | Gudang | Tombol "Template" untuk apa? | ❓ | ✅ Label jadi "Template import" (Gudang & Kontak). |
| C9 | Gudang | Pembelian stok: nota pembelian + pembayaran | ✨ | ✅ No. nota + foto nota (Lampirkan bukti) di dialog pembelian; nama supplier sudah ada sejak R2 awal. Klien: pembelian selalu lunas penuh, kadang beberapa hari kemudian → checkbox "Sudah dibayar sekarang" (mati = belum dibayar, stok & harga beli tetap jalan, tidak ada kas keluar). Tab Pembelian: kolom & pill status Lunas/Belum bayar, tombol "Lunasi sekarang" (owner) membayar penuh dari rekening yang sudah dipilih saat pembelian dicatat. |
| C10 | Gudang | Menu riwayat pembelian stok | ✨ | ✅ Tab **Pembelian** di Gudang (khusus owner, dicek di repo): daftar + rincian barang/harga beli. Nota & status bayar = C9 (tunggu client). |
| C11 | Gudang | Riwayat stok: klik baris pembelian → riwayat pembelian itu | ✨ | ✅ Baris pembelian di riwayat stok → buka tab Pembelian (minta PIN). |
| C12 | Gudang | Riwayat stok: baris penjualan tampilkan customer, invoice, rincian | ✨ | ✅ Baris penjualan/batal menampilkan no. invoice · customer · plat; klik → buka invoice di Penjualan (`openDoc` di `shell.dart`, dipakai bersama cari global). |
| C13 | Kontak | Riwayat belanja: klik → detail invoice | ✨ | ✅ Klik riwayat belanja → buka invoice di Penjualan. |
| C14 | Dashboard | Grafik penjualan & pembelian harian/bulanan/tahunan | ✨ | ✅ Jawaban client: bagan (bar chart) pemasukan vs pengeluaran, dengan rentang tanggal. Jadi satu "Pemasukan & pengeluaran" di Dashboard (pakai `cashFlow` yang sudah ada), mencakup penjualan (pembayaran) & pembelian stok sekaligus. |
| C15 | Dashboard | Grafik kas & bank harian/bulanan/tahunan | ✨ | ✅ Sama dengan C14 — kas & bank = arus kas, bukan saldo (saldo tetap khusus owner, lihat catatan di C16). Grafik ini terlihat untuk semua (sesuai jawaban Q1: kasir boleh lihat grafik). |
| C16 | Dashboard | Grafik omzet harian/bulanan/tahunan | ✨ | ✅ Grafik Omzet di Dashboard sekarang punya pilihan periode (Harian/Bulanan/Tahunan) + tombol rentang tanggal bebas (date range picker bawaan Flutter). Default Bulanan 12 bulan (sama seperti sebelumnya). **Catatan:** saldo rekening TIDAK dibuat grafik — tetap khusus owner (keputusan `c747716` sebelumnya); yang grafik di sini arus kas (masuk/keluar), bukan saldo. |
| C17 | Gaji | Download slip gaji per karyawan per periode (PDF) | ✨ | ✅ Jawaban client: PDF A4, hanya kolom ttd Finance Star Garage (tanpa kolom tanda terima karyawan), tidak perlu dikirim lewat WA. Tombol "Unduh slip" di dialog slip gaji (`lib/modules/gaji/slip_pdf.dart`, gaya sama dengan nota invoice) — simpan ke folder export/Slip. |
| C18 | Semua | Mode terkunci (bukan owner) = hanya lihat; kasir hanya boleh tambah penjualan & customer | ✨ | ✅ Terkunci = hanya lihat. Kasir boleh: invoice/pemesanan + DP, pembayaran, buat invoice dari pemesanan, tambah & ubah customer, catat biaya baru, lihat grafik. Selain itu `requireOwner()` di repo (produk, ubah dokumen apa pun, hapus customer, import, transfer, uang masuk, rekening, biaya ubah/hapus, kategori, karyawan, gaji, pengaturan lewat `PengaturanController._set`). Tombol terkait minta PIN dulu. Test: `test/akses_test.dart`. |

## Masukan client R3 (22 Okt) — ✅ dikerjakan & di-commit (belum di-push/di-build)

23 nomor asli (nomor 4 dobel = 24 butir) → 18 pekerjaan (C1–C18), semua ✅. #4a: owner memutuskan tetap lewat tombol "Buat invoice" (tidak otomatis saat lunas). analyze bersih, 88 test lulus. Jawaban client: pemesanan lunas → jadi invoice di Tagihan; biaya berulang dicatat manual per klik; jurnal otomatis cukup (tanpa input jurnal manual). Skema DB naik ke **v3** (additive; migrasi dites di `test/r3_test.dart`).

| # | Masukan (butir asli) | Hasil |
|---|---|---|
| C1 | Split View MacBook (#1) | ✅ `minimumSize` 640×560 (dulu 1280×720); sidebar otomatis ciut <1000 px; panel kanan menggantikan daftar di jendela sempit (`MasterDetail`); toolbar tabel/header membungkus; halaman Kas & Laporan bisa digulir. Dijaga `test/layout_test.dart` (semua halaman & sub-halaman tanpa overflow di 720 & 1440 px) |
| C2 | Sidebar: garis pemisah, urutan baru, ikon berwarna, dropdown (#2,#3,#4b,#7,#15) | ✅ Beranda │ Penjualan▸(Tagihan, Pemesanan), Pembelian▸(Tagihan Pembelian) │ Gudang, Biaya │ Kontak, Kas & Bank, Gaji │ Laporan; ikon warna per menu |
| C3 | Popup tanggal kecil 2 bulan (#8) | ✅ `lib/core/range_picker.dart` (`pickRange`/`RangeButton`), dipakai Dashboard, Penjualan, Pembelian, Biaya, Kas & Bank; daftar pilihan cepat di kiri ala Kledo (Kemarin … 2 tahun terakhir; jendela sempit = dibungkus di atas kalender) |
| C4 | Dashboard rapi, warna grafik soft (#9) | ✅ 2 baris × 3 KPI, grafik pastel, tata letak responsif |
| C5 | Pengaturan tidak panjang sebelah (#13) | ✅ 3 tab (Bengkel & nota / Pesan WhatsApp / File, backup & PIN), dua kolom seimbang |
| C6 | Tabel di slip gaji PDF (#10) | ✅ tabel identitas + tabel komponen + baris total |
| C7 | Stempel LUNAS di invoice (#11) | ✅ pojok kanan bawah blok judul "Invoice", hanya bila lunas |
| C8 | Template import digabung ke tombol Import (#16,#19) | ✅ `ImportButton` (menu: Unduh template / Pilih file) di Gudang & Kontak |
| C9 | Info Gudang geser ke kanan (#17) | ✅ 7 kartu: stok tersedia/hampir habis/habis, total stok, HPP, penjualan, pembelian (HPP & pembelian khusus owner) |
| C10 | Biaya & Kas: rentang tanggal + filter kolom + export (#6,#12) | ✅ rentang tanggal; Kas punya Export mutasi (owner). Filter teks per kolom **dihapus 23 Okt** (owner: "tidak sesuai"), diganti **urut naik/turun per kolom di 16 tabel + tombol Reset** (`Col.sort`, `AppTable.pinned`; Reset = kotak cari + urutan tabel itu saja; dites `test/table_test.dart`) |
| C11 | Kontak: Customer/Vendor/Pegawai (#18,#20) | ✅ tab Customer/Vendor/Pegawai; tabel `vendors` baru; form pembelian: vendor dicari/diketik (vendor baru otomatis dibuat); Pegawai memakai tabel karyawan (+ no. HP & catatan) |
| C12 | Tagihan vs Pemesanan (#3,#4,#14) | ✅ Penjualan dipecah 2 halaman; pemesanan yang sudah dijadikan invoice pindah ke Tagihan; tombol "+ Tagihan" di Tagihan, "+ Pemesanan" di Pemesanan |
| C13 | Menu Pembelian ▸ Tagihan Pembelian (#4b) | ✅ halaman Pembelian (pindah dari tab Gudang), Tagihan Pembelian = yang belum dibayar |
| C14 | Riwayat pembelian: tgl input + tgl lunas bila beda hari (#5) | ✅ kolom Tgl beli / Tgl lunas |
| C15 | Biaya berulang (#22) | ✅ tombol "Biaya berulang" di Biaya: templat (mis. Uang transport Rp20.000 per pegawai), Catat = pilih tanggal + centang pegawai yang masuk → satu biaya per pegawai |
| C16 | Laporan keuangan, penjualan, pembelian (#21) | ✅ Neraca, Arus kas, Proyeksi arus kas, Laba rugi, Perubahan modal, Ringkasan eksekutif; Detail penjualan & Detail pembelian; semua bisa di-export |
| C17 | Laporan akuntansi (#21) | ✅ Ringkasan bank, Buku besar, Buku besar pembantu (piutang/utang/persediaan), Jurnal, Trial balance — dari **jurnal turunan** (`akuntansi_repo.dart`: dibangun ulang dari invoice/kas/pembelian/stok, tanpa tabel jurnal). Dites seimbang & cocok dengan Kas & Bank dan Laba Rugi (`test/akuntansi_test.dart`) |

| C18 | Tambah barang baru ke Gudang dari kolom produk/jasa di Tagihan/Pemesanan (#23) | ✅ tombol "Barang/jasa baru" di form (minta PIN owner): nama, harga jual, stok awal ≥ 1 untuk barang; harga beli kosong = modal 0 (lengkapi di Gudang). **Aturan stok baru (keputusan owner):** barang stok 0/minus tidak muncul di form invoice dan ditolak repo (`saveDoc`, termasuk Pemesanan → invoice); pemesanan, transaksi lama, dan barang yang sudah ada di invoice yang diubah tidak dicek. Qty melebihi stok yang masih > 0 tetap boleh dengan peringatan |

**Catatan keputusan:** (1) Pemesanan → invoice lewat tombol "Buat invoice" (bukan otomatis saat lunas) — dikonfirmasi owner 23 Okt. (2) Proyeksi arus kas = rata-rata 3 bulan terakhir (metode sederhana; definisi client belum ada). (3) Persediaan di neraca dinilai dari pembelian/modal invoice; stok awal & opname dinilai harga beli saat ini — perlu data produk bersih & saldo awal rekening dari client agar neraca akurat. (4) Laba berjalan di neraca termasuk "Pemasukan lain"; menu Laba rugi lama tetap hanya penjualan.

**Close-out 23 Okt (code-review + simplify):** diperbaiki — semua `watch().first` diganti query sekali jalan (pola `xxxQuery().get()`, termasuk sisa R1/R2 di invoice PDF, editor dokumen, gaji, biaya); pencarian global → customer kembali ke tab Customer; (filter kolom `AppTable` sempat diperbaiki di sini, lalu dihapus seluruhnya atas permintaan owner); HPP transaksi lama melawan Modal, bukan Persediaan (neraca tidak minus); nama supplier pembelian = nama baku vendor; biaya berulang menolak pegawai nonaktif/tak dikenal di repo; total Gudang tidak tertimpa hasil query lama; Detail penjualan/pembelian & export mutasi Kas dicek owner di repo/controller; helper rentang tanggal (`thisMonth`, `endExclusive`, `covers`) menggantikan 8 salinan; `MonthNav` & `LapTab` dihapus; Laporan hanya memuat ulang jenis laporan yang tampil; daftar akun buku besar tanpa membangun jurnal.
**Sengaja dilewati (catatan, bukan bug mendesak):** dua definisi laba (Laba rugi lama = penjualan saja vs jurnal termasuk pemasukan lain — keputusan (4) di atas); `purchases.supplier` masih salinan yang disinkron saat vendor diganti nama; belum ada unique index nama vendor; layout responsif masih breakpoint per halaman; `Nav.pembelianTagihan` di sidebar; jurnal dibangun ulang tiap ganti parameter laporan (data kecil, belum terasa).
**Vendor:** tambah/ubah/hapus khusus owner (keputusan owner 23 Okt; `requireOwner` di `saveVendor`, dites di `akses_test` & `r3_test`).

**Sebelum build 1.2.0:** uji migrasi v2→v3 terhadap salinan DB asli client (seperti R2) — salinan tidak ada di `docs/`, minta lagi; cek Split View langsung di Mac (sejauh ini hanya `test/layout_test.dart` + preview). `flutter build macos --release` sudah lolos kompilasi.

**Masih menunggu client:** saldo awal 4 rekening, data produk bersih, definisi proyeksi arus kas, hasil testing build 1.1.0+2. Owner testing sendiri `dist/Garage-ERP-1.2.0+3.dmg` dulu sebelum dikirim.

## Catatan teknis

- **Struktur:** `lib/core/` (theme, format, owner/PIN, ui, table, xlsx), `lib/db/database.dart` (semua tabel), `lib/modules/<modul>/` (repo = aturan bisnis + test, controller GetX, page, dialogs), `lib/shell.dart`.
- **Alat:** preview UI ke PNG `flutter test tool/preview --update-goldens`; cek import file asli `IMPORT_FILE=… flutter test tool/check_import_test.dart`; rilis `sh tool/release_macos.sh` (panduan `docs/rilis-macos.md`).
- **Skema:** schemaVersion tetap 1 sampai terpasang di client; tabel baru otomatis dibuat di DB lama (`CREATE TABLE IF NOT EXISTS`). Perubahan **kolom** = hapus DB dev (`~/Library/Application Support/com.mpratama.garageErp/`) selama belum di client.
- **Aturan bisnis di repo, bukan di UI** (pelajaran sirviu): aturan owner dicek lewat `AppDb.requireOwner()` (sesi PIN) di repo. Sejak R2 (C18) kebalikannya: tanpa PIN hanya boleh tambah penjualan/pemesanan/pembayaran, customer (tambah/ubah), biaya baru — daftar lengkap di `test/akses_test.dart`. Pembelian hanya barang & rekening aktif. `setSetting` sengaja tidak dikunci (nomor nota kasir, catatan backup).
- **Penjualan:** invoice & pemesanan satu tabel (`kind`); total/terbayar/status dihitung (tidak disimpan); DP tetap di pemesanan dan ikut dihitung di invoice turunannya; nomor otomatis melompati nomor yang sudah dipakai transaksi lama; invoice butuh stok > 0 per barang (sejak 23 Okt), qty melebihi stok tetap boleh (stok bisa minus, dengan peringatan).
- **Kas:** saldo tidak disimpan (saldo awal + SUM kas); transfer = 2 baris saling menunjuk `refId`, dihapus berpasangan; transaksi dari modul lain hanya diubah di modulnya. Rekening aktif dicek di satu tempat (`AppDb.requireActiveAccount`).
- **Biaya:** tidak ada tabel biaya — biaya = baris `cash_entries` jenis `expense`, `refId` = kategori. Pribadi/operasional mengikuti kategori (ubah tanda kategori = ikut mengubah biaya lama). Kategori awal di-seed sekali (batch) saat tabel kosong.
- **Gaji:** slip = tabel `payslips` (unik per karyawan+awal periode); dibayar = ada `cash_entries` kind `salary` refId=slip. Komponen otomatis null selama belum dibayar (ikut data terbaru), dibekukan saat bayar. Akhir periode selalu diturunkan dari `payroll_start_day` di repo; bayar ditolak bila bertumpuk dengan slip lain yang sudah dibayar. Insentif hanya dari invoice tidak batal (pemesanan tidak dihitung, transaksi lama dihitung). **Laporan (Modul 7): gaji = kind `salary` → masuk biaya operasional.** Komisi: tiap karyawan peran Sales dapat % × omzet toko. **Client: tidak ada karyawan sales (2 teknisi saja); owner merangkap sales/admin** → tidak ada komisi kecuali owner ditambahkan sebagai karyawan Sales.
- **Laporan:** pendapatan & HPP menurut tanggal invoice (pemesanan/DP tidak dihitung); biaya & gaji menurut tanggal uang keluar; pembelian stok bukan biaya. Terlaris dikelompokkan per produk (nama produk saat ini). Grafik belum dibuat (tabel + Excel cukup untuk PRD).
- **Owner/PIN:** `ensure()` membuka `db.ownerUnlocked` DULU baru `isOwner` (listener Dashboard/Kas langsung memuat data owner). Saldo, laba, nilai stok, gaji hanya dimuat saat owner terbuka.
- **Feedback:** `runAction` → sukses/`warn` (ArgumentError = aturan bisnis)/gagal (error sistem → log); `confirmAction` untuk aksi penting; controller teks dialog tidak di-dispose manual (dialog masih beranimasi).
- **UI bersama** (`core/ui.dart`): `runAction`, `dateField`, `proofRow`, `accountField`, `OwnerGate`; `core/range_picker.dart`: `RangeButton`, `thisMonth()`, `range.endExclusive`/`covers()` (+ `dayAfter` di `format.dart`); `core/xlsx.dart`: `buildXlsxSheets`, `saveXlsx`.
- **Format:** lebar 120 dipatok di `analysis_options.yaml`; jangan `dart format` file `*.g.dart` (build_runner tetap 80).
- **Log error:** `~/Library/Logs/Garage ERP/app.log`.
- Font Inter via `fonts:` pubspec; App Sandbox mati; bundle id `com.mpratama.garageErp` **tidak boleh berubah**; backup Google Drive ditunda.

**Git:** GitHub **private** [mpratama17/garage-erp-desktop](https://github.com/mpratama17/garage-erp-desktop), branch `main`. File client di `docs/` di-gitignore. Riwayat commit awal masih memuat 1 no. HP customer & 2 nama teknisi asli (sudah diganti di commit terbaru) — jangan jadikan repo ini publik; untuk portofolio buat snapshot bersih terpisah.

**Menunggu dari client:** perbaikan data produk (SKU kembar CB/001, SR800.3 & LED HVT EXPERT H4 dobel, produk yang belum ada: POWER+, switch, kabel, paket) + daftar jasa (harga, tarif insentif); saldo awal 4 rekening; versi macOS di Air M1 (minimal 12). Logo latar terang sudah ada (`docs/logo-star-baru.png`, dipasang lewat Pengaturan).
