class UserModel {
  final String id;
  final String phone;
  final String name;
  final String email;
  final String role; // 'customer', 'rider', 'admin'
  final bool ageConfirmed;
  final bool isOnline;
  final String? vehicleNumber;
  final String? avatarUrl;

  UserModel({
    required this.id,
    required this.phone,
    required this.name,
    this.email = '',
    this.role = 'customer',
    this.ageConfirmed = false,
    this.isOnline = false,
    this.vehicleNumber,
    this.avatarUrl,
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
      avatarUrl: json['avatarUrl'] ?? json['avatar'],
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
    'avatarUrl': avatarUrl,
  };

  UserModel copyWith({
    String? id,
    String? phone,
    String? name,
    String? email,
    String? role,
    bool? ageConfirmed,
    bool? isOnline,
    String? vehicleNumber,
    String? avatarUrl,
  }) {
    return UserModel(
      id: id ?? this.id,
      phone: phone ?? this.phone,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      ageConfirmed: ageConfirmed ?? this.ageConfirmed,
      isOnline: isOnline ?? this.isOnline,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}
