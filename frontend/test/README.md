# เทสต์ของ Ho-Phak (แบ่งตาม ประเภท → role → คน)

```
test/
├── unit/                 เทสต์ controller / service / model (test)
│   ├── student/
│   │   ├── big/          หน้าหลัก, ค้นหา, รายละเอียดหอ, รายการโปรด, รีวิวของฉัน
│   │   └── karn/         login/สมัคร, แชท, การแจ้งเตือน, badge, สมัครเป็นเจ้าของหอ
│   ├── owner/
│   │   ├── plub/         dashboard, ฟอร์มหอ, รายละเอียดหอ, เลือกตำแหน่ง, กติกาฟอร์ม
│   │   └── kren/         บัญชี (โปรไฟล์, รหัสผ่าน, แจ้งเตือน), รีวิว, ยืนยันตัวตน
│   ├── admin/
│   │   ├── bank/         dashboard, คำขอเจ้าของ, หอ, เอกสารหอ, ผู้ใช้, รายละเอียดผู้ใช้
│   │   └── plem/         รีวิว, activity log, amenities, settings, profile
│   └── shared/           ส่วนกลาง: api_client, format
├── widget/               เทสต์หน้าจอ (testWidgets)
│   ├── student/big/      home, search, dorm_detail, favorites
│   ├── student/karn/     auth_screens, forgot_password, chat_and_notifications, profile
│   ├── owner/plub/       owner_dorm_screens (dashboard/detail/form/location), owner_ui
│   ├── owner/kren/       owner_shell_profile, owner_profile_screens, owner_review_verification
│   ├── admin/bank/       dashboard, owner_requests, dorms, users, user_detail, reset_password
│   ├── admin/plem/       reviews, activity_log, amenities, settings, profile
│   └── shared/           responsive layout
└── helpers/              ตัวช่วยที่ใช้ร่วมกัน (ไม่ใช่เทสต์)
    ├── admin_test_helpers.dart   servicesWith, jsonResponse, ขนาดจอ
    ├── owner_test_helpers.dart   ตัวช่วย widget test ฝั่ง owner
    └── test_services.dart        studentServicesWith
```

## ลำดับพรีเซนต์และคำสั่งรัน

| # | Role | คน | คำสั่ง |
|---|---|---|---|
| 1 | Student | Karn | `flutter test test/unit/student/karn test/widget/student/karn` |
| 2 | Student | Big | `flutter test test/unit/student/big test/widget/student/big` |
| 3 | Owner | Kren | `flutter test test/unit/owner/kren test/widget/owner/kren` |
| 4 | Owner | Plub | `flutter test test/unit/owner/plub test/widget/owner/plub` |
| 5 | Admin | Bank | `flutter test test/unit/admin/bank test/widget/admin/bank` |
| 6 | Admin | Plem | `flutter test test/unit/admin/plem test/widget/admin/plem` |
| 7 | ทุกคน | ปิดท้าย | `flutter test` (รันทั้งหมด รวม shared) |

รันจากโฟลเดอร์ `frontend/`

## กติกา
- บรรทัดแรกของทุกไฟล์เขียนว่า `// ผู้รับผิดชอบ: <ชื่อ> (<role>)`
- เทสต์ใหม่วางในโฟลเดอร์ของตัวเอง: `test/unit/<role>/<ชื่อ>/` หรือ `test/widget/<role>/<ชื่อ>/`
- ชื่อไฟล์ต้องลงท้าย `_test.dart` ไม่งั้น `flutter test` จะไม่รัน
- ตัวช่วยที่ใช้ร่วมกันวางใน `test/helpers/`
