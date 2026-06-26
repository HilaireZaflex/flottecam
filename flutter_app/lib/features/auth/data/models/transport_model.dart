import 'truck_model.dart';
import 'driver_model.dart';

class TransportModel {
  final int id;
  final int companyId;
  final String reference;
  final String origin;
  final String destination;
  final double? originLat;
  final double? originLng;
  final double? destinationLat;
  final double? destinationLng;
  final String cargoType;
  final double? cargoWeight;
  final String? cargoDescription;
  final String status;
  final String priority;
  final String? scheduledDeparture;
  final String? scheduledArrival;
  final String? actualDeparture;
  final String? actualArrival;
  final String? clientName;
  final String? clientPhone;
  final String? clientEmail;
  final String? notes;
  final double? distanceKm;
  final double? fuelConsumed;
  final double? tollCost;
  final TruckModel? truck;
  final DriverModel? driver;
  final String? statutPaiement; // non_paye | paye | partiel
  final double? montantTransport;
  final double? montantPaye;
  final String? createdAt;
  final String? updatedAt;

  const TransportModel({
    required this.id,
    required this.companyId,
    required this.reference,
    required this.origin,
    required this.destination,
    this.originLat,
    this.originLng,
    this.destinationLat,
    this.destinationLng,
    required this.cargoType,
    this.cargoWeight,
    this.cargoDescription,
    required this.status,
    required this.priority,
    this.scheduledDeparture,
    this.scheduledArrival,
    this.actualDeparture,
    this.actualArrival,
    this.clientName,
    this.clientPhone,
    this.clientEmail,
    this.notes,
    this.distanceKm,
    this.fuelConsumed,
    this.tollCost,
    this.truck,
    this.driver,
    this.statutPaiement,
    this.montantTransport,
    this.montantPaye,
    this.createdAt,
    this.updatedAt,
  });

  factory TransportModel.fromJson(Map<String, dynamic> json) => TransportModel(
    id:                 json['id'] as int,
    companyId:          json['company_id'] as int,
    reference:          json['reference'] as String,
    origin:             json['origin'] as String,
    destination:        json['destination'] as String,
    originLat:          (json['origin_lat'] as num?)?.toDouble(),
    originLng:          (json['origin_lng'] as num?)?.toDouble(),
    destinationLat:     (json['destination_lat'] as num?)?.toDouble(),
    destinationLng:     (json['destination_lng'] as num?)?.toDouble(),
    cargoType:          json['cargo_type'] as String,
    cargoWeight:        (json['cargo_weight'] as num?)?.toDouble(),
    cargoDescription:   json['cargo_description'] as String?,
    status:             json['status'] as String,
    priority:           json['priority'] as String? ?? 'normal',
    scheduledDeparture: json['scheduled_departure'] as String?,
    scheduledArrival:   json['scheduled_arrival'] as String?,
    actualDeparture:    json['actual_departure'] as String?,
    actualArrival:      json['actual_arrival'] as String?,
    clientName:         json['client_name'] as String?,
    clientPhone:        json['client_phone'] as String?,
    clientEmail:        json['client_email'] as String?,
    notes:              json['notes'] as String?,
    distanceKm:         (json['distance_km'] as num?)?.toDouble(),
    fuelConsumed:       (json['fuel_consumed'] as num?)?.toDouble(),
    tollCost:           (json['toll_cost'] as num?)?.toDouble(),
    truck:             json['truck']  != null ? TruckModel.fromJson(json['truck']  as Map<String, dynamic>) : null,
    driver:            json['driver'] != null ? DriverModel.fromJson(json['driver'] as Map<String, dynamic>) : null,
    statutPaiement:    json['statut_paiement'] as String?,
    // Le backend retourne ces valeurs comme String depuis MySQL DECIMAL
    montantTransport:  _parseDouble(json['montant_transport']),
    montantPaye:       _parseDouble(json['montant_paye']),
    createdAt:         json['created_at'] as String?,
    updatedAt:         json['updated_at'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'truck_id': truck?.id,
    'driver_id': driver?.id,
    'origin': origin,
    'destination': destination,
    if (originLat != null) 'origin_lat': originLat,
    if (originLng != null) 'origin_lng': originLng,
    if (destinationLat != null) 'destination_lat': destinationLat,
    if (destinationLng != null) 'destination_lng': destinationLng,
    'cargo_type': cargoType,
    if (cargoWeight != null) 'cargo_weight': cargoWeight,
    if (cargoDescription != null) 'cargo_description': cargoDescription,
    'priority': priority,
    if (scheduledDeparture != null) 'scheduled_departure': scheduledDeparture,
    if (scheduledArrival != null) 'scheduled_arrival': scheduledArrival,
    if (clientName != null) 'client_name': clientName,
    if (clientPhone != null) 'client_phone': clientPhone,
    if (clientEmail != null) 'client_email': clientEmail,
    if (notes != null) 'notes': notes,
  };

  static double? _parseDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  bool get isPending    => status == 'pending';
  bool get isInProgress => status == 'in_progress';
  bool get isCompleted  => status == 'completed';
  bool get isCancelled  => status == 'cancelled';
  bool get isDelayed    => status == 'delayed';
}
