class UserModel {
  final String id;
  final String name;
  final String email;
  final String role; // 'admin' | 'employee'
  final String? phone;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    required this.createdAt,
  });

  bool get isAdmin => role == 'admin';

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'employee',
      phone: json['phone'],
      createdAt: json['created_at'] is DateTime 
          ? json['created_at'] 
          : (DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now()),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role,
        'phone': phone,
        'created_at': createdAt.toIso8601String(),
      };

  Map<String, dynamic> toInsertJson() => {
        'name': name,
        'email': email,
        'role': role,
        if (phone != null) 'phone': phone,
      };

  @override
  String toString() => 'UserModel($id, $name, $role)';
}
