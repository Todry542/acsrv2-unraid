FROM ubuntu:22.04

# Définitions des variables d'environnement
ENV DEBIAN_FRONTEND=noninteractive \
    SERVER_USER=assetto \
    SERVER_MANAGER_DIR=/opt/ACSMv2UNRAID \
    SERVER_INSTALL_DIR=/opt/ACSMv2UNRAID/assetto \
    LANG=C.UTF-8 \
    STEAMCMD_URL="http://media.steampowered.com/installer/steamcmd_linux.tar.gz" \
    STEAMROOT=/opt/steamcmd \
    PATH="${STEAMROOT}:${PATH}"

# Installation des dépendances nécessaires
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        curl \
        libc6-i386 \
        lib32gcc-s1 \
        lib32z1 \
        ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Création de l'utilisateur dédié
RUN useradd -ms /bin/bash ${SERVER_USER}

# Installation de SteamCMD
RUN mkdir -p ${STEAMROOT} && \
    curl -sSL ${STEAMCMD_URL} | tar -xz -C ${STEAMROOT}

# Mise à jour de SteamCMD
RUN ${STEAMROOT}/steamcmd.sh +login anonymous +quit || true

# Création des répertoires
RUN mkdir -p ${SERVER_MANAGER_DIR} ${SERVER_INSTALL_DIR} && \
    chown -R ${SERVER_USER}:${SERVER_USER} /opt/ACSMv2UNRAID ${STEAMROOT}

# Copie des fichiers du gestionnaire
COPY --chown=${SERVER_USER}:${SERVER_USER} acsmv2-unraid/ ${SERVER_MANAGER_DIR}/

# Correction des permissions et exécution des scripts
RUN chmod +x ${SERVER_MANAGER_DIR}/server-manager ${SERVER_MANAGER_DIR}/assetto-multiserver-manager

# Passage à l'utilisateur non root
USER ${SERVER_USER}
WORKDIR ${SERVER_MANAGER_DIR}

# Vérification de l'état du serveur
HEALTHCHECK CMD curl --fail http://localhost:8772/healthcheck.json || exit 1

# Configuration des volumes et ports
VOLUME ["${SERVER_INSTALL_DIR}"]
EXPOSE 8772 9600 8081

# Exécution du serveur
ENTRYPOINT ["./server-manager"]
