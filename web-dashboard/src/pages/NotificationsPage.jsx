import { useState, useMemo } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { AlertCircle, AlertTriangle, Info, CheckCircle, Filter } from 'lucide-react';
import { notificationsApi, dashboardApi } from '../lib/api';
import toast from 'react-hot-toast';

const NotificationCard = ({ notification, onMarkRead }) => {
  const getIcon = (type) => {
    switch (type) {
      case 'error':
        return <AlertCircle className="text-red-500" size={24} />;
      case 'warning':
        return <AlertTriangle className="text-yellow-500" size={24} />;
      case 'info':
        return <Info className="text-blue-500" size={24} />;
      case 'success':
        return <CheckCircle className="text-green-500" size={24} />;
      default:
        return <Info className="text-gray-500" size={24} />;
    }
  };

  const getBgColor = (type) => {
    switch (type) {
      case 'error':
        return 'bg-red-50 border-red-200 hover:bg-red-100';
      case 'warning':
        return 'bg-yellow-50 border-yellow-200 hover:bg-yellow-100';
      case 'info':
        return 'bg-blue-50 border-blue-200 hover:bg-blue-100';
      case 'success':
        return 'bg-green-50 border-green-200 hover:bg-green-100';
      default:
        return 'bg-gray-50 border-gray-200 hover:bg-gray-100';
    }
  };

  const getTypeColor = (type) => {
    switch (type) {
      case 'error':
        return 'bg-red-100 text-red-800';
      case 'warning':
        return 'bg-yellow-100 text-yellow-800';
      case 'info':
        return 'bg-blue-100 text-blue-800';
      case 'success':
        return 'bg-green-100 text-green-800';
      default:
        return 'bg-gray-100 text-gray-800';
    }
  };

  return (
    <div className={`border rounded-lg p-4 flex gap-4 transition-all duration-200 ${getBgColor(notification.type)} ${notification.read === false ? 'ring-2 ring-blue-300' : ''}`}>
      <div className="flex-shrink-0 mt-1">{getIcon(notification.type)}</div>
      
      <div className="flex-1 min-w-0">
        <div className="flex items-start justify-between gap-2 mb-2">
          <h3 className="font-semibold text-gray-900">{notification.title}</h3>
          {notification.entity && (
            <span className={`px-2 py-1 rounded text-xs font-semibold whitespace-nowrap ${getTypeColor(notification.type)}`}>
              {notification.entity}
            </span>
          )}
        </div>
        
        <p className="text-gray-700 text-sm mb-3">{notification.message}</p>
        
        <div className="flex items-center justify-between">
          <p className="text-xs text-gray-500">
            {notification.created_at ? new Date(notification.created_at).toLocaleString('fr-FR') : ''}
          </p>
          {notification.read === false && (
            <button
              onClick={() => onMarkRead(notification.id)}
              className="text-xs text-blue-600 hover:text-blue-700 font-medium transition-colors"
            >
              Marquer comme lu
            </button>
          )}
        </div>
      </div>
    </div>
  );
};

export default function NotificationsPage() {
  const [filterType, setFilterType] = useState('all');
  const queryClient = useQueryClient();

  const { data: notificationsData, isLoading: notificationsLoading } = useQuery({
    queryKey: ['notifications'],
    queryFn: () => notificationsApi.list(),
    refetchInterval: 30000,
  });

  const { data: alertsData, isLoading: alertsLoading } = useQuery({
    queryKey: ['dashboard-alerts'],
    queryFn: () => dashboardApi.alerts(),
    refetchInterval: 30000,
  });

  const markReadMutation = useMutation({
    mutationFn: (id) => notificationsApi.markRead(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['notifications'] });
    },
    onError: () => toast.error('Erreur lors de la mise à jour'),
  });

  const markAllReadMutation = useMutation({
    mutationFn: () => notificationsApi.markAllRead(),
    onSuccess: () => {
      toast.success('Toutes les notifications marquées comme lues');
      queryClient.invalidateQueries({ queryKey: ['notifications'] });
    },
    onError: () => toast.error('Erreur lors de la mise à jour'),
  });

  // Combine both sources
  const dbNotifications = notificationsData?.data?.data || [];
  const dashboardAlerts = alertsData?.data?.alerts || [];
  const allNotifications = [...dashboardAlerts, ...dbNotifications];
  
  const unreadCount = dbNotifications.filter(n => !n.read).length;

  const filteredNotifications = filterType === 'all' 
    ? allNotifications 
    : allNotifications.filter(n => n.type === filterType);

  const groupedByType = {
    error: filteredNotifications.filter(n => n.type === 'error'),
    warning: filteredNotifications.filter(n => n.type === 'warning'),
    info: filteredNotifications.filter(n => n.type === 'info'),
    success: filteredNotifications.filter(n => n.type === 'success'),
  };

  const allRead = unreadCount === 0;
  const isLoading = notificationsLoading || alertsLoading;

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 via-white to-purple-50">
      {/* Header */}
      <div className="bg-gradient-to-r from-blue-600 to-blue-800 text-white px-8 py-12 shadow-lg">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-4xl font-bold mb-2">Notifications</h1>
            <p className="text-blue-100">Gérez vos alertes et notifications</p>
          </div>
          {!allRead && (
            <button
              onClick={() => markAllReadMutation.mutate()}
              disabled={markAllReadMutation.isPending}
              className="bg-white text-blue-600 px-4 py-2 rounded-lg font-medium hover:bg-blue-50 transition-colors disabled:opacity-50"
            >
              Tout marquer comme lu
            </button>
          )}
        </div>
      </div>

      <div className="p-8 max-w-4xl mx-auto">
        {/* Stats & Filter */}
        <div className="flex items-center justify-between mb-8">
          <div className="flex gap-4 items-center">
            <div className="flex items-center gap-3">
              <div className="w-3 h-3 bg-blue-500 rounded-full animate-pulse"></div>
              <span className="text-gray-700 font-medium">
                {unreadCount} notification{unreadCount !== 1 ? 's' : ''} non lue{unreadCount !== 1 ? 's' : ''}
              </span>
            </div>
            
            {!allRead ? (
              <div className="flex items-center gap-2">
                <div className="w-2 h-2 bg-blue-500 rounded-full"></div>
                <span className="text-xs text-blue-600 font-semibold">Vous avez des mises à jour</span>
              </div>
            ) : (
              <div className="flex items-center gap-2">
                <CheckCircle className="text-green-500" size={20} />
                <span className="text-green-600 font-semibold">Tout est en ordre!</span>
              </div>
            )}
          </div>

          <div className="flex items-center gap-2">
            <Filter size={20} className="text-gray-500" />
            <select
              value={filterType}
              onChange={(e) => setFilterType(e.target.value)}
              className="px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 text-sm"
            >
              <option value="all">Tous les types</option>
              <option value="error">Erreurs</option>
              <option value="warning">Avertissements</option>
              <option value="info">Infos</option>
              <option value="success">Succès</option>
            </select>
          </div>
        </div>

        {/* Empty State */}
        {!isLoading && filteredNotifications.length === 0 && (
          <div className="text-center py-16">
            <CheckCircle size={64} className="text-green-500 mx-auto mb-4" />
            <h2 className="text-2xl font-bold text-gray-900 mb-2">Tout est en ordre!</h2>
            <p className="text-gray-500">
              {filterType === 'all' 
                ? 'Aucune notification pour le moment.'
                : `Aucune notification de type "${filterType}" pour le moment.`}
            </p>
          </div>
        )}

        {/* Notifications */}
        {filteredNotifications.length > 0 && (
          <div className="space-y-6">
            {/* Errors */}
            {groupedByType.error.length > 0 && (
              <div>
                <div className="flex items-center gap-2 mb-4">
                  <AlertCircle className="text-red-500" size={20} />
                  <h2 className="text-lg font-bold text-gray-900">Erreurs ({groupedByType.error.length})</h2>
                </div>
                <div className="space-y-3">
                  {groupedByType.error.map(notification => (
                    <NotificationCard
                      key={notification.id}
                      notification={notification}
                      onMarkRead={() => notification.read !== undefined && markReadMutation.mutate(notification.id)}
                    />
                  ))}
                </div>
              </div>
            )}

            {/* Warnings */}
            {groupedByType.warning.length > 0 && (
              <div>
                <div className="flex items-center gap-2 mb-4">
                  <AlertTriangle className="text-yellow-500" size={20} />
                  <h2 className="text-lg font-bold text-gray-900">Avertissements ({groupedByType.warning.length})</h2>
                </div>
                <div className="space-y-3">
                  {groupedByType.warning.map(notification => (
                    <NotificationCard
                      key={notification.id}
                      notification={notification}
                      onMarkRead={() => notification.read !== undefined && markReadMutation.mutate(notification.id)}
                    />
                  ))}
                </div>
              </div>
            )}

            {/* Info */}
            {groupedByType.info.length > 0 && (
              <div>
                <div className="flex items-center gap-2 mb-4">
                  <Info className="text-blue-500" size={20} />
                  <h2 className="text-lg font-bold text-gray-900">Informations ({groupedByType.info.length})</h2>
                </div>
                <div className="space-y-3">
                  {groupedByType.info.map(notification => (
                    <NotificationCard
                      key={notification.id}
                      notification={notification}
                      onMarkRead={() => notification.read !== undefined && markReadMutation.mutate(notification.id)}
                    />
                  ))}
                </div>
              </div>
            )}

            {/* Success */}
            {groupedByType.success.length > 0 && (
              <div>
                <div className="flex items-center gap-2 mb-4">
                  <CheckCircle className="text-green-500" size={20} />
                  <h2 className="text-lg font-bold text-gray-900">Succès ({groupedByType.success.length})</h2>
                </div>
                <div className="space-y-3">
                  {groupedByType.success.map(notification => (
                    <NotificationCard
                      key={notification.id}
                      notification={notification}
                      onMarkRead={() => notification.read !== undefined && markReadMutation.mutate(notification.id)}
                    />
                  ))}
                </div>
              </div>
            )}
          </div>
        )}
      </div>
    </div>
  );
}
