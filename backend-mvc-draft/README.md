# Backend (MVC) ระบบหอพักใกล้มหาวิทยาลัยแม่ฟ้าหลวง

Backend ของแอปหอพัก แยกโค้ดตามรูปแบบ MVC ให้อ่านและแก้ไขได้ง่าย ใช้ Node.js, Express 5 และ MySQL (MariaDB ผ่าน XAMPP)

## เทคโนโลยีที่ใช้
- Express 5 สำหรับ routing
- mysql2 ผ่าน pool แบบ promise
- @node-rs/argon2 สำหรับ hash รหัสผ่าน
- jsonwebtoken สำหรับ token (อายุ 1 วัน)

## เตรียมเครื่อง
1. เปิด **MySQL** ใน XAMPP
2. ฐานข้อมูลชื่อ `hopak` ต้องมี schema ครบแล้ว (ดูหัวข้อ "ฐานข้อมูล")
3. มีไฟล์ `.env` ในโฟลเดอร์นี้ โดยมีบรรทัด

```
JWT_KEY="ค่าที่เดายาก"
```

## การติดตั้งและรัน

```bash
cd "D:\Ho-Phak Mobile Project\backend-mvc-draft"
npm install
node --env-file=.env App.js
```

เมื่อขึ้น `server running at http://localhost:3000` แปลว่าพร้อมใช้งาน

> ต้องปิด `App.js` ของ `backend/` หรือ `TEST-API.js` ที่รันอยู่ก่อน เพราะทุกตัวใช้พอร์ต 3000

## โครงสร้างโฟลเดอร์

```
backend-mvc-draft/
├── App.js              ← ประกอบ app, mount router และ error handler
├── config/
│   ├── env.js          ← ตรวจ JWT_KEY
│   └── db.js           ← pool ของ MySQL
├── routes/             ← กำหนด path และ middleware ของแต่ละ route
├── controllers/        ← รับ request และส่ง response
├── services/           ← กฎทางธุรกิจ เช่น การตรวจข้อมูลและการอนุมัติ
├── models/             ← คำสั่ง SQL ทั้งหมดอยู่ที่นี่
├── middleware/
│   ├── auth.js         ← ตรวจ token, role และการยืนยันตัวตน
│   └── errorHandler.js ← แปลง error เป็น response จุดเดียว
└── utils/
    ├── AppError.js     ← error ที่มี status code
    ├── transaction.js  ← ทรานแซกชัน
    └── validators.js   ← ตรวจข้อมูลที่ส่งมา
```

**หลักการแบ่งหน้าที่**
- route ไม่มี SQL และไม่มีกฎทางธุรกิจ
- controller ไม่เรียก model โดยตรง เรียกผ่าน service
- model ไม่ตรวจสิทธิ์ ทุกคำสั่งที่เกี่ยวกับเจ้าของจะมี `owner_id` เป็นเงื่อนไขเสมอ
- การกระทำของ admin ที่เปลี่ยนข้อมูลจะบันทึก `admin_logs` และแจ้งเตือนในทรานแซกชันเดียวกัน

## การยืนยันตัวตนและสิทธิ์
- login ด้วยเบอร์โทรและรหัสผ่าน (รองรับ `+66` และ `0`)
- ทุก request ที่มีสิทธิ์จะโหลดสถานะผู้ใช้จาก DB ใหม่ทุกครั้ง จึงระงับบัญชีได้ทันที
- role
  - `student` ค้นหาหอ, รีวิว, รายการโปรด, แชท
  - `owner` จัดการหอ, ส่งเอกสารยืนยันตัวตน (ต้อง `is_verified = 1` จึงจะจัดการหอได้)
  - `admin` ตรวจคิว, อนุมัติ, ระงับ และดูบันทึก

## Endpoint

| กลุ่ม | Method | Path | สิทธิ์ |
|---|---|---|---|
| Auth | POST | `/api/auth/register` | ทุกคน |
| Auth | POST | `/api/login` | ทุกคน |
| Auth | POST | `/api/auth/logout` | ต้อง login |
| Auth | GET | `/api/me` | ต้อง login |
| หอพักสาธารณะ | GET | `/api/dormitories` | ทุกคน (ค้นหาและกรอง) |
| หอพักสาธารณะ | GET | `/api/dormitories/:id` | ทุกคน |
| หอพักสาธารณะ | GET | `/api/dormitories/:id/reviews` | ทุกคน |
| รีวิว | POST | `/api/dormitories/:id/reviews` | student |
| รีวิว | PUT / DELETE | `/api/reviews/:id` | student (ของตัวเอง) |
| เจ้าของ | GET / POST | `/api/owner/dormitories` | owner ที่ยืนยันแล้ว |
| เจ้าของ | GET / PUT | `/api/owner/dormitories/:id` | owner ที่ยืนยันแล้ว |
| เจ้าของ | PATCH | `/api/owner/dormitories/:id/visibility` | owner ที่ยืนยันแล้ว |
| เจ้าของ | GET | `/api/owner/dormitories/:id/reviews` | owner ที่ยืนยันแล้ว |
| ยืนยันตัวตน | GET / POST | `/api/owner/verification` | owner |
| รายการโปรด | GET | `/api/favorites` | student |
| รายการโปรด | POST / DELETE | `/api/favorites/:dormitoryId` | student |
| แชท | GET / POST | `/api/conversations` | GET: student และ owner, POST: student |
| แชท | GET / POST | `/api/conversations/:id/messages` | student และ owner ที่เป็นคู่สนทนา |
| แชท | DELETE | `/api/conversations/:id` | student และ owner ที่เป็นคู่สนทนา |
| การแจ้งเตือน | GET | `/api/notifications` | ต้อง login |
| การแจ้งเตือน | PATCH | `/api/notifications/:id/read` | ต้อง login |
| admin | GET | `/api/admin/queue` | admin |
| admin | POST | `/api/admin/dormitories/:id/approve`, `/reject`, `/suspend`, `/restore` | admin |
| admin | POST | `/api/admin/verifications/:id/approve`, `/reject` | admin |
| admin | POST | `/api/admin/users/:id/suspend`, `/restore` | admin |
| admin | GET | `/api/admin/reviews` | admin |
| admin | POST | `/api/admin/reviews/:id/publish`, `/hide` | admin |
| admin | GET | `/api/admin/logs` | admin |

รายละเอียดรูปแบบข้อมูลและ error ทั้งหมดอยู่ในไฟล์ `api-reference-TEST-API.md` ที่โฟลเดอร์ shared notes

## ฐานข้อมูล
- schema หลักมาจากไฟล์ dump `hopak (2).sql` ที่เพื่อนออกแบบ
- migration ที่เพิ่มทีหลังอยู่ในโฟลเดอร์ `db/` ได้แก่
  - `001_check_constraints.sql` เพิ่ม CHECK ที่หายไปจาก dump
  - `002_notifications.sql` ตารางการแจ้งเตือน
  - `003_reviews_pending.sql` สถานะรีวิว `pending`, `published`, `hidden`
- ทั้งสามไฟล์รันแล้วบนฐาน `hopak` ปัจจุบัน ไม่ต้องรันซ้ำ

## ทดสอบ
- smoke test ครอบคลุม register, login, owner, student, admin และการตรวจสิทธิ์ ผ่าน 34/34 เคส
- ตอนนี้ยังไม่มี unit test อัตโนมัติ ตรวจด้วยการยิง request ตามเอกสาร API

## ข้อจำกัดที่ยังมี
- ยังไม่รองรับการอัปโหลดไฟล์รูปและเอกสาร รับเป็น URL/ข้อความไปก่อน
- ยังไม่มี endpoint รายการสิ่งอำนวยความสะดวก
- admin login ทดสอบด้วย token ที่สร้างเองยังไม่ครบ ควรทดสอบด้วยการ login จริง
- route ทดสอบ `/api/password/:raw` ไม่ได้ถูกย้ายมาในโครงนี้ จึงไม่มีให้เรียก
