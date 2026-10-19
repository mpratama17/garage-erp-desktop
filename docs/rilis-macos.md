# Rilis & Instalasi di Mac Client

Tanpa Apple Developer Program ($99/tahun). App di-*ad-hoc sign* otomatis oleh Flutter: berjalan normal, hanya macOS tidak mengenali "pengembangnya", jadi pembukaan pertama perlu satu langkah izin.

## 1. Build (di Mac developer)

```sh
sh tool/release_macos.sh
```

Hasil: `dist/Garage-ERP-<versi>.dmg` (±23 MB, **universal**: Mac Intel & Apple Silicon, minimal **macOS 12**). Naikkan `version:` di `pubspec.yaml` setiap rilis.

## 2. Instal di Mac client (sekali)

1. Salin `.dmg` ke Mac client — **paling mulus lewat flashdisk** (file dari flashdisk biasanya tidak ditandai "diunduh dari internet", jadi tidak diblokir). Lewat AirDrop/WhatsApp/download juga bisa, tapi pasti kena langkah 4.
2. Buka `.dmg` → seret **Garage ERP** ke folder **Applications**.
3. Buka Garage ERP dari Launchpad/Applications.
4. Bila muncul *"Apple could not verify 'Garage ERP'…"*: klik **Done** → buka **System Settings → Privacy & Security** → gulir ke bawah → **Open Anyway** → masukkan password Mac. Cukup sekali; setelah itu app terbuka normal.
   - Alternatif lewat Terminal: `xattr -dr com.apple.quarantine "/Applications/Garage ERP.app"`
5. Pertama kali dibuka: masuk **Pengaturan** → buat PIN owner → isi data bengkel & logo.

## 3. Update ke versi baru

Ulangi langkah 2 (seret & **Replace**). **Data tidak hilang** — data tersimpan terpisah dari app.

## 4. Lokasi data (penting)

| Apa | Lokasi |
|---|---|
| Database | `~/Library/Application Support/com.mpratama.garageErp/garage_erp.sqlite` |
| Backup otomatis | `~/Documents/Garage ERP Backup/` (harian + saat app ditutup, 60 terbaru) |

- **Jangan pernah mengubah bundle id** (`com.mpratama.garageErp` di `macos/Runner/Configs/AppInfo.xcconfig`) setelah app terpasang di client — lokasi data ikut bundle id, mengubahnya membuat app mulai dengan database kosong.
- **Pulihkan dari backup**: tutup app → salin file backup terbaru ke lokasi database dengan nama `garage_erp.sqlite` → buka app.
- Backup lokal ada di disk yang sama: tidak melindungi bila Mac rusak/hilang. Sementara Google Drive ditunda, salin folder backup ke flashdisk secara berkala.

## 5. Kapan perlu Apple Developer Program

Hanya bila app akan dibagikan lewat download ke banyak Mac / banyak client (notarisasi menghilangkan langkah 4). Untuk 1 Mac kasir yang diinstal langsung: tidak perlu.
