
CREATE DATABASE distribusi;
USE db_distribusi;

CREATE TABLE IF NOT EXISTS barang (
    kode_barang CHAR(5) PRIMARY KEY,
    nama_barang VARCHAR(100) NOT NULL,
    kategori VARCHAR(30) NOT NULL,
    harga DECIMAL(12,2) NOT NULL,
    stok INT NOT NULL
);

CREATE TABLE IF NOT EXISTS penjualan (
    no_transaksi CHAR(5) PRIMARY KEY,
    tanggal DATE NOT NULL,
    kode_barang CHAR(5) NOT NULL,
    jumlah INT NOT NULL,
    CONSTRAINT fk_penjualan_barang
        FOREIGN KEY (kode_barang) REFERENCES barang(kode_barang)
);

INSERT INTO barang (kode_barang, nama_barang, kategori, harga, stok) VALUES
('BR001', 'Kertas A4', 'ATK', 65000, 120),
('BR002', 'Tinta Printer', 'Elektronik', 85000, 45),
('BR003', 'Pulpen', 'ATK', 2500, 500),
('BR004', 'Toner Printer', 'Elektronik', 450000, 20),
('BR005', 'Map Arsip', 'ATK', 5000, 200),
('BR006', 'Kalkulator', 'Elektronik', 125000, 35),
('BR007', 'Buku Agenda', 'ATK', 18000, 80),
('BR008', 'Label Pengiriman', 'Kemasan', 12000, 150);

select * from barang;

INSERT INTO penjualan (no_transaksi, tanggal, kode_barang, jumlah) VALUES
('TR001', '2026-10-01', 'BR001', 10),
('TR002', '2026-10-02', 'BR002', 5),
('TR003', '2026-10-03', 'BR003', 50),
('TR004', '2026-10-04', 'BR005', 20),
('TR005', '2026-10-05', 'BR007', 15);

SELECT * FROM penjualan;

DROP PROCEDURE IF EXISTS sp_tampil_barang;
DROP PROCEDURE IF EXISTS sp_cari_kategori;
DROP PROCEDURE IF EXISTS sp_tambah_barang;
DROP PROCEDURE IF EXISTS sp_catat_penjualan;

DELIMITER $$

CREATE PROCEDURE sp_tampil_barang()
BEGIN
    SELECT kode_barang, nama_barang, kategori, harga, stok
    FROM barang;
END$$

CREATE PROCEDURE sp_cari_kategori(IN p_kategori VARCHAR(30))
BEGIN
    SELECT kode_barang, nama_barang, kategori, harga, stok
    FROM barang
    WHERE kategori = p_kategori;
END$$

DELIMITER $$
CREATE PROCEDURE sp_tambah_barang(
    IN p_kode_barang CHAR(5),
    IN p_nama_barang VARCHAR(100),
    IN p_kategori VARCHAR(30),
    IN p_harga DECIMAL(12,2),
    IN p_stok INT
)
BEGIN
    INSERT INTO barang (kode_barang, nama_barang, kategori, harga, stok)
    VALUES (p_kode_barang, p_nama_barang, p_kategori, p_harga, p_stok);

    SELECT * FROM barang WHERE kode_barang = p_kode_barang;
END$$


DELIMITER $$
CREATE PROCEDURE sp_catat_penjualan(
    IN p_no_transaksi CHAR(5),
    IN p_tanggal DATE,
    IN p_kode_barang CHAR(5),
    IN p_jumlah INT
)
BEGIN
    INSERT INTO penjualan (no_transaksi, tanggal, kode_barang, jumlah)
    VALUES (p_no_transaksi, p_tanggal, p_kode_barang, p_jumlah);

    SELECT * FROM penjualan WHERE no_transaksi = p_no_transaksi;
END$$

DELIMITER ;
CALL sp_tampil_barang();
CALL sp_cari_kategori('Elektronik');
CALL sp_tambah_barang('BR009', 'Label Barcode', 'Kemasan', 25000, 75);
SELECT * FROM barang;

CALL sp_catat_penjualan('TR006', '2026-10-06', 'BR009', 10);
SELECT * FROM penjualan;

SHOW PROCEDURE STATUS
WHERE Db = 'db_distribusi';
DROP PROCEDURE sp_tampil_barang;

DELIMITER $$
CREATE PROCEDURE sp_tampil_barang()
BEGIN
    SELECT kode_barang, nama_barang, kategori, harga, stok
    FROM barang
    WHERE stok < 50;
END$$

DELIMITER ;

CALL sp_tampil_barang();


DROP PROCEDURE sp_catat_penjualan;
DROP PROCEDURE IF EXISTS sp_tambah_barang;

SHOW PROCEDURE STATUS
WHERE Db = 'db_distribusi';

SELECT * FROM barang;
SELECT * FROM penjualan;
