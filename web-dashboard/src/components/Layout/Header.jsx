import { useState } from 'react';
import { Search, Bell, ChevronDown, LogOut, User } from 'lucide-react';
import { useAuth } from '../../context/AuthContext';

export default function Header({ title = 'Dashboard' }) {
  const { user, logout } = useAuth();
  const [isUserMenuOpen, setIsUserMenuOpen] = useState(false);
  const [notificationCount] = useState(3);

  const handleLogout = () => {
    logout();
    setIsUserMenuOpen(false);
  };

  return (
    <header className="fixed top-0 left-[260px] right-0 h-16 bg-white border-b border-gray-200 flex items-center justify-between px-8 shadow-sm z-40">
      {/* Left: Title */}
      <h1 className="text-2xl font-bold text-slate-900">{title}</h1>

      {/* Right: Search, Notifications, User Menu */}
      <div className="flex items-center gap-6">
        {/* Search bar */}
        <div className="hidden md:flex items-center bg-gray-100 rounded-lg px-4 py-2.5 w-64">
          <Search className="w-4 h-4 text-gray-400" />
          <input
            type="text"
            placeholder="Rechercher..."
            className="ml-2 bg-transparent outline-none text-sm text-gray-700 placeholder-gray-400 w-full"
          />
        </div>

        {/* Notification bell */}
        <div className="relative">
          <button className="p-2 hover:bg-gray-100 rounded-lg transition-colors duration-200 relative">
            <Bell className="w-5 h-5 text-slate-600 hover:text-blue-500 transition-colors" />
            {notificationCount > 0 && (
              <span className="absolute top-0 right-0 inline-flex items-center justify-center w-5 h-5 text-xs font-bold text-white bg-red-500 rounded-full">
                {notificationCount}
              </span>
            )}
          </button>
        </div>

        {/* User menu */}
        <div className="relative">
          <button
            onClick={() => setIsUserMenuOpen(!isUserMenuOpen)}
            className="flex items-center gap-3 px-3 py-2 hover:bg-gray-100 rounded-lg transition-colors duration-200"
          >
            <div className="w-8 h-8 bg-gradient-to-br from-cyan-400 to-blue-500 rounded-full flex items-center justify-center text-white text-sm font-bold">
              {user?.name?.charAt(0)?.toUpperCase() || 'U'}
            </div>
            <div className="hidden sm:block">
              <p className="text-sm font-medium text-slate-900">{user?.name || 'Utilisateur'}</p>
              <p className="text-xs text-gray-500">{user?.isAdmin ? 'Administrateur' : 'Utilisateur'}</p>
            </div>
            <ChevronDown
              className={`w-4 h-4 text-gray-400 transition-transform duration-200 ${
                isUserMenuOpen ? 'rotate-180' : ''
              }`}
            />
          </button>

          {/* Dropdown menu */}
          {isUserMenuOpen && (
            <div className="absolute right-0 mt-2 w-56 bg-white rounded-lg shadow-lg border border-gray-200 py-2 z-50">
              {/* Profile section */}
              <div className="px-4 py-3 border-b border-gray-200">
                <p className="text-sm font-semibold text-slate-900">{user?.name || 'Utilisateur'}</p>
                <p className="text-xs text-gray-500">{user?.email || 'user@example.com'}</p>
              </div>

              {/* Menu items */}
              <button className="w-full px-4 py-2.5 flex items-center gap-3 text-slate-700 hover:bg-gray-50 transition-colors duration-200 text-sm">
                <User className="w-4 h-4" />
                <span>Mon profil</span>
              </button>

              {/* Logout */}
              <button
                onClick={handleLogout}
                className="w-full px-4 py-2.5 flex items-center gap-3 text-red-600 hover:bg-red-50 transition-colors duration-200 text-sm border-t border-gray-200"
              >
                <LogOut className="w-4 h-4" />
                <span>Déconnexion</span>
              </button>
            </div>
          )}
        </div>
      </div>
    </header>
  );
}
