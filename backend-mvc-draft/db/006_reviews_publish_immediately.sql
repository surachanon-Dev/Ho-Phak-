-- รีวิวนักศึกษาขึ้นทันที (D-101/D-202): สถานะเริ่มต้น = published, admin ตรวจเฉพาะรีวิวที่ owner รายงาน
-- รันหลัง 005_dormitory_documents.sql · รันซ้ำได้
-- ค่า 'pending' ยังอยู่ใน ENUM เพื่อไม่ให้ข้อมูลเก่าพัง แต่โค้ดไม่ใช้แล้ว

ALTER TABLE reviews
  MODIFY COLUMN status ENUM('pending','published','hidden') NOT NULL DEFAULT 'published';

-- รีวิวเก่าที่ค้าง pending (เคยรอตรวจ) → เผยแพร่ เพราะไม่มีขั้นตรวจก่อนแสดงอีกแล้ว
UPDATE reviews SET status = 'published' WHERE status = 'pending';
