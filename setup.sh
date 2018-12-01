#!/usr/bin/env bash

if [[ -e .env ]]; then
    source .env
else
    echo "Please set up your .env file before starting your environment."
    exit 1
fi

if [ -z ${DATA_VOLUME+x} ]; then
    # Mount data volume
    VOLUME_MOUNT=/mnt/koken-data-volume
    KOKEN_DATA_PATH=${VOLUME_MOUNT}/koken-data

    mkdir ${VOLUME_MOUNT}
    mount -o discard,defaults ${VOLUME_MOUNT} ${KOKEN_DATA_PATH}
    mkdir ${KOKEN_DATA_PATH}
else
    KOKEN_DATA_PATH=/var/koken
    mkdir -p KOKEN_DATA_PATH
fi

# Install docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

# install docker compose
sudo curl -L "https://github.com/docker/compose/releases/download/1.23.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# install letsencrypt-companion
git clone https://github.com/evertramos/docker-compose-letsencrypt-nginx-proxy-companion.git build/proxy

# generate env file for companion
cp nginx-proxy.env build/proxy/.env

# install koken-docker-compose
git clone https://github.com/igin/docker-koken-letsencrypt.git build/koken

# generate env file for koken
MYSQL_ROOT_PASSWORD=$(dd if=/dev/urandom bs=1 count=32 2>/dev/null | base64 -w 0 | rev | cut -b 2- | rev)
MYSQL_PASSWORD=$(dd if=/dev/urandom bs=1 count=32 2>/dev/null | base64 -w 0 | rev | cut -b 2- | rev)

cat >koken.gen.env <<EOL
CONTAINER_NAME=koken
NETWORK=webproxy
MYSQL_DATABASE=koken
MYSQL_USER=koken

# following variables are set by setup.sh
KOKEN_DATA_DIR=${KOKEN_DATA_PATH}/koken
MYSQL_DATA_DIR=${KOKEN_DATA_PATH}/mysql
MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD}
MYSQL_PASSWORD=${MYSQL_PASSWORD}
LETSENCRYPT_EMAIL=${LETSENCRYPT_EMAIL}
DOMAIN=${DOMAIN}
EOL

cp koken.gen.env build/koken/.env

