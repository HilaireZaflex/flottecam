import React, { useState, useMemo } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { toast } from 'react-hot-toast';
import { useForm } from 'react-hook-form';
import { documentsApi, trucksApi, driversApi } from '../lib/api';
import {
  Plus,
  Search,
  Download,
  Trash2,
  AlertCircle,
  X,
  FileText,
  Shield,
  CreditCard,
  Wrench,
  Upload,
  Calendar,
} from 'lucide-react';

const CATEGORY_LABELS = {
  assurance: 'Assurance',
  permis: 'Permis',
  visite_technique: 'Visite technique',
  carte_grise: 'Carte grise',
  other: 'Autres',
};

const getCategoryIcon = (category) => {
  switch (category) {
    case 'assurance':
      return Shield;
    case 'permis':
      return CreditCard;
    case 'visite_technique':
      return Wrench;
    case 'carte_grise':
      return FileText;
    default:
      return FileText;
  }
};

const getCategoryColor = (category) => {
  switch (category) {
    case 'assurance':
      return 'bg-red-100 text-red-700';
    case 'permis':
      return 'bg-blue-100 text-blue-700';
    case 'visite_technique':
      return 'bg-orange-100 text-orange-700';
    case 'carte_grise':
      return 'bg-green-100 text-green-700';
    default:
      return 'bg-gray-100 text-gray-700';
  }
};

const getExpiryBadgeColor = (status) => {
  switch (status) {
    case 'expired':
      return 'bg-red-100 text-red-700';
    case 'expiring_soon':
      return 'bg-yellow-100 text-yellow-700';
    case 'valid':
      return 'bg-green-100 text-green-700';
    default:
      return 'bg-gray-100 text-gray-700';
  }
};

const getExpiryLabel = (status, expiryDate) => {
  if (!expiryDate) return 'Permanent';

  const today = new Date();
  const expiry = new Date(expiryDate);
  const daysUntilExpiry = Math.floor((expiry - today) / (1000 * 60 * 60 * 24));

  switch (status) {
    case 'expired':
      return 'Expiré';
    case 'expiring_soon':
      return `Expire bientôt (${daysUntilExpiry}j)`;
    case 'valid':
      return `Valide (${daysUntilExpiry}j)`;
    default:
      return 'Permanent';
  }
};

const DocumentCard = ({ document, onDelete, onDownload }) => {
  const IconComponent = getCategoryIcon(document.type);
  const isDocumentTruck = document.documentable_type && document.documentable_type.includes('Truck');

  return (
    <div className="bg-white rounded-xl shadow-md hover:shadow-lg transition-shadow overflow-hidden">
      <div className="p-6">
        <div className="flex items-start justify-between mb-4">
          <div className={`w-12 h-12 rounded-lg flex items-center justify-center ${getCategoryColor(document.type)}`}>
            <IconComponent size={24} />
          </div>
          <div className="flex gap-2">
            <button
              onClick={() => onDownload(document.id)}
              className="p-2 bg-blue-100 text-blue-700 rounded-lg hover:bg-blue-200 transition-colors"
              title="Télécharger"
            >
              <Download size={16} />
            </button>
            <button
              onClick={() => onDelete(document.id)}
              className="p-2 bg-red-100 text-red-700 rounded-lg hover:bg-red-200 transition-colors"
              title="Supprimer"
            >
              <Trash2 size={16} />
            </button>
          </div>
        </div>

        <div className="mb-3">
          <h3 className="font-semibold text-gray-900 mb-1">{document.name}</h3>
          <p className="text-xs text-gray-600">{CATEGORY_LABELS[document.type]}</p>
        </div>

        <div className="mb-3 pb-3 border-b border-gray-200">
          <p className="text-sm text-gray-700">
            <span className="font-medium">Entité:</span> {isDocumentTruck ? 'Camion' : 'Conducteur'}
          </p>
        </div>

        <div>
          <span className={`inline-block px-3 py-1 rounded-full text-xs font-semibold ${getExpiryBadgeColor(document.status)}`}>
            {getExpiryLabel(document.status, document.expiry_date)}
          </span>
        </div>
      </div>
    </div>
  );
};

const DocumentSkeleton = () => (
  <div className="bg-white rounded-xl shadow-md overflow-hidden animate-pulse">
    <div className="p-6">
      <div className="flex items-start justify-between mb-4">
        <div className="w-12 h-12 bg-gray-200 rounded-lg" />
        <div className="flex gap-2">
          <div className="w-10 h-10 bg-gray-200 rounded-lg" />
          <div className="w-10 h-10 bg-gray-200 rounded-lg" />
        </div>
      </div>
      <div className="space-y-2 mb-3">
        <div className="h-4 bg-gray-200 rounded w-32" />
        <div className="h-3 bg-gray-200 rounded w-24" />
      </div>
      <div className="h-4 bg-gray-200 rounded w-40 mb-3" />
      <div className="h-6 bg-gray-200 rounded w-28" />
    </div>
  </div>
);

const DocumentModal = ({ isOpen, onClose, onSubmit, isLoading, trucks = [], drivers = [] }) => {
  const {
    register,
    handleSubmit,
    reset,
    watch,
    formState: { errors },
  } = useForm({
    defaultValues: {
      name: '',
      type: 'assurance',
      entity_type: 'truck',
      entity_id: '',
      file: null,
      expiry_date: '',
    },
  });

  const entityType = watch('entity_type');

  React.useEffect(() => {
    if (!isOpen) reset();
  }, [isOpen, reset]);

  const handleFormSubmit = (data) => {
    onSubmit(data);
    reset();
  };

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 overflow-y-auto">
      <div className="bg-white rounded-xl shadow-xl w-full max-w-2xl my-8">
        <div className="sticky top-0 bg-gradient-to-r from-blue-600 to-blue-800 px-6 py-4 flex justify-between items-center">
          <h2 className="text-xl font-bold text-white">Télécharger un document</h2>
          <button onClick={onClose} className="text-white hover:bg-blue-700 p-1 rounded">
            <X size={24} />
          </button>
        </div>

        <form onSubmit={handleSubmit(handleFormSubmit)} className="p-6 space-y-4">
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Titre du document *
              </label>
              <input
                type="text"
                {...register('name', { required: 'Requis' })}
                className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                placeholder="ex: Assurance auto 2026"
              />
              {errors.name && (
                <p className="text-red-500 text-xs mt-1">{errors.name.message}</p>
              )}
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Type *
              </label>
              <select
                {...register('type')}
                className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
              >
                <option value="assurance">Assurance</option>
                <option value="permis">Permis</option>
                <option value="visite_technique">Visite technique</option>
                <option value="carte_grise">Carte grise</option>
                <option value="other">Autres</option>
              </select>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Type d'entité
              </label>
              <select
                {...register('entity_type')}
                className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
              >
                <option value="truck">Camion</option>
                <option value="driver">Conducteur</option>
              </select>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Sélectionner {entityType === 'truck' ? 'un camion' : 'un conducteur'} *
              </label>
              <select
                {...register('entity_id', { required: 'Requis' })}
                className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
              >
                <option value="">Sélectionner</option>
                {entityType === 'truck'
                  ? trucks.map((t) => (
                      <option key={t.id} value={t.id}>
                        {t.plate_number}
                      </option>
                    ))
                  : drivers.map((d) => (
                      <option key={d.id} value={d.id}>
                        {d.name}
                      </option>
                    ))}
              </select>
              {errors.entity_id && (
                <p className="text-red-500 text-xs mt-1">{errors.entity_id.message}</p>
              )}
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Date d'expiration (optionnel)
              </label>
              <input
                type="date"
                {...register('expiry_date')}
                className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
              />
            </div>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Fichier *
            </label>
            <div className="border-2 border-dashed border-gray-300 rounded-lg p-6 hover:border-blue-500 transition-colors">
              <input
                type="file"
                {...register('file', { required: 'Requis' })}
                className="w-full"
                accept=".pdf,.jpg,.jpeg,.png,.doc,.docx"
              />
              <p className="text-sm text-gray-600 mt-2">
                PDF, images ou documents autorisés
              </p>
            </div>
            {errors.file && (
              <p className="text-red-500 text-xs mt-1">{errors.file.message}</p>
            )}
          </div>

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
              {isLoading ? 'Téléchargement...' : 'Télécharger'}
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
            <h2 className="text-lg font-bold text-gray-900">Supprimer ce document?</h2>
          </div>
          <p className="text-gray-600 mb-6">Cette action est irréversible.</p>
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
      <FileText size={32} className="text-blue-600" />
    </div>
    <h3 className="text-lg font-semibold text-gray-900 mb-2">Aucun document trouvé</h3>
    <p className="text-gray-600 text-center max-w-md">
      Commencez par télécharger votre premier document.
    </p>
  </div>
);


export default function DocumentsPage() {
  const [searchTerm, setSearchTerm] = useState('');
  const [entityTypeFilter, setEntityTypeFilter] = useState('all');
  const [categoryFilter, setCategoryFilter] = useState('all');
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [deleteConfirm, setDeleteConfirm] = useState(null);
  const queryClient = useQueryClient();

  const { data: documentsResponse, isLoading, isError } = useQuery({
    queryKey: ['documents', searchTerm, entityTypeFilter, categoryFilter],
    queryFn: () =>
      documentsApi.list({
        search: searchTerm,
        entity_type: entityTypeFilter === 'all' ? '' : entityTypeFilter,
        category: categoryFilter === 'all' ? '' : categoryFilter,
      }),
  });
  const documents = Array.isArray(documentsResponse?.data?.data) ? documentsResponse.data.data : Array.isArray(documentsResponse?.data) ? documentsResponse.data : [];
  // isLoading from useQuery
  const error = null;

  const { data: trucksResponse } = useQuery({
    queryKey: ['trucks'],
    queryFn: () => trucksApi.list(),
  });
  const trucks = trucksResponse?.data?.data || [];

  const { data: driversResponse } = useQuery({
    queryKey: ['drivers'],
    queryFn: () => driversApi.list(),
  });
  const drivers = driversResponse?.data?.data || [];

  const createMutation = useMutation({
    mutationFn: (data) => documentsApi.create(data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['documents'] });
      setIsModalOpen(false);
      toast.success('Document téléchargé avec succès');
    },
    onError: () => toast.error('Erreur lors du téléchargement'),
  });

  const deleteMutation = useMutation({
    mutationFn: (id) => documentsApi.delete(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['documents'] });
      setDeleteConfirm(null);
      toast.success('Document supprimé avec succès');
    },
    onError: () => toast.error('Erreur lors de la suppression'),
  });

  const handleDownload = async (id) => {
    try {
      await documentsApi.download(id);
      toast.success('Document téléchargé');
    } catch {
      toast.error('Erreur lors du téléchargement');
    }
  };

  const handleModalSubmit = (data) => {
    createMutation.mutate(data);
  };

  const filteredDocuments = useMemo(() => {
    return documents.filter((doc) => {
      const isDocumentTruck = doc.documentable_type && doc.documentable_type.includes('Truck');
      const matchesSearch =
        doc.name.toLowerCase().includes(searchTerm.toLowerCase());
      const matchesEntityType =
        entityTypeFilter === 'all' || 
        (entityTypeFilter === 'truck' && isDocumentTruck) ||
        (entityTypeFilter === 'driver' && !isDocumentTruck);
      const matchesType =
        categoryFilter === 'all' || doc.type === categoryFilter;
      return matchesSearch && matchesEntityType && matchesType;
    });
  }, [documents, searchTerm, entityTypeFilter, categoryFilter]);

  return (
    <div className="p-6 bg-gray-50 min-h-screen">
      {/* Header */}
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-gray-900 mb-2">Gestion des documents</h1>
        <p className="text-gray-600">Gérez les documents de votre flotte</p>
      </div>

      {/* Filters */}
      <div className="bg-white rounded-xl shadow-md p-4 mb-6">
        <div className="flex gap-4 flex-wrap items-end">
          <div className="flex-1 min-w-64">
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Rechercher
            </label>
            <div className="relative">
              <Search className="absolute left-3 top-3 text-gray-400" size={20} />
              <input
                type="text"
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                placeholder="Chercher par titre ou entité..."
                className="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
              />
            </div>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Type d'entité
            </label>
            <select
              value={entityTypeFilter}
              onChange={(e) => setEntityTypeFilter(e.target.value)}
              className="px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              <option value="all">Tous</option>
              <option value="truck">Camion</option>
              <option value="driver">Conducteur</option>
            </select>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Catégorie
            </label>
            <select
              value={categoryFilter}
              onChange={(e) => setCategoryFilter(e.target.value)}
              className="px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              <option value="all">Tous</option>
              <option value="assurance">Assurance</option>
              <option value="permis">Permis</option>
              <option value="visite_technique">Visite technique</option>
              <option value="carte_grise">Carte grise</option>
              <option value="other">Autres</option>
            </select>
          </div>

          <button
            onClick={() => setIsModalOpen(true)}
            className="flex items-center gap-2 px-4 py-2 bg-gradient-to-r from-blue-600 to-blue-800 text-white rounded-lg hover:from-blue-700 hover:to-blue-900 font-medium"
          >
            <Upload size={20} />
            Télécharger
          </button>
        </div>
      </div>

      {/* Error state */}
      {error && (
        <div className="bg-red-50 border border-red-200 rounded-lg p-4 mb-6">
          <p className="text-red-700 font-medium">
            Erreur lors du chargement des documents
          </p>
        </div>
      )}

      {/* Grid */}
      {isLoading ? (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {[...Array(6)].map((_, i) => (
            <DocumentSkeleton key={i} />
          ))}
        </div>
      ) : filteredDocuments.length === 0 ? (
        <div className="bg-white rounded-xl shadow-md p-12">
          <EmptyState />
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {filteredDocuments.map((document) => (
            <DocumentCard
              key={document.id}
              document={document}
              onDelete={() => setDeleteConfirm(document.id)}
              onDownload={handleDownload}
            />
          ))}
        </div>
      )}

      {/* Modals */}
      <DocumentModal
        isOpen={isModalOpen}
        onClose={() => setIsModalOpen(false)}
        onSubmit={handleModalSubmit}
        isLoading={createMutation.isPending}
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
