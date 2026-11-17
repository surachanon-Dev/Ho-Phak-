// แอปพรีวิวสำหรับนักพัฒนา: เปิดหน้า admin / owner ด้วยข้อมูลจำลอง ไม่ต้องมี backend
// รัน: flutter run -d chrome -t dev/preview_main.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hopak_frontend/core/app_services.dart';
import 'package:hopak_frontend/core/network/api_client.dart';
import 'package:hopak_frontend/core/theme/app_theme.dart';
import 'package:hopak_frontend/features/admin/admin_home_screen.dart';
import 'package:hopak_frontend/features/owner/screens/owner_shell.dart';
import 'package:hopak_frontend/features/student/screens/student_shell.dart';
import 'package:hopak_frontend/shared/models/user.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  final services = PreviewServices(
    ApiClient(
      tokenProvider: () => 'preview-token',
      client: MockClient((req) async => _route(req)),
    ),
  );
  runApp(
    MaterialApp(
      title: 'Ho-Phak preview',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: _Picker(services: services),
    ),
  );
}

/// AppServices ที่ใช้ ApiClient จำลอง (getter ของ api ถูกแทนที่)
class PreviewServices extends AppServices {
  PreviewServices(this._mock) : super(localOwnerExtras: false);

  final ApiClient _mock;

  @override
  ApiClient get api => _mock;
}

class _Picker extends StatelessWidget {
  const _Picker({required this.services});

  final AppServices services;

  @override
  Widget build(BuildContext context) {
    final owner = CurrentUser(
      id: 30,
      role: 'owner',
      status: 'active',
      isVerified: true,
      username: 'somchai',
    );
    final unverified = CurrentUser(
      id: 31,
      role: 'owner',
      status: 'active',
      isVerified: false,
      username: 'newowner',
    );
    final student = CurrentUser(
      id: 40,
      role: 'student',
      status: 'active',
      isVerified: false,
      username: 'Big',
    );
    void go(Widget w) =>
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => w));
    return Scaffold(
      body: Center(
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            FilledButton(
              key: const Key('admin'),
              onPressed: () => go(AdminHomeScreen(services: services)),
              child: const Text('Admin'),
            ),
            FilledButton(
              key: const Key('owner'),
              onPressed: () => go(OwnerShell(services: services, user: owner)),
              child: const Text('Owner'),
            ),
            FilledButton(
              key: const Key('student'),
              onPressed: () =>
                  go(StudentShell(services: services, user: student)),
              child: const Text('Student'),
            ),
            OutlinedButton(
              key: const Key('unverified'),
              onPressed: () =>
                  go(OwnerShell(services: services, user: unverified)),
              child: const Text('Owner (unverified)'),
            ),
          ],
        ),
      ),
    );
  }
}

http.Response _json(Object data, [int status = 200]) => http.Response(
  jsonEncode(data),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

final _dorms = [
  {
    'id': 1,
    'name': 'หอพักบ้านสวนแม่ฟ้า',
    'zone': 'หน้ามอ',
    'latitude': 20.045,
    'longitude': 99.894,
    'price_per_month': 3200,
    'total_rooms': 24,
    'available_rooms': 6,
    'status': 'published',
    'water_rate': 18,
    'water_billing_type': 'per_unit',
    'electricity_rate': 7,
    'electricity_billing_type': 'per_unit',
    'description':
        'ห้องกว้าง เงียบสงบ ใกล้ประตูหน้ามหาวิทยาลัย เดินไปเซเว่น 2 นาที',
    'address': '123 หมู่ 9 ต.ท่าสุด อ.เมือง จ.เชียงราย',
    'contact_phone': '0812345678',
    'amenity_ids': [1, 2, 3, 5],
    'images': [],
  },
  {
    'id': 2,
    'name': 'Hillview Residence',
    'zone': 'หลังมอ',
    'latitude': 20.05,
    'longitude': 99.89,
    'price_per_month': 4500,
    'total_rooms': 30,
    'available_rooms': 0,
    'status': 'pending',
    'images': [],
  },
  {
    'id': 3,
    'name': 'คชพล เพลส',
    'zone': 'คชพลแลนด์',
    'latitude': 20.04,
    'longitude': 99.88,
    'price_per_month': 2800,
    'total_rooms': 16,
    'available_rooms': 3,
    'status': 'rejected',
    'rejection_reason': 'รูปภาพไม่ชัด กรุณาอัปโหลดรูปห้องใหม่',
    'images': [],
  },
];

final _amenities = [
  {'id': 1, 'name': 'Wi-Fi'},
  {'id': 2, 'name': 'Air conditioner'},
  {'id': 3, 'name': 'Parking'},
  {'id': 4, 'name': 'Laundry'},
  {'id': 5, 'name': 'CCTV'},
  {'id': 6, 'name': 'Water heater'},
  {'id': 7, 'name': 'Refrigerator'},
  {'id': 8, 'name': 'Key card'},
];

final _users = [
  {
    'id': 30,
    'username': 'somchai',
    'first_name': 'สมชาย',
    'surname': 'ใจดี',
    'phone': '0812345678',
    'role': 'owner',
    'status': 'active',
    'is_verified': 1,
    'created_at': '2026-10-02T10:00:00Z',
  },
  {
    'id': 41,
    'username': 'nina',
    'first_name': 'Nina',
    'surname': 'Park',
    'phone': '0898765432',
    'role': 'student',
    'status': 'suspended',
    'suspension_reason': 'Spam reviews',
    'suspended_at': '2026-11-12T08:30:00Z',
    'created_at': '2026-09-15T10:00:00Z',
  },
  {
    'id': 42,
    'username': 'beam',
    'first_name': 'Beam',
    'surname': 'Chai',
    'phone': '0861112222',
    'role': 'student',
    'status': 'active',
    'created_at': '2026-11-01T10:00:00Z',
  },
  {
    'id': 7,
    'username': 'Test Admin',
    'phone': '0800000000',
    'role': 'admin',
    'status': 'active',
    'is_verified': 1,
    'created_at': '2026-01-01T10:00:00Z',
  },
];

final _verifications = [
  {
    'id': 7,
    'owner_id': 50,
    'document_url': 'private_uploads/business-licence.png',
    'status': 'pending',
    'submitted_at': '2026-11-16T05:42:05Z',
    'first_name': 'Pim',
    'surname': 'Suksan',
    'owner_phone': '0899900003',
  },
  {
    'id': 8,
    'owner_id': 51,
    'document_url': 'private_uploads/id-card.jpg',
    'status': 'pending',
    'submitted_at': '2026-11-15T09:12:00Z',
    'first_name': 'Krit',
    'surname': 'Wong',
    'owner_phone': '0811122233',
  },
];

final _adminReviews = [
  {
    'id': 9,
    'dormitory_id': 1,
    'dormitory_name': 'หอพักบ้านสวนแม่ฟ้า',
    'rating': 2,
    'body': 'Water pressure is weak at night and the Wi-Fi drops often.',
    'author': 'Nina Park',
    'created_at': '2026-11-08',
    'reporter_name': 'สมชาย ใจดี',
    'report_reason': 'This student never stayed here.',
    'status': 'pending',
  },
];

final _logs = [
  for (final (i, a) in [
    'dormitory.approve',
    'verification.approve',
    'review.hide',
    'user.suspend',
    'amenity.create',
  ].indexed)
    {
      'id': 30 + i,
      'action': a,
      'admin_name': 'Test Admin',
      'target_type': a.split('.').first,
      'target_id': 10 + i,
      'created_at': '2026-11-1${6 - i % 3} 09:${10 + i}',
    },
];

// ---- นักศึกษา (หอที่เผยแพร่แล้ว พิกัดรอบมหาวิทยาลัยแม่ฟ้าหลวง) ----
final _publicDorms = [
  {
    'id': 1,
    'name': 'หอพักบ้านสวนแม่ฟ้า',
    'zone': 'หน้ามอ',
    'latitude': 19.8822,
    'longitude': 99.8361,
    'price_per_month': 3200,
    'total_rooms': 24,
    'available_rooms': 6,
    'status': 'published',
    'water_rate': 18,
    'water_billing_type': 'per_unit',
    'electricity_rate': 7,
    'electricity_billing_type': 'per_unit',
    'rating_avg': 4.6,
    'review_count': 12,
  },
  {
    'id': 3,
    'name': 'คชพล เพลส',
    'zone': 'คชพลแลนด์',
    'latitude': 19.8745,
    'longitude': 99.8290,
    'price_per_month': 2800,
    'total_rooms': 18,
    'available_rooms': 2,
    'status': 'published',
    'rating_avg': 4.1,
    'review_count': 5,
  },
  {
    'id': 5,
    'name': 'สกายไลน์ อพาร์ทเม้นท์',
    'zone': 'หลังมอ',
    'latitude': 19.8718,
    'longitude': 99.8355,
    'price_per_month': 5000,
    'total_rooms': 20,
    'available_rooms': 0,
    'status': 'published',
    'rating_avg': null,
    'review_count': 0,
  },
  {
    'id': 6,
    'name': 'The Nest MFU',
    'zone': 'หน้ามอ',
    'latitude': 19.8840,
    'longitude': 99.8402,
    'price_per_month': 3900,
    'total_rooms': 32,
    'available_rooms': 11,
    'status': 'published',
    'rating_avg': 3.8,
    'review_count': 3,
  },
];

http.Response? _studentRoute(http.Request req) {
  final p = req.url.path;
  final q = req.url.queryParameters;
  if (p == '/api/dormitories') {
    var list = _publicDorms.where((d) {
      if (q['zone'] != null && d['zone'] != q['zone']) return false;
      if (q['hasRooms'] == '1' && (d['available_rooms'] as int) <= 0) {
        return false;
      }
      final kw = q['q'];
      if (kw != null && !(d['name'] as String).contains(kw)) return false;
      return true;
    }).toList();
    if (q['sort'] == 'price_asc' || q['sort'] == 'price_desc') {
      list.sort(
        (a, b) => (a['price_per_month'] as int).compareTo(
          b['price_per_month'] as int,
        ),
      );
      if (q['sort'] == 'price_desc') list = list.reversed.toList();
    }
    return _json({'dormitories': list});
  }
  final m = RegExp(r'^/api/dormitories/(\d+)(/reviews)?$').firstMatch(p);
  if (m != null) {
    final id = int.parse(m.group(1)!);
    if (m.group(2) != null) {
      return _json({
        'reviews': id == 1
            ? [
                {
                  'id': 1,
                  'rating': 5,
                  'body': 'ห้องสะอาด เจ้าของใจดี เดินไปมอได้',
                  'created_at': '2026-11-02T10:00:00Z',
                },
                {
                  'id': 2,
                  'rating': 4,
                  'body': 'เน็ตเร็ว แต่ที่จอดรถน้อย',
                  'created_at': '2026-10-21T10:00:00Z',
                },
              ]
            : [],
      });
    }
    final d = _publicDorms.firstWhere(
      (e) => e['id'] == id,
      orElse: () => _publicDorms.first,
    );
    return _json({
      'dormitory': {
        ...d,
        'description':
            'ห้องกว้าง เงียบสงบ ใกล้ประตูหน้ามหาวิทยาลัย เดินไปเซเว่น 2 นาที',
        'address': '123 หมู่ 9 ต.ท่าสุด อ.เมือง จ.เชียงราย',
        'contact_phone': '0812345678',
        'amenities': [
          {'id': 1, 'name': 'Wi-Fi'},
          {'id': 2, 'name': 'แอร์'},
          {'id': 3, 'name': 'ที่จอดรถ'},
          {'id': 5, 'name': 'กล้องวงจรปิด'},
        ],
        'images': [],
      },
    });
  }
  if (p == '/api/favorites') {
    return _json({
      'favorites': [
        {
          'id': 1,
          'name': 'หอพักบ้านสวนแม่ฟ้า',
          'zone': 'หน้ามอ',
          'price_per_month': 3200,
          'status': 'published',
          'saved_at': '2026-11-10T10:00:00Z',
        },
        {
          'id': 9,
          'name': 'Green Garden',
          'zone': 'หลังมอ',
          'price_per_month': 3000,
          'status': 'hidden',
          'saved_at': '2026-11-01T10:00:00Z',
        },
      ],
    });
  }
  return null;
}

http.Response _route(http.Request req) {
  final p = req.url.path;
  final status = req.url.queryParameters['status'];
  if (req.method != 'GET')
    return _json({'ok': true, 'id': 99, 'status': 'hidden'});
  final student = _studentRoute(req);
  if (student != null) return student;

  // ---- admin ----
  if (p == '/api/admin/queue') {
    return _json({
      'new_dormitories': [_dorms[1]],
      'revisions': [
        {
          ..._dorms[0],
          'dormitory_id': 1,
          'dormitory_name': _dorms[0]['name'],
          'owner_username': 'somchai',
        },
      ],
      'verifications': _verifications,
    });
  }
  if (p == '/api/admin/verifications') {
    if (status == 'pending' || status == null) {
      return _json({'verifications': _verifications});
    }
    if (status == 'rejected') {
      return _json({
        'verifications': [
          {
            ..._verifications.first,
            'id': 3,
            'status': 'rejected',
            'first_name': 'Arthit',
            'reviewed_at': '2026-11-10T08:00:00Z',
            'rejection_reason': 'The document is blurry.',
          },
        ],
      });
    }
    return _json({
      'verifications': [
        {
          ..._verifications.last,
          'id': 2,
          'status': 'approved',
          'first_name': 'Somchai',
        },
      ],
    });
  }
  if (p == '/api/admin/dormitories') {
    final list = [
      for (final d in _dorms)
        {...d, 'owner_username': 'somchai', 'owner_id': 30},
      {..._dorms.first, 'id': 4, 'name': 'The Nest MFU', 'status': 'suspended'},
    ];
    return _json({
      'dormitories': status == null
          ? list
          : list.where((d) => d['status'] == status).toList(),
    });
  }
  if (p == '/api/admin/users') {
    return _json({
      'users': status == null
          ? _users
          : _users.where((u) => u['status'] == status).toList(),
    });
  }
  if (p == '/api/admin/reviews') {
    return _json({
      'reviews': status == 'pending' || status == null ? _adminReviews : [],
    });
  }
  if (p == '/api/admin/logs') return _json({'logs': _logs});
  if (p == '/api/admin/amenities' || p == '/api/amenities') {
    return _json({'amenities': _amenities});
  }
  if (p == '/api/me') {
    return _json({
      'user': {
        'id': 7,
        'username': 'Test Admin',
        'phone': '0800000000',
        'role': 'admin',
        'status': 'active',
        'is_verified': 1,
      },
    });
  }

  // ---- owner ----
  if (p == '/api/owner/dormitories') return _json({'dormitories': _dorms});
  final dormMatch = RegExp(r'^/api/owner/dormitories/(\d+)$').firstMatch(p);
  if (dormMatch != null) {
    final id = int.parse(dormMatch.group(1)!);
    return _json({'dormitory': _dorms.firstWhere((d) => d['id'] == id)});
  }
  if (p.endsWith('/utilities')) {
    return _json({'water': 'set_price', 'electricity': 'set_price'});
  }
  if (p.endsWith('/reviews')) {
    return _json({
      'reviews': [
        {
          'id': 9,
          'rating': 2,
          'body': 'Water pressure is weak at night and the Wi-Fi drops often.',
          'created_at': '2026-11-08',
        },
        {
          'id': 10,
          'rating': 5,
          'body': 'เจ้าของใจดีมาก ห้องสะอาด ใกล้มหาลัย แนะนำเลยครับ',
          'created_at': '2026-11-02',
        },
        {
          'id': 11,
          'rating': 4,
          'body': 'Quiet and clean. Parking is a bit tight.',
          'created_at': '2026-10-20',
        },
      ],
    });
  }
  if (p == '/api/owner/review-reports') {
    return _json({
      'reports': [
        {'review_id': 9, 'reason': 'This student never stayed here.'},
      ],
    });
  }
  if (p == '/api/me/profile') {
    return _json({
      'profile': {
        'first_name': 'สมชาย',
        'surname': 'ใจดี',
        'phone': '0812345678',
        'pending_phone': null,
      },
    });
  }
  if (p == '/api/me/notification-settings') {
    return _json({'messages': true, 'approvals': true, 'reviews': false});
  }
  if (p == '/api/owner/verification') {
    return _json({
      'verification': {
        'status': 'rejected',
        'document_url': 'private_uploads/id.png',
        'reason': 'The document is blurry — please upload a clear photo.',
      },
    });
  }
  if (p == '/api/conversations') {
    return _json({
      'conversations': [
        {
          'id': 1,
          'tenant_id': 41,
          'tenant_name': 'Nina Park',
          'dormitory_name': 'หอพักบ้านสวนแม่ฟ้า',
          'dormitory_status': 'published',
          'unread_count': 2,
          'last_message': 'Is there a room available next month?',
          'last_sent_at': DateTime.now().toIso8601String(),
        },
        {
          'id': 2,
          'tenant_id': 42,
          'tenant_name': 'Beam Chai',
          'dormitory_name': 'Hillview Residence',
          'dormitory_status': 'pending',
          'unread_count': 0,
          'last_message': 'ขอบคุณครับ',
          'last_sent_at': '2026-11-14T09:00:00Z',
        },
      ],
    });
  }
  if (RegExp(r'^/api/conversations/\d+/messages$').hasMatch(p) ||
      RegExp(r'^/api/conversations/\d+$').hasMatch(p)) {
    return _json({
      'messages': [
        {
          'id': 1,
          'sender_id': 41,
          'body': 'สวัสดีค่ะ ยังมีห้องว่างไหมคะ',
          'sent_at': '2026-11-17T09:00:00Z',
        },
        {
          'id': 2,
          'sender_id': 30,
          'body': 'มีครับ ว่าง 6 ห้อง แวะมาดูได้ทุกวันครับ',
          'sent_at': '2026-11-17T09:05:00Z',
          'read_at': '2026-11-17T09:06:00Z',
        },
        {
          'id': 3,
          'sender_id': 41,
          'body': 'Is there a room available next month?',
          'sent_at': '2026-11-17T09:10:00Z',
        },
      ],
      'read_only': false,
    });
  }
  if (p == '/api/notifications') {
    return _json({
      'notifications': [
        {
          'id': 1,
          'type': 'dorm_approved',
          'title': 'Dorm approved',
          'body': 'หอพักบ้านสวนแม่ฟ้า is now live.',
          'created_at': '2026-11-16T10:00:00Z',
          'read_at': null,
        },
        {
          'id': 2,
          'type': 'new_review',
          'title': 'New review',
          'body': 'Someone reviewed Hillview Residence.',
          'created_at': '2026-11-14T10:00:00Z',
          'read_at': '2026-11-14T11:00:00Z',
        },
      ],
    });
  }
  return _json({'error': 'not found: $p'}, 404);
}
