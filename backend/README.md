# Backend (Node.js + Express + MySQL)

ฝั่ง backend ของแอปหอพักใกล้มหาวิทยาลัยแม่ฟ้าหลวง ทำหน้าที่ API ให้ frontend เรียกใช้

## เทคโนโลยี

- Express 5
- MySQL ผ่าน `mysql2` (ฐานข้อมูล `hopak`)
- `@node-rs/argon2` สำหรับ hash password
- `jsonwebtoken` สำหรับ JWT

## ก่อนเริ่ม

1. เปิด **MySQL** ใน XAMPP ไว้ก่อนทุกครั้ง
2. ติดตั้ง dependencies (ทำครั้งแรกครั้งเดียว)

```bash
cd "D:/Ho-Phak Mobile Project/backend"
npm install
```

3. สร้างไฟล์ `.env` ในโฟลเดอร์ `backend/` โดยมีค่านี้ (ค่าของ `JWT_KEY` ตั้งเองได้ ต้องเดายาก และอย่า commit ไฟล์นี้)

```
JWT_KEY="ใส่ค่าที่เดายาก"
```

4. ฐานข้อมูลใช้ค่าตาม `Database-Config.js` คือ host `localhost`, user `root`, password ว่าง, database `hopak`

## การรัน

```bash
cd "D:/Ho-Phak Mobile Project/backend"
node --env-file=.env --watch App.js
```

Server รันที่ `http://localhost:3000` เมื่อเห็นข้อความ `server running at http://localhost:3000`

## โครงโฟลเดอร์

```
backend/
├── App.js              ← route ทั้งหมด (ตอนนี้รวมอยู่ไฟล์เดียว)
├── Database-Config.js  ← การเชื่อมต่อ MySQL
├── package.json
├── .env                ← ไม่ commit
├── node_modules/       ← ไม่ commit
└── uploads/            ← ไฟล์รูปที่อัปโหลด
```

## ตารางในฐานข้อมูล `hopak`

| ตาราง | ใช้ทำอะไร |
|---|---|
| `users` | บัญชีผู้ใช้ (owner, student, admin) มี `is_verified` บอกว่ายืนยันตัวตนแล้วหรือยัง |
| `dormitories` | ข้อมูลหอพัก มี `owner_id` ชี้ไปที่ `users.id` |
| `dormitory_images` | รูปของหอพัก ลบหอแล้วรูปจะถูกลบตามด้วย (`ON DELETE CASCADE`) |
| `verifications` | เอกสารยืนยันตัวตนของ owner (ยังไม่ได้ใช้ในรอบนี้) |

## Endpoints

ทุก endpoint ส่งและรับข้อมูลเป็น JSON ยกเว้นส่วนที่ระบุว่าต้องใส่ token

### Auth

| Method | Path | ต้องใช้ token | Body | ผลลัพธ์ |
|---|---|---|---|---|
| POST | `/api/auth/register` | ไม่ | `{ "username", "password" }` | 201 `{ message, id }` |
| POST | `/api/login` | ไม่ | `{ "username", "password" }` | 200 `{ message, token }` |
| POST | `/api/auth/logout` | ใช่ | - | 200 `{ message }` |

- `password` ต้องยาวอย่างน้อย 8 ตัวอักษร
- สมัครได้เฉพาะ owner ระบบกำหนด role ให้เอง และตั้ง `is_verified` เป็น 0
- owner ที่ยังไม่ยืนยันตัวตนยัง login ได้ แต่ใช้ฟังก์ชัน owner ไม่ได้
- logout ฝั่ง server แค่ตรวจ token แล้วตอบ 200 แอปต้องลบ token เอง token เดิมยังใช้ได้จนกว่าจะหมดอายุ (1 วัน)

### Owner

| Method | Path | Body | ผลลัพธ์ |
|---|---|---|---|
| GET | `/api/owner/middleware` | - | 200 ถ้าเป็น owner ที่ยืนยันแล้ว |
| POST | `/api/owner/dormitories` | ดูด้านล่าง | 201 `{ message, id }` |
| GET | `/api/owner/dormitories` | - | 200 `{ dormitories }` |
| GET | `/api/owner/dormitories/:id` | - | 200 `{ dormitory }` |
| PUT | `/api/owner/dormitories/:id` | ดูด้านล่าง | 200 `{ message }` |
| DELETE | `/api/owner/dormitories/:id` | - | 200 `{ message }` |

ข้อมูลหอพักที่ต้องส่ง (POST และ PUT ต้องส่งครบทุก field)

```json
{
  "name": "หอพักตัวอย่าง",
  "zone": "หน้ามอ",
  "latitude": 19.8807,
  "longitude": 99.8325,
  "price_per_month": 3500
}
```

- `zone` รับได้เฉพาะ `หน้ามอ`, `หลังมอ`, `คชพลแลนด์`
- `latitude` อยู่ระหว่าง -90 ถึง 90 และ `longitude` อยู่ระหว่าง -180 ถึง 180
- `price_per_month` เป็นจำนวนเต็มระหว่าง 1 ถึง 1,000,000 บาท

ทุก route ของ owner ต้องส่ง header `Authorization: Bearer <token>` และ owner ต้องยืนยันตัวตนแล้ว

### Error ที่พบบ่อย

| Status | ความหมาย |
|---|---|
| 400 | ข้อมูลที่ส่งไม่ครบหรือไม่ถูกต้อง |
| 401 | ไม่มี token, รูปแบบผิด หรือ token หมดอายุ/ไม่ถูกต้อง |
| 403 | token ถูกต้องแต่ไม่มีสิทธิ์ เช่น ไม่ใช่ owner หรือยังไม่ยืนยันตัวตน |
| 404 | ไม่พบหอพัก หรือหอพักนั้นไม่ได้เป็นของ owner คนนี้ |
| 409 | username ซ้ำตอนสมัคร |
| 500 | error ฝั่ง server หรือ database ดูรายละเอียดในเทอร์มินัลที่รัน server |

## ทดสอบ API

ใช้ LiteClient หรือ Thunder Client ยิงตาม endpoint ด้านบน ตัวอย่าง register:

- Method `POST`, URL `http://localhost:3000/api/auth/register`
- Body แบบ JSON: `{ "username": "owner_test1", "password": "password123" }`
