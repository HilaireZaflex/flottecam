class AppConstants {
  // ── API Base URL ───────────────────────────────────────────────────────────
  // 🔧 DÉVELOPPEMENT LOCAL (mobile sur réseau WiFi local) :
  //    Remplacez par l'IP de votre Mac : Terminal → ipconfig getifaddr en0
  // static const String baseUrl = 'http://172.20.10.4:8000/api';
  //
  // 🌐 PWA WEB LOCAL (flutter run -d chrome) :
  // static const String baseUrl = 'http://localhost:8000/api';
  //
  // 🚀 PRODUCTION Railway (à remplir après déploiement backend) :
  // static const String baseUrl = 'https://flottecam-backend.up.railway.app/api';

  static const String baseUrl = 'http://172.20.10.4:8000/api'; // ← Changer selon env

  // Storage Keys
  static const String tokenKey   = 'fleet_auth_token';
  static const String userKey    = 'fleet_auth_user';
  static const String companyKey = 'fleet_company';

  // Timeouts
  static const int connectTimeout = 30000;
  static const int receiveTimeout = 30000;

  // Map
  static const String googleMapsApiKey = 'YOUR_GOOGLE_MAPS_API_KEY';

  // App Info
  static const String appName    = 'Fleet SaaS';
  static const String appVersion = '1.0.0';

  // Truck statuses — alignés avec le backend API
  static const Map<String, String> truckStatuses = {
    'available':      'Disponible',
    'on_mission':     'En mission',
    'maintenance':    'Maintenance',
    'out_of_service': 'Hors service',
  };

  // Driver statuses
  static const Map<String, String> driverStatuses = {
    'available':  'Disponible',
    'on_mission': 'En mission',
    'on_leave':   'En congé',
    'inactive':   'Inactif',
  };

  // Transport statuses
  static const Map<String, String> transportStatuses = {
    'pending':     'En attente',
    'in_progress': 'En cours',
    'completed':   'Terminé',
    'cancelled':   'Annulé',
    'delayed':     'Retardé',
  };

  // Priorities
  static const Map<String, String> priorities = {
    'low':    'Faible',
    'normal': 'Normal',
    'high':   'Élevé',
    'urgent': 'Urgent',
  };
}
