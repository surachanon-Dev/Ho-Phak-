# Ho-Phak Frontend (Mock) – ตรงกับฐานข้อมูล `hopak`

แอป Flutter ครบ 3 บทบาท (นักศึกษา / เจ้าของหอพัก / ผู้ดูแลระบบ) ใช้ **ข้อมูลจำลอง (mock)** ที่มีชื่อตารางและคอลัมน์เหมือน `hopakDB.sql`
ยังไม่เชื่อม Backend – ตอนเชื่อมจริงแก้แค่ไฟล์ใน `lib/services/` (ให้เรียก API แทน `MockDb`) ส่วน views / controllers / models ใช้ต่อได้เลย

## วิธีรันครั้งแรก
```bash
cd Frontend
flutter create . --project-name hophak_frontend --org com.hophak --platforms android,web
flutter pub get
flutter run -d chrome
```
ต้องใช้ Flutter 3.35 ขึ้นไป · ข้อมูลจะรีเซ็ตทุกครั้งที่ปิด/เปิดแอปใหม่

## บัญชีทดสอบ (รหัสผ่านทุกบัญชี `Pass@1234`)
| เข้าสู่ระบบด้วย | บทบาท | ใช้ทดสอบ |
|---|---|---|
| `Frame` | นักศึกษา | ค้นหา, รายการโปรด, รีวิว, แชทกับ Bank |
| `Bank` | เจ้าของหอ | หอที่เผยแพร่ 3 หอ, แชทกับ Frame |
| `Big` | เจ้าของหอ | มีหอครบทุกสถานะ (เผยแพร่ / รอตรวจสอบ / ไม่อนุมัติ / ซ่อน / ถูกระงับ) |
| `admin` | ผู้ดูแลระบบ | อนุมัติหอใหม่, ระงับ, ดูรีวิว |

ล็อกอินได้ทั้ง **ชื่อผู้ใช้ (username)** หรือ **เบอร์โทร (phone)**

**ลืมรหัสผ่าน:** หน้า login › "ลืมรหัสผ่าน?" › กรอกเบอร์โทรของบัญชี › กรอก OTP 6 หลัก (โหมดจำลองจะแสดงรหัสบนจอแทน SMS) › ตั้งรหัสผ่านใหม่
OTP หมดอายุใน 5 นาที, กรอกผิดได้ไม่เกิน 5 ครั้ง, ขอรหัสใหม่ได้ทุก 60 วินาที

## ตาราง → หน้าจอ
| ตาราง | หน้าจอ |
|---|---|
| users | login / register / profile, admin › ผู้ใช้ (ระงับ/เปิดใช้งาน) |
| dormitories, dormitory_images, amenities, dormitory_amenities | ค้นหา, แผนที่, รายละเอียดหอ, owner › ฟอร์มหอพัก, admin › หอพัก |
| favorites | student › รายการโปรด |
| reviews | student › เขียน/แก้ไขรีวิว, รีวิวของฉัน, owner › รีวิว, admin › รีวิว (ดูอย่างเดียว) |
| conversations, messages | ไอคอนแชทมุมขวาบน |
| notifications | ไอคอนกระดิ่งมุมขวาบน |
| admin_logs | admin › บันทึกการทำงาน |

## กฎที่ mock ทำตาม (Backend ต้องทำเหมือนกัน)
- นักศึกษาเห็นเฉพาะหอ `published`
- **ไม่มีการยืนยันตัวตนบัญชีเจ้าของหอแล้ว** – ตอนเพิ่มหอพักต้องแนบ **รูปหอพักอย่างน้อย 1 รูป + เอกสารแสดงความเป็นเจ้าของ** หอใหม่ = `pending` รอแอดมินดูรูปและเอกสารแล้วอนุมัติ
- **ไม่มีคำขอแก้ไขแล้ว** – เจ้าของแก้ไขหอได้ทันที (`published`/`hidden`/`pending` คงสถานะเดิม, `rejected` แก้แล้วกลับเป็น `pending` ให้ตรวจใหม่)
- หอ `suspended` แก้ไม่ได้ · เจ้าของซ่อน/แสดงได้ (published ↔ hidden)
- **รีวิวไม่ต้องผ่านแอดมิน** – ส่งแล้วแสดงทันที (1 คน/1 หอ) แอดมินดูรีวิวได้อย่างเดียว
- แอดมิน: อนุมัติ/ไม่อนุมัติหอใหม่ (ต้องมีเหตุผล), ระงับ/คืนสถานะหอ, ระงับผู้ใช้ (ยกเว้นแอดมิน) – ทุกการกระทำบันทึกลง `admin_logs`

## สิ่งที่ Backend / ฐานข้อมูลต้องปรับให้ตรง
```sql
ALTER TABLE dormitories ADD COLUMN ownership_document_url VARCHAR(255) NULL AFTER contact_phone;
-- ไม่ใช้แล้ว: ตาราง verifications, dormitory_revisions, users.is_verified, สถานะ dormitories 'changes_pending'
-- ไม่ใช้แล้ว: dormitories.total_rooms, dormitories.available_rooms (ลบคอลัมน์ หรือให้ DEFAULT 0)
-- reviews.status ให้ default = 'published'
-- ลืมรหัสผ่าน: POST /auth/forgot-password {phone} (ส่ง SMS OTP) → POST /auth/verify-otp {phone, code} → POST /auth/reset-password {phone, reset_token, new_password}
CREATE TABLE password_resets (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  otp_hash VARCHAR(255) NOT NULL,        -- เก็บ hash ไม่เก็บรหัสตรง ๆ
  attempts TINYINT NOT NULL DEFAULT 0,
  reset_token_hash VARCHAR(255) NULL,
  expires_at DATETIME NOT NULL,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
```

## โครงสร้าง (MVC)
```
lib/
  core/         theme, config (โซน, วิธีคิดค่าน้ำไฟ), formatters (ป้ายภาษาไทย)
  mock/         mock_db.dart  ← ข้อมูลจำลองตามตาราง hopak
  models/       user, dormitory (+images, amenities), activity (review, chat, notification, log)
  services/     auth, dorm, owner, admin, chat, notification  ← จุดที่ต้องเปลี่ยนตอนเชื่อม Backend
  controllers/  auth, badge, favorites, owner (ChangeNotifier)
  views/        auth / student / owner / admin / common / widgets
test/           mock_rules_test.dart (กฎธุรกิจ), widget_test.dart
```
