import { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { Plus, Trash2, Edit2, Search, X, AlertCircle } from 'lucide-react';
import { operationsApi, trucksApi } from '../lib/api';
import toast from 'react-hot-toast';

const StatsBar = ({ totals }) => (
  <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
    <div className="bg-gradient-to-br from-green-50 to-green-100 border border-green-200 rounded-xl p-6">
      <p className="text-sm font-medium text-green-700">Total Recettes</p>
      <p className="text-3xl font-bold text-green-900 mt-2">
        {(totals.recettes || 0).toLocaleString('fr-FR', { style: 'currency', currency: 'XOF', maximumFractionDigits: 0 })}
      </p>
    </div>
    <div className="bg-gradient-to-br from-red-50 to-red-100 border border-red-200 rounded-xl p-6">
      <p className="text-sm font-medium text-red-700">Total Dépenses</p>
      <p className="text-3xl font-bold text-red-900 mt-2">
        {(totals.depenses || 0).toLocaleString('fr-FR', { style: 'currency', currency: 'XOF', maximumFractionDigits: 0 })}
      </p>
    </div>
    <div className={`bg-gradient-to-br ${totals.benefice >= 0 ? 'from-blue-50 to-blue-100 border-blue-200' : 'from-orange-50 to-orange-100 border-orange-200'} border rounded-xl p-6`}>
      <p className={`text-sm font-medium ${totals.benefice >= 0 ? 'text-blue-700' : 'text-orange-700'}`}>Bénéfice Net</p>
      <p className={`text-3xl font-bold ${totals.benefice >= 0 ? 'text-blue-900' : 'text-orange-900'} mt-2`}>
        {(totals.benefice || 0).toLocaleString('fr-FR', { style: 'currency', currency: 'XOF', maximumFractionDigits: 0 })}
      </p>
    </div>
  </div>
);

const OperationModal = ({ isOpen, onClose, operation, onSubmit, trucks }) => {
  const [formData, setFormData] = useState(operation || {
    type_operation: operation?.type_operation || 'recette',
    truck_id: operation?.truck_id || '',
    categorie: operation?.categorie || '',
    prix_unitaire: operation?.prix_unitaire || '',
    designation: operation?.designation || '',
    quantite: operation?.quantite || 1,
    notes: operation?.notes || '',
    date: operation?.date || new Date().toISOString().split('T')[0],
  });

  const handleSubmit = (e) => {
    e.preventDefault();
    onSubmit(formData);
  };

  const categories = ['Carburant', 'Maintenance', 'Assurance', 'Péage', 'Transport', 'Autre'];
  const types = ['recette', 'depense'];

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4 z-50">
      <div className="bg-white rounded-xl shadow-2xl max-w-md w-full">
        <div className="flex items-center justify-between p-6 border-b border-gray-200">
          <h2 className="text-xl font-bold text-gray-900">
            {operation ? 'Modifier l\'opération' : 'Nouvelle opération'}
          </h2>
          <button onClick={onClose} className="text-gray-400 hover:text-gray-600">
            <X size={24} />
          </button>
        </div>

        <form onSubmit={handleSubmit} className="p-6 space-y-4">
          <div>
            <label className="block text-sm font-medium text-gray-900 mb-1">Type</label>
            <select
              value={formData.type_operation}
              onChange={(e) => setFormData({ ...formData, type_operation: e.target.value })}
              className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
              required
            >
              {types.map(t => (
                <option key={t} value={t}>{t === 'recette' ? 'Recette' : 'Dépense'}</option>
              ))}
            </select>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-900 mb-1">Camion</label>
            <select
              value={formData.truck_id}
              onChange={(e) => setFormData({ ...formData, truck_id: e.target.value })}
              className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
              required
            >
              <option value="">Sélectionner un camion</option>
              {trucks?.map(truck => (
                <option key={truck.id} value={truck.id}>{truck.plate_number}</option>
              ))}
            </select>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-900 mb-1">Catégorie</label>
            <select
              value={formData.categorie}
              onChange={(e) => setFormData({ ...formData, categorie: e.target.value })}
              className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
              required
            >
              <option value="">Sélectionner une catégorie</option>
              {categories.map(cat => (
                <option key={cat} value={cat}>{cat}</option>
              ))}
            </select>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-900 mb-1">Montant unitaire (FCFA)</label>
            <input
              type="number"
              value={formData.prix_unitaire}
              onChange={(e) => setFormData({ ...formData, prix_unitaire: parseFloat(e.target.value) })}
              className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
              required
              min="0"
              step="100"
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-900 mb-1">Désignation</label>
            <textarea
              value={formData.designation}
              onChange={(e) => setFormData({ ...formData, designation: e.target.value })}
              className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
              rows="3"
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-900 mb-1">Date</label>
            <input
              type="date"
              value={formData.date}
              onChange={(e) => setFormData({ ...formData, date: e.target.value })}
              className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
              required
            />
          </div>

          <div className="flex gap-3 pt-4">
            <button
              type="button"
              onClick={onClose}
              className="flex-1 px-4 py-2 border border-gray-300 rounded-lg text-gray-700 font-medium hover:bg-gray-50"
            >
              Annuler
            </button>
            <button
              type="submit"
              className="flex-1 px-4 py-2 bg-blue-600 text-white rounded-lg font-medium hover:bg-blue-700"
            >
              {operation ? 'Modifier' : 'Créer'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};

const DeleteConfirmModal = ({ isOpen, onClose, onConfirm, loading }) => {
  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4 z-50">
      <div className="bg-white rounded-xl shadow-2xl max-w-sm w-full">
        <div className="p-6 text-center">
          <AlertCircle className="w-12 h-12 text-red-500 mx-auto mb-4" />
          <h2 className="text-xl font-bold text-gray-900 mb-2">Supprimer l'opération?</h2>
          <p className="text-gray-600 mb-6">Cette action ne peut pas être annulée.</p>
          <div className="flex gap-3">
            <button
              onClick={onClose}
              className="flex-1 px-4 py-2 border border-gray-300 rounded-lg text-gray-700 font-medium hover:bg-gray-50"
            >
              Annuler
            </button>
            <button
              onClick={onConfirm}
              disabled={loading}
              className="flex-1 px-4 py-2 bg-red-600 text-white rounded-lg font-medium hover:bg-red-700 disabled:opacity-50"
            >
              {loading ? 'Suppression...' : 'Supprimer'}
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};

export default function OperationsPage() {
  const [filters, setFilters] = useState({
    search: '',
    type: '',
    category: '',
    dateFrom: '',
    dateTo: '',
  });
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [selectedOperation, setSelectedOperation] = useState(null);
  const [deleteId, setDeleteId] = useState(null);
  const queryClient = useQueryClient();

  const { data: trucksData } = useQuery({
    queryKey: ['trucks'],
    queryFn: () => trucksApi.list(),
  });

  const { data: operationsData, isLoading } = useQuery({
    queryKey: ['operations', filters],
    queryFn: () => operationsApi.list(filters),
  });

  const createMutation = useMutation({
    mutationFn: (data) => operationsApi.create(data),
    onSuccess: () => {
      toast.success('Opération créée avec succès');
      queryClient.invalidateQueries(['operations']);
      setIsModalOpen(false);
      setSelectedOperation(null);
    },
    onError: () => toast.error('Erreur lors de la création'),
  });

  const updateMutation = useMutation({
    mutationFn: ({ id, data }) => operationsApi.update(id, data),
    onSuccess: () => {
      toast.success('Opération modifiée avec succès');
      queryClient.invalidateQueries(['operations']);
      setIsModalOpen(false);
      setSelectedOperation(null);
    },
    onError: () => toast.error('Erreur lors de la modification'),
  });

  const deleteMutation = useMutation({
    mutationFn: (id) => operationsApi.delete(id),
    onSuccess: () => {
      toast.success('Opération supprimée avec succès');
      queryClient.invalidateQueries(['operations']);
      setDeleteId(null);
    },
    onError: () => toast.error('Erreur lors de la suppression'),
  });

  const operations = operationsData?.data?.operations || [];
  const totaux = operationsData?.data?.totaux || { total_recettes: 0, total_depenses: 0, benefice: 0 };

  // Transform totaux to match StatsBar component expectations
  const totals = {
    recettes: totaux.total_recettes || 0,
    depenses: totaux.total_depenses || 0,
    benefice: totaux.benefice || 0,
  };

  const handleSubmit = (data) => {
    if (selectedOperation) {
      updateMutation.mutate({ id: selectedOperation.id, data });
    } else {
      createMutation.mutate(data);
    }
  };

  const openModal = (op = null) => {
    setSelectedOperation(op);
    setIsModalOpen(true);
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 via-white to-purple-50">
      {/* Header */}
      <div className="bg-gradient-to-r from-blue-600 to-blue-800 text-white px-8 py-12 shadow-lg">
        <h1 className="text-4xl font-bold mb-2">Opérations Financières</h1>
        <p className="text-blue-100">Gérez vos recettes et dépenses</p>
      </div>

      <div className="p-8 max-w-7xl mx-auto">
        {/* Stats */}
        <StatsBar totals={totals} />

        {/* Filter Bar */}
        <div className="bg-white rounded-xl shadow-lg p-6 mb-8">
          <div className="grid grid-cols-1 md:grid-cols-5 gap-4 mb-4">
            <div className="relative">
              <Search size={20} className="absolute left-3 top-3 text-gray-400" />
              <input
                type="text"
                placeholder="Rechercher..."
                value={filters.search}
                onChange={(e) => setFilters({ ...filters, search: e.target.value })}
                className="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
              />
            </div>

            <select
              value={filters.type}
              onChange={(e) => setFilters({ ...filters, type: e.target.value })}
              className="px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              <option value="">Tous les types</option>
              <option value="recette">Recettes</option>
              <option value="depense">Dépenses</option>
            </select>

            <select
              value={filters.category}
              onChange={(e) => setFilters({ ...filters, category: e.target.value })}
              className="px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              <option value="">Toutes les catégories</option>
              <option value="Carburant">Carburant</option>
              <option value="Maintenance">Maintenance</option>
              <option value="Assurance">Assurance</option>
              <option value="Péage">Péage</option>
              <option value="Transport">Transport</option>
              <option value="Autre">Autre</option>
            </select>

            <input
              type="date"
              value={filters.dateFrom}
              onChange={(e) => setFilters({ ...filters, dateFrom: e.target.value })}
              className="px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
            />

            <input
              type="date"
              value={filters.dateTo}
              onChange={(e) => setFilters({ ...filters, dateTo: e.target.value })}
              className="px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
          </div>

          <button
            onClick={() => openModal()}
            className="flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 font-medium"
          >
            <Plus size={20} />
            Nouvelle Opération
          </button>
        </div>

        {/* Table */}
        <div className="bg-white rounded-xl shadow-lg overflow-hidden">
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead className="bg-gray-50 border-b border-gray-200">
                <tr>
                  <th className="px-6 py-4 text-left text-sm font-semibold text-gray-900">Date</th>
                  <th className="px-6 py-4 text-left text-sm font-semibold text-gray-900">Description</th>
                  <th className="px-6 py-4 text-left text-sm font-semibold text-gray-900">Camion</th>
                  <th className="px-6 py-4 text-left text-sm font-semibold text-gray-900">Catégorie</th>
                  <th className="px-6 py-4 text-left text-sm font-semibold text-gray-900">Type</th>
                  <th className="px-6 py-4 text-right text-sm font-semibold text-gray-900">Montant</th>
                  <th className="px-6 py-4 text-center text-sm font-semibold text-gray-900">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-200">
                {operations.map((op) => (
                  <tr key={op.id} className="hover:bg-gray-50 transition-colors">
                    <td className="px-6 py-4 text-sm text-gray-900">
                      {new Date(op.date).toLocaleDateString('fr-FR')}
                    </td>
                    <td className="px-6 py-4 text-sm text-gray-600">{op.designation || op.description || "-"}</td>
                    <td className="px-6 py-4 text-sm text-gray-900 font-medium">{op.truck?.plate_number || "-"}</td>
                    <td className="px-6 py-4 text-sm">
                      <span className="px-3 py-1 bg-gray-100 text-gray-800 rounded-full text-xs font-semibold">
                        {op.categorie}
                      </span>
                    </td>
                    <td className="px-6 py-4 text-sm">
                      <span className={`px-3 py-1 rounded-full text-xs font-semibold ${
                        op.type_operation === 'recette' 
                          ? 'bg-green-100 text-green-800' 
                          : 'bg-red-100 text-red-800'
                      }`}>
                        {op.type_operation === 'recette' ? 'Recette' : 'Dépense'}
                      </span>
                    </td>
                    <td className={`px-6 py-4 text-sm font-bold text-right ${
                      op.type_operation === 'recette' ? 'text-green-600' : 'text-red-600'
                    }`}>
                      {op.type_operation === 'recette' ? '+' : '-'}{parseFloat(op.montant || 0).toLocaleString('fr-FR', { style: 'currency', currency: 'XOF', maximumFractionDigits: 0 })}
                    </td>
                    <td className="px-6 py-4 text-center">
                      <div className="flex items-center justify-center gap-2">
                        <button
                          onClick={() => openModal(op)}
                          className="p-2 text-blue-600 hover:bg-blue-50 rounded-lg transition-colors"
                        >
                          <Edit2 size={18} />
                        </button>
                        <button
                          onClick={() => setDeleteId(op.id)}
                          className="p-2 text-red-600 hover:bg-red-50 rounded-lg transition-colors"
                        >
                          <Trash2 size={18} />
                        </button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          {operations.length === 0 && (
            <div className="text-center py-12">
              <p className="text-gray-500 text-lg">Aucune opération trouvée</p>
            </div>
          )}
        </div>
      </div>

      <OperationModal
        isOpen={isModalOpen}
        onClose={() => {
          setIsModalOpen(false);
          setSelectedOperation(null);
        }}
        operation={selectedOperation}
        onSubmit={handleSubmit}
        trucks={[]}
      />

      <DeleteConfirmModal
        isOpen={!!deleteId}
        onClose={() => setDeleteId(null)}
        onConfirm={() => deleteMutation.mutate(deleteId)}
        loading={deleteMutation.isPending}
      />
    </div>
  );
}
