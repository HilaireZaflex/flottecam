import axios from 'axios';

const API_BASE = '/api';

const api = axios.create({
  baseURL: API_BASE,
  headers: { 'Content-Type': 'application/json', Accept: 'application/json' },
});

// Inject token
api.interceptors.request.use((config) => {
  const token = localStorage.getItem('admin_token');
  if (token) config.headers.Authorization = `Bearer ${token}`;
  return config;
});

// Handle 401
api.interceptors.response.use(
  (res) => res,
  (err) => {
    if (err.response?.status === 401) {
      localStorage.removeItem('admin_token');
      localStorage.removeItem('admin_user');
      window.location.href = '/login';
    }
    return Promise.reject(err);
  }
);

export default api;

// ── Auth ──────────────────────────────────────────────────────────────────────
export const authApi = {
  login:  (data) => api.post('/auth/login', data),
  me:     ()     => api.get('/auth/me'),
  logout: ()     => api.post('/auth/logout'),
};

// ── Dashboard ─────────────────────────────────────────────────────────────────
export const dashboardApi = {
  stats:     () => api.get('/dashboard/stats'),
  alerts:    () => api.get('/dashboard/alerts'),
  chart:     () => api.get('/dashboard/chart'),
  rentabilite: () => api.get('/dashboard/rentabilite'),
  depensesCategorie: () => api.get('/dashboard/depenses-categorie'),
};

// ── Trucks ────────────────────────────────────────────────────────────────────
export const trucksApi = {
  list:         (params) => api.get('/trucks', { params }),
  get:          (id)     => api.get(`/trucks/${id}`),
  create:       (data)   => api.post('/trucks', data),
  update:       (id, d)  => api.put(`/trucks/${id}`, d),
  delete:       (id)     => api.delete(`/trucks/${id}`),
  updateStatus: (id, s)  => api.patch(`/trucks/${id}/status`, { status: s }),
  transports:   (id)     => api.get(`/trucks/${id}/transports`),
};

// ── Drivers ───────────────────────────────────────────────────────────────────
export const driversApi = {
  list:   (params) => api.get('/drivers', { params }),
  get:    (id)     => api.get(`/drivers/${id}`),
  create: (data)   => api.post('/drivers', data),
  update: (id, d)  => api.put(`/drivers/${id}`, d),
  delete: (id)     => api.delete(`/drivers/${id}`),
};

// ── Transports ────────────────────────────────────────────────────────────────
export const transportsApi = {
  list:          (params) => api.get('/transports', { params }),
  get:           (id)     => api.get(`/transports/${id}`),
  create:        (data)   => api.post('/transports', data),
  update:        (id, d)  => api.put(`/transports/${id}`, d),
  delete:        (id)     => api.delete(`/transports/${id}`),
  updateStatus:  (id, s)  => api.patch(`/transports/${id}/status`, { status: s }),
  updatePaiement:(id, d)  => api.patch(`/transports/${id}/paiement`, d),
};

// ── Operations ────────────────────────────────────────────────────────────────
export const operationsApi = {
  list:          (params) => api.get('/operations', { params }),
  get:           (id)     => api.get(`/operations/${id}`),
  create:        (data)   => api.post('/operations', data),
  update:        (id, d)  => api.put(`/operations/${id}`, d),
  delete:        (id)     => api.delete(`/operations/${id}`),
  statsByTruck:  ()       => api.get('/operations/stats/par-camion'),
  statsCategorie:()       => api.get('/operations/stats/par-categorie'),
  clientDettes:  ()       => api.get('/operations/clients/dettes'),
};

// ── Documents ─────────────────────────────────────────────────────────────────
export const documentsApi = {
  list:     (params) => api.get('/documents', { params }),
  get:      (id)     => api.get(`/documents/${id}`),
  create:   (data)   => api.post('/documents', data, { headers: { 'Content-Type': 'multipart/form-data' } }),
  update:   (id, d)  => api.put(`/documents/${id}`, d),
  delete:   (id)     => api.delete(`/documents/${id}`),
  download: (id)     => api.get(`/documents/${id}/download`, { responseType: 'blob' }),
};

// ── Notifications ─────────────────────────────────────────────────────────────
export const notificationsApi = {
  list:       () => api.get('/notifications'),
  markRead:   (id) => api.patch(`/notifications/${id}/read`),
  markAllRead:()   => api.post('/notifications/read-all'),
};

// ── Users ─────────────────────────────────────────────────────────────────────
export const usersApi = {
  list:   (params) => api.get('/users', { params }),
  get:    (id)     => api.get(`/users/${id}`),
  create: (data)   => api.post('/users', data),
  update: (id, d)  => api.put(`/users/${id}`, d),
  delete: (id)     => api.delete(`/users/${id}`),
};

// ── Import ────────────────────────────────────────────────────────────────────
export const importApi = {
  operations: (file) => {
    const fd = new FormData();
    fd.append('file', file);
    return api.post('/import/operations', fd, { headers: { 'Content-Type': 'multipart/form-data' } });
  },
  template: () => api.get('/import/template', { responseType: 'blob' }),
};

// ── GPS ───────────────────────────────────────────────────────────────────────
export const gpsApi = {
  latest:       ()         => api.get('/gps/latest'),
  history:      (id, h)    => api.get(`/gps/history/${id}?hours=${h}`),
  truckPos:     (id)       => api.get(`/gps/truck/${id}`),
  update:       (data)     => api.post('/gps/update', data),
};

// ── Reports ───────────────────────────────────────────────────────────────────
export const reportsApi = {
  monthly:     (params) => api.get('/reports/monthly', { params }),
  downloadPdf: (params) => api.get('/reports/monthly/pdf', { params, responseType: 'blob' }),
};
