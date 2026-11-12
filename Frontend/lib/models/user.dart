import 'json_utils.dart';

/// Table: users
class AppUser {
  final int id;
  final String? username;
  final String phone;
  final String role; // student | owner | admin
  final bool isVerified; // owner verified by admin
  final String status; // active | suspended
  final String? suspensionReason;
  final DateTime? suspendedAt;
  final DateTime? createdAt;

  const AppUser({
    required this.id,
    this.username,
    required this.phone,
    required this.role,
    this.isVerified = false,
    this.status = 'active',
    this.suspensionReason,
    this.suspendedAt,
    this.createdAt,
  });

  String get displayName => (username ?? '').isNotEmpty ? username! : phone;
  bool get isStudent => role == 'student';
  bool get isOwner => role == 'owner';
  bool get isAdmin => role == 'admin';
  bool get isSuspended => status == 'suspended';

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
        id: asInt(j['id']),
        username: j['username']?.toString(),
        phone: asStr(j['phone']),
        role: asStr(j['role'], 'student'),
        isVerified: asInt(j['is_verified']) == 1 || j['is_verified'] == true,
        status: asStr(j['status'], 'active'),
        suspensionReason: j['suspension_reason']?.toString(),
        suspendedAt: asDate(j['suspended_at']),
        createdAt: asDate(j['created_at']),
      );
}
