# Keys the Frontend team needs to add (for Widget Tests)

The widget tests find widgets by `Key`. Ask P2, P4 and P6 to add a `key:` to these widgets.

| Page | Widget | Key |
| --- | --- | --- |
| Login | Username field | `Key('login_username')` |
| Login | Password field | `Key('login_password')` |
| Login | Eye button (show/hide password) | `Key('login_toggle_password')` |
| Login | Login button | `Key('login_submit')` |
| Login | "Sign up" link | `Key('login_go_register')` |
| Register | Username field | `Key('register_username')` |
| Register | Password field | `Key('register_password')` |
| Register | Confirm password field | `Key('register_confirm')` |
| Register | Upload document button (Owner) | `Key('register_upload_doc')` |
| Register | Sign up button | `Key('register_submit')` |
| Dorm form (Owner) | Name field | `Key('dorm_name')` |
| Dorm form (Owner) | Price field | `Key('dorm_price')` |
| Dorm form (Owner) | Zone dropdown | `Key('dorm_zone')` |
| Dorm form (Owner) | Save button | `Key('dorm_save')` |
| Search (Student) | Search box | `Key('search_input')` |
| Search (Student) | Zone chip | `Key('zone_chip_หน้ามอ')` and so on |

Example:

```dart
TextFormField(
  key: const Key('login_username'),
  decoration: const InputDecoration(labelText: 'ชื่อผู้ใช้'),
)
```
