-- 1. สร้าง PDB ใหม่ จาก PDB$SEED
-- 1. สร้าง PDB ใหม่ จาก PDB$SEED
CREATE PLUGGABLE DATABASE devpdb
  ADMIN USER pdbadmin IDENTIFIED BY PdbPass123
  FILE_NAME_CONVERT = ('pdbseed', 'devpdb');

-- 2. เปิดใช้งาน PDB
ALTER PLUGGABLE DATABASE devpdb OPEN;

-- 3. บันทึกสถานะให้ PDB เปิดอัตโนมัติหลังรีสตาร์ท
ALTER PLUGGABLE DATABASE devpdb SAVE STATE;

-- 4. สลับ session ไปยัง PDB ใหม่
ALTER SESSION SET CONTAINER = devpdb;

-- 5. สร้าง Tablespace ใหม่ (หากยังไม่มี)
CREATE TABLESPACE user_data
  DATAFILE '/opt/oracle/oradata/XE/devpdb_user_data01.dbf' SIZE 100M
  AUTOEXTEND ON NEXT 10M MAXSIZE UNLIMITED;

-- 6. สร้าง Local User (schema) และกำหนด default tablespace
CREATE USER service IDENTIFIED BY serv123
  DEFAULT TABLESPACE user_data
  TEMPORARY TABLESPACE TEMP
  QUOTA UNLIMITED ON user_data;

GRANT CONNECT, RESOURCE TO service;

-- 7. สร้าง DIRECTORY สำหรับ Data Pump
CREATE OR REPLACE DIRECTORY data_pump_dir_test AS '/opt/oracle/oradata/dpump';
GRANT READ, WRITE ON DIRECTORY data_pump_dir_test TO service;

-- 8. สร้างตาราง
CREATE TABLE service.buckets (
    bk_id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    bk_bucket_name VARCHAR2(50) NOT NULL,
    bk_path_bucket VARCHAR2(1024) NOT NULL,
    bk_created_by VARCHAR2(100) NOT NULL,
    bk_created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
);

CREATE TABLE service.files (
    fs_id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    bk_id NUMBER NOT NULL,
    fs_file_name VARCHAR2(50) NOT NULL,
    fs_path_file VARCHAR2(1024) NOT NULL,
    fs_mime_type VARCHAR2(50) NOT NULL,
    fs_created_by VARCHAR2(100) NOT NULL,
    fs_created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT fk_files_bucket FOREIGN KEY (bk_id) REFERENCES service.buckets(bk_id)
);
;

-- 8. กำหนดสิทธิ์ให้ userpdb บนตารางของตัวเอง (จริงๆ เจ้าของ schema ก็มีสิทธิ์ทั้งหมด)
-- GRANT SELECT, INSERT, UPDATE, DELETE ON userpdb.files_storage TO userpdb;
-- GRANT SELECT, INSERT, UPDATE, DELETE ON userpdb.buckets_storage TO userpdb;

-- 9. ปิด Auto Commit (ถ้าต้องการ)
SET AUTOCOMMIT OFF;
