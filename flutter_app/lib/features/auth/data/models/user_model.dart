class UserModel {
  final int id;
  final int? companyId;
  final String name;
  final String email;
  final String role;
  final bool isActive;
  final String? avatar;
  final String? avatarUrl;
  final String? phone;
  final CompanyModel? company;

  const UserModel({
    required this.id,
    this.companyId,
    required this.name,
    required this.email,
    required this.role,
    required this.isActive,
    this.avatar,
    this.avatarUrl,
    this.phone,
    this.company,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id:        json['id'] as int,
    companyId: json['company_id'] as int?,
    name:      json['name'] as String,
    email:     json['email'] as String,
    role:      json['role'] as String? ?? 'driver',
    isActive:  json['is_active'] as bool? ?? true,
    avatar:    json['avatar'] as String?,
    avatarUrl: json['avatar_url'] as String?,
    phone:     json['phone'] as String?,
    company:   json['company'] != null
        ? CompanyModel.fromJson(json['company'] as Map<String, dynamic>)
        : null,
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'company_id': companyId, 'name': name,
    'email': email, 'role': role, 'is_active': isActive,
    'avatar': avatar, 'avatar_url': avatarUrl, 'phone': phone,
  };

  bool get isAdmin    => role == 'admin';
  bool get isManager  => ['admin', 'manager'].contains(role);
  bool get isDriver   => role == 'driver';

  String get displayAvatar =>
      avatarUrl ?? 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(name)}&background=1E40AF&color=fff';
}

class CompanyModel {
  final int id;
  final String name;
  final String? email;
  final String? phone;
  final String? logo;
  final String subscriptionPlan;

  const CompanyModel({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.logo,
    required this.subscriptionPlan,
  });

  factory CompanyModel.fromJson(Map<String, dynamic> json) => CompanyModel(
    id:               json['id'] as int,
    name:             json['name'] as String,
    email:            json['email'] as String?,
    phone:            json['phone'] as String?,
    logo:             json['logo'] as String?,
    subscriptionPlan: json['subscription_plan'] as String? ?? 'trial',
  );
}
