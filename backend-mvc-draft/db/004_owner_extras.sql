-- ฟีเจอร์ฝั่ง owner ที่แอปเรียกผ่าน ApiOwnerExtras: ชื่อ-นามสกุล, การตั้งค่าแจ้งเตือน,
-- วิธีระบุค่าน้ำ/ค่าไฟ (set_price / included / not_specified), การ report รีวิว, amenities ตั้งต้น
-- รันหลัง 003_reviews_pending.sql · รันซ้ำได้ และรันได้ทั้ง MySQL 8 และ MariaDB
-- (MySQL 8 ไม่รองรับ ADD COLUMN IF NOT EXISTS จึงเช็ค information_schema ก่อนเพิ่มคอลัมน์)

-- เพิ่มคอลัมน์เมื่อยังไม่มี: ตั้ง @tbl / @col / @ddl แล้วรันชุด PREPARE ด้านล่าง
SET @tbl = 'users', @col = 'first_name', @ddl = 'ALTER TABLE users ADD COLUMN first_name VARCHAR(50) DEFAULT NULL';
SET @sql = IF((SELECT COUNT(*) FROM information_schema.COLUMNS
               WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = @tbl AND COLUMN_NAME = @col) = 0, @ddl, 'DO 0');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @tbl = 'users', @col = 'surname', @ddl = 'ALTER TABLE users ADD COLUMN surname VARCHAR(50) DEFAULT NULL';
SET @sql = IF((SELECT COUNT(*) FROM information_schema.COLUMNS
               WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = @tbl AND COLUMN_NAME = @col) = 0, @ddl, 'DO 0');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

CREATE TABLE IF NOT EXISTS notification_preferences (
  user_id INT UNSIGNED NOT NULL,
  messages TINYINT(1) NOT NULL DEFAULT 1,
  approvals TINYINT(1) NOT NULL DEFAULT 1,
  reviews TINYINT(1) NOT NULL DEFAULT 0,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (user_id),
  CONSTRAINT fk_notification_preferences_user FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

SET @tbl = 'dormitories', @col = 'water_utility_mode',
    @ddl = 'ALTER TABLE dormitories ADD COLUMN water_utility_mode ENUM(''set_price'',''included'',''not_specified'') NOT NULL DEFAULT ''not_specified''';
SET @sql = IF((SELECT COUNT(*) FROM information_schema.COLUMNS
               WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = @tbl AND COLUMN_NAME = @col) = 0, @ddl, 'DO 0');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @tbl = 'dormitories', @col = 'electricity_utility_mode',
    @ddl = 'ALTER TABLE dormitories ADD COLUMN electricity_utility_mode ENUM(''set_price'',''included'',''not_specified'') NOT NULL DEFAULT ''not_specified''';
SET @sql = IF((SELECT COUNT(*) FROM information_schema.COLUMNS
               WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = @tbl AND COLUMN_NAME = @col) = 0, @ddl, 'DO 0');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- ตั้งค่าเริ่มจาก rate เดิม เฉพาะหอที่ยังเป็นค่า default (รันซ้ำไม่ทับค่าที่ owner เลือกแล้ว)
UPDATE dormitories SET water_utility_mode = 'set_price'
  WHERE water_rate IS NOT NULL AND water_utility_mode = 'not_specified';
UPDATE dormitories SET electricity_utility_mode = 'set_price'
  WHERE electricity_rate IS NOT NULL AND electricity_utility_mode = 'not_specified';

CREATE TABLE IF NOT EXISTS review_reports (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  review_id INT UNSIGNED NOT NULL,
  owner_id INT UNSIGNED NOT NULL,
  reason TEXT NOT NULL,
  status ENUM('open','resolved') NOT NULL DEFAULT 'open',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_review_reports_review_owner (review_id, owner_id),
  KEY idx_review_reports_owner (owner_id, created_at),
  CONSTRAINT chk_review_reports_reason CHECK (CHAR_LENGTH(TRIM(reason)) > 0),
  CONSTRAINT fk_review_reports_review FOREIGN KEY (review_id) REFERENCES reviews (id) ON DELETE CASCADE,
  CONSTRAINT fk_review_reports_owner FOREIGN KEY (owner_id) REFERENCES users (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- amenities ตั้งต้นตาม Figma O-3 (ชื่อซ้ำจะถูกข้าม)
INSERT IGNORE INTO amenities (name) VALUES
  ('Wi-Fi'), ('CCTV'), ('Key card'), ('Air conditioner'), ('Fan'),
  ('Parking'), ('Washing machine'), ('Elevator'), ('Pets allowed');
