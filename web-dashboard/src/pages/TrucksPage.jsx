import React, { useState, useMemo } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { toast } from 'react-hot-toast';
import { useForm } from 'react-hook-form';
import {
  Plus,
  Search,
  Edit2,
  Trash2,
  Eye,
  Truck,
  AlertCircle,
  X,
  Check,
} from 'lucide-react';
import { trucksApi } from '../lib/api';

const TRUCK_STATUS_LABELS = {
  available: 'Disponible',
  on_mission: 'En mission',
  maintenance: 'Maintenance',
  out_of_service: 'Hors service',
};

const getStatusColor = (status) => {
  switch (status) {
    case 'available':
      return 'bg-green-100 text-green-700';
    case 'on_mission':
      return 'bg-blue-100 text-blue-700';
    case 'maintenance':
      return 'bg-yellow-100 text-yellow-700';
    case 'out_of_service':
      return 'bg-red-100 text-red-700';
    default:
      return 'bg-gray-100 text-gray-700';
  }
};

const getStatusGradient = (status) => {
  switch (status) {
    case 'available':
      return 'from-green-400 to-green-600';
    case 'on_mission':
      return 'from-blue-400 to-blue-600';
    case 'maintenance':
      return 'from-yellow-400 to-yellow-600';
    case 'out_of_service':
      return 'from-red-400 to-red-600';
    default:
      return 'from-gray-400 to-gray-600';
  }
};

const TruckCard = ({ truck, onEdit, onDelete, onViewDetails }) => {
  return (
    <div className="bg-white rounded-xl shadow-md hover:shadow-lg transition-shadow overflow-hidden">
      {/* Header with gradient */}
      <div className={`bg-gradient-to-r ${getStatusGradient(truck.status)} h-20 flex items-center px-6`}>
        <div className="flex-1">
          <p className="text-white font-bold text-xl">{truck.plate_number}</p>
          <p className="text-white text-sm opacity-90">
            {truck.brand} {truck.model} • {truck.year}
          </p>
        </div>
      </div>

      {/* Body */}
      <div className="p-6">
        <div className="space-y-3 mb-4">
          <div className="grid grid-cols-2 gap-4 text-sm">
            <div>
              <p className="text-gray-500">Capacité</p>
              <p className="text-gray-900 font-semibold">{truck.capacity} km</p>
            </div>
            <div>
              <p className="text-gray-500">Type carburant</p>
              <p className="text-gray-900 font-semibold">{truck.fuel_type}</p>
            </div>
            <div>
              <p className="text-gray-500">Kilométrage</p>
              <p className="text-gray-900 font-semibold">{truck.mileage?.toLocaleString()} km</p>
            </div>
            <div>
              <p className="text-gray-500">Ville</p>
              <p className="text-gray-900 font-semibold">{truck.ville_actuelle}</p>
            </div>
          </div>
          <div className="border-t pt-3">
            <p className="text-gray-500 text-sm">Propriétaire</p>
            <p className="text-gray-900 font-semibold">{truck.proprietaire}</p>
          </div>
        </div>

        {/* Status Badge */}
        <div className="mb-4">
          <span className={`inline-block px-3 py-1 rounded-full text-xs font-semibold ${getStatusColor(truck.status)}`}>
            {TRUCK_STATUS_LABELS[truck.status]}
          </span>
        </div>

        {/* Actions */}
        <div className="flex gap-2">
          <button
            onClick={() => onViewDetails(truck)}
            className="flex-1 flex items-center justify-center gap-2 px-3 py-2 bg-blue-100 text-blue-700 rounded-lg hover:bg-blue-200 transition-colors text-sm font-medium"
          >
            <Eye size={16} />
            Détails
          </button>
          <button
            onClick={() => onEdit(truck)}
            className="flex-1 flex items-center justify-center gap-2 px-3 py-2 bg-gray-100 text-gray-700 rounded-lg hover:bg-gray-200 transition-colors text-sm font-medium"
          >
            <Edit2 size={16} />
            Éditer
          </button>
          <button
            onClick={() => onDelete(truck.id)}
            className="flex-1 flex items-center justify-center gap-2 px-3 py-2 bg-red-100 text-red-700 rounded-lg hover:bg-red-200 transition-colors text-sm font-medium"
          >
            <Trash2 size={16} />
            Supprimer
          </button>
        </div>
      </div>
    </div>
  );
};

const TruckSkeleton = () => (
  <div className="bg-white rounded-xl shadow-md overflow-hidden animate-pulse">
    <div className="h-20 bg-gray-200" />
    <div className="p-6">
      <div className="space-y-3 mb-4">
        <div className="h-4 bg-gray-200 rounded w-32" />
        <div className="h-4 bg-gray-200 rounded w-full" />
        <div className="h-4 bg-gray-200 rounded w-full" />
      </div>
      <div className="h-8 bg-gray-200 rounded w-24 mb-4" />
      <div className="space-y-2">
        <div className="h-10 bg-gray-200 rounded" />
        <div className="grid grid-cols-2 gap-2">
          <div className="h-10 bg-gray-200 rounded" />
          <div className="h-10 bg-gray-200 rounded" />
        </div>
      </div>
    </div>
  </div>
);

const TruckModal = ({ isOpen, onClose, onSubmit, initialData, isLoading }) => {
  const {
    register,
    handleSubmit,
    reset,
    formState: { errors },
  } = useForm({
    defaultValues: initialData || {
      plate_number: '',
      brand: '',
      model: '',
      year: new Date().getFullYear(),
      capacity: '',
      fuel_type: 'Diesel',
      mileage: '',
      status: 'available',
      proprietaire: '',
      ville_actuelle: '',
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
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
      <div className="bg-white rounded-xl shadow-xl w-full max-w-2xl max-h-[90vh] overflow-y-auto">
        {/* Header */}
        <div className="sticky top-0 bg-gradient-to-r from-blue-600 to-blue-800 px-6 py-4 flex justify-between items-center">
          <h2 className="text-xl font-bold text-white">
            {initialData ? 'Modifier un camion' : 'Ajouter un camion'}
          </h2>
          <button onClick={onClose} className="text-white hover:bg-blue-700 p-1 rounded">
            <X size={24} />
          </button>
        </div>

        {/* Form */}
        <form onSubmit={handleSubmit(handleFormSubmit)} className="p-6 space-y-4">
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Immatriculation *
              </label>
              <input
                type="text"
                {...register('plate_number', { required: 'Requis' })}
                className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                placeholder="ex: ABC-123"
              />
              {errors.plate_number && (
                <p className="text-red-500 text-xs mt-1">{errors.plate_number.message}</p>
              )}
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Marque
              </label>
              <input
                type="text"
                {...register('brand')}
                className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                placeholder="ex: Volvo"
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Modèle
              </label>
              <input
                type="text"
                {...register('model')}
                className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                placeholder="ex: FH16"
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Année
              </label>
              <input
                type="number"
                {...register('year')}
                className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Capacité (kg)
              </label>
              <input
                type="number"
                {...register('capacity')}
                className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                placeholder="ex: 20000"
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Type carburant
              </label>
              <select
                {...register('fuel_type')}
                className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
              >
                <option value="Diesel">Diesel</option>
                <option value="Essence">Essence</option>
                <option value="Électrique">Électrique</option>
                <option value="Hybride">Hybride</option>
              </select>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Kilométrage
              </label>
              <input
                type="number"
                {...register('mileage')}
                className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                placeholder="ex: 150000"
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Statut
              </label>
              <select
                {...register('status')}
                className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
              >
                <option value="available">Disponible</option>
                <option value="on_mission">En mission</option>
                <option value="maintenance">Maintenance</option>
                <option value="out_of_service">Hors service</option>
              </select>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Propriétaire
              </label>
              <input
                type="text"
                {...register('proprietaire')}
                className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                placeholder="Nom du propriétaire"
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Ville actuelle
              </label>
              <input
                type="text"
                {...register('ville_actuelle')}
                className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                placeholder="ex: Dakar"
              />
            </div>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Remarques
            </label>
            <textarea
              {...register('notes')}
              className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
              rows="3"
              placeholder="Notes additionnelles..."
            />
          </div>

          {/* Actions */}
          <div className="flex gap-3 pt-4">
            <button
              type="button"
              onClick={onClose}
              className="flex-1 px-4 py-2 bg-gray-100 text-gray-700 rounded-lg hover:bg-gray-200 font-medium"
            >
              Annuler
            </button>
            <button
              type="submit"
              disabled={isLoading}
              className="flex-1 px-4 py-2 bg-gradient-to-r from-blue-600 to-blue-800 text-white rounded-lg hover:from-blue-700 hover:to-blue-900 font-medium disabled:opacity-50"
            >
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
            <h2 className="text-lg font-bold text-gray-900">Supprimer ce camion?</h2>
          </div>
          <p className="text-gray-600 mb-6">
            Cette action est irréversible. Tous les données associées seront supprimées.
          </p>
          <div className="flex gap-3">
            <button
              onClick={onCancel}
              className="flex-1 px-4 py-2 bg-gray-100 text-gray-700 rounded-lg hover:bg-gray-200 font-medium"
            >
              Annuler
            </button>
            <button
              onClick={onConfirm}
              disabled={isLoading}
              className="flex-1 px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700 font-medium disabled:opacity-50"
            >
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
      <Truck size={32} className="text-blue-600" />
    </div>
    <h3 className="text-lg font-semibold text-gray-900 mb-2">Aucun camion trouvé</h3>
    <p className="text-gray-600 text-center max-w-md">
      Commencez par ajouter votre premier camion à la flotte.
    </p>
  </div>
);

export default function TrucksPage() {
  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState('all');
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [selectedTruck, setSelectedTruck] = useState(null);
  const [deleteConfirm, setDeleteConfirm] = useState(null);
  const queryClient = useQueryClient();

  const { data: trucksResponse, isLoading, isError } = useQuery({
    queryKey: ['trucks', searchTerm],
    queryFn: () => trucksApi.list({ search: searchTerm }),
  });
  const trucks = Array.isArray(trucksResponse?.data?.data) ? trucksResponse.data.data : Array.isArray(trucksResponse?.data) ? trucksResponse.data : [];
  // isLoading from useQuery
  const error = null;

  const createMutation = useMutation({
    mutationFn: (data) => trucksApi.create(data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['trucks'] });
      setIsModalOpen(false);
      setSelectedTruck(null);
      toast.success('Camion créé avec succès');
    },
    onError: () => toast.error('Erreur lors de la création'),
  });

  const updateMutation = useMutation({
    mutationFn: ({ id, data }) => trucksApi.update(id, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['trucks'] });
      setIsModalOpen(false);
      setSelectedTruck(null);
      toast.success('Camion modifié avec succès');
    },
    onError: () => toast.error('Erreur lors de la modification'),
  });

  const deleteMutation = useMutation({
    mutationFn: (id) => trucksApi.delete(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['trucks'] });
      setDeleteConfirm(null);
      toast.success('Camion supprimé avec succès');
    },
    onError: () => toast.error('Erreur lors de la suppression'),
  });

  const filteredTrucks = useMemo(() => {
    return trucks.filter((truck) =>
      statusFilter === 'all' ? true : truck.status === statusFilter
    );
  }, [trucks, statusFilter]);

  const handleAddTruck = () => {
    setSelectedTruck(null);
    setIsModalOpen(true);
  };

  const handleEditTruck = (truck) => {
    setSelectedTruck(truck);
    setIsModalOpen(true);
  };

  const handleDeleteTruck = (id) => {
    setDeleteConfirm(id);
  };

  const handleModalSubmit = (data) => {
    if (selectedTruck) {
      updateMutation.mutate({ id: selectedTruck.id, data });
    } else {
      createMutation.mutate(data);
    }
  };

  return (
    <div className="p-6 bg-gray-50 min-h-screen">
      {/* Header */}
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-gray-900 mb-2">Gestion des camions</h1>
        <p className="text-gray-600">Gérez votre flotte de véhicules</p>
      </div>

      {/* Filters */}
      <div className="bg-white rounded-xl shadow-md p-4 mb-6 flex gap-4 items-end">
        <div className="flex-1">
          <label className="block text-sm font-medium text-gray-700 mb-2">Rechercher</label>
          <div className="relative">
            <Search className="absolute left-3 top-3 text-gray-400" size={20} />
            <input
              type="text"
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              placeholder="Chercher par immatriculation..."
              className="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
          </div>
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-700 mb-2">Statut</label>
          <select
            value={statusFilter}
            onChange={(e) => setStatusFilter(e.target.value)}
            className="px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
          >
            <option value="all">Tous les statuts</option>
            <option value="available">Disponible</option>
            <option value="on_mission">En mission</option>
            <option value="maintenance">Maintenance</option>
            <option value="out_of_service">Hors service</option>
          </select>
        </div>

        <button
          onClick={handleAddTruck}
          className="flex items-center gap-2 px-4 py-2 bg-gradient-to-r from-blue-600 to-blue-800 text-white rounded-lg hover:from-blue-700 hover:to-blue-900 font-medium"
        >
          <Plus size={20} />
          Ajouter un camion
        </button>
      </div>

      {/* Error state */}
      {error && (
        <div className="bg-red-50 border border-red-200 rounded-lg p-4 mb-6">
          <p className="text-red-700 font-medium">Erreur lors du chargement des camions</p>
        </div>
      )}

      {/* Loading state */}
      {isLoading ? (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {[...Array(6)].map((_, i) => (
            <TruckSkeleton key={i} />
          ))}
        </div>
      ) : filteredTrucks.length === 0 ? (
        <div className="bg-white rounded-xl shadow-md p-12">
          <EmptyState />
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {filteredTrucks.map((truck) => (
            <TruckCard
              key={truck.id}
              truck={truck}
              onEdit={handleEditTruck}
              onDelete={handleDeleteTruck}
              onViewDetails={(truck) => {
                // Could open a detailed view modal
              }}
            />
          ))}
        </div>
      )}

      {/* Modals */}
      <TruckModal
        isOpen={isModalOpen}
        onClose={() => {
          setIsModalOpen(false);
          setSelectedTruck(null);
        }}
        onSubmit={handleModalSubmit}
        initialData={selectedTruck}
        isLoading={createMutation.isPending || updateMutation.isPending}
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
