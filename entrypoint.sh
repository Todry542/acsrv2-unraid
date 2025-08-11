#!/bin/bash
set -e

PUID=${PUID:-1000}
PGID=${PGID:-1000}
USER=assetto
HOME_DIR="/home/$USER"
ACSM_DIR="$HOME_DIR/ACSMv2UNRAID"
ORIGINAL_DIR="/opt/original-server-manager"
MAIN_EXEC="$ACSM_DIR/server-manager"

echo "🔧 UID:GID demandés = $PUID:$PGID"

# Créer groupe si nécessaire
if ! getent group "$PGID" >/dev/null; then
    groupadd -g "$PGID" "$USER" || true
fi

# Créer utilisateur si nécessaire
if ! id "$USER" >/dev/null 2>&1; then
    useradd -u "$PUID" -g "$PGID" -m -s /bin/bash "$USER"
else
    usermod -u "$PUID" "$USER" || true
    groupmod -g "$PGID" "$USER" || true
fi

# 🧼 Permissions du home
echo "🛠️ Chown de $HOME_DIR"
chown -R "$PUID:$PGID" "$HOME_DIR"

# 🔐 S'assurer que le dossier est accessible en écriture
if [ -d "$ACSM_DIR" ]; then
    echo "🛡️ Application de chmod pour l'écriture sur $ACSM_DIR"
    chmod -R ug+rwX "$ACSM_DIR"
else
    mkdir -p "$ACSM_DIR"
    chown "$PUID:$PGID" "$ACSM_DIR"
fi

# 📦 Copier systématiquement les exécutables depuis l'original
echo "📥 Copie des exécutables server-manager et assetto-multiserver-manager..."
cp -f "$ORIGINAL_DIR/server-manager" "$ACSM_DIR/"
cp -f "$ORIGINAL_DIR/assetto-multiserver-manager" "$ACSM_DIR/"
chown "$PUID:$PGID" "$ACSM_DIR/server-manager" "$ACSM_DIR/assetto-multiserver-manager"
chmod +x "$ACSM_DIR/server-manager" "$ACSM_DIR/assetto-multiserver-manager"

# 🚀 Lancement de server-manager
echo "🚀 Lancement de server-manager..."
cd "$ACSM_DIR"
exec su -s /bin/bash "$USER" -c "./server-manager"
