# ── Stage 1 : Build Flutter Web ───────────────────────────────────────────────
FROM ghcr.io/cirruslabs/flutter:stable AS builder

WORKDIR /app

# Copier les fichiers du projet
COPY . .

# Installer les dépendances
RUN flutter pub get

# Builder la PWA Flutter Web (optimisée production)
RUN flutter build web \
    --release \
    --no-tree-shake-icons \
    --no-wasm-dry-run \
    --dart-define=FLUTTER_WEB_USE_SKIA=true

# ── Stage 2 : Servir avec Nginx ───────────────────────────────────────────────
FROM nginx:alpine

# Copier le build Flutter Web
COPY --from=builder /app/build/web /usr/share/nginx/html

# Config Nginx pour PWA (SPA routing)
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
