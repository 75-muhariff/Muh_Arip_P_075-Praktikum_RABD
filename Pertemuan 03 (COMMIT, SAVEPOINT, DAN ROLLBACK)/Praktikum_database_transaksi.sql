CREATE TABLE rekening (
    id INT PRIMARY KEY,
    nama VARCHAR(50) NOT NULL,
    saldo NUMERIC(12,2) NOT NULL CHECK (saldo >= 0)
);

INSERT INTO rekening (id, nama, saldo)
VALUES
    (1, 'Budi', 500000.00),
    (2, 'Siti', 250000.00);

select * from rekening;

-- START TRANSACTION dan COMMIT
START TRANSACTION;

-- 1. Mengurangi saldo Budi Rp75.000
UPDATE rekening
SET saldo = saldo - 75000
WHERE nama = 'Budi';

-- 2. Menambah saldo Siti Rp75.000
UPDATE rekening
SET saldo = saldo + 75000
WHERE nama = 'Siti';

-- 3. Memeriksa saldo sebelum COMMIT
SELECT id, nama, saldo
FROM rekening
ORDER BY id;

-- 4. Menyimpan perubahan
COMMIT;

-- 5. Melihat saldo setelah COMMIT
SELECT id, nama, saldo
FROM rekening
ORDER BY id;

-- Batalkan Perubahan / ROLLBAC
-- 1. Melihat saldo sebelum transaksi
SELECT id, nama, saldo
FROM rekening
WHERE nama = 'Budi';

-- 2. Memulai transaksi
START TRANSACTION;

-- 3. Mengurangi saldo Budi Rp20.000
UPDATE rekening
SET saldo = saldo - 20000
WHERE nama = 'Budi';

-- 4. Memeriksa saldo sementara
SELECT id, nama, saldo
FROM rekening
WHERE nama = 'Budi';

-- 5. Membatalkan perubahan
ROLLBACK;

-- 6. Memastikan saldo kembali seperti semula
SELECT id, nama, saldo
FROM rekening
WHERE nama = 'Budi';

-- Savepoint
-- 1. Melihat saldo sebelum transaksi
SELECT id, nama, saldo
FROM rekening
ORDER BY id;

-- 2. Memulai transaksi
START TRANSACTION;

-- 3. Mengurangi saldo Budi Rp30.000
UPDATE rekening
SET saldo = saldo - 30000
WHERE nama = 'Budi';

-- 4. Menambah saldo Siti Rp30.000
UPDATE rekening
SET saldo = saldo + 30000
WHERE nama = 'Siti';

-- 5. Membuat savepoint
SAVEPOINT sp_transfer;

-- 6. Mengurangi saldo Budi tambahan Rp5.000
UPDATE rekening
SET saldo = saldo - 5000
WHERE nama = 'Budi';

-- 7. Memeriksa perubahan sementara
SELECT id, nama, saldo
FROM rekening
ORDER BY id;

-- 8. Membatalkan perubahan setelah savepoint
ROLLBACK TO SAVEPOINT sp_transfer;

-- 9. Memeriksa saldo setelah rollback savepoint
SELECT id, nama, saldo
FROM rekening
ORDER BY id;

-- 10. Menyimpan transfer utama
COMMIT;

-- 11. Memeriksa saldo akhir
SELECT id, nama, saldo
FROM rekening
ORDER BY id;

-- RELEASE SAVEPOINT
-- 1. Melihat saldo sebelum transaksi
SELECT id, nama, saldo
FROM rekening
ORDER BY id;

-- 2. Memulai transaksi
START TRANSACTION;

-- 3. Mengurangi saldo Budi Rp10.000
UPDATE rekening
SET saldo = saldo - 10000
WHERE nama = 'Budi';

-- 4. Membuat savepoint
SAVEPOINT sp1;

-- 5. Menghapus penanda savepoint
RELEASE SAVEPOINT sp1;

-- 6. Menyimpan perubahan secara permanen
COMMIT;

-- 7. Memeriksa saldo setelah transaksi
SELECT id, nama, saldo
FROM rekening
ORDER BY id;

-- 1. Melihat saldo sebelum transaksi
SELECT id, nama, saldo
FROM rekening
ORDER BY id;

-- 2. Memulai transaksi
START TRANSACTION;

-- 3. Mengurangi saldo Budi Rp10.000
UPDATE rekening
SET saldo = saldo - 10000
WHERE nama = 'Budi';

-- 4. Membuat savepoint
SAVEPOINT sp1;

-- 5. Menghapus penanda savepoint
RELEASE SAVEPOINT sp1;

-- 6. Menyimpan perubahan secara permanen
COMMIT;

-- 7. Memeriksa saldo setelah transaksi
SELECT id, nama, saldo
FROM rekening
ORDER BY id;