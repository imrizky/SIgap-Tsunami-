class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    this.location,
  });

  final int id;
  final String name;
  final String email;
  final String role;
  final String? phone;
  final String? location;

  bool get isWarga => role == 'warga';
  bool get isRelawan => role == 'relawan';
  bool get isPetugas => role == 'petugas';
  bool get isAdmin => role == 'admin';

  String get roleLabel {
    switch (role) {
      case 'admin':
        return 'Administrator';
      case 'petugas':
        return 'Petugas BPBD/SAR';
      case 'relawan':
        return 'Relawan Lapangan';
      case 'warga':
      default:
        return 'Warga';
    }
  }

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
    id: json['id'] is int
        ? json['id'] as int
        : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
    name: json['name']?.toString() ?? 'Pengguna',
    email: json['email']?.toString() ?? '',
    role: json['role']?.toString().toLowerCase() ?? 'warga',
    phone: json['phone']?.toString(),
    location: json['location']?.toString(),
  );
}
