# เทสต์ unit (controller, service, utils) แยกตามผู้รับผิดชอบ

| ผู้รับผิดชอบ | บทบาท | ไฟล์ | โฟลเดอร์ |
|---|---|---|---|
| Bank | แอดมิน | Owner requests, Dorms, Users, Dashboard, รายละเอียดผู้ใช้ | `admin/bank/` |
| Plem | แอดมิน | Amenities, Profile, Settings, Activity log, Reviews | `admin/plem/` |
| Plub | เจ้าของหอ | Dashboard, ฟอร์มหอ, รายละเอียดหอ, เลือกตำแหน่ง, extras, controller รวม | `owner/plub/` |
| Kelu | เจ้าของหอ | บัญชี (โปรไฟล์, รหัสผ่าน, การแจ้งเตือน), รีวิว และการยืนยันตัวตน | `owner/kelu/` |
| Big | นักศึกษา | controller ของนักศึกษา (หน้าหลัก, ค้นหา, รายละเอียดหอ, โปรด) | `student/big/` |
| Karn | นักศึกษา | เข้าสู่ระบบ/สมัคร, แชท, การแจ้งเตือน | `student/karn/` |
| ส่วนกลาง | – | api_client, format | `services/`, `ui/` |

ไฟล์ `admin/dormitory_document_test.dart` เกี่ยวกับการดาวน์โหลดเอกสารหอของแอดมิน จึงอยู่ที่ `admin/` ไม่ได้แยกไปคนใด
บรรทัดแรกของทุกไฟล์บอกผู้รับผิดชอบ
