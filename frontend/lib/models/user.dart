int _toInt(dynamic v) => v is num ? v.toInt() : int.parse(v.toString());

bool _toBool(dynamic v) => v == true || v == 1 || v == '1';

/// ผลจาก GET /api/me → { user: { id, username, role, status, is_verified } }
class CurrentUser {
  CurrentUser({
    required this.id,
    required this.role,
    required this.status,
    required this.isVerified,
    this.username,
  });

  final int id;
  final String role;
  final String status;
  final bool isVerified;
  final String? username;

  bool get isOwner => role == 'owner';
  bool get isStudent => role == 'student';
  bool get isAdmin => role == 'admin';
  bool get isSuspended => status == 'suspended';

  factory CurrentUser.fromJson(Map<String, dynamic> json) => CurrentUser(
    id: _toInt(json['id']),
    role: json['role'] as String,
    status: (json['status'] as String?) ?? 'active',
    isVerified: _toBool(json['is_verified']),
    username: json['username'] as String?,
  );
}
