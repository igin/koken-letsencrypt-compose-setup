#!/usr/bin/env bash

pushd build/proxy
./start.sh
popd

pushd build/koken
./start.sh
popd
