#!/bin/sh
set -e

echo "🚀 Démarrage FlotteCam Backend..."

# Créer les dossiers de logs supervisor
mkdir -p /var/log/supervisor

# Optimisations Laravel pour production
echo "⚙️ Optimisation Laravel..."
php artisan config:cache
php artisan route:cache
php artisan view:cache

# Migrations automatiques au démarrage
echo "🗄️ Exécution des migrations..."
php artisan migrate --force

# Lien storage
php artisan storage:link --force 2>/dev/null || true

# Permissions finales
chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache

echo "✅ FlotteCam Backend prêt !"

# Démarrer nginx + php-fpm via supervisor
exec /usr/bin/supervisord -c /etc/supervisord.conf
