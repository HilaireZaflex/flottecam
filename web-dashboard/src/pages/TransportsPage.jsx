import React, { useState, useMemo } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { toast } from 'react-hot-toast';
import { useForm, Controller } from 'react-hook-form';
import {
  Plus,
  Search,
  Edit2,
  Trash2,
  AlertCircle,
  X,
  ArrowRight,
  Package,
  DollarSign,
  TrendingUp,
} from 'lucide-react';
import { transportsApi, trucksApi, driversApi } from '../lib/api';

const TRANSPORT_STATUS_LABELS = {
  pending: 'En attente',
  in_progress: 'En cours',
  completed: 'Terminé',
  cancelled: 'Annulé',
  delayed: 'Retardé',
};

const PAYMENT_STATUS_LABELS = {
  paye: 'Payé',
  partiel: 'Partiel',
  non_paye: 'Impayé',
};

const getStatusColor = (status) => {
  switch (status) {
    case 'completed':
      return 'bg-green-100 text-green-700';
    case 'in_progress':
    case 'pending':
      return 'bg-blue-100 text-blue-700';
    case 'delayed':
      return 'bg-yellow-100 text-yellow-700';
    case 'cancelled':
      return 'bg-red-100 text-red-700';
    default:
      return 'bg-gray-100 text-gray-700';
  }
};

const getPaymentStatusColor = (status) => {
  switch (status) {
    case 'paye':
      return 'bg-green-100 text-green-700';
    case 'partiel':
      return 'bg-yellow-100 text-yellow-700';
    case 'non_paye':
      return 'bg-red-100 text-red-700';
    default:
      return 'bg-gray-100 text-gray-700';
  }
};

const StatCard = ({ icon: Icon, label, value, color }) => (
  <div className="bg-white rounded-xl shadow-md p-6">
    <div className="flex items-center justify-between">
      <div>
        <p className="text-gray-600 text-sm mb-1">{label}</p>
        <p className="text-2xl font-bold text-gray-900">{value}</p>
      </div>
      <div className={`w-12 h-12 rounded-lg flex items-center justify-center ${color}`}>
        <Icon size={24} />
      </div>
    </div>
  </div>
);

const TransportTableSkeleton = () => (
  <div className="bg-white rounded-xl shadow-md overflow-hidden">
    <table className="w-full">
      <thead className="bg-gray-50 border-b border-gray-200">
        <tr>
          <th className="px-6 py-3 text-left text-sm font-semibold text-gray-700">Référence</th>
          <th className="px-6 py-3 text-left text-sm font-semibold text-gray-700">Trajet</th>
          <th className="px-6 py-3 text-left text-sm font-semibold text-gray-700">Véhicule</th>
          <th className="px-6 py-3 text-left text-sm font-semibold text-gray-700">Dates</th>
          <th className="px-6 py-3 text-left text-sm font-semibold text-gray-700">Fret</th>
          <th className="px-6 py-3 text-left text-sm font-semibold text-gray-700">Montant</th>
          <th className="px-6 py-3 text-left text-sm font-semibold text-gray-700">Paiement</th>
          <th className="px-6 py-3 text-left text-sm font-semibold text-gray-700">Statut</th>
          <th className="px-6 py-3 text-left text-sm font-semibold text-gray-700">Actions</th>
        </tr>
      </thead>
      <tbody>
        {[...Array(5)].map((_, i) => (
          <tr key={i} className="border-b border-gray-200 animate-pulse">
            <td className="px-6 py-4"><div className="h-4 bg-gray-200 rounded w-20" /></td>
            <td className="px-6 py-4"><div className="h-4 bg-gray-200 rounded w-32" /></td>
            <td className="px-6 py-4"><div className="h-4 bg-gray-200 rounded w-24" /></td>
            <td className="px-6 py-4"><div className="h-4 bg-gray-200 rounded w-28" /></td>
            <td className="px-6 py-4"><div className="h-4 bg-gray-200 rounded w-24" /></td>
            <td className="px-6 py-4"><div className="h-4 bg-gray-200 rounded w-20" /></td>
            <td className="px-6 py-4"><div className="h-6 bg-gray-200 rounded w-16" /></td>
            <td className="px-6 py-4"><div className="h-6 bg-gray-200 rounded w-20" /></td>
            <td className="px-6 py-4"><div className="flex gap-2"><div className="h-8 bg-gray-200 rounded w-8" /><div className="h-8 bg-gray-200 rounded w-8" /></div></td>
          </tr>
        ))}
      </tbody>
    </table>
  </div>
);

const TransportModal = ({ isOpen, onClose, onSubmit, initialData, isLoading, trucks = [], drivers = [] }) => {
  const {
    register,
    handleSubmit,
    reset,
    control,
    formState: { errors },
  } = useForm({
    defaultValues: initialData || {
      truck_id: '',
      driver_id: '',
      origin: '',
      destination: '',
      scheduled_departure: '',
      scheduled_arrival: '',
      cargo_type: '',
      cargo_weight: '',
      montant_transport: '',
      client_name: '',
      client_phone: '',
      status: 'pending',
      notes: '',
    },
  });

  React.useEffect(() => {
    reset(initialData || {});
  }, [initialData, reset]);

  const handleFormSubmit = (data) => {
    onSubmit(data);
    reset();
  };

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 overflow-y-auto">
      <div className="bg-white rounded-xl shadow-xl w-full max-w-3xl my-8">
        <div className="sticky top-0 bg-gradient-to-r from-blue-600 to-blue-800 px-6 py-4 flex justify-between items-center">
          <h2 className="text-xl font-bold text-white">
            {initialData ? 'Modifier un transport' : 'Créer un transport'}
          </h2>
          <button onClick={onClose} className="text-white hover:bg-blue-700 p-1 rounded">
            <X size={24} />
          </button>
        </div>

        <form onSubmit={handleSubmit(handleFormSubmit)} className="p-6 space-y-4">
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Camion *</label>
              <select
                {...register('truck_id', { required: 'Requis' })}
                className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
              >
                <option value="">Sélectionner un camion</option>
                {trucks.map(t => (
                  <option key={t.id} value={t.id}>{t.plate_number}</option>
                ))}
              </select>
              {errors.truck_id && <p className="text-red-500 text-xs mt-1">{errors.truck_id.message}</p>}
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Conducteur *</label>
              <select
                {...register('driver_id', { required: 'Requis' })}
                className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
              >
                <option value="">Sélectionner un conducteur</option>
                {drivers.map(d => (
                  <option key={d.id} value={d.id}>{d.full_name || d.first_name || d.name}</option>
                ))}
              </select>
              {errors.driver_id && <p className="text-red-500 text-xs mt-1">{errors.driver_id.message}</p>}
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Origine *</label>
              <input
                type="text"
                {...register('origin', { required: 'Requis' })}
                className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                placeholder="ex: Dakar"
              />
              {errors.origin && <p className="text-red-500 text-xs mt-1">{errors.origin.message}</p>}
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Destination *</label>
              <input
                type="text"
                {...register('destination', { required: 'Requis' })}
                className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                placeholder="ex: Thiès"
              />
              {errors.destination && <p className="text-red-500 text-xs mt-1">{errors.destination.message}</p>}
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Date départ</label>
              <input type="datetime-local" {...register('scheduled_departure')} className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500" />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Date arrivée</label>
              <input type="datetime-local" {...register('scheduled_arrival')} className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500" />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Type de fret</label>
              <input type="text" {...register('cargo_type')} className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500" placeholder="ex: Riz" />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Poids (kg)</label>
              <input type="number" {...register('cargo_weight')} className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500" />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Montant (FCFA)</label>
              <input type="number" {...register('montant_transport')} className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500" />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Statut</label>
              <select {...register('status')} className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500">
                <option value="pending">En attente</option>
                <option value="in_progress">En cours</option>
                <option value="completed">Terminé</option>
                <option value="delayed">Retardé</option>
                <option value="cancelled">Annulé</option>
              </select>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Client</label>
              <input type="text" {...register('client_name')} className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500" placeholder="Nom du client" />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Tél. Client</label>
              <input type="tel" {...register('client_phone')} className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500" placeholder="Téléphone" />
            </div>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Remarques</label>
            <textarea {...register('notes')} className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500" rows="3" />
          </div>

          <div className="flex gap-3 pt-4">
            <button type="button" onClick={onClose} className="flex-1 px-4 py-2 bg-gray-100 text-gray-700 rounded-lg hover:bg-gray-200 font-medium">Annuler</button>
            <button type="submit" disabled={isLoading} className="flex-1 px-4 py-2 bg-gradient-to-r from-blue-600 to-blue-800 text-white rounded-lg hover:from-blue-700 hover:to-blue-900 font-medium disabled:opacity-50">
              {isLoading ? 'Enregistrement...' : 'Enregistrer'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};

const DeleteConfirmDialog = ({ isOpen, onConfirm, onCancel, isLoading }) => {
  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
      <div className="bg-white rounded-xl shadow-xl max-w-sm">
        <div className="p-6">
          <div className="flex items-center gap-3 mb-4">
            <div className="w-10 h-10 bg-red-100 rounded-full flex items-center justify-center">
              <AlertCircle className="text-red-600" size={20} />
            </div>
            <h2 className="text-lg font-bold text-gray-900">Supprimer ce transport?</h2>
          </div>
          <p className="text-gray-600 mb-6">Cette action est irréversible.</p>
          <div className="flex gap-3">
            <button onClick={onCancel} className="flex-1 px-4 py-2 bg-gray-100 text-gray-700 rounded-lg hover:bg-gray-200 font-medium">Annuler</button>
            <button onClick={onConfirm} disabled={isLoading} className="flex-1 px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700 font-medium disabled:opacity-50">
              {isLoading ? 'Suppression...' : 'Supprimer'}
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};

const EmptyState = () => (
  <div className="flex flex-col items-center justify-center py-12">
    <div className="w-16 h-16 bg-blue-100 rounded-full flex items-center justify-center mb-4">
      <Package size={32} className="text-blue-600" />
    </div>
    <h3 className="text-lg font-semibold text-gray-900 mb-2">Aucun transport trouvé</h3>
    <p className="text-gray-600 text-center max-w-md">Créez votre premier transport pour commencer.</p>
  </div>
);

export default function TransportsPage() {
  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState('all');
  const [dateFrom, setDateFrom] = useState('');
  const [dateTo, setDateTo] = useState('');
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [selectedTransport, setSelectedTransport] = useState(null);
  const [deleteConfirm, setDeleteConfirm] = useState(null);
  const queryClient = useQueryClient();

  const { data: transportsResponse, isLoading, isError } = useQuery({
    queryKey: ['transports', searchTerm, statusFilter],
    queryFn: () => transportsApi.list({
      search: searchTerm || undefined,
      status: statusFilter !== 'all' ? statusFilter : undefined,
    }),
  });
  // Laravel paginated response: { current_page, data: [...], total, ... }
  const transports = Array.isArray(transportsResponse?.data?.data)
    ? transportsResponse.data.data
    : Array.isArray(transportsResponse?.data)
      ? transportsResponse.data
      : [];
  const error = isError;

  const { data: trucksResponse } = useQuery({
    queryKey: ['trucks'],
    queryFn: () => trucksApi.list({}),
  });
  const trucks = trucksResponse?.data?.data || [];

  const { data: driversResponse } = useQuery({
    queryKey: ['drivers'],
    queryFn: () => driversApi.list({}),
  });
  const drivers = driversResponse?.data?.data || [];

  const createMutation = useMutation({
    mutationFn: (data) => transportsApi.create(data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['transports'] });
      setIsModalOpen(false);
      setSelectedTransport(null);
      toast.success('Transport créé avec succès');
    },
    onError: () => toast.error('Erreur lors de la création'),
  });

  const updateMutation = useMutation({
    mutationFn: ({ id, data }) => transportsApi.update(id, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['transports'] });
      setIsModalOpen(false);
      setSelectedTransport(null);
      toast.success('Transport modifié avec succès');
    },
    onError: () => toast.error('Erreur lors de la modification'),
  });

  const deleteMutation = useMutation({
    mutationFn: (id) => transportsApi.delete(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['transports'] });
      setDeleteConfirm(null);
      toast.success('Transport supprimé avec succès');
    },
    onError: () => toast.error('Erreur lors de la suppression'),
  });

  const stats = useMemo(() => {
    const total = transports.length;
    const inProgress = transports.filter(t => t.status === 'in_progress').length;
    const completed = transports.filter(t => t.status === 'completed').length;
    const totalAmount = transports.reduce((sum, t) => sum + parseFloat(t.montant_transport || 0), 0);
    return { total, inProgress, completed, totalAmount };
  }, [transports]);

  const handleAddTransport = () => {
    setSelectedTransport(null);
    setIsModalOpen(true);
  };

  const handleEditTransport = (transport) => {
    setSelectedTransport(transport);
    setIsModalOpen(true);
  };

  const handleDeleteTransport = (id) => {
    setDeleteConfirm(id);
  };

  const handleModalSubmit = (data) => {
    if (selectedTransport) {
      updateMutation.mutate({ id: selectedTransport.id, data });
    } else {
      createMutation.mutate(data);
    }
  };

  const formatCurrency = (value) => {
    return new Intl.NumberFormat('fr-FR', {
      style: 'currency',
      currency: 'XOF',
      minimumFractionDigits: 0,
    }).format(value);
  };

  return (
    <div className="p-6 bg-gray-50 min-h-screen">
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-gray-900 mb-2">Gestion des transports</h1>
        <p className="text-gray-600">Suivez et gérez vos transports</p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
        <StatCard icon={Package} label="Total" value={stats.total} color="bg-blue-100 text-blue-600" />
        <StatCard icon={TrendingUp} label="En cours" value={stats.inProgress} color="bg-yellow-100 text-yellow-600" />
        <StatCard icon={TrendingUp} label="Terminés" value={stats.completed} color="bg-green-100 text-green-600" />
        <StatCard icon={DollarSign} label="Montant total" value={formatCurrency(stats.totalAmount)} color="bg-purple-100 text-purple-600" />
      </div>

      <div className="bg-white rounded-xl shadow-md p-4 mb-6 space-y-4">
        <div className="flex gap-4 flex-wrap items-end">
          <div className="flex-1 min-w-64">
            <label className="block text-sm font-medium text-gray-700 mb-2">Rechercher</label>
            <div className="relative">
              <Search className="absolute left-3 top-3 text-gray-400" size={20} />
              <input
                type="text"
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                placeholder="Chercher par référence, client..."
                className="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
              />
            </div>
          </div>

          <div className="flex gap-2 items-end">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">Du</label>
              <input type="date" value={dateFrom} onChange={(e) => setDateFrom(e.target.value)} className="px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500" />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">Au</label>
              <input type="date" value={dateTo} onChange={(e) => setDateTo(e.target.value)} className="px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500" />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">Statut</label>
              <select value={statusFilter} onChange={(e) => setStatusFilter(e.target.value)} className="px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500">
                <option value="all">Tous</option>
                <option value="pending">En attente</option>
                <option value="in_progress">En cours</option>
                <option value="completed">Terminé</option>
                <option value="delayed">Retardé</option>
                <option value="cancelled">Annulé</option>
              </select>
            </div>

            <button onClick={handleAddTransport} className="flex items-center gap-2 px-4 py-2 bg-gradient-to-r from-blue-600 to-blue-800 text-white rounded-lg hover:from-blue-700 hover:to-blue-900 font-medium">
              <Plus size={20} />
              Créer
            </button>
          </div>
        </div>
      </div>

      {error && (
        <div className="bg-red-50 border border-red-200 rounded-lg p-4 mb-6">
          <p className="text-red-700 font-medium">Erreur lors du chargement</p>
        </div>
      )}

      {isLoading ? (
        <TransportTableSkeleton />
      ) : transports.length === 0 ? (
        <div className="bg-white rounded-xl shadow-md p-12">
          <EmptyState />
        </div>
      ) : (
        <div className="bg-white rounded-xl shadow-md overflow-hidden">
          <table className="w-full text-sm">
            <thead className="bg-gray-50 border-b border-gray-200">
              <tr>
                <th className="px-6 py-3 text-left font-semibold text-gray-700">Réf.</th>
                <th className="px-6 py-3 text-left font-semibold text-gray-700">Trajet</th>
                <th className="px-6 py-3 text-left font-semibold text-gray-700">Véhicule</th>
                <th className="px-6 py-3 text-left font-semibold text-gray-700">Dates</th>
                <th className="px-6 py-3 text-left font-semibold text-gray-700">Fret</th>
                <th className="px-6 py-3 text-left font-semibold text-gray-700">Montant</th>
                <th className="px-6 py-3 text-left font-semibold text-gray-700">Paiement</th>
                <th className="px-6 py-3 text-left font-semibold text-gray-700">Statut</th>
                <th className="px-6 py-3 text-left font-semibold text-gray-700">Actions</th>
              </tr>
            </thead>
            <tbody>
              {transports.map((transport) => (
                <tr key={transport.id} className="border-b border-gray-200 hover:bg-gray-50">
                 <td className="px-6 py-4 font-medium text-gray-900">#{transport.reference}</td>
                 <td className="px-6 py-4">
                   <div className="flex items-center gap-2 text-gray-900">
                     <span>{transport.origin}</span>
                     <ArrowRight size={16} className="text-gray-400" />
                     <span>{transport.destination}</span>
                   </div>
                 </td>
                 <td className="px-6 py-4 text-gray-900">{transport.truck?.plate_number || '-'}</td>
                 <td className="px-6 py-4 text-gray-700 text-xs">
                   <div>Départ: {transport.scheduled_departure ? new Date(transport.scheduled_departure).toLocaleDateString('fr-FR') : '-'}</div>
                   <div>Arrivée: {transport.scheduled_arrival ? new Date(transport.scheduled_arrival).toLocaleDateString('fr-FR') : '-'}</div>
                 </td>
                 <td className="px-6 py-4 text-gray-900">
                   {transport.cargo_type} {transport.cargo_weight ? `(${transport.cargo_weight}kg)` : ''}
                 </td>
                 <td className="px-6 py-4 text-gray-900 font-semibold">{formatCurrency(parseFloat(transport.montant_transport || 0))}</td>
                 <td className="px-6 py-4">
                   <span className={`inline-block px-2 py-1 rounded text-xs font-semibold ${getPaymentStatusColor(transport.statut_paiement || 'non_paye')}`}>
                     {PAYMENT_STATUS_LABELS[transport.statut_paiement || 'non_paye']}
                   </span>
                 </td>
                  <td className="px-6 py-4">
                    <span className={`inline-block px-2 py-1 rounded text-xs font-semibold ${getStatusColor(transport.status)}`}>
                      {TRANSPORT_STATUS_LABELS[transport.status]}
                    </span>
                  </td>
                  <td className="px-6 py-4">
                    <div className="flex gap-2">
                      <button onClick={() => handleEditTransport(transport)} className="p-2 bg-blue-100 text-blue-700 rounded-lg hover:bg-blue-200" title="Éditer">
                        <Edit2 size={16} />
                      </button>
                      <button onClick={() => handleDeleteTransport(transport.id)} className="p-2 bg-red-100 text-red-700 rounded-lg hover:bg-red-200" title="Supprimer">
                        <Trash2 size={16} />
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      <TransportModal
        isOpen={isModalOpen}
        onClose={() => {
          setIsModalOpen(false);
          setSelectedTransport(null);
        }}
        onSubmit={handleModalSubmit}
        initialData={selectedTransport}
        isLoading={createMutation.isPending || updateMutation.isPending}
        trucks={trucks}
        drivers={drivers}
      />

      <DeleteConfirmDialog
        isOpen={deleteConfirm !== null}
        onConfirm={() => deleteMutation.mutate(deleteConfirm)}
        onCancel={() => setDeleteConfirm(null)}
        isLoading={deleteMutation.isPending}
      />
    </div>
  );
}
