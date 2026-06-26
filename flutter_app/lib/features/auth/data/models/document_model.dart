class DocumentModel {
  final int id;
  final int companyId;
  final String documentableType; // 'App\\Models\\Truck' ou 'App\\Models\\Driver'
  final int documentableId;
  final String type; // carte_grise, assurance, visite_technique, vignette
  final String name;
  final String filePath;
  final String? expiryDate;
  final String? notes;
  final String? status; // permanent, valid, expiring_soon, expired
  final String? createdAt;

  const DocumentModel({
    required this.id,
    required this.companyId,
    required this.documentableType,
    required this.documentableId,
    required this.type,
    required this.name,
    required this.filePath,
    this.expiryDate,
    this.notes,
    this.status,
    this.createdAt,
  });

  factory DocumentModel.fromJson(Map<String, dynamic> json) => DocumentModel(
    id:                 json['id'] as int,
    companyId:          json['company_id'] as int,
    documentableType:   json['documentable_type'] as String? ?? '',
    documentableId:     json['documentable_id'] as int? ?? 0,
    type:               json['type'] as String,
    name:               json['name'] as String,
    filePath:           json['file_path'] as String,
    expiryDate:         json['expiry_date'] as String?,
    notes:              json['notes'] as String?,
    status:             json['status'] as String?,
    createdAt:          json['created_at'] as String?,
  );

  bool get isExpired       => status == 'expired';
  bool get isExpiringSoon  => status == 'expiring_soon';
  bool get isPermanent     => status == 'permanent' || expiryDate == null;

  String get typeLabel {
    const labels = {
      'carte_grise':       'Carte Grise',
      'assurance':         'Assurance',
      'visite_technique':  'Visite Technique',
      'vignette':          'Vignette',
    };
    return labels[type] ?? type;
  }

  String get entityLabel => documentableType.contains('Truck') ? 'Camion' : 'Chauffeur';
}
