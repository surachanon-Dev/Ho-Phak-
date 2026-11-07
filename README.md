# Ho-Phak-

แอปรวบรวมหอพักใกล้มหาวิทยาลัยแม่ฟ้าหลวง แบ่งเป็นสองฝั่งอยู่ในโปรเจกต์เดียวกัน

| ฝั่ง | โฟลเดอร์ | เทคโนโลยี | README |
|---|---|---|---|
| Backend | `backend-mvc-draft/` | Node.js, Express 5, MySQL (MariaDB) | [backend-mvc-draft/README.md](backend-mvc-draft/README.md) |
| Frontend | `frontend/` | Flutter | [frontend/README.md](frontend/README.md) |

## เริ่มต้นอย่างย่อ

1. เปิด MySQL ใน XAMPP และตรวจว่าฐาน `hopak` มี schema ครบ
2. รัน backend

```bash
cd "D:\Ho-Phak Mobile Project\backend-mvc-draft"
npm install
node --env-file=.env App.js
```

3. รัน frontend

```bash
cd "D:\Ho-Phak Mobile Project\frontend"
flutter pub get
flutter run -d chrome --web-port 8080
```

> `.env` ต้องมี `JWT_KEY` และไม่ถูก commit ทั้ง backend และ frontend ใช้พอร์ต 3000 สำหรับ API จึงรันพร้อมกันได้โดยไม่ต้องปรับค่าอื่น

## บทบาทในระบบ

- **student** นักศึกษา ค้นหาและดูหอ รีวิว เก็บรายการโปรด และแชทกับเจ้าของ
- **owner** เจ้าของหอ ต้องยืนยันตัวตนก่อนจัดการหอพัก
- **admin** ผู้ดูแลระบบ ตรวจหอใหม่และฉบับแก้ไข ยืนยันเจ้าของ ระงับบัญชีและหอ ตรวจรีวิว และดูบันทึกการกระทำ

## เอกสารที่เกี่ยวข้อง

- [backend-mvc-draft/README.md](backend-mvc-draft/README.md) โครงสร้าง, การรัน, endpoint, ฐานข้อมูล
- [backend-mvc-draft/docs/API-TEST.md](backend-mvc-draft/docs/API-TEST.md) ชุดเคสทดสอบ API
- [backend-mvc-draft/db/](backend-mvc-draft/db/) migration ของฐาน `hopak`

## Branch

- `main` ใช้เป็นหลัก
- `Backend-Bank` งานฝั่ง backend (โค้ดอยู่ที่ `backend-mvc-draft/`)
- `Frontend-*` งานฝั่ง frontend ของแต่ละคน
