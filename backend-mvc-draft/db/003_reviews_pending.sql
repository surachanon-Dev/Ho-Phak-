-- รีวิวต้องผ่านการตรวจก่อนแสดง: สถานะ pending (รอตรวจ), published (แสดง), hidden (admin ซ่อนภายหลัง)
-- รันหลัง 002_notifications.sql

ALTER TABLE reviews
  MODIFY COLUMN status ENUM('pending','published','hidden') NOT NULL DEFAULT 'pending';
