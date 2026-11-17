# เทสต์ widget แยกตามผู้รับผิดชอบ

ทุกไฟล์ในโฟลเดอร์นี้เป็นเทสต์ widget (`testWidgets`) ของหน้าจอ ชื่อโฟลเดอร์บอกผู้รับผิดชอบ
ส่วนเทสต์ controller/service อยู่ที่ `test/unit/`

| ผู้รับผิดชอบ | บทบาท | หน้าที่ทดสอบ | โฟลเดอร์ |
|---|---|---|---|
| Bank | แอดมิน | Dashboard, Owner requests, Dorms, Users, รายละเอียดผู้ใช้ | `admin/bank/` |
| Plem | แอดมิน | Reviews, Activity log, Amenities, Settings, Profile | `admin/plem/` |
| Plub | เจ้าของหอ | Dashboard, ฟอร์มหอ, รายละเอียดหอ, เลือกตำแหน่ง | `owner/plub/` |
| Kelu | เจ้าของหอ | ยืนยันตัวตน, รีวิว, โปรไฟล์, แก้ไขโปรไฟล์, เปลี่ยนรหัสผ่าน, การแจ้งเตือน | `owner/kelu/` |
| Big | นักศึกษา | หน้าหลัก, ค้นหา, รายละเอียดหอ, รายการโปรด | `student/big/` (home, search, dorm_detail, favorites) |
| Karn | นักศึกษา | โปรไฟล์, แชท, การแจ้งเตือน, เข้าสู่ระบบ/สมัครสมาชิก | `student/karn/` (profile, auth_screens, chat_and_notifications) |
| ส่วนกลาง | – | responsive layout | `shared/` |

**กติกา**
- บรรทัดแรกของทุกไฟล์บอกผู้รับผิดชอบ
- ชื่อไฟล์ตั้งตามหน้าจอ เช่น `dorms_test.dart`
- เทสต์ใหม่ให้วางไว้ในโฟลเดอร์ของตัวเอง
- เทสต์หน้าของนักศึกษาใช้ `test/helpers/test_services.dart` (`studentServicesWith`) ที่ใช้บริการจริงผ่าน MockClient
