# Ho-Phak-

แอปรวบรวมหอพักใกล้มหาวิทยาลัยแม่ฟ้าหลวง แบ่งเป็นสองฝั่งอยู่ในโปรเจกต์เดียวกัน

| ฝั่ง | โฟลเดอร์ | เทคโนโลยี | README |
|---|---|---|---|
| Backend | `backend/` | Node.js, Express, MySQL | [backend/README.md](backend/README.md) |
| Frontend | `frontend/` | Flutter | [frontend/README.md](frontend/README.md) |

## เริ่มต้นอย่างย่อ

1. เปิด MySQL ใน XAMPP
2. รัน backend ตามขั้นตอนใน [backend/README.md](backend/README.md)
3. รัน frontend ตามขั้นตอนใน [frontend/README.md](frontend/README.md)

## บทบาทในระบบ

- **owner** เจ้าของหอ สมัครเองและต้องยืนยันตัวตนก่อนจัดการหอพักได้
- **student** นักศึกษา (ยังไม่ได้ทำ)
- **admin** ผู้ดูแลระบบ (ยังไม่ได้ทำ)

## Branch

- `main` ใช้เป็นหลัก
- `Backend-Bank` งานฝั่ง backend
- `Frontend-*` งานฝั่ง frontend ของแต่ละคน
