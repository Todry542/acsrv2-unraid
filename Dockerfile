FROM ubuntu:22.04

# Variables d’environnement Unraid (définies via template)
ENV PUID=1000 \
    PGID=1000 \
    SERVER_USER=assetto \
    SERVER_MANAGER_DIR=/home/assetto/ACSMv2UNRAID \
    SERVER_INSTALL_DIR=/home/assetto/ACSMv2UNRAID/assetto \
    LANG=C.UTF-8 \
    STEAMCMD_URL="http://media.steampowered.com/installer/steamcmd_linux.tar.gz" \
    STEAMROOT=/home/steamcmd \
    PATH="/home/steamcmd:$PATH"

# Installer les paquets nécessaires
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl libc6-i386 lib32gcc-s1 lib32z1 ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Créer les répertoires
RUN mkdir -p /home/steamcmd $SERVER_MANAGER_DIR $SERVER_INSTALL_DIR && \
    useradd -m -s /bin/bash assetto || true && \
    useradd -ms /bin/bash steamcmd && \
    curl -sSL "$STEAMCMD_URL" | tar -xz -C /home/steamcmd && \
    chown -R steamcmd:steamcmd /home/steamcmd

# Copier les fichiers
COPY acsrv2-unraid/ ${SERVER_MANAGER_DIR}/
COPY entrypoint.sh /entrypoint.sh
COPY acsrv2-unraid/ /opt/original-server-manager/

# Permissions
RUN chmod +x /entrypoint.sh && \
    find /opt/original-server-manager -type f -iname "*.sh" -exec chmod +x {} \;
	
# Exposer les ports
EXPOSE 8772 9600 8081

# Healthcheck
HEALTHCHECK CMD curl --fail http://localhost:8772/healthcheck.json || exit 1

# Lancement
ENTRYPOINT ["/entrypoint.sh"]