# ── Servir directement le build pré-compilé avec Nginx ───────────────────────
# Le build Flutter Web est fait localement et inclus dans le repo (build/web/)
# → Déploiement Railway ultra-rapide (30s au lieu de 10min)
FROM nginx:alpine

# Copier le build Flutter Web pré-compilé
COPY build/web /usr/share/nginx/html

# Config Nginx pour PWA (SPA routing)
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
