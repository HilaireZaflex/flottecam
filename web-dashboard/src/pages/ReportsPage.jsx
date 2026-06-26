import { useState } from 'react';
import { useQuery, useMutation } from '@tanstack/react-query';
import { PieChart, Pie, Cell, ResponsiveContainer, BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, Legend } from 'recharts';
import { Download, Printer, Calendar, AlertCircle } from 'lucide-react';
import { reportsApi } from '../lib/api';
import toast from 'react-hot-toast';

const COLORS = ['#1B4FD8', '#10B981', '#F59E0B', '#EF4444', '#8B5CF6', '#06B6D4'];

export default function ReportsPage() {
  const [selectedMonth, setSelectedMonth] = useState(new Date().getMonth() + 1);
  const [selectedYear, setSelectedYear] = useState(new Date().getFullYear());
  const [reportGenerated, setReportGenerated] = useState(null);

  const { data: reportData, isLoading, refetch } = useQuery({
    queryKey: ['report', { month: selectedMonth, year: selectedYear }],
    queryFn: () => reportsApi.monthly({ month: selectedMonth, year: selectedYear }),
    enabled: !!reportGenerated,
  });

  const downloadPdfMutation = useMutation({
    mutationFn: () => reportsApi.downloadPdf({ month: selectedMonth, year: selectedYear }),
    onSuccess: (blob) => {
      const url = window.URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = `rapport_${selectedMonth}_${selectedYear}.pdf`;
      document.body.appendChild(a);
      a.click();
      window.URL.revokeObjectURL(url);
      document.body.removeChild(a);
      toast.success('PDF téléchargé avec succès');
    },
    onError: () => toast.error('Erreur lors du téléchargement du PDF'),
  });

  const handleGenerateReport = () => {
    setReportGenerated(true);
    refetch();
  };

  const handlePrint = () => {
    window.print();
  };

  const report = reportData?.data || null;

  const monthNames = [
    'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
    'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
  ];

  const years = Array.from({ length: 5 }, (_, i) => new Date().getFullYear() - i);

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 via-white to-purple-50">
      {/* Header */}
      <div className="bg-gradient-to-r from-blue-600 to-blue-800 text-white px-8 py-12 shadow-lg">
        <h1 className="text-4xl font-bold mb-2">Rapports Mensuels</h1>
        <p className="text-blue-100">Générez et analysez vos rapports financiers</p>
      </div>

      <div className="p-8 max-w-7xl mx-auto">
        {/* Date Selection */}
        <div className="bg-white rounded-xl shadow-lg p-8 mb-8">
          <div className="flex flex-col md:flex-row items-center justify-between gap-6 mb-8">
            <div className="flex items-center gap-4">
              <Calendar className="text-blue-600" size={24} />
              <div className="flex gap-4">
                <div>
                  <label className="block text-sm font-medium text-gray-900 mb-2">Mois</label>
                  <select
                    value={selectedMonth}
                    onChange={(e) => {
                      setSelectedMonth(parseInt(e.target.value));
                      setReportGenerated(false);
                    }}
                    className="px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                  >
                    {monthNames.map((month, idx) => (
                      <option key={idx} value={idx + 1}>{month}</option>
                    ))}
                  </select>
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-900 mb-2">Année</label>
                  <select
                    value={selectedYear}
                    onChange={(e) => {
                      setSelectedYear(parseInt(e.target.value));
                      setReportGenerated(false);
                    }}
                    className="px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                  >
                    {years.map((year) => (
                      <option key={year} value={year}>{year}</option>
                    ))}
                  </select>
                </div>
              </div>
            </div>

            <div className="flex gap-3">
              <button
                onClick={handleGenerateReport}
                disabled={isLoading}
                className="px-6 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 font-medium transition-colors disabled:opacity-50"
              >
                {isLoading ? 'Génération...' : 'Générer le Rapport'}
              </button>
              {reportGenerated && (
                <>
                  <button
                    onClick={() => downloadPdfMutation.mutate()}
                    disabled={downloadPdfMutation.isPending}
                    className="flex items-center gap-2 px-6 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 font-medium transition-colors disabled:opacity-50"
                  >
                    <Download size={18} />
                    PDF
                  </button>
                  <button
                    onClick={handlePrint}
                    className="flex items-center gap-2 px-6 py-2 bg-gray-600 text-white rounded-lg hover:bg-gray-700 font-medium transition-colors"
                  >
                    <Printer size={18} />
                    Imprimer
                  </button>
                </>
              )}
            </div>
          </div>

          {!reportGenerated && (
            <div className="bg-blue-50 border border-blue-200 rounded-lg p-4 flex items-start gap-3">
              <AlertCircle className="text-blue-600 flex-shrink-0 mt-0.5" size={20} />
              <p className="text-blue-800">Sélectionnez une période et cliquez sur "Générer le Rapport" pour voir les données.</p>
            </div>
          )}
        </div>

        {reportGenerated && report && (
          <div className="space-y-8">
            {/* Revenue Summary */}
            <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
              <div className="bg-gradient-to-br from-green-50 to-green-100 border border-green-200 rounded-xl p-6">
                <p className="text-sm font-medium text-green-700">Total Recettes</p>
                <p className="text-3xl font-bold text-green-900 mt-2">
                  {(report.total_recettes || 0).toLocaleString('fr-FR', { style: 'currency', currency: 'XOF', maximumFractionDigits: 0 })}
                </p>
                <p className="text-xs text-green-600 mt-2">{monthNames[selectedMonth - 1]} {selectedYear}</p>
              </div>

              <div className="bg-gradient-to-br from-red-50 to-red-100 border border-red-200 rounded-xl p-6">
                <p className="text-sm font-medium text-red-700">Total Dépenses</p>
                <p className="text-3xl font-bold text-red-900 mt-2">
                  {(report.total_depenses || 0).toLocaleString('fr-FR', { style: 'currency', currency: 'XOF', maximumFractionDigits: 0 })}
                </p>
                <p className="text-xs text-red-600 mt-2">{monthNames[selectedMonth - 1]} {selectedYear}</p>
              </div>

              <div className={`bg-gradient-to-br ${report.benefice_net >= 0 ? 'from-blue-50 to-blue-100 border-blue-200' : 'from-orange-50 to-orange-100 border-orange-200'} border rounded-xl p-6`}>
                <p className={`text-sm font-medium ${report.benefice_net >= 0 ? 'text-blue-700' : 'text-orange-700'}`}>
                  Bénéfice Net
                </p>
                <p className={`text-3xl font-bold ${report.benefice_net >= 0 ? 'text-blue-900' : 'text-orange-900'} mt-2`}>
                  {(report.benefice_net || 0).toLocaleString('fr-FR', { style: 'currency', currency: 'XOF', maximumFractionDigits: 0 })}
                </p>
                <p className={`text-xs ${report.benefice_net >= 0 ? 'text-blue-600' : 'text-orange-600'} mt-2`}>
                  {report.benefice_net >= 0 ? 'Positif' : 'Négatif'}
                </p>
              </div>
            </div>

            {/* Top Performing Trucks */}
            {report.top_camions && report.top_camions.length > 0 && (
              <div className="bg-white rounded-xl shadow-lg p-6">
                <h2 className="text-2xl font-bold text-gray-900 mb-6">Camions les Plus Performants</h2>
                <div className="overflow-x-auto">
                  <table className="w-full text-sm">
                    <thead>
                      <tr className="border-b border-gray-200 bg-gray-50">
                        <th className="px-6 py-3 text-left font-semibold text-gray-900">Immatriculation</th>
                        <th className="px-6 py-3 text-left font-semibold text-gray-900">Marque</th>
                        <th className="px-6 py-3 text-right font-semibold text-gray-900">Recettes</th>
                        <th className="px-6 py-3 text-right font-semibold text-gray-900">Dépenses</th>
                        <th className="px-6 py-3 text-right font-semibold text-gray-900">Bénéfice</th>
                        <th className="px-6 py-3 text-right font-semibold text-gray-900">Rentabilité</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-gray-200">
                      {report.top_camions.map((truck, idx) => (
                        <tr key={idx} className="hover:bg-gray-50 transition-colors">
                          <td className="px-6 py-4 font-medium text-gray-900">{truck.immatriculation}</td>
                          <td className="px-6 py-4 text-gray-600">{truck.marque}</td>
                          <td className="px-6 py-4 text-right text-green-600 font-semibold">
                            {truck.recettes.toLocaleString('fr-FR', { style: 'currency', currency: 'XOF', maximumFractionDigits: 0 })}
                          </td>
                          <td className="px-6 py-4 text-right text-red-600 font-semibold">
                            {truck.depenses.toLocaleString('fr-FR', { style: 'currency', currency: 'XOF', maximumFractionDigits: 0 })}
                          </td>
                          <td className="px-6 py-4 text-right text-blue-600 font-semibold">
                            {truck.benefice.toLocaleString('fr-FR', { style: 'currency', currency: 'XOF', maximumFractionDigits: 0 })}
                          </td>
                          <td className="px-6 py-4 text-right">
                            <span className={`px-3 py-1 rounded-full text-xs font-semibold ${
                              truck.rentabilite >= 0 
                                ? 'bg-green-100 text-green-800' 
                                : 'bg-red-100 text-red-800'
                            }`}>
                              {truck.rentabilite >= 0 ? '+' : ''}{truck.rentabilite.toFixed(1)}%
                            </span>
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              </div>
            )}

            {/* Operations Breakdown */}
            {report.operations_breakdown && report.operations_breakdown.length > 0 && (
              <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
                <div className="bg-white rounded-xl shadow-lg p-6">
                  <h2 className="text-2xl font-bold text-gray-900 mb-6">Répartition par Catégorie</h2>
                  <ResponsiveContainer width="100%" height={300}>
                    <PieChart>
                      <Pie
                        data={report.operations_breakdown}
                        cx="50%"
                        cy="50%"
                        labelLine={false}
                        label={({ name, value }) => `${name}: ${value}`}
                        outerRadius={80}
                        fill="#8884d8"
                        dataKey="montant"
                      >
                        {report.operations_breakdown.map((entry, index) => (
                          <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                        ))}
                      </Pie>
                      <Tooltip formatter={(value) => value.toLocaleString('fr-FR')} />
                    </PieChart>
                  </ResponsiveContainer>
                </div>

                {/* Breakdown Table */}
                <div className="bg-white rounded-xl shadow-lg p-6">
                  <h2 className="text-2xl font-bold text-gray-900 mb-6">Détail par Catégorie</h2>
                  <div className="space-y-3">
                    {report.operations_breakdown.map((item, idx) => (
                      <div key={idx} className="flex items-center justify-between p-3 bg-gray-50 rounded-lg">
                        <div className="flex items-center gap-3">
                          <div
                            className="w-3 h-3 rounded-full"
                            style={{ backgroundColor: COLORS[idx % COLORS.length] }}
                          ></div>
                          <span className="font-medium text-gray-900">{item.categorie}</span>
                        </div>
                        <span className="font-bold text-gray-900">
                          {item.montant.toLocaleString('fr-FR', { style: 'currency', currency: 'XOF', maximumFractionDigits: 0 })}
                        </span>
                      </div>
                    ))}
                  </div>
                </div>
              </div>
            )}

            {/* Client Debts */}
            {report.client_dettes && report.client_dettes.length > 0 && (
              <div className="bg-white rounded-xl shadow-lg p-6">
                <h2 className="text-2xl font-bold text-gray-900 mb-6">Dettes Clients</h2>
                <div className="overflow-x-auto">
                  <table className="w-full text-sm">
                    <thead>
                      <tr className="border-b border-gray-200 bg-gray-50">
                        <th className="px-6 py-3 text-left font-semibold text-gray-900">Client</th>
                        <th className="px-6 py-3 text-right font-semibold text-gray-900">Montant Dû</th>
                        <th className="px-6 py-3 text-left font-semibold text-gray-900">Jours</th>
                        <th className="px-6 py-3 text-left font-semibold text-gray-900">Statut</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-gray-200">
                      {report.client_dettes.map((debt, idx) => (
                        <tr key={idx} className="hover:bg-gray-50 transition-colors">
                          <td className="px-6 py-4 font-medium text-gray-900">{debt.client}</td>
                          <td className="px-6 py-4 text-right text-red-600 font-semibold">
                            {debt.montant_du.toLocaleString('fr-FR', { style: 'currency', currency: 'XOF', maximumFractionDigits: 0 })}
                          </td>
                          <td className="px-6 py-4 text-gray-600">{debt.jours_delai} jours</td>
                          <td className="px-6 py-4">
                            <span className={`px-3 py-1 rounded-full text-xs font-semibold ${
                              debt.jours_delai > 30 
                                ? 'bg-red-100 text-red-800' 
                                : debt.jours_delai > 15
                                ? 'bg-yellow-100 text-yellow-800'
                                : 'bg-green-100 text-green-800'
                            }`}>
                              {debt.jours_delai > 30 ? 'En retard' : debt.jours_delai > 15 ? 'À surveiller' : 'Normal'}
                            </span>
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              </div>
            )}
          </div>
        )}

        {reportGenerated && !report && (
          <div className="text-center py-12">
            <AlertCircle className="w-12 h-12 text-gray-400 mx-auto mb-4" />
            <p className="text-gray-500 text-lg">Aucune donnée disponible pour cette période</p>
          </div>
        )}
      </div>

      {/* Print Styles */}
      <style>{`
        @media print {
          .min-h-screen > div:first-child,
          button,
          select {
            display: none !important;
          }
          body {
            background: white;
          }
        }
      `}</style>
    </div>
  );
}
