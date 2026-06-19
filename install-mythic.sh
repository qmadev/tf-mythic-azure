#!/bin/bash

set -e pipefail

MYTHIC_DIR=/opt/tools
VERSION=$MYTHIC_VERSION
USER=$MYTHIC_ADMIN_USER
PASSWORD=$MYTHIC_ADMIN_PASSWORD
AGENT=$MYTHIC_AGENT
C2_PROFILE=$MYTHIC_C2_PROFILE

dnf remove -y docker \
  docker-client \
  docker-client-latest \
  docker-common \
  docker-latest \
  docker-latest-logrotate \
  docker-logrotate \
  docker-selinux \
  docker-engine-selinux \
  docker-engine

dnf install 'dnf5-command(config-manager)'
dnf config-manager addrepo --from-repofile=https://download.docker.com/linux/fedora/docker-ce.repo

rpm --import https://download.docker.com/linux/fedora/gpg
dnf install -y docker-ce \
  docker-ce-cli \
  containerd.io \
  docker-buildx-plugin \
  docker-compose-plugin

systemctl restart docker

mkdir -p "${MYTHIC_DIR}"
curl -L "https://api.github.com/repos/its-a-feature/Mythic/tarball/${VERSION}" | tar -zxC "${MYTHIC_DIR}"

export MYTHIC_ADMIN_USER=$USER
export MYTHIC_ADMIN_PASSWORD=$PASSWORD

cd ${MYTHIC_DIR}/its-a-feature-Mythic-*

make
./mythic-cli install github "${AGENT}"
./mythic-cli install github "${C2_PROFILE}"
./mythic-cli start
