#!/bin/sh
set -e

echo "🚀 Démarrage FlotteCam Backend..."

# Créer les dossiers de logs supervisor
mkdir -p /var/log/supervisor

# Permissions finales
chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache 2>/dev/null || true

# Migrations automatiques au démarrage
echo "🗄️ Exécution des migrations..."
php artisan migrate --force || echo "⚠️ Migration échouée - continuons quand même"

# Lien storage
php artisan storage:link --force 2>/dev/null || true

# Optimisations Laravel pour production
echo "⚙️ Optimisation Laravel..."
php artisan config:cache || true
php artisan route:cache || true
php artisan view:cache || true

echo "✅ FlotteCam Backend prêt !"

# Démarrer nginx + php-fpm via supervisor
exec /usr/bin/supervisord -c /etc/supervisord.conf
