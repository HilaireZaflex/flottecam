import { Truck, LogOut, LayoutDashboard, Users, Route, Receipt, FolderOpen, Bell, UserCog, Settings, Navigation, FileSpreadsheet } from 'lucide-react';
import { NavLink } from 'react-router-dom';
import { useAuth } from '../../context/AuthContext';

const navItems = [
  { path: '/',              label: 'Dashboard',    icon: LayoutDashboard },
  { path: '/trucks',        label: 'Camions',      icon: Truck },
  { path: '/gps',           label: '📍 Suivi GPS', icon: Navigation, highlight: true },
  { path: '/drivers',       label: 'Conducteurs',  icon: Users },
  { path: '/transports',    label: 'Transports',   icon: Route },
  { path: '/operations',    label: 'Opérations',   icon: Receipt },
  { path: '/documents',     label: 'Documents',    icon: FolderOpen },
  { path: '/notifications', label: 'Notifications',icon: Bell, badge: true },
  { path: '/users',         label: 'Utilisateurs', icon: UserCog },
  { path: '/import',        label: 'Import Excel', icon: FileSpreadsheet },
  { path: '/reports',       label: 'Rapports',     icon: Settings },
];

export default function Sidebar() {
  const { user, logout } = useAuth();

  const handleLogout = () => {
    logout();
  };

  return (
    <aside className="fixed left-0 top-0 h-screen w-[260px] bg-slate-900 border-r border-slate-800 flex flex-col shadow-xl">
      {/* Logo section */}
      <div className="p-6 border-b border-slate-800">
        <div className="flex items-center gap-3">
          <div className="p-2 bg-gradient-to-br from-cyan-400 to-blue-500 rounded-lg inline-flex items-center justify-center">
            <Truck className="w-5 h-5 text-white" />
          </div>
          <div>
            <h1 className="text-white font-bold text-lg">FlotteCam</h1>
            <p className="text-cyan-300 text-xs font-semibold">Admin</p>
          </div>
        </div>
      </div>

      {/* Navigation items */}
      <nav className="flex-1 overflow-y-auto py-6 px-3 space-y-2">
        {navItems.map((item) => {
          const Icon = item.icon;
          return (
            <NavLink
              key={item.path}
              to={item.path}
              className={({ isActive }) =>
                `flex items-center justify-between gap-3 px-4 py-3 rounded-lg transition-all duration-200 group ${
                  isActive
                    ? 'bg-gradient-to-r from-blue-500 to-cyan-400 text-white shadow-lg shadow-blue-500/30'
                    : 'text-gray-400 hover:text-white hover:bg-slate-800'
                }`
              }
            >
              <div className="flex items-center gap-3 flex-1">
                <Icon className="w-5 h-5" />
                <span className="text-sm font-medium">{item.label}</span>
              </div>
              {item.badge && (
                <span className="inline-flex items-center justify-center w-5 h-5 text-xs font-bold text-white bg-red-500 rounded-full">
                  3
                </span>
              )}
            </NavLink>
          );
        })}
      </nav>

      {/* User section */}
      <div className="p-4 border-t border-slate-800">
        <div className="flex items-center gap-3 mb-4">
          <div className="w-10 h-10 bg-gradient-to-br from-cyan-400 to-blue-500 rounded-full flex items-center justify-center text-white font-bold shadow-lg">
            {user?.name?.charAt(0)?.toUpperCase() || 'U'}
          </div>
          <div className="flex-1 min-w-0">
            <p className="text-sm font-semibold text-white truncate">{user?.name || 'Utilisateur'}</p>
            <p className="text-xs text-gray-400 truncate">{user?.email || 'user@example.com'}</p>
          </div>
        </div>
        <button
          onClick={handleLogout}
          className="w-full flex items-center justify-center gap-2 px-3 py-2 bg-red-500/10 hover:bg-red-500/20 text-red-400 hover:text-red-300 rounded-lg transition-all duration-200 text-sm font-medium border border-red-500/30"
        >
          <LogOut className="w-4 h-4" />
          <span>Déconnexion</span>
        </button>
      </div>
    </aside>
  );
}
