import { useEffect, useState, useRef } from 'react';
import { MapContainer, TileLayer, Marker, Popup, Polyline, useMap } from 'react-leaflet';
import L from 'leaflet';
import 'leaflet/dist/leaflet.css';
import { Truck, Navigation, RefreshCw, Clock, Gauge, MapPin, Wifi, WifiOff } from 'lucide-react';
import { useQuery } from '@tanstack/react-query';
import api from '../lib/api';
import { toast } from 'sonner';

// Fix Leaflet default icons
delete L.Icon.Default.prototype._getIconUrl;
L.Icon.Default.mergeOptions({
  iconRetinaUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/images/marker-icon-2x.png',
  iconUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/images/marker-icon.png',
  shadowUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/images/marker-shadow.png',
});

// Bamako center
const BAMAKO = [12.3472, -6.8897];

// Status colors
const STATUS_COLORS = {
  available:      '#10B981',
  on_mission:     '#1B4FD8',
  maintenance:    '#F59E0B',
  out_of_service: '#EF4444',
};

const STATUS_LABELS = {
  available:      'Disponible',
  on_mission:     'En mission',
  maintenance:    'Maintenance',
  out_of_service: 'Hors service',
};

// Create custom truck marker
function createTruckIcon(status, isSelected) {
  const color = STATUS_COLORS[status] || '#64748B';
  const size = isSelected ? 44 : 36;
  return L.divIcon({
    html: `
      <div style="
        width: ${size}px; height: ${size}px;
        background: ${color};
        border-radius: 50% 50% 50% 0;
        transform: rotate(-45deg);
        border: 3px solid white;
        box-shadow: 0 4px 12px rgba(0,0,0,0.3);
        display: flex; align-items: center; justify-content: center;
      ">
        <div style="transform: rotate(45deg); color: white; font-size: ${isSelected ? 18 : 14}px;">🚛</div>
      </div>`,
    className: '',
    iconSize: [size, size],
    iconAnchor: [size / 2, size],
    popupAnchor: [0, -size],
  });
}

// Auto-fit map to markers
function FitBounds({ positions }) {
  const map = useMap();
  useEffect(() => {
    if (positions.length > 0) {
      const bounds = L.latLngBounds(positions);
      map.fitBounds(bounds, { padding: [60, 60] });
    }
  }, [positions, map]);
  return null;
}

export default function GpsPage() {
  const [selectedTruck, setSelectedTruck] = useState(null);
  const [showHistory, setShowHistory]     = useState(false);
  const [historyHours, setHistoryHours]   = useState(24);
  const [lastRefresh, setLastRefresh]     = useState(new Date());
  const mapRef = useRef();

  // Fetch all truck positions
  const { data, isLoading, refetch } = useQuery({
    queryKey: ['gps-latest'],
    queryFn: async () => {
      const res = await api.get('/gps/latest');
      return res.data;
    },
    refetchInterval: 30000, // auto-refresh every 30s
    onSuccess: () => setLastRefresh(new Date()),
  });

  // Fetch history for selected truck
  const { data: historyData } = useQuery({
    queryKey: ['gps-history', selectedTruck?.id, historyHours],
    queryFn: async () => {
      const res = await api.get(`/gps/history/${selectedTruck.id}?hours=${historyHours}`);
      return res.data;
    },
    enabled: !!selectedTruck && showHistory,
  });

  const trucks = data?.trucks || [];
  const onlineTrucks = trucks.filter(t => t.location);
  const historyPoints = historyData?.history || [];

  const handleRefresh = () => {
    refetch();
    toast.success('Positions actualisées');
    setLastRefresh(new Date());
  };

  // Positions with GPS for fitBounds
  const positions = onlineTrucks
    .map(t => t.location ? [parseFloat(t.location.latitude), parseFloat(t.location.longitude)] : null)
    .filter(Boolean);

  return (
    <div className="h-[calc(100vh-64px)] flex flex-col">
      {/* ── Header ─────────────────────────────────────────── */}
      <div className="bg-white border-b border-slate-100 px-6 py-3 flex items-center justify-between z-10">
        <div className="flex items-center gap-4">
          <div className="flex items-center gap-2">
            <div className="w-9 h-9 bg-gradient-to-br from-blue-500 to-blue-600 rounded-xl flex items-center justify-center">
              <Navigation size={18} className="text-white" />
            </div>
            <div>
              <h1 className="font-bold text-slate-900 text-base">Suivi GPS en temps réel</h1>
              <p className="text-xs text-slate-400">Actualisé à {lastRefresh.toLocaleTimeString('fr-FR')}</p>
            </div>
          </div>

          {/* Stats */}
          <div className="flex items-center gap-3 ml-4">
            <div className="flex items-center gap-1.5 bg-slate-50 px-3 py-1.5 rounded-lg">
              <Truck size={14} className="text-slate-500" />
              <span className="text-xs font-semibold text-slate-700">{trucks.length} camions</span>
            </div>
            <div className="flex items-center gap-1.5 bg-green-50 px-3 py-1.5 rounded-lg">
              <Wifi size={14} className="text-green-600" />
              <span className="text-xs font-semibold text-green-700">{onlineTrucks.length} en ligne</span>
            </div>
            {trucks.length - onlineTrucks.length > 0 && (
              <div className="flex items-center gap-1.5 bg-slate-50 px-3 py-1.5 rounded-lg">
                <WifiOff size={14} className="text-slate-400" />
                <span className="text-xs font-semibold text-slate-500">{trucks.length - onlineTrucks.length} hors ligne</span>
              </div>
            )}
          </div>
        </div>

        <div className="flex items-center gap-2">
          {selectedTruck && (
            <>
              <select
                value={historyHours}
                onChange={e => setHistoryHours(Number(e.target.value))}
                className="text-xs border border-slate-200 rounded-lg px-2 py-1.5 bg-white focus:outline-none focus:ring-2 focus:ring-blue-300"
              >
                <option value={6}>6 heures</option>
                <option value={12}>12 heures</option>
                <option value={24}>24 heures</option>
                <option value={48}>48 heures</option>
              </select>
              <button
                onClick={() => setShowHistory(!showHistory)}
                className={`text-xs px-3 py-1.5 rounded-lg font-semibold transition-all ${
                  showHistory
                    ? 'bg-blue-600 text-white'
                    : 'bg-slate-100 text-slate-600 hover:bg-slate-200'
                }`}
              >
                Historique
              </button>
              <button
                onClick={() => { setSelectedTruck(null); setShowHistory(false); }}
                className="text-xs px-3 py-1.5 rounded-lg bg-slate-100 text-slate-600 hover:bg-slate-200 font-semibold"
              >
                ✕ Désélectionner
              </button>
            </>
          )}
          <button
            onClick={handleRefresh}
            className="flex items-center gap-1.5 bg-blue-600 text-white text-xs px-3 py-1.5 rounded-lg font-semibold hover:bg-blue-700 transition-colors"
          >
            <RefreshCw size={13} />
            Actualiser
          </button>
        </div>
      </div>

      <div className="flex flex-1 overflow-hidden">
        {/* ── Sidebar trucks list ─────────────────────────── */}
        <div className="w-72 bg-white border-r border-slate-100 overflow-y-auto flex-shrink-0">
          <div className="p-3 border-b border-slate-50">
            <p className="text-xs font-semibold text-slate-400 uppercase tracking-wide">Liste des camions</p>
          </div>

          {isLoading ? (
            <div className="p-4 space-y-3">
              {[...Array(4)].map((_, i) => (
                <div key={i} className="animate-pulse">
                  <div className="h-16 bg-slate-100 rounded-xl" />
                </div>
              ))}
            </div>
          ) : (
            <div className="p-2 space-y-1.5">
              {trucks.map(truck => {
                const isOnline  = !!truck.location;
                const isSelected = selectedTruck?.id === truck.id;
                const color = STATUS_COLORS[truck.status] || '#64748B';

                return (
                  <div
                    key={truck.id}
                    onClick={() => {
                      setSelectedTruck(truck);
                      // Pan map to truck
                      if (truck.location && mapRef.current) {
                        mapRef.current.setView(
                          [parseFloat(truck.location.latitude), parseFloat(truck.location.longitude)],
                          14
                        );
                      }
                    }}
                    className={`p-3 rounded-xl cursor-pointer transition-all border ${
                      isSelected
                        ? 'bg-blue-50 border-blue-200 shadow-sm'
                        : 'hover:bg-slate-50 border-transparent hover:border-slate-200'
                    }`}
                  >
                    <div className="flex items-start gap-2.5">
                      <div
                        className="w-8 h-8 rounded-lg flex items-center justify-center flex-shrink-0 mt-0.5"
                        style={{ backgroundColor: color + '20' }}
                      >
                        <Truck size={16} style={{ color }} />
                      </div>
                      <div className="flex-1 min-w-0">
                        <div className="flex items-center justify-between gap-1">
                          <p className="font-bold text-slate-900 text-sm truncate">{truck.plate_number}</p>
                          <div className={`w-2 h-2 rounded-full flex-shrink-0 ${isOnline ? 'bg-green-500' : 'bg-slate-300'}`} />
                        </div>
                        <p className="text-xs text-slate-500 truncate">{truck.brand} {truck.model}</p>
                        {truck.driver_name && (
                          <p className="text-xs text-blue-600 font-medium truncate mt-0.5">👤 {truck.driver_name}</p>
                        )}
                        {truck.location ? (
                          <div className="flex items-center gap-2 mt-1">
                            <span className="text-xs text-slate-400 flex items-center gap-0.5">
                              <Gauge size={10} />
                              {truck.location.speed || 0} km/h
                            </span>
                            <span className="text-xs text-slate-400">•</span>
                            <span className="text-xs" style={{ color }}>
                              {STATUS_LABELS[truck.status] || truck.status}
                            </span>
                          </div>
                        ) : (
                          <p className="text-xs text-slate-400 mt-1 italic">Position inconnue</p>
                        )}
                      </div>
                    </div>
                  </div>
                );
              })}

              {trucks.length === 0 && (
                <div className="text-center py-8 text-slate-400">
                  <Truck size={32} className="mx-auto mb-2 opacity-30" />
                  <p className="text-sm">Aucun camion</p>
                </div>
              )}
            </div>
          )}
        </div>

        {/* ── Map ────────────────────────────────────────────── */}
        <div className="flex-1 relative">
          <MapContainer
            center={BAMAKO}
            zoom={12}
            className="h-full w-full"
            ref={mapRef}
            zoomControl={true}
          >
            <TileLayer
              url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
              attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>'
            />

            {/* Auto fit bounds */}
            {positions.length > 0 && !selectedTruck && <FitBounds positions={positions} />}

            {/* Truck markers */}
            {trucks.map(truck => {
              if (!truck.location) return null;
              const lat = parseFloat(truck.location.latitude);
              const lng = parseFloat(truck.location.longitude);
              const isSelected = selectedTruck?.id === truck.id;

              return (
                <Marker
                  key={truck.id}
                  position={[lat, lng]}
                  icon={createTruckIcon(truck.status, isSelected)}
                  eventHandlers={{ click: () => setSelectedTruck(truck) }}
                >
                  <Popup className="truck-popup" maxWidth={280}>
                    <div className="p-1">
                      <div className="flex items-center gap-2 mb-2">
                        <div
                          className="w-8 h-8 rounded-lg flex items-center justify-center"
                          style={{ backgroundColor: (STATUS_COLORS[truck.status] || '#64748B') + '20' }}
                        >
                          <Truck size={16} style={{ color: STATUS_COLORS[truck.status] || '#64748B' }} />
                        </div>
                        <div>
                          <p className="font-bold text-slate-900">{truck.plate_number}</p>
                          <p className="text-xs text-slate-500">{truck.brand} {truck.model}</p>
                        </div>
                      </div>

                      <div className="space-y-1.5 text-xs">
                        {truck.driver_name && (
                          <div className="flex items-center gap-1.5 text-slate-600">
                            <span>👤</span>
                            <span>{truck.driver_name}</span>
                          </div>
                        )}
                        <div className="flex items-center gap-1.5 text-slate-600">
                          <Gauge size={12} />
                          <span>{truck.location.speed || 0} km/h</span>
                        </div>
                        {truck.location.address && (
                          <div className="flex items-start gap-1.5 text-slate-600">
                            <MapPin size={12} className="mt-0.5 flex-shrink-0" />
                            <span>{truck.location.address}</span>
                          </div>
                        )}
                        <div className="flex items-center gap-1.5 text-slate-400">
                          <Clock size={12} />
                          <span>
                            {truck.location.recorded_at
                              ? new Date(truck.location.recorded_at).toLocaleString('fr-FR')
                              : 'N/A'}
                          </span>
                        </div>
                        <div className="mt-2 pt-2 border-t border-slate-100">
                          <span
                            className="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-bold"
                            style={{
                              backgroundColor: (STATUS_COLORS[truck.status] || '#64748B') + '20',
                              color: STATUS_COLORS[truck.status] || '#64748B',
                            }}
                          >
                            {STATUS_LABELS[truck.status] || truck.status}
                          </span>
                        </div>
                      </div>
                    </div>
                  </Popup>
                </Marker>
              );
            })}

            {/* History polyline */}
            {showHistory && historyPoints.length > 1 && (
              <Polyline
                positions={historyPoints.map(p => [parseFloat(p.latitude), parseFloat(p.longitude)])}
                color="#1B4FD8"
                weight={3}
                opacity={0.8}
                dashArray="8, 4"
              />
            )}
          </MapContainer>

          {/* Legend */}
          <div className="absolute bottom-6 right-4 bg-white rounded-xl shadow-lg p-3 z-[1000]">
            <p className="text-xs font-bold text-slate-600 mb-2 uppercase tracking-wide">Légende</p>
            <div className="space-y-1.5">
              {Object.entries(STATUS_LABELS).map(([key, label]) => (
                <div key={key} className="flex items-center gap-2">
                  <div className="w-3 h-3 rounded-full" style={{ backgroundColor: STATUS_COLORS[key] }} />
                  <span className="text-xs text-slate-600">{label}</span>
                </div>
              ))}
            </div>
          </div>

          {/* No GPS info banner */}
          {trucks.length > 0 && onlineTrucks.length === 0 && (
            <div className="absolute top-4 left-1/2 -translate-x-1/2 bg-white rounded-xl shadow-lg px-4 py-3 z-[1000] flex items-center gap-3 border border-amber-200">
              <WifiOff size={18} className="text-amber-500" />
              <div>
                <p className="text-sm font-semibold text-slate-800">Aucune position GPS active</p>
                <p className="text-xs text-slate-500">Les chauffeurs doivent activer le GPS dans l'app mobile</p>
              </div>
            </div>
          )}

          {/* Auto-refresh indicator */}
          <div className="absolute top-4 right-4 bg-white rounded-lg shadow px-3 py-1.5 z-[1000] flex items-center gap-2">
            <div className="w-2 h-2 rounded-full bg-green-500 animate-pulse" />
            <span className="text-xs text-slate-500">Actualisation auto 30s</span>
          </div>
        </div>
      </div>
    </div>
  );
}
