-- ฟีเจอร์ฝั่ง owner ที่แอปเรียกผ่าน ApiOwnerExtras: ชื่อ-นามสกุล, การตั้งค่าแจ้งเตือน,
-- วิธีระบุค่าน้ำ/ค่าไฟ (set_price / included / not_specified), การ report รีวิว, amenities ตั้งต้น
-- รันหลัง 003_reviews_pending.sql

ALTER TABLE users
  ADD COLUMN IF NOT EXISTS first_name VARCHAR(50) DEFAULT NULL,
  ADD COLUMN IF NOT EXISTS surname VARCHAR(50) DEFAULT NULL;

CREATE TABLE IF NOT EXISTS notification_preferences (
  user_id INT UNSIGNED NOT NULL,
  messages TINYINT(1) NOT NULL DEFAULT 1,
  approvals TINYINT(1) NOT NULL DEFAULT 1,
  reviews TINYINT(1) NOT NULL DEFAULT 0,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (user_id),
  CONSTRAINT fk_notification_preferences_user FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

ALTER TABLE dormitories
  ADD COLUMN IF NOT EXISTS water_utility_mode ENUM('set_price','included','not_specified') NOT NULL DEFAULT 'not_specified',
  ADD COLUMN IF NOT EXISTS electricity_utility_mode ENUM('set_price','included','not_specified') NOT NULL DEFAULT 'not_specified';

UPDATE dormitories SET water_utility_mode = 'set_price' WHERE water_rate IS NOT NULL;
UPDATE dormitories SET electricity_utility_mode = 'set_price' WHERE electricity_rate IS NOT NULL;

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
