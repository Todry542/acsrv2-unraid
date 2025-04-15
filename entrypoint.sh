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
    echo "🛡️  Application de chmod pour l'écriture sur $ACSM_DIR"
    chmod -R ug+rwX "$ACSM_DIR"
fi

# 📦 Vérification de l'exécutable
if [ ! -x "$MAIN_EXEC" ]; then
    echo "⚠️  server-manager introuvable. Tentative de restauration..."
    if [ -d "$ACSM_DIR" ] && [ -w "$ACSM_DIR" ]; then
        cp -r "$ORIGINAL_DIR/"* "$ACSM_DIR/" || {
            echo "❌ Erreur de copie vers $ACSM_DIR"
            exit 1
        }
        chown -R "$PUID:$PGID" "$ACSM_DIR"
        find "$ACSM_DIR" -type f -iname "*.sh" -exec chmod +x {} \;
    else
        echo "❌ $ACSM_DIR non accessible. Vérifiez vos volumes et droits Unraid."
        ls -ld "$ACSM_DIR"
        id
        exit 1
    fi
fi

echo "🚀 Lancement de server-manager..."

cd "$ACSM_DIR"
exec su -s /bin/bash "$USER" -c "./server-manager"