-- ตารางการแจ้งเตือนของผู้ใช้ (เช่น ผลการตรวจเอกสาร, สถานะหอ, ข้อความใหม่)
-- รันหลัง 001_check_constraints.sql

CREATE TABLE notifications (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id INT UNSIGNED NOT NULL,
  type VARCHAR(50) NOT NULL,
  title VARCHAR(255) NOT NULL,
  body TEXT DEFAULT NULL,
  related_type VARCHAR(50) DEFAULT NULL,
  related_id INT UNSIGNED DEFAULT NULL,
  read_at DATETIME DEFAULT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_notifications_user_unread (user_id, read_at, id),
  CONSTRAINT chk_notifications_title CHECK (CHAR_LENGTH(TRIM(title)) > 0),
  CONSTRAINT chk_notifications_type CHECK (CHAR_LENGTH(TRIM(type)) > 0),
  CONSTRAINT fk_notifications_user FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
