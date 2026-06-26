class DriverModel {
  final int id;
  final int companyId;
  final String firstName;
  final String lastName;
  final String phone;
  final String? email;
  final String licenseNumber;
  final String licenseType;
  final String licenseExpiry;
  final String status;
  final String? avatar;
  final int? currentTruckId;
  final Map<String, dynamic>? truck; // Camion assigné au chauffeur
  final String? notes;
  final String? licenseStatus;
  // Champs supplémentaires retournés par le backend
  final String? dateOfBirth;
  final String? address;
  final String? city;
  final String? country;
  final String? createdAt;
  final String? updatedAt;

  const DriverModel({
    required this.id,
    required this.companyId,
    required this.firstName,
    required this.lastName,
    required this.phone,
    this.email,
    required this.licenseNumber,
    required this.licenseType,
    required this.licenseExpiry,
    required this.status,
    this.avatar,
    this.currentTruckId,
    this.truck,
    this.notes,
    this.licenseStatus,
    this.dateOfBirth,
    this.address,
    this.city,
    this.country,
    this.createdAt,
    this.updatedAt,
  });

  factory DriverModel.fromJson(Map<String, dynamic> json) => DriverModel(
    id:             json['id'] as int,
    companyId:      json['company_id'] as int,
    firstName:      json['first_name'] as String,
    lastName:       json['last_name'] as String,
    phone:          json['phone'] as String,
    email:          json['email'] as String?,
    licenseNumber:  json['license_number'] as String,
    licenseType:    json['license_type'] as String,
    licenseExpiry:  json['license_expiry'] as String,
    status:         json['status'] as String,
    avatar:         json['avatar'] as String?,
    currentTruckId: json['current_truck_id'] as int?,
    truck:          json['truck'] as Map<String, dynamic>?,
    notes:          json['notes'] as String?,
    licenseStatus:  json['license_status'] as String?,
    dateOfBirth:    json['date_of_birth'] as String?,
    address:        json['address'] as String?,
    city:           json['city'] as String?,
    country:        json['country'] as String?,
    createdAt:      json['created_at'] as String?,
    updatedAt:      json['updated_at'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'first_name': firstName,
    'last_name': lastName,
    'phone': phone,
    if (email != null) 'email': email,
    'license_number': licenseNumber,
    'license_type': licenseType,
    'license_expiry': licenseExpiry,
    'status': status,
    if (notes != null) 'notes': notes,
    if (dateOfBirth != null) 'date_of_birth': dateOfBirth,
    if (address != null) 'address': address,
    if (city != null) 'city': city,
    if (country != null) 'country': country,
  };

  String get fullName    => '$firstName $lastName';
  String get displayName => fullName; // alias pour compatibilité
  bool get isAvailable   => status == 'available';
  bool get isOnMission   => status == 'on_mission';

  String get displayAvatar =>
      avatar ?? 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(fullName)}&background=1E40AF&color=fff';
}
