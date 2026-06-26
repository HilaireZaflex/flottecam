import React, { useState, useMemo } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { toast } from 'react-hot-toast';
import { useForm } from 'react-hook-form';
import {
  Plus,
  Search,
  Edit2,
  Trash2,
  AlertCircle,
  X,
  Badge,
} from 'lucide-react';
import { driversApi } from '../lib/api';

const DRIVER_STATUS_LABELS = {
  available: 'Disponible',
  on_mission: 'En mission',
  on_leave: 'En congé',
  inactive: 'Inactif',
};

const getStatusColor = (status) => {
  switch (status) {
    case 'available':
      return 'bg-green-100 text-green-700';
    case 'on_mission':
      return 'bg-blue-100 text-blue-700';
    case 'on_leave':
      return 'bg-cyan-100 text-cyan-700';
    case 'inactive':
      return 'bg-red-100 text-red-700';
    default:
      return 'bg-gray-100 text-gray-700';
  }
};

const getInitialBgColor = (index) => {
  const colors = [
    'bg-blue-500',
    'bg-purple-500',
    'bg-pink-500',
    'bg-green-500',
    'bg-yellow-500',
    'bg-red-500',
    'bg-indigo-500',
    'bg-cyan-500',
  ];
  return colors[index % colors.length];
};

const DriverAvatar = ({ fullName, firstName, index }) => {
  const displayName = fullName || (firstName ? firstName : '');
  const initials = displayName
    .split(' ')
    .map((part) => part[0])
    .join('')
    .toUpperCase()
    .slice(0, 2);

  return (
    <div className={`w-10 h-10 ${getInitialBgColor(index)} rounded-full flex items-center justify-center text-white font-bold text-sm`}>
      {initials}
    </div>
  );
};

const DriverTableSkeleton = () => (
  <div className="bg-white rounded-xl shadow-md overflow-hidden">
    <table className="w-full">
      <thead className="bg-gray-50 border-b border-gray-200">
        <tr>
          <th className="px-6 py-3 text-left text-sm font-semibold text-gray-700">Conducteur</th>
          <th className="px-6 py-3 text-left text-sm font-semibold text-gray-700">Permis</th>
          <th className="px-6 py-3 text-left text-sm font-semibold text-gray-700">Téléphone</th>
          <th className="px-6 py-3 text-left text-sm font-semibold text-gray-700">Expérience</th>
          <th className="px-6 py-3 text-left text-sm font-semibold text-gray-700">Statut</th>
          <th className="px-6 py-3 text-left text-sm font-semibold text-gray-700">Camion</th>
          <th className="px-6 py-3 text-left text-sm font-semibold text-gray-700">Actions</th>
        </tr>
      </thead>
      <tbody>
        {[...Array(5)].map((_, i) => (
          <tr key={i} className="border-b border-gray-200 animate-pulse">
            <td className="px-6 py-4">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 bg-gray-200 rounded-full" />
                <div className="h-4 bg-gray-200 rounded w-32" />
              </div>
            </td>
            <td className="px-6 py-4">
              <div className="h-4 bg-gray-200 rounded w-24" />
            </td>
            <td className="px-6 py-4">
              <div className="h-4 bg-gray-200 rounded w-28" />
            </td>
            <td className="px-6 py-4">
              <div className="h-4 bg-gray-200 rounded w-16" />
            </td>
            <td className="px-6 py-4">
              <div className="h-6 bg-gray-200 rounded w-20" />
            </td>
            <td className="px-6 py-4">
              <div className="h-4 bg-gray-200 rounded w-20" />
            </td>
            <td className="px-6 py-4">
              <div className="flex gap-2">
                <div className="h-8 bg-gray-200 rounded w-8" />
                <div className="h-8 bg-gray-200 rounded w-8" />
              </div>
            </td>
          </tr>
        ))}
      </tbody>
    </table>
  </div>
);

const DriverModal = ({ isOpen, onClose, onSubmit, initialData, isLoading }) => {
  const {
    register,
    handleSubmit,
    reset,
    formState: { errors },
  } = useForm({
    defaultValues: initialData || {
      first_name: '',
      last_name: '',
      license_number: '',
      license_type: 'B',
      license_expiry: '',
      phone: '',
      address: '',
      status: 'available',
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
            {initialData ? 'Modifier un conducteur' : 'Ajouter un conducteur'}
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
                Prénom *
              </label>
              <input
                type="text"
                {...register('first_name', { required: 'Requis' })}
                className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                placeholder="ex: Jean"
              />
              {errors.first_name && (
                <p className="text-red-500 text-xs mt-1">{errors.first_name.message}</p>
              )}
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Nom *
              </label>
              <input
                type="text"
                {...register('last_name', { required: 'Requis' })}
                className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                placeholder="ex: Dupont"
              />
              {errors.last_name && (
                <p className="text-red-500 text-xs mt-1">{errors.last_name.message}</p>
              )}
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Numéro de permis *
              </label>
              <input
                type="text"
                {...register('license_number', { required: 'Requis' })}
                className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                placeholder="ex: 1234567890"
              />
              {errors.license_number && (
                <p className="text-red-500 text-xs mt-1">{errors.license_number.message}</p>
              )}
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Catégorie de permis
              </label>
              <select
                {...register('license_type')}
                className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
              >
                <option value="B">Catégorie B</option>
                <option value="C">Catégorie C</option>
                <option value="D">Catégorie D</option>
                <option value="EC">Catégorie EC</option>
              </select>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Expiration du permis
              </label>
              <input
                type="date"
                {...register('license_expiry')}
                className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Téléphone
              </label>
              <input
                type="tel"
                {...register('phone')}
                className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                placeholder="ex: +221 77 123 45 67"
              />
            </div>

            <div className="col-span-2">
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Adresse
              </label>
              <input
                type="text"
                {...register('address')}
                className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                placeholder="ex: 123 Rue de la Paix, Dakar"
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
                <option value="on_leave">En congé</option>
                <option value="inactive">Inactif</option>
              </select>
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
            <h2 className="text-lg font-bold text-gray-900">Supprimer ce conducteur?</h2>
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
      <Badge size={32} className="text-blue-600" />
    </div>
    <h3 className="text-lg font-semibold text-gray-900 mb-2">Aucun conducteur trouvé</h3>
    <p className="text-gray-600 text-center max-w-md">
      Commencez par ajouter votre premier conducteur à l'équipe.
    </p>
  </div>
);

export default function DriversPage() {
  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState('all');
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [selectedDriver, setSelectedDriver] = useState(null);
  const [deleteConfirm, setDeleteConfirm] = useState(null);
  const queryClient = useQueryClient();

  const { data: driversResponse, isLoading, isError } = useQuery({
    queryKey: ['drivers', searchTerm],
    queryFn: () => driversApi.list({ search: searchTerm }),
  });
  const drivers = Array.isArray(driversResponse?.data?.data) ? driversResponse.data.data : Array.isArray(driversResponse?.data) ? driversResponse.data : [];
  // isLoading from useQuery
  const error = null;

  const createMutation = useMutation({
    mutationFn: (data) => driversApi.create(data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['drivers'] });
      setIsModalOpen(false);
      setSelectedDriver(null);
      toast.success('Conducteur créé avec succès');
    },
    onError: () => toast.error('Erreur lors de la création'),
  });

  const updateMutation = useMutation({
    mutationFn: ({ id, data }) => driversApi.update(id, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['drivers'] });
      setIsModalOpen(false);
      setSelectedDriver(null);
      toast.success('Conducteur modifié avec succès');
    },
    onError: () => toast.error('Erreur lors de la modification'),
  });

  const deleteMutation = useMutation({
    mutationFn: (id) => driversApi.delete(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['drivers'] });
      setDeleteConfirm(null);
      toast.success('Conducteur supprimé avec succès');
    },
    onError: () => toast.error('Erreur lors de la suppression'),
  });

  const filteredDrivers = useMemo(() => {
    if (!Array.isArray(drivers)) {
      return [];
    }
    return drivers.filter((driver) =>
      statusFilter === 'all' ? true : driver.status === statusFilter
    );
  }, [drivers, statusFilter]);

  const handleAddDriver = () => {
    setSelectedDriver(null);
    setIsModalOpen(true);
  };

  const handleEditDriver = (driver) => {
    setSelectedDriver(driver);
    setIsModalOpen(true);
  };

  const handleDeleteDriver = (id) => {
    setDeleteConfirm(id);
  };

  const handleModalSubmit = (data) => {
    if (selectedDriver) {
      updateMutation.mutate({ id: selectedDriver.id, data });
    } else {
      createMutation.mutate(data);
    }
  };

  return (
    <div className="p-6 bg-gray-50 min-h-screen">
      {/* Header */}
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-gray-900 mb-2">Gestion des conducteurs</h1>
        <p className="text-gray-600">Gérez votre équipe de conducteurs</p>
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
              placeholder="Chercher par nom ou numéro de permis..."
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
            <option value="on_leave">En congé</option>
            <option value="inactive">Inactif</option>
          </select>
        </div>

        <button
          onClick={handleAddDriver}
          className="flex items-center gap-2 px-4 py-2 bg-gradient-to-r from-blue-600 to-blue-800 text-white rounded-lg hover:from-blue-700 hover:to-blue-900 font-medium"
        >
          <Plus size={20} />
          Ajouter un conducteur
        </button>
      </div>

      {/* Error state */}
      {error && (
        <div className="bg-red-50 border border-red-200 rounded-lg p-4 mb-6">
          <p className="text-red-700 font-medium">Erreur lors du chargement des conducteurs</p>
        </div>
      )}

      {/* Table */}
      {isLoading ? (
        <DriverTableSkeleton />
      ) : filteredDrivers.length === 0 ? (
        <div className="bg-white rounded-xl shadow-md p-12">
          <EmptyState />
        </div>
      ) : (
        <div className="bg-white rounded-xl shadow-md overflow-hidden">
          <table className="w-full">
            <thead className="bg-gray-50 border-b border-gray-200">
              <tr>
                <th className="px-6 py-3 text-left text-sm font-semibold text-gray-700">
                  Conducteur
                </th>
                <th className="px-6 py-3 text-left text-sm font-semibold text-gray-700">
                  Permis
                </th>
                <th className="px-6 py-3 text-left text-sm font-semibold text-gray-700">
                  Téléphone
                </th>
                <th className="px-6 py-3 text-left text-sm font-semibold text-gray-700">
                  Statut
                </th>
                <th className="px-6 py-3 text-left text-sm font-semibold text-gray-700">
                  Camion assigné
                </th>
                <th className="px-6 py-3 text-left text-sm font-semibold text-gray-700">
                  Actions
                </th>
              </tr>
            </thead>
            <tbody>
              {filteredDrivers.map((driver, index) => (
                <tr
                  key={driver.id}
                  className="border-b border-gray-200 hover:bg-gray-50 transition-colors"
                >
                  <td className="px-6 py-4">
                    <div className="flex items-center gap-3">
                      <DriverAvatar 
                        fullName={driver.full_name} 
                        firstName={driver.first_name} 
                        index={index} 
                      />
                      <div>
                        <p className="font-semibold text-gray-900">
                          {driver.full_name || `${driver.first_name} ${driver.last_name}`}
                        </p>
                        <p className="text-sm text-gray-500">{driver.address}</p>
                      </div>
                    </div>
                  </td>
                  <td className="px-6 py-4">
                    <div>
                      <p className="font-medium text-gray-900">{driver.license_number}</p>
                      <p className="text-sm text-gray-500">Cat. {driver.license_type}</p>
                    </div>
                  </td>
                  <td className="px-6 py-4 text-gray-900">{driver.phone || '-'}</td>
                  <td className="px-6 py-4">
                    <span
                      className={`inline-block px-3 py-1 rounded-full text-xs font-semibold ${getStatusColor(
                        driver.status
                      )}`}
                    >
                      {DRIVER_STATUS_LABELS[driver.status]}
                    </span>
                  </td>
                  <td className="px-6 py-4 text-gray-900">
                    {driver.truck ? (
                      <span className="inline-block px-3 py-1 bg-blue-50 text-blue-700 rounded text-sm font-medium">
                        {driver.truck.plate_number}
                      </span>
                    ) : (
                      <span className="text-gray-500">-</span>
                    )}
                  </td>
                  <td className="px-6 py-4">
                    <div className="flex gap-2">
                      <button
                        onClick={() => handleEditDriver(driver)}
                        className="p-2 bg-blue-100 text-blue-700 rounded-lg hover:bg-blue-200 transition-colors"
                        title="Éditer"
                      >
                        <Edit2 size={16} />
                      </button>
                      <button
                        onClick={() => handleDeleteDriver(driver.id)}
                        className="p-2 bg-red-100 text-red-700 rounded-lg hover:bg-red-200 transition-colors"
                        title="Supprimer"
                      >
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

      {/* Modals */}
      <DriverModal
        isOpen={isModalOpen}
        onClose={() => {
          setIsModalOpen(false);
          setSelectedDriver(null);
        }}
        onSubmit={handleModalSubmit}
        initialData={selectedDriver}
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
