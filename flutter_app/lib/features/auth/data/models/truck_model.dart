class TruckModel {
  final int id;
  final int companyId;
  final String plateNumber;
  final String brand;
  final String model;
  final int year;
  final String type;
  final double capacity;
  final String status;
  final int mileage;
  final String fuelType;
  final String? color;
  final String? vin;
  final String? photo;
  final String? insuranceExpiry;
  final String? technicalControlExpiry;
  final String? notes;
  final String? insuranceStatus;
  final String? proprietaire;
  final String? telephoneProprietaire;
  final String? villeActuelle;
  // Chauffeur assigné au camion
  final Map<String, dynamic>? driver;
  // Transport actif (voyage en cours)
  final Map<String, dynamic>? activeTransport;
  final String? createdAt;
  final String? updatedAt;

  const TruckModel({
    required this.id,
    required this.companyId,
    required this.plateNumber,
    required this.brand,
    required this.model,
    required this.year,
    required this.type,
    required this.capacity,
    required this.status,
    required this.mileage,
    required this.fuelType,
    this.color,
    this.vin,
    this.photo,
    this.insuranceExpiry,
    this.technicalControlExpiry,
    this.notes,
    this.insuranceStatus,
    this.proprietaire,
    this.telephoneProprietaire,
    this.villeActuelle,
    this.driver,
    this.activeTransport,
    this.createdAt,
    this.updatedAt,
  });

  factory TruckModel.fromJson(Map<String, dynamic> json) => TruckModel(
    id:                      json['id'] as int,
    companyId:               json['company_id'] as int,
    plateNumber:             json['plate_number'] as String,
    brand:                   json['brand'] as String,
    model:                   json['model'] as String,
    year:                    json['year'] as int,
    type:                    json['type'] as String,
    // Le backend peut retourner capacity comme int ou double
    capacity:                (json['capacity'] as num).toDouble(),
    status:                  json['status'] as String,
    mileage:                 (json['mileage'] as num?)?.toInt() ?? 0,
    fuelType:                json['fuel_type'] as String? ?? 'diesel',
    color:                   json['color'] as String?,
    vin:                     json['vin'] as String?,
    photo:                   json['photo'] as String?,
    // Le backend retourne des timestamps ISO 8601
    insuranceExpiry:         json['insurance_expiry'] as String?,
    technicalControlExpiry:  json['technical_control_expiry'] as String?,
    notes:                   json['notes'] as String?,
    insuranceStatus:         json['insurance_status'] as String?,
    proprietaire:            json['proprietaire'] as String?,
    telephoneProprietaire:   json['telephone_proprietaire'] as String?,
    villeActuelle:           json['ville_actuelle'] as String?,
    driver:                  json['driver'] as Map<String, dynamic>?,
    activeTransport:         json['active_transport'] as Map<String, dynamic>?,
    createdAt:               json['created_at'] as String?,
    updatedAt:               json['updated_at'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'plate_number': plateNumber,
    'brand': brand,
    'model': model,
    'year': year,
    'type': type,
    'capacity': capacity,
    'status': status,
    'mileage': mileage,
    'fuel_type': fuelType,
    if (color != null) 'color': color,
    if (vin != null) 'vin': vin,
    if (notes != null) 'notes': notes,
    if (insuranceExpiry != null) 'insurance_expiry': insuranceExpiry,
    if (technicalControlExpiry != null) 'technical_control_expiry': technicalControlExpiry,
    if (proprietaire != null) 'proprietaire': proprietaire,
    if (telephoneProprietaire != null) 'telephone_proprietaire': telephoneProprietaire,
    if (villeActuelle != null) 'ville_actuelle': villeActuelle,
  };

  String get displayName => '$brand $model ($plateNumber)';
  bool get isAvailable   => status == 'available';
  bool get isOnMission   => status == 'on_mission';
  bool get isMaintenance => status == 'maintenance';
  bool get isOutOfService => status == 'out_of_service';
}
