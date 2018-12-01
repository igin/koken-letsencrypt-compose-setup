#!/usr/bin/env bash

if [[ -e .env ]]; then
    source .env
else
    echo "Please set up your .env file before starting your environment."
    exit 1
fi

if [[ -z ${DATA_VOLUME+x} ]]; then
    echo "Not mounting a data volume. Data will be at /var/koken."
    KOKEN_DATA_PATH=/var/koken
    mkdir -p KOKEN_DATA_PATH
else
    echo "Mounting volume ${DATA_VOLUME}"
    VOLUME_MOUNT=/mnt/koken-data-volume
    KOKEN_DATA_PATH=${VOLUME_MOUNT}/koken-data

    mkdir -p ${VOLUME_MOUNT}
    mount -o discard,defaults ${DATA_VOLUME} ${VOLUME_MOUNT}
    mkdir -p ${KOKEN_DATA_PATH}
    echo "Data will be at ${KOKEN_DATA_PATH}"
fi

echo "Installing Docker"
curl -fsSL https://get.docker.com -o build/get-docker.sh
pushd build
sh get-docker.sh
popd

echo "Installing Docker Compose"
sudo curl -L "https://github.com/docker/compose/releases/download/1.23.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

echo "Setting up proxy"
git clone https://github.com/evertramos/docker-compose-letsencrypt-nginx-proxy-companion.git build/proxy
cp nginx-proxy.env build/proxy/.env

echo "Setting up koken"
git clone https://github.com/igin/docker-koken-letsencrypt.git build/koken

# generate passwords for koken
MYSQL_ROOT_PASSWORD=$(dd if=/dev/urandom bs=1 count=32 2>/dev/null | base64 -w 0 | rev | cut -b 2- | rev)
MYSQL_PASSWORD=$(dd if=/dev/urandom bs=1 count=32 2>/dev/null | base64 -w 0 | rev | cut -b 2- | rev)

cat >build/koken/.env <<EOL
CONTAINER_NAME=koken
NETWORK=webproxy
MYSQL_DATABASE=koken
MYSQL_USER=koken
KOKEN_DATA_DIR=${KOKEN_DATA_PATH}/koken
MYSQL_DATA_DIR=${KOKEN_DATA_PATH}/mysql
MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD}
MYSQL_PASSWORD=${MYSQL_PASSWORD}
LETSENCRYPT_EMAIL=${LETSENCRYPT_EMAIL}
DOMAIN=${DOMAIN}
EOL

echo "Koken is set up with the following config:"
cat build/koken/.env
