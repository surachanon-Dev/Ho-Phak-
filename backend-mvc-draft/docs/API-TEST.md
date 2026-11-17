# ชุดทดสอบ API (Thunder Client / LiteClient)

ก่อนทดสอบ
- เปิด MySQL ใน XAMPP และรัน `node --env-file=.env --watch App.js` ในโฟลเดอร์ `backend/`
- ตั้งค่า base URL เป็น `http://localhost:3000`
- ตัวแปรที่ใช้ในตาราง
  - `{owner_token}` token ของ owner ที่ `is_verified = 1` ได้จาก login
  - `{owner_unverified_token}` token ของ owner ที่ `is_verified = 0`
  - `{student_token}` token ของ student
  - `{other_owner_token}` token ของ owner อีกคนที่เป็นเจ้าของหอคนละหลัง
  - `{dorm_id}` id ของหอพักที่ owner เป็นเจ้าของ
  - `{image_id}` id ของรูปในหอพักนั้น
- ทุก request ที่ต้องใช้สิทธิ์ ใส่ header `Authorization: Bearer <token>`

ช่องผลจริง: ใส่ ✅ ถ้าได้ตามที่คาดหวัง หรือ ❌ พร้อมบันทึกสิ่งที่ได้

## 1. Auth

| # | ทดสอบ | Method | URL | Body | คาดหวัง | ผลจริง |
|---|---|---|---|---|---|---|
| 1.1 | สมัครสำเร็จ | POST | `/api/auth/register` | `{"username":"owner_t1","password":"password123"}` | 201 มี `id` | |
| 1.2 | ไม่กรอก username | POST | `/api/auth/register` | `{"password":"password123"}` | 400 | |
| 1.3 | password สั้นกว่า 8 ตัว | POST | `/api/auth/register` | `{"username":"owner_t2","password":"123"}` | 400 | |
| 1.4 | username ซ้ำ | POST | `/api/auth/register` | ใช้ username จากข้อ 1.1 | 409 | |
| 1.5 | login สำเร็จ | POST | `/api/login` | `{"username":"owner_t1","password":"password123"}` | 200 มี `token` | |
| 1.6 | password ผิด | POST | `/api/login` | `{"username":"owner_t1","password":"wrong123"}` | 401 "Password not match" | |
| 1.7 | ไม่มีผู้ใช้นี้ | POST | `/api/login` | `{"username":"nobody","password":"password123"}` | 401 "User not found" | |
| 1.8 | ไม่กรอกข้อมูล login | POST | `/api/login` | `{}` | 400 | |
| 1.9 | logout ด้วย token ถูกต้อง | POST | `/api/auth/logout` | ไม่มี body (ใส่ token) | 200 | |
| 1.10 | logout ไม่มี header | POST | `/api/auth/logout` | ไม่ใส่ header | 401 "ม่ายมี header นะ" | |
| 1.11 | logout token ผิด | POST | `/api/auth/logout` | `Bearer abc` | 401 "token ไม่ถูกต้อง" | |

## 2. Middleware owner

| # | ทดสอบ | Method | URL | Header | คาดหวัง | ผลจริง |
|---|---|---|---|---|---|---|
| 2.1 | ไม่มี header | GET | `/api/owner/middleware` | ไม่มี | 401 | |
| 2.2 | ไม่ขึ้นต้นด้วย Bearer | GET | `/api/owner/middleware` | `Authorization: abc` | 401 | |
| 2.3 | token ผิด | GET | `/api/owner/middleware` | `Bearer abc` | 401 "token ไม่ถูกต้อง" | |
| 2.4 | token หมดอายุ | GET | `/api/owner/middleware` | token ที่หมดอายุแล้ว | 401 "token หมดอายุแล้ว" | |
| 2.5 | student เรียก | GET | `/api/owner/middleware` | `{student_token}` | 403 | |
| 2.6 | owner ยังไม่ยืนยัน | GET | `/api/owner/middleware` | `{owner_unverified_token}` | 403 | |
| 2.7 | owner ที่ยืนยันแล้ว | GET | `/api/owner/middleware` | `{owner_token}` | 200 | |

## 3. หอพัก (Dormitory CRUD)

| # | ทดสอบ | Method | URL | Body | คาดหวัง | ผลจริง |
|---|---|---|---|---|---|---|
| 3.1 | สร้างหอ | POST | `/api/owner/dormitories` | `{"name":"หอทดสอบ","zone":"หน้ามอ","latitude":19.8807,"longitude":99.8325,"price_per_month":3500}` | 201 มี `id` | |
| 3.2 | ขาด field | POST | `/api/owner/dormitories` | ไม่มี `name` | 400 | |
| 3.3 | zone ไม่ถูกต้อง | POST | `/api/owner/dormitories` | `"zone":"ไม่มี"` | 400 | |
| 3.4 | latitude เกิน 90 | POST | `/api/owner/dormitories` | `"latitude":95` | 400 | |
| 3.5 | ราคาเป็น 0 | POST | `/api/owner/dormitories` | `"price_per_month":0` | 400 | |
| 3.6 | ราคาเกิน 1,000,000 | POST | `/api/owner/dormitories` | `"price_per_month":1000001` | 400 | |
| 3.7 | student สร้างหอ | POST | `/api/owner/dormitories` | ใช้ `{student_token}` | 403 | |
| 3.8 | ดูรายการหอของตัวเอง | GET | `/api/owner/dormitories` | ไม่มี | 200 มี `dormitories` | |
| 3.9 | ดูหอของตัวเอง | GET | `/api/owner/dormitories/{dorm_id}` | ไม่มี | 200 มี `dormitory` | |
| 3.10 | ดูหอของคนอื่น | GET | `/api/owner/dormitories/{dorm_id}` | ใช้ `{other_owner_token}` | 404 | |
| 3.11 | id ไม่ใช่ตัวเลข | GET | `/api/owner/dormitories/abc` | ไม่มี | 404 | |
| 3.12 | แก้ไขหอของตัวเอง | PUT | `/api/owner/dormitories/{dorm_id}` | ส่งครบ 5 field และราคาใหม่ | 200 | |
| 3.13 | แก้ไขหอของคนอื่น | PUT | `/api/owner/dormitories/{dorm_id}` | ใช้ `{other_owner_token}` | 404 | |
| 3.14 | แก้ไขด้วยราคาเกิน | PUT | `/api/owner/dormitories/{dorm_id}` | `"price_per_month":1000001` | 400 | |
| 3.15 | ลบหอของคนอื่น | DELETE | `/api/owner/dormitories/{dorm_id}` | ใช้ `{other_owner_token}` | 404 | |
| 3.16 | ลบหอของตัวเอง | DELETE | `/api/owner/dormitories/{dorm_id}` | ไม่มี | 200 | |
| 3.17 | ลบซ้ำ | DELETE | `/api/owner/dormitories/{dorm_id}` | ไม่มี | 404 | |

## 4. รูปหอพัก

ตั้งค่าใน Thunder: Body → `form-data` เพิ่ม key ชื่อ `images` ชนิด File เลือกไฟล์ได้หลายไฟล์

| # | ทดสอบ | Method | URL | ไฟล์ | คาดหวัง | ผลจริง |
|---|---|---|---|---|---|---|
| 4.1 | อัปโหลดรูป jpg | POST | `/api/owner/dormitories/{dorm_id}/images` | `a.jpg` | 201 มี `count` | |
| 4.2 | อัปโหลดหลายรูป | POST | `/api/owner/dormitories/{dorm_id}/images` | `a.png`, `b.jpg` | 201 `count: 2` | |
| 4.3 | ไฟล์ไม่ใช่รูป | POST | `/api/owner/dormitories/{dorm_id}/images` | `note.txt` | 400 | |
| 4.4 | ไฟล์เกิน 5 MB | POST | `/api/owner/dormitories/{dorm_id}/images` | ไฟล์ขนาดมากกว่า 5 MB | 400 | |
| 4.5 | ไม่เลือกไฟล์ | POST | `/api/owner/dormitories/{dorm_id}/images` | ไม่มีไฟล์ | 400 | |
| 4.6 | หอของคนอื่น | POST | `/api/owner/dormitories/{dorm_id}/images` | ใช้ `{other_owner_token}` | 404 | |
| 4.7 | ไม่มี token | POST | `/api/owner/dormitories/{dorm_id}/images` | ไม่มี header | 401 | |
| 4.8 | เปิดรูปที่อัปโหลด | GET | `/uploads/<ชื่อไฟล์จากข้อ 4.1>` | ไม่มี | 200 แสดงรูป | |
| 4.9 | ลบรูปของตัวเอง | DELETE | `/api/owner/dormitories/{dorm_id}/images/{image_id}` | ไม่มี | 200 | |
| 4.10 | ลบรูปของหอคนอื่น | DELETE | `/api/owner/dormitories/{dorm_id}/images/{image_id}` | ใช้ `{other_owner_token}` | 404 | |
| 4.11 | ลบรูปซ้ำ | DELETE | `/api/owner/dormitories/{dorm_id}/images/{image_id}` | ไม่มี | 404 | |

## บันทึกผล

- วันที่ทดสอบ: ..........
- ผ่าน: ....... / รวม ....... เคส
- ข้อที่ไม่ผ่านและสาเหตุ: ..........
