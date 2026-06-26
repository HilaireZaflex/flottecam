import { useState } from 'react';
import { useCallback } from 'react';
import { useMutation } from '@tanstack/react-query';
import { Upload, Download, CheckCircle, AlertCircle, FileUp } from 'lucide-react';
import { importApi } from '../lib/api';
import toast from 'react-hot-toast';

const DropZone = ({ onDrop, accept, disabled }) => {
  const [isDragActive, setIsDragActive] = useState(false);

  const handleDrag = (e) => {
    e.preventDefault();
    e.stopPropagation();
    if (!disabled) {
      setIsDragActive(e.type === 'dragenter' || e.type === 'dragover');
    }
  };

  const handleDrop = (e) => {
    e.preventDefault();
    e.stopPropagation();
    setIsDragActive(false);
    
    if (disabled) return;
    
    const files = e.dataTransfer.files;
    if (files && files.length > 0) {
      const file = files[0];
      if (accept && !accept.includes(file.type)) {
        toast.error('Format de fichier non accepté');
        return;
      }
      onDrop(file);
    }
  };

  return (
    <div
      onDragEnter={handleDrag}
      onDragLeave={handleDrag}
      onDragOver={handleDrag}
      onDrop={handleDrop}
      className={`border-2 border-dashed rounded-xl p-8 text-center transition-all cursor-pointer ${
        isDragActive
          ? 'border-blue-500 bg-blue-50'
          : 'border-gray-300 bg-gray-50 hover:border-gray-400'
      } ${disabled ? 'opacity-50 cursor-not-allowed' : ''}`}
    >
      <Upload className="w-12 h-12 mx-auto mb-4 text-gray-400" />
      <p className="text-gray-900 font-semibold mb-1">Glisser-déposer votre fichier Excel ici</p>
      <p className="text-sm text-gray-500">ou cliquez pour sélectionner</p>
      <p className="text-xs text-gray-400 mt-3">Formats acceptés: .xlsx, .xls, .csv</p>
    </div>
  );
};

const ImportSection = ({ title, description, icon: Icon, color, onDrop, onDownloadTemplate, loading, children, comingSoon }) => {
  const [file, setFile] = useState(null);

  const handleFileSelect = (file) => {
    setFile(file);
    onDrop(file);
  };

  return (
    <div className="bg-white rounded-xl shadow-lg overflow-hidden">
      {/* Header */}
      <div className={`${color} text-white px-6 py-6 flex items-center justify-between`}>
        <div className="flex items-center gap-4">
          <Icon size={32} />
          <div>
            <h2 className="text-2xl font-bold">{title}</h2>
            <p className="text-sm opacity-90 mt-1">{description}</p>
          </div>
        </div>
        {comingSoon && (
          <span className="bg-white text-gray-900 px-3 py-1 rounded-full text-sm font-semibold">
            Bientôt disponible
          </span>
        )}
      </div>

      {/* Content */}
      <div className="p-8">
        {comingSoon ? (
          <div className="text-center py-12">
            <AlertCircle className="w-12 h-12 text-yellow-500 mx-auto mb-4" />
            <p className="text-gray-600 font-medium mb-6">Cette fonctionnalité sera bientôt disponible</p>
            <button
              onClick={onDownloadTemplate}
              className="inline-flex items-center gap-2 px-4 py-2 bg-gray-200 text-gray-700 rounded-lg hover:bg-gray-300 font-medium transition-colors"
            >
              <Download size={18} />
              Télécharger le modèle
            </button>
          </div>
        ) : (
          <>
            <DropZone onDrop={handleFileSelect} disabled={loading} />

            {file && (
              <div className="mt-6 p-4 bg-blue-50 border border-blue-200 rounded-lg flex items-start gap-3">
                <CheckCircle className="text-blue-600 flex-shrink-0 mt-0.5" size={20} />
                <div className="flex-1">
                  <p className="font-semibold text-gray-900">{file.name}</p>
                  <p className="text-sm text-gray-600">
                    {(file.size / 1024).toFixed(2)} KB
                  </p>
                </div>
              </div>
            )}

            {/* Column Mapping Table */}
            {children && (
              <div className="mt-8">
                <h3 className="text-lg font-bold text-gray-900 mb-4">Colonnes attendues</h3>
                {children}
              </div>
            )}

            {/* Download Template */}
            <div className="mt-8 flex gap-3">
              <button
                onClick={onDownloadTemplate}
                className="inline-flex items-center gap-2 px-4 py-2 bg-gray-100 text-gray-700 rounded-lg hover:bg-gray-200 font-medium transition-colors"
              >
                <Download size={18} />
                Télécharger le modèle
              </button>
              {file && (
                <button
                  disabled={loading}
                  className="inline-flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 font-medium transition-colors disabled:opacity-50"
                >
                  {loading ? 'Import en cours...' : 'Importer'}
                </button>
              )}
            </div>
          </>
        )}
      </div>
    </div>
  );
};

const ColumnTable = ({ columns }) => (
  <table className="w-full text-sm">
    <thead>
      <tr className="border-b border-gray-200">
        <th className="px-4 py-2 text-left font-semibold text-gray-900">Colonne Excel</th>
        <th className="px-4 py-2 text-left font-semibold text-gray-900">Type</th>
        <th className="px-4 py-2 text-left font-semibold text-gray-900">Exemple</th>
      </tr>
    </thead>
    <tbody>
      {columns.map((col, idx) => (
        <tr key={idx} className="border-b border-gray-100 hover:bg-gray-50">
          <td className="px-4 py-2 text-gray-900 font-medium">{col.name}</td>
          <td className="px-4 py-2 text-gray-600">{col.type}</td>
          <td className="px-4 py-2 text-gray-500">{col.example}</td>
        </tr>
      ))}
    </tbody>
  </table>
);

export default function ImportPage() {
  const operationsMutation = useMutation({
    mutationFn: (file) => importApi.operations(file),
    onSuccess: (data) => {
      const count = data?.data?.count || 0;
      toast.success(`${count} opérations importées avec succès`);
    },
    onError: (error) => {
      const message = error.response?.data?.message || 'Erreur lors de l\'import';
      toast.error(message);
    },
  });

  const templateMutation = useMutation({
    mutationFn: () => importApi.template(),
    onSuccess: (blob) => {
      const url = window.URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = 'template_operations.xlsx';
      document.body.appendChild(a);
      a.click();
      window.URL.revokeObjectURL(url);
      document.body.removeChild(a);
      toast.success('Modèle téléchargé');
    },
    onError: () => toast.error('Erreur lors du téléchargement'),
  });

  const handleOperationsImport = (file) => {
    operationsMutation.mutate(file);
  };

  const handleDownloadTemplate = () => {
    templateMutation.mutate();
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 via-white to-purple-50">
      {/* Header */}
      <div className="bg-gradient-to-r from-blue-600 to-blue-800 text-white px-8 py-12 shadow-lg">
        <h1 className="text-4xl font-bold mb-2">Centre d'Import</h1>
        <p className="text-blue-100">Importer vos données en masse depuis Excel</p>
      </div>

      <div className="p-8 max-w-6xl mx-auto">
        <div className="space-y-8">
          {/* Operations Import */}
          <ImportSection
            title="Opérations Financières"
            description="Importer vos recettes et dépenses"
            icon={FileUp}
            color="bg-gradient-to-r from-blue-500 to-blue-600"
            onDrop={handleOperationsImport}
            onDownloadTemplate={handleDownloadTemplate}
            loading={operationsMutation.isPending}
          >
            <ColumnTable
              columns={[
                { name: 'date', type: 'Date (YYYY-MM-DD)', example: '2026-03-15' },
                { name: 'type', type: 'Text (recette/depense)', example: 'recette' },
                { name: 'camion_id', type: 'Number', example: '1' },
                { name: 'categorie', type: 'Text', example: 'Carburant' },
                { name: 'montant', type: 'Number (FCFA)', example: '50000' },
                { name: 'description', type: 'Text', example: 'Ravitaillement carburant' },
              ]}
            />
          </ImportSection>

          {/* Trucks Import - Coming Soon */}
          <ImportSection
            title="Camions"
            description="Importer vos camions"
            icon={FileUp}
            color="bg-gradient-to-r from-orange-500 to-orange-600"
            onDrop={() => {}}
            onDownloadTemplate={handleDownloadTemplate}
            loading={false}
            comingSoon={true}
          >
            <ColumnTable
              columns={[
                { name: 'immatriculation', type: 'Text', example: 'SN-2024-001' },
                { name: 'marque', type: 'Text', example: 'Mercedes Benz' },
                { name: 'modele', type: 'Text', example: 'Sprinter' },
                { name: 'annee', type: 'Number', example: '2024' },
                { name: 'capacite', type: 'Number (kg)', example: '5000' },
              ]}
            />
          </ImportSection>

          {/* Drivers Import - Coming Soon */}
          <ImportSection
            title="Conducteurs"
            description="Importer vos conducteurs"
            icon={FileUp}
            color="bg-gradient-to-r from-green-500 to-green-600"
            onDrop={() => {}}
            onDownloadTemplate={handleDownloadTemplate}
            loading={false}
            comingSoon={true}
          >
            <ColumnTable
              columns={[
                { name: 'nom', type: 'Text', example: 'Diallo Mamadou' },
                { name: 'email', type: 'Email', example: 'diallo@example.com' },
                { name: 'telephone', type: 'Text', example: '+221771234567' },
                { name: 'permis', type: 'Text', example: 'PL123456' },
                { name: 'date_embauche', type: 'Date (YYYY-MM-DD)', example: '2024-01-15' },
              ]}
            />
          </ImportSection>

          {/* Transports Import - Coming Soon */}
          <ImportSection
            title="Transports"
            description="Importer vos transports"
            icon={FileUp}
            color="bg-gradient-to-r from-purple-500 to-purple-600"
            onDrop={() => {}}
            onDownloadTemplate={handleDownloadTemplate}
            loading={false}
            comingSoon={true}
          >
            <ColumnTable
              columns={[
                { name: 'date_depart', type: 'Date (YYYY-MM-DD)', example: '2026-03-15' },
                { name: 'destination', type: 'Text', example: 'Kaolack' },
                { name: 'camion_id', type: 'Number', example: '1' },
                { name: 'conducteur_id', type: 'Number', example: '5' },
                { name: 'montant', type: 'Number (FCFA)', example: '100000' },
                { name: 'statut', type: 'Text (en_cours/complete/annule)', example: 'complete' },
              ]}
            />
          </ImportSection>
        </div>

        {/* Info Box */}
        <div className="mt-12 bg-blue-50 border border-blue-200 rounded-xl p-6 flex items-start gap-4">
          <AlertCircle className="text-blue-600 flex-shrink-0 mt-0.5" size={24} />
          <div>
            <h3 className="font-bold text-blue-900 mb-2">Conseils pour l'import</h3>
            <ul className="text-sm text-blue-800 space-y-1">
              <li>✓ Utilisez les modèles fournis pour un import sans erreur</li>
              <li>✓ Respectez le format des dates (YYYY-MM-DD)</li>
              <li>✓ Les montants doivent être en FCFA sans symbole de devise</li>
              <li>✓ Vérifiez que les IDs (camion, conducteur) existent dans le système</li>
              <li>✓ Un maximum de 10,000 lignes par fichier</li>
            </ul>
          </div>
        </div>
      </div>
    </div>
  );
}
