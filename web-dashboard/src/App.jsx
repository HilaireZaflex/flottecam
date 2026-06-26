import { Suspense, lazy } from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { Toaster } from 'sonner';
import { AuthProvider } from './context/AuthContext';
import MainLayout from './components/Layout/MainLayout';
import ErrorBoundary from './components/ErrorBoundary';

// Lazy load pages
const LoginPage        = lazy(() => import('./pages/LoginPage'));
const DashboardPage    = lazy(() => import('./pages/DashboardPage'));
const TrucksPage       = lazy(() => import('./pages/TrucksPage'));
const DriversPage      = lazy(() => import('./pages/DriversPage'));
const TransportsPage   = lazy(() => import('./pages/TransportsPage'));
const OperationsPage   = lazy(() => import('./pages/OperationsPage'));
const DocumentsPage    = lazy(() => import('./pages/DocumentsPage'));
const NotificationsPage= lazy(() => import('./pages/NotificationsPage'));
const UsersPage        = lazy(() => import('./pages/UsersPage'));
const ImportPage       = lazy(() => import('./pages/ImportPage'));
const ReportsPage      = lazy(() => import('./pages/ReportsPage'));
const GpsPage          = lazy(() => import('./pages/GpsPage'));

function LoadingFallback() {
  return (
    <div className="min-h-screen flex items-center justify-center bg-[#F0F4FF]">
      <div className="flex flex-col items-center gap-4">
        <div className="w-12 h-12 border-4 border-blue-600 border-t-transparent rounded-full animate-spin"></div>
        <p className="text-slate-500 font-medium text-sm">Chargement...</p>
      </div>
    </div>
  );
}

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      retry: 1,
      refetchOnWindowFocus: false,
      staleTime: 30000,
    },
  },
});

function ProtectedRoute({ title, children }) {
  return (
    <MainLayout title={title}>
      <ErrorBoundary>
        {children}
      </ErrorBoundary>
    </MainLayout>
  );
}

export default function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <AuthProvider>
        <Router>
          <Suspense fallback={<LoadingFallback />}>
            <Routes>
              <Route path="/login" element={<LoginPage />} />
              <Route path="/" element={<ProtectedRoute title="Dashboard"><DashboardPage /></ProtectedRoute>} />
              <Route path="/trucks" element={<ProtectedRoute title="Camions"><TrucksPage /></ProtectedRoute>} />
              <Route path="/drivers" element={<ProtectedRoute title="Conducteurs"><DriversPage /></ProtectedRoute>} />
              <Route path="/transports" element={<ProtectedRoute title="Transports"><TransportsPage /></ProtectedRoute>} />
              <Route path="/operations" element={<ProtectedRoute title="Opérations"><OperationsPage /></ProtectedRoute>} />
              <Route path="/documents" element={<ProtectedRoute title="Documents"><DocumentsPage /></ProtectedRoute>} />
              <Route path="/notifications" element={<ProtectedRoute title="Notifications"><NotificationsPage /></ProtectedRoute>} />
              <Route path="/users" element={<ProtectedRoute title="Utilisateurs"><UsersPage /></ProtectedRoute>} />
              <Route path="/import" element={<ProtectedRoute title="Import Excel"><ImportPage /></ProtectedRoute>} />
              <Route path="/reports" element={<ProtectedRoute title="Rapports"><ReportsPage /></ProtectedRoute>} />
              <Route path="/gps" element={<ProtectedRoute title="Suivi GPS"><GpsPage /></ProtectedRoute>} />
              <Route path="*" element={<Navigate to="/" replace />} />
            </Routes>
          </Suspense>
        </Router>
        <Toaster position="top-right" richColors />
      </AuthProvider>
    </QueryClientProvider>
  );
}
