import { useQuery } from '@tanstack/react-query';
import { BarChart, Bar, LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer, PieChart, Pie, Cell } from 'recharts';
import { TrendingUp, Users, Truck, DollarSign, AlertCircle, FileText, Package, Plus, FileUp, ArrowRight } from 'lucide-react';
import { dashboardApi } from '../lib/api';
import toast from 'react-hot-toast';
import { useNavigate } from 'react-router-dom';

const StatCard = ({ title, value, icon: Icon, gradient, trend }) => (
  <div className={`${gradient} rounded-xl p-6 text-white shadow-lg transform hover:scale-105 transition-all duration-300`}>
    <div className="flex items-center justify-between">
      <div>
        <p className="text-sm font-medium opacity-90">{title}</p>
        <p className="text-3xl font-bold mt-2">{value}</p>
        {trend && <p className={`text-xs mt-2 ${trend > 0 ? 'text-green-200' : 'text-red-200'}`}>
          {trend > 0 ? '↑' : '↓'} {Math.abs(trend)}%
        </p>}
      </div>
      <Icon size={40} className="opacity-50" />
    </div>
  </div>
);

const AlertCard = ({ type, title, message, timestamp }) => {
  const bgColor = {
    error: 'bg-red-50 border-red-200',
    warning: 'bg-yellow-50 border-yellow-200',
    info: 'bg-blue-50 border-blue-200',
  }[type] || 'bg-gray-50 border-gray-200';

  const iconColor = {
    error: 'text-red-500',
    warning: 'text-yellow-500',
    info: 'text-blue-500',
  }[type] || 'text-gray-500';

  return (
    <div className={`${bgColor} border rounded-lg p-4 flex gap-3`}>
      <AlertCircle className={`${iconColor} flex-shrink-0`} size={20} />
      <div className="flex-1">
        <h4 className="font-semibold text-gray-900 text-sm">{title}</h4>
        <p className="text-gray-600 text-sm mt-1">{message}</p>
        {timestamp && <p className="text-xs text-gray-500 mt-2">{new Date(timestamp).toLocaleString('fr-FR')}</p>}
      </div>
    </div>
  );
};

const QuickActionCard = ({ title, description, icon: Icon, color, link }) => {
  const navigate = useNavigate();
  return (
    <button
      onClick={() => navigate(link)}
      className={`${color} rounded-xl p-6 text-white text-left shadow-lg transform hover:scale-105 hover:shadow-xl transition-all duration-300 group w-full`}
    >
      <div className="flex items-start justify-between">
        <div>
          <Icon size={32} className="mb-4 group-hover:scale-110 transition-transform" />
          <h3 className="font-bold text-lg">{title}</h3>
          <p className="text-sm opacity-90 mt-1">{description}</p>
        </div>
        <ArrowRight size={20} className="opacity-0 group-hover:opacity-100 transition-all group-hover:translate-x-1" />
      </div>
    </button>
  );
};

export default function DashboardPage() {
  const navigate = useNavigate();
  const { data: statsData, isLoading: statsLoading } = useQuery({
    queryKey: ['dashboard-stats'],
    queryFn: () => dashboardApi.stats(),
  });

  const { data: chartData, isLoading: chartLoading } = useQuery({
    queryKey: ['dashboard-chart'],
    queryFn: () => dashboardApi.chart(),
  });

  const { data: alertsData, isLoading: alertsLoading } = useQuery({
    queryKey: ['dashboard-alerts'],
    queryFn: () => dashboardApi.alerts(),
  });

  const { data: rentabiliteData, isLoading: rentabiliteLoading } = useQuery({
    queryKey: ['dashboard-rentabilite'],
    queryFn: () => dashboardApi.rentabilite(),
  });

  const stats = statsData?.data || {};
  const chart = Array.isArray(chartData?.data?.chart) ? chartData.data.chart : Array.isArray(chartData?.data) ? chartData.data : [];
  const alerts = Array.isArray(alertsData?.data?.alerts) ? alertsData.data.alerts : Array.isArray(alertsData?.data) ? alertsData.data : [];
  const rentabilite = Array.isArray(rentabiliteData?.data?.rentabilite) ? rentabiliteData.data.rentabilite : Array.isArray(rentabiliteData?.data) ? rentabiliteData.data : [];

  // Extraire les valeurs avec les bons noms de champs de l'API
  const camionsActifs = (stats.trucks?.available || 0) + (stats.trucks?.on_mission || 0);
  const conducteursDisponibles = stats.drivers?.available || 0;
  const transportsMois = stats.transports?.total || 0;
  const chiffreAffaires = stats.financials?.total_recettes || 0;

  const COLORS = ['#1B4FD8', '#10B981', '#F59E0B', '#EF4444', '#8B5CF6'];

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 via-white to-purple-50">
      {/* Header */}
      <div className="bg-gradient-to-r from-blue-600 to-blue-800 text-white px-8 py-12 shadow-lg">
        <h1 className="text-4xl font-bold mb-2">Tableau de Bord</h1>
        <p className="text-blue-100">Vue d'ensemble de vos opérations FlotteCam</p>
      </div>

      <div className="p-8 max-w-7xl mx-auto">
        {/* Top Row: Stats */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
          <StatCard
            title="Camions Actifs"
            value={camionsActifs}
            icon={Truck}
            gradient="bg-gradient-to-br from-blue-500 to-blue-600"
          />
          <StatCard
            title="Conducteurs Disponibles"
            value={conducteursDisponibles}
            icon={Users}
            gradient="bg-gradient-to-br from-green-500 to-green-600"
          />
          <StatCard
            title="Transports du Mois"
            value={transportsMois}
            icon={Package}
            gradient="bg-gradient-to-br from-orange-500 to-orange-600"
          />
          <StatCard
            title="Chiffre d'Affaires"
            value={`${chiffreAffaires.toLocaleString('fr-FR')} FCFA`}
            icon={DollarSign}
            gradient="bg-gradient-to-br from-purple-500 to-purple-600"
          />
        </div>

        {/* Charts Row */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-8 mb-8">
          {/* Bar & Line Chart */}
          <div className="bg-white rounded-xl shadow-lg p-6">
            <h2 className="text-xl font-bold text-gray-900 mb-6">Recettes vs Dépenses (6 derniers mois)</h2>
            <ResponsiveContainer width="100%" height={300}>
              <BarChart data={chart}>
                <CartesianGrid strokeDasharray="3 3" stroke="#e5e7eb" />
                <XAxis dataKey="month" stroke="#6b7280" />
                <YAxis stroke="#6b7280" />
                <Tooltip 
                  contentStyle={{ backgroundColor: '#fff', border: '1px solid #e5e7eb', borderRadius: '8px' }}
                  formatter={(value) => value.toLocaleString('fr-FR')}
                />
                <Legend />
                <Bar dataKey="recettes" fill="#1B4FD8" radius={[8, 8, 0, 0]} />
                <Bar dataKey="depenses" fill="#EF4444" radius={[8, 8, 0, 0]} />
              </BarChart>
            </ResponsiveContainer>
          </div>

          {/* Pie Chart */}
          <div className="bg-white rounded-xl shadow-lg p-6">
            <h2 className="text-xl font-bold text-gray-900 mb-6">Répartition par Catégorie</h2>
            <ResponsiveContainer width="100%" height={300}>
              <PieChart>
                <Pie
                  data={chart}
                  cx="50%"
                  cy="50%"
                  labelLine={false}
                  label={({ name, value }) => `${name}: ${value}`}
                  outerRadius={80}
                  fill="#8884d8"
                  dataKey="montant"
                >
                  {chart.map((entry, index) => (
                    <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                  ))}
                </Pie>
                <Tooltip formatter={(value) => value.toLocaleString('fr-FR')} />
              </PieChart>
            </ResponsiveContainer>
          </div>
        </div>

        {/* Alerts & Rentabilité */}
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8 mb-8">
          {/* Alerts */}
          <div className="lg:col-span-2 bg-white rounded-xl shadow-lg p-6">
            <div className="flex items-center justify-between mb-6">
              <h2 className="text-xl font-bold text-gray-900">Alertes Récentes</h2>
              <span className="bg-red-100 text-red-700 text-xs font-semibold px-3 py-1 rounded-full">
                {alerts.length} alertes
              </span>
            </div>
            {alerts.length > 0 ? (
              <div className="space-y-4">
                {alerts.slice(0, 5).map((alert) => (
                  <AlertCard key={alert.id} {...alert} />
                ))}
              </div>
            ) : (
              <div className="text-center py-8">
                <p className="text-gray-500">Aucune alerte - Tout fonctionne parfaitement!</p>
              </div>
            )}
          </div>

          {/* Top Rentabilité */}
          <div className="bg-white rounded-xl shadow-lg p-6">
            <h2 className="text-xl font-bold text-gray-900 mb-6">Top 3 Camions</h2>
            <div className="space-y-4">
              {rentabilite.slice(0, 3).map((item, idx) => {
                const truck = item.truck || item;
                const benefice = item.benefice || 0;
                const recettes = item.recettes || 1;
                const pct = ((benefice / recettes) * 100).toFixed(1);
                return (
                  <div key={truck.id || idx} className="flex items-center gap-4 p-3 bg-gradient-to-r from-blue-50 to-transparent rounded-lg border border-blue-100">
                    <div className="w-8 h-8 rounded-full bg-gradient-to-br from-blue-500 to-purple-500 text-white flex items-center justify-center font-bold text-sm">
                      {idx + 1}
                    </div>
                    <div className="flex-1">
                      <p className="font-semibold text-gray-900 text-sm">{truck.plate_number || truck.immatriculation}</p>
                      <p className="text-xs text-gray-500">{truck.brand || truck.marque} {truck.model}</p>
                    </div>
                    <div className="text-right">
                      <p className="font-bold text-green-600 text-sm">+{pct}%</p>
                      <p className="text-xs text-gray-400">{(benefice/1000).toFixed(0)}k FCFA</p>
                    </div>
                  </div>
                );
              })}
              {rentabilite.length === 0 && (
                <p className="text-center text-gray-400 text-sm py-4">Aucune donnée disponible</p>
              )}
            </div>
          </div>
        </div>

        {/* Quick Actions */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
          <QuickActionCard
            title="Importer Excel"
            description="Importer données en masse"
            icon={FileUp}
            color="bg-gradient-to-br from-blue-500 to-blue-600"
            link="/import"
          />
          <QuickActionCard
            title="Nouveau Transport"
            description="Ajouter un transport"
            icon={Package}
            color="bg-gradient-to-br from-green-500 to-green-600"
            link="/transports"
          />
          <QuickActionCard
            title="Nouveau Camion"
            description="Enregistrer un camion"
            icon={Truck}
            color="bg-gradient-to-br from-orange-500 to-orange-600"
            link="/trucks"
          />
          <QuickActionCard
            title="Rapport PDF"
            description="Générer un rapport"
            icon={FileText}
            color="bg-gradient-to-br from-purple-500 to-purple-600"
            link="/reports"
          />
        </div>
      </div>
    </div>
  );
}
