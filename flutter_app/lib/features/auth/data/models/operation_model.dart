class OperationModel {
  final int id;
  final int companyId;
  final int? truckId;
  final int? userId;
  final String date;
  final String designation;
  final double quantite;
  final double prixUnitaire;
  final double montant;
  final String typeOperation; // 'recette' ou 'depense'
  final String categorie;
  final String? notes;
  final String? createdAt;
  // Relations
  final Map<String, dynamic>? truck;
  final Map<String, dynamic>? user;

  const OperationModel({
    required this.id,
    required this.companyId,
    this.truckId,
    this.userId,
    required this.date,
    required this.designation,
    required this.quantite,
    required this.prixUnitaire,
    required this.montant,
    required this.typeOperation,
    required this.categorie,
    this.notes,
    this.createdAt,
    this.truck,
    this.user,
  });

  factory OperationModel.fromJson(Map<String, dynamic> json) => OperationModel(
    id:            json['id'] as int,
    companyId:     json['company_id'] as int,
    truckId:       json['truck_id'] as int?,
    userId:        json['user_id'] as int?,
    date:          json['date'] as String,
    designation:   json['designation'] as String,
    quantite:      (json['quantite'] as num).toDouble(),
    prixUnitaire:  (json['prix_unitaire'] as num).toDouble(),
    montant:       (json['montant'] as num?)?.toDouble() ??
                   ((json['quantite'] as num).toDouble() * (json['prix_unitaire'] as num).toDouble()),
    typeOperation: json['type_operation'] as String,
    categorie:     json['categorie'] as String,
    notes:         json['notes'] as String?,
    createdAt:     json['created_at'] as String?,
    truck:         json['truck'] as Map<String, dynamic>?,
    user:          json['user'] as Map<String, dynamic>?,
  );

  Map<String, dynamic> toJson() => {
    'date':           date,
    'designation':    designation,
    'quantite':       quantite,
    'prix_unitaire':  prixUnitaire,
    'type_operation': typeOperation,
    'categorie':      categorie,
    if (truckId != null) 'truck_id': truckId,
    if (notes != null) 'notes': notes,
  };

  bool get isRecette => typeOperation == 'recette';
  bool get isDepense => typeOperation == 'depense';

  String get truckLabel => truck != null
      ? '${truck!['brand']} ${truck!['model']} (${truck!['plate_number']})'
      : 'Non assigné';
}
