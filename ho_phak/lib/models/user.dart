class AppUser {
  final String name;
  final String email;
  final String phone;
  final String? avatarUrl;

  const AppUser({
    required this.name,
    required this.email,
    required this.phone,
    this.avatarUrl,
  });

  AppUser copyWith({
    String? name,
    String? email,
    String? phone,
    String? avatarUrl,
    bool clearAvatar = false,
  }) {
    return AppUser(
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatarUrl: clearAvatar ? null : (avatarUrl ?? this.avatarUrl),
    );
  }
}