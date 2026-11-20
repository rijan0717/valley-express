class UserModel {
  final String id;
  final String phone;
  final String name;
  final String email;
  final String role; // 'customer', 'rider', 'admin'
  final bool ageConfirmed;
  final bool isOnline;
  final String? vehicleNumber;

  UserModel({
    required this.id,
    required this.phone,
    required this.name,
    this.email = '',
    this.role = 'customer',
    this.ageConfirmed = false,
    this.isOnline = false,
    this.vehicleNumber,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? json['_id'] ?? '',
      phone: json['phone'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'customer',
      ageConfirmed: json['ageConfirmed'] ?? false,
      isOnline: json['isOnline'] ?? false,
      vehicleNumber: json['vehicleNumber'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'phone': phone,
    'name': name,
    'email': email,
    'role': role,
    'ageConfirmed': ageConfirmed,
    'isOnline': isOnline,
    'vehicleNumber': vehicleNumber,
  };
}
