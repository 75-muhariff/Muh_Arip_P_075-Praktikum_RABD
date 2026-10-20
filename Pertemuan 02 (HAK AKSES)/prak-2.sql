-- =====================================================================
-- PRAKTIKUM 2 : MEMBUAT DAN MENGATUR HAK AKSES
-- Database    : Praktikum_PrakR&ADB_Pertemuan 02
-- Nama        : Muhammad Arip purnama
-- NIM         : 2507075
-- =====================================================================

CREATE DATABASE "prak-2";
SELECT current_database();
SELECT version();

CREATE TABLE IF NOT EXISTS mahasiswa (
    nim         VARCHAR(10) PRIMARY KEY,
    nama        VARCHAR(100) NOT NULL,
    jurusan     VARCHAR(50)  NOT NULL,
    angkatan    INT          NOT NULL,
    ipk         DECIMAL(3,2) DEFAULT 0.00,
    no_telepon  VARCHAR(15)
);

CREATE TABLE IF NOT EXISTS mata_kuliah (
    kode_mk    VARCHAR(10) PRIMARY KEY,
    nama_mk    VARCHAR(100) NOT NULL,
    sks        INT NOT NULL CHECK (sks > 0),
    nip_dosen  VARCHAR(18) NOT NULL
);

CREATE TABLE IF NOT EXISTS nilai_akademik (
    id_nilai     SERIAL PRIMARY KEY,
    nim          VARCHAR(10) REFERENCES mahasiswa(nim),
    kode_mk      VARCHAR(10) REFERENCES mata_kuliah(kode_mk),
    nilai_tugas  NUMERIC(5,2) CHECK (nilai_tugas BETWEEN 0 AND 100),
    nilai_uts    NUMERIC(5,2) CHECK (nilai_uts   BETWEEN 0 AND 100),
    nilai_uas    NUMERIC(5,2) CHECK (nilai_uas   BETWEEN 0 AND 100),
    nilai_akhir  NUMERIC(5,2)
);

INSERT INTO mahasiswa (nim, nama, jurusan, angkatan, ipk, no_telepon)
SELECT * FROM (VALUES
    ('2024001', 'Budi Santoso', 'Informatika', 2024, 3.75, '08123456789'),
    ('2024002', 'Siti Aminah',  'Informatika', 2024, 3.85, '08129876543')
) v(nim, nama, jurusan, angkatan, ipk, no_telepon)
WHERE NOT EXISTS (SELECT 1 FROM mahasiswa);

INSERT INTO mata_kuliah (kode_mk, nama_mk, sks, nip_dosen)
SELECT * FROM (VALUES
    ('IF101', 'Basis Data Lanjut', 3, '198501012010121001'),
    ('IF102', 'Struktur Data',     3, '198803152015042002')
) v(kode_mk, nama_mk, sks, nip_dosen)
WHERE NOT EXISTS (SELECT 1 FROM mata_kuliah);

INSERT INTO nilai_akademik (nim, kode_mk, nilai_tugas, nilai_uts, nilai_uas, nilai_akhir)
SELECT * FROM (VALUES
    ('2024001', 'IF101', 85.00, 80.00, 90.00, 85.50),
    ('2024002', 'IF101', 75.00, 70.00, 82.00, 76.10)
) v(nim, kode_mk, nilai_tugas, nilai_uts, nilai_uas, nilai_akhir)
WHERE NOT EXISTS (SELECT 1 FROM nilai_akademik);

-- role_mahasiswa (dibuat hanya jika belum ada)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'role_mahasiswa') THEN
        CREATE ROLE role_mahasiswa;
    END IF;
END $$;

GRANT SELECT ON mahasiswa, mata_kuliah, nilai_akademik TO role_mahasiswa;

-- View bantu pengganti SHOW GRANTS (hak tabel & kolom beserta pemberinya)
CREATE OR REPLACE VIEW v_hak_akses AS
SELECT c.relname::text AS tabel,
       ''::text AS kolom,
       a.grantor::regrole::text AS pemberi,
       CASE WHEN a.grantee = 0 THEN 'PUBLIC' ELSE a.grantee::regrole::text END AS penerima,
       a.privilege_type,
       a.is_grantable
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
CROSS JOIN LATERAL aclexplode(c.relacl) a
WHERE n.nspname = 'public' AND c.relkind = 'r'
UNION ALL
SELECT c.relname::text,
       att.attname::text,
       a.grantor::regrole::text,
       CASE WHEN a.grantee = 0 THEN 'PUBLIC' ELSE a.grantee::regrole::text END,
       a.privilege_type,
       a.is_grantable
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
JOIN pg_attribute att ON att.attrelid = c.oid AND att.attacl IS NOT NULL
CROSS JOIN LATERAL aclexplode(att.attacl) a
WHERE n.nspname = 'public' AND c.relkind = 'r';


-- =====================================================================
-- BAGIAN 2 : DDL - TABEL tagihan_kuliah
CREATE TABLE tagihan_kuliah (
    id_tagihan           SERIAL PRIMARY KEY,
    nim                  VARCHAR(10) REFERENCES mahasiswa(nim),
    nominal              NUMERIC(12,2) NOT NULL CHECK (nominal >= 0),
    status_lunas         BOOLEAN DEFAULT FALSE,
    tanggal_jatuh_tempo  DATE NOT NULL
);

-- Data uji (diisi oleh admin)
INSERT INTO tagihan_kuliah (nim, nominal, tanggal_jatuh_tempo) VALUES
('2024001', 4500000, '2026-12-31'),
('2024002', 4500000, '2026-12-31');

SELECT * FROM tagihan_kuliah;


-- =====================================================================
-- BAGIAN 3 : DCL - PEMBUATAN ROLE BARU
CREATE ROLE role_keuangan;
CREATE ROLE role_tata_usaha;


-- =====================================================================
-- BAGIAN 4 : DCL - KONFIGURASI HAK AKSES
REVOKE ALL ON tagihan_kuliah, nilai_akademik FROM PUBLIC;
REVOKE ALL ON SEQUENCE tagihan_kuliah_id_tagihan_seq FROM PUBLIC;

-- 4a. role_keuangan
GRANT SELECT ON mahasiswa, mata_kuliah, nilai_akademik, tagihan_kuliah
      TO role_keuangan;
GRANT INSERT ON tagihan_kuliah TO role_keuangan;
GRANT UPDATE (status_lunas) ON tagihan_kuliah TO role_keuangan;
GRANT USAGE, SELECT ON SEQUENCE tagihan_kuliah_id_tagihan_seq TO role_keuangan;

-- 4b. role_tata_usaha
GRANT SELECT, INSERT, UPDATE ON mahasiswa, mata_kuliah TO role_tata_usaha;
REVOKE ALL ON tagihan_kuliah, nilai_akademik FROM role_tata_usaha;

-- 4c. role_mahasiswa boleh membaca tagihan_kuliah
GRANT SELECT ON tagihan_kuliah TO role_mahasiswa;


-- =====================================================================
-- BAGIAN 5 : PEMBUATAN USER & PENUGASAN ROLE
-- =====================================================================
CREATE USER staff_keuangan01 WITH PASSWORD 'Keu#Staff01_2026!';
CREATE USER staff_tu01       WITH PASSWORD 'TU#Staff01_2026!';

GRANT role_keuangan   TO staff_keuangan01;
GRANT role_tata_usaha TO staff_tu01;

-- Pemeriksaan keanggotaan role
SELECT r.rolname AS role, m.rolname AS anggota
FROM pg_auth_members a
JOIN pg_roles r ON a.roleid = r.oid
JOIN pg_roles m ON a.member = m.oid
WHERE m.rolname IN ('staff_keuangan01', 'staff_tu01');

-- Pemeriksaan hak akses yang aktif (pengganti SHOW GRANTS)
SELECT * FROM v_hak_akses WHERE penerima = 'role_keuangan'
ORDER BY tabel, kolom, privilege_type;
SELECT * FROM v_hak_akses WHERE penerima = 'role_tata_usaha'
ORDER BY tabel, kolom, privilege_type;
SELECT * FROM v_hak_akses WHERE penerima = 'role_mahasiswa'
ORDER BY tabel, kolom, privilege_type;

-- Matriks hak akses (TRUE = diizinkan)
SELECT 'staff_tu01' AS akun,
       has_table_privilege('staff_tu01', 'tagihan_kuliah', 'SELECT')  AS baca_tagihan,
       has_table_privilege('staff_tu01', 'nilai_akademik', 'SELECT')  AS baca_nilai,
       has_table_privilege('staff_tu01', 'mahasiswa', 'UPDATE')       AS ubah_mahasiswa,
       has_table_privilege('staff_tu01', 'mata_kuliah', 'INSERT')     AS tambah_mk;

-- staff_keuangan01: ubah_nominal harus FALSE, sisanya TRUE
SELECT 'staff_keuangan01' AS akun,
       has_table_privilege('staff_keuangan01', 'tagihan_kuliah', 'SELECT')  AS baca_tagihan,
       has_table_privilege('staff_keuangan01', 'tagihan_kuliah', 'INSERT')  AS tambah_tagihan,
       has_column_privilege('staff_keuangan01', 'tagihan_kuliah', 'status_lunas', 'UPDATE') AS ubah_status_lunas,
       has_column_privilege('staff_keuangan01', 'tagihan_kuliah', 'nominal', 'UPDATE')      AS ubah_nominal;


-- =====================================================================
-- BAGIAN 6 : PENGUJIAN VERIFIKASI (jalankan satu per satu + screenshot)
-- =====================================================================

-- ---- 6.1 staff_tu01 ------------------------------------------------
SET ROLE staff_tu01;
SELECT current_user;                                                 
SELECT * FROM mahasiswa;                                             
UPDATE mata_kuliah SET sks = 3 WHERE kode_mk = 'IF101';              
SELECT * FROM tagihan_kuliah;                                        
SELECT * FROM nilai_akademik;                                        
RESET ROLE;

-- ---- 6.2 staff_keuangan01 ------------------------------------------
SET ROLE staff_keuangan01;
SELECT current_user;                                                 
SELECT * FROM tagihan_kuliah;                                        
INSERT INTO tagihan_kuliah (nim, nominal, tanggal_jatuh_tempo)
VALUES ('2024001', 1500000, '2027-01-31');                           
UPDATE tagihan_kuliah SET status_lunas = TRUE WHERE id_tagihan = 1;  
UPDATE tagihan_kuliah SET nominal = 1000 WHERE id_tagihan = 1;      
UPDATE tagihan_kuliah SET nim = '2024002' WHERE id_tagihan = 1;      
INSERT INTO mahasiswa (nim, nama, jurusan, angkatan)
VALUES ('2024003', 'Test', 'Informatika', 2024);                     
RESET ROLE;


-- =====================================================================
-- BAGIAN 7 : DEMO REVOKE (opsional, bukti pencabutan)
-- =====================================================================
REVOKE UPDATE (status_lunas) ON tagihan_kuliah FROM role_keuangan;

SET ROLE staff_keuangan01;
UPDATE tagihan_kuliah SET status_lunas = FALSE WHERE id_tagihan = 1; 
RESET ROLE;

GRANT UPDATE (status_lunas) ON tagihan_kuliah TO role_keuangan;       

