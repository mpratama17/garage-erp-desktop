-- Star Garage POS — skema SQLite (sumber: lib/db.dart, drift)
-- Uang = INTEGER rupiah. Boolean = INTEGER 0/1. Waktu = INTEGER unix epoch (detik).
-- Transaksi tidak pernah dihapus: nota batal di-void.

PRAGMA foreign_keys = ON;

CREATE TABLE products (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  sku         TEXT    NOT NULL DEFAULT '',
  name        TEXT    NOT NULL,
  type        INTEGER NOT NULL,                 -- 0=barang, 1=jasa, 2=paket
  sell_price  INTEGER NOT NULL,
  min_stock   INTEGER NOT NULL DEFAULT 0,       -- batas laporan stok menipis
  active      INTEGER NOT NULL DEFAULT 1 CHECK (active IN (0, 1))
);

-- Komposisi paket: jual 1 paket = stok tiap komponen berkurang qty.
CREATE TABLE bundle_items (
  bundle_id   INTEGER NOT NULL REFERENCES products (id),
  product_id  INTEGER NOT NULL REFERENCES products (id),
  qty         INTEGER NOT NULL,
  PRIMARY KEY (bundle_id, product_id)
);

-- Barang masuk. Baris & harga modal ada di stock_moves (ref_type='purchase').
CREATE TABLE purchases (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  supplier    TEXT    NOT NULL DEFAULT '',
  at          INTEGER NOT NULL DEFAULT (strftime('%s', 'now'))
);

-- Buku stok. Stok produk = SUM(qty). Hanya produk tipe barang.
-- ref_id menunjuk purchases.id atau invoices.id sesuai ref_type (tanpa FK).
CREATE TABLE stock_moves (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  product_id  INTEGER NOT NULL REFERENCES products (id),
  qty         INTEGER NOT NULL,                 -- + masuk, - keluar
  unit_cost   INTEGER NOT NULL DEFAULT 0,       -- harga modal (purchase)
  ref_type    TEXT    NOT NULL,                 -- purchase | sale | void | adjust
  ref_id      INTEGER,
  note        TEXT    NOT NULL DEFAULT '',      -- alasan adjust/opname
  at          INTEGER NOT NULL DEFAULT (strftime('%s', 'now'))
);

CREATE TABLE customers (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  name        TEXT    NOT NULL,
  phone       TEXT    NOT NULL UNIQUE           -- dinormalisasi 08xxxx, kunci dedupe
);

CREATE TABLE invoices (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  no          TEXT    NOT NULL UNIQUE,          -- INV/00247, lanjut dari nomor terakhir
  at          INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
  customer_id INTEGER REFERENCES customers (id),-- NULL = UMUM
  car         TEXT    NOT NULL DEFAULT '',      -- mobil per transaksi
  plate       TEXT    NOT NULL DEFAULT '',      -- plat, uppercase
  ppn         INTEGER NOT NULL DEFAULT 0 CHECK (ppn IN (0, 1)),  -- PPN 11% opsional
  pay_method  TEXT    NOT NULL,                 -- Cash | Transfer | QRIS
  subtotal    INTEGER NOT NULL,
  total       INTEGER NOT NULL,                 -- subtotal + PPN
  is_void     INTEGER NOT NULL DEFAULT 0 CHECK (is_void IN (0, 1)),
  void_reason TEXT    NOT NULL DEFAULT ''
);

CREATE TABLE invoice_lines (
  id           INTEGER PRIMARY KEY AUTOINCREMENT,
  invoice_id   INTEGER NOT NULL REFERENCES invoices (id),
  product_id   INTEGER NOT NULL REFERENCES products (id),
  name         TEXT    NOT NULL,                -- snapshot nama saat jual
  description  TEXT    NOT NULL DEFAULT '',
  qty          INTEGER NOT NULL,
  price        INTEGER NOT NULL,                -- snapshot harga jual
  discount_pct INTEGER NOT NULL DEFAULT 0,
  total        INTEGER NOT NULL,
  cost         INTEGER NOT NULL                 -- HPP per unit saat jual -> laba
);

-- Key-value: shop_name, shop_address, shop_phone, shop_email, logo_path,
-- invoice_note, pin_hash, backup_dir, last_invoice_no
CREATE TABLE settings (
  key    TEXT PRIMARY KEY,
  value  TEXT NOT NULL
);

-- Contoh query yang dipakai app:
-- Stok:      SELECT SUM(qty) FROM stock_moves WHERE product_id = ?;
-- HPP:       SELECT SUM(qty * unit_cost) * 1.0 / SUM(qty) FROM stock_moves
--            WHERE product_id = ? AND ref_type = 'purchase';
-- Laba nota: SELECT SUM(total - qty * cost) FROM invoice_lines WHERE invoice_id = ?;
