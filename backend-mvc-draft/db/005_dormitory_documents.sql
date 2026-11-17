-- เอกสารความเป็นเจ้าของหอพัก (เจ้าของแนบตอนส่งหอ ให้ admin เปิดดูตอนตรวจ)
-- เก็บไฟล์ในโฟลเดอร์ private_uploads เหมือนเอกสารยืนยันตัวตน; รันหลัง 004_owner_extras.sql
CREATE TABLE IF NOT EXISTS dormitory_documents (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  dormitory_id INT UNSIGNED NOT NULL,
  document_url VARCHAR(255) NOT NULL,
  original_name VARCHAR(255) NOT NULL,
  uploaded_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_dormitory_documents_dormitory (dormitory_id),
  CONSTRAINT fk_dormitory_documents_dormitory FOREIGN KEY (dormitory_id) REFERENCES dormitories (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
