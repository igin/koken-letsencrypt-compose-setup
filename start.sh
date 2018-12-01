#!/usr/bin/env bash

pushd docker-compose-letsencrypt-nginx-proxy-companion
./start.sh

popd

pushd docker-koken-letsencrypt
./start.sh

popd
