# Frontend (Flutter)

ฝั่ง frontend ของแอปหอพักใกล้มหาวิทยาลัยแม่ฟ้าหลวง ตอนนี้ทำฝั่งเจ้าของหอ (owner) ก่อน

## ก่อนเริ่ม

1. ติดตั้ง Flutter SDK และตรวจด้วย `flutter doctor`
2. ติดตั้ง extension **Flutter** ใน VS Code
3. รัน backend ก่อนทุกครั้ง ตามขั้นตอนใน [backend/README.md](../backend/README.md)

## การรัน

```bash
cd "D:/Ho-Phak Mobile Project/frontend"
flutter pub get
flutter run -d chrome --web-port 8080
```

- ตอนพัฒนาใช้ Chrome ได้เลย backend เปิด CORS ไว้แล้ว
- ถ้าจะรันบน Android emulator ต้องเปลี่ยน base URL เป็น `http://10.0.2.2:3000` เพราะ `localhost` ในเครื่อง emulator คือตัวมันเอง

## การตั้งค่า

- base URL อยู่ที่ `lib/config/api_config.dart` ตอนพัฒนาเป็น `http://localhost:3000`
- token เก็บด้วย `shared_preferences` หลัง login และแนบเป็น `Authorization: Bearer <token>` ทุก request ที่ต้องใช้สิทธิ์
- รายการ endpoint และรูปแบบข้อมูลอยู่ใน [backend/README.md](../backend/README.md)

## หน้าจอ

| ไฟล์ | หน้าที่ |
|---|---|
| `screens/login_screen.dart` | login แล้วเช็กว่าเป็น owner ที่ยืนยันตัวตนแล้ว |
| `screens/register_screen.dart` | สมัคร owner ใหม่ |
| `screens/dormitory_list_screen.dart` | รายการหอพัก ลบ และออกจากระบบ |
| `screens/dormitory_form_screen.dart` | ฟอร์มเพิ่มและแก้ไขหอพัก (ใช้ฟอร์มเดียวกัน) |

## โครงโฟลเดอร์

```
frontend/
├── lib/
│   ├── main.dart       ← จุดเริ่มต้นของแอป
│   ├── config/         ← base URL ของ API
│   ├── models/         ← โครงข้อมูล เช่น Dormitory และรายการโซน
│   ├── services/       ← เรียก API และจัดการ token
│   ├── screens/        ← หน้าจอ
│   └── widgets/        ← ส่วนประกอบที่ใช้ซ้ำ (ยังว่าง)
├── test/               ← ยังไม่มี test
└── pubspec.yaml
```

## Workflow ของทีม

- อย่า commit ตรงลง branch กลาง ให้สร้าง branch ของตัวเองก่อน เช่น `Frontend-<ชื่อ>`
- ก่อน push ให้ตรวจว่าไม่มีไฟล์ build หรือ token ติดขึ้นไป
- ตรวจโค้ดก่อน commit ด้วย `flutter analyze`
