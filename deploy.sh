#!/bin/bash
# ══════════════════════════════════════════════════════════════════════════════
# deploy.sh — Script de déploiement FlotteCam PWA
# Usage: ./deploy.sh "Message du commit"
# ══════════════════════════════════════════════════════════════════════════════

set -e

MSG=${1:-"feat: mise à jour FlotteCam"}
VERSION_FILE="flutter_app/build/web/version.json"
PUBSPEC="flutter_app/pubspec.yaml"

echo "🚀 Déploiement FlotteCam PWA..."
echo "📝 Message: $MSG"

# ── 1. Incrémenter le numéro de build ────────────────────────────────────────
echo "📦 Incrémentation de la version..."

# Lire le build number actuel depuis pubspec.yaml
CURRENT_BUILD=$(grep "^version:" $PUBSPEC | sed 's/version: [0-9.]*+//')
NEW_BUILD=$((CURRENT_BUILD + 1))

echo "   Build: $CURRENT_BUILD → $NEW_BUILD"

# Mettre à jour pubspec.yaml
sed -i '' "s/^version: \([0-9.]*\)+[0-9]*/version: \1+$NEW_BUILD/" $PUBSPEC

# ── 2. Builder Flutter Web ───────────────────────────────────────────────────
echo "🔨 Build Flutter Web..."
cd flutter_app
flutter pub get --quiet
flutter build web --release --no-tree-shake-icons --quiet
cd ..

# ── 3. Mettre à jour version.json avec le nouveau build number ───────────────
echo "📋 Mise à jour version.json (build $NEW_BUILD)..."
cat > $VERSION_FILE << EOF
{"app_name":"flottecam","version":"1.0.0","build_number":"$NEW_BUILD","package_name":"flottecam","built_at":"$(date -u +%Y-%m-%dT%H:%M:%SZ)"}
EOF

echo "   version.json: $(cat $VERSION_FILE)"

# ── 4. Git add + commit + push ───────────────────────────────────────────────
echo "📤 Push vers GitHub..."
git add -f flutter_app/build/web
git add flutter_app/pubspec.yaml
git add flutter_app/lib/

git commit -m "$MSG [build $NEW_BUILD]"
git push origin main

echo ""
echo "✅ Déploiement terminé !"
echo "   Build: $NEW_BUILD"
echo "   Railway déploie en ~30 secondes"
echo "   Les clients verront la mise à jour automatiquement au prochain démarrage de l'app"
echo ""
echo "🌐 URL PWA: https://adequate-warmth-production-a90c.up.railway.app"
