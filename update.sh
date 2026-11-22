#!/usr/bin/env bash
# ==============================================================================
# OrbitNorth Remote — One-Command Update Script
# Updates /opt/remote to latest bundle and reloads PM2 with zero downtime
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd || echo "/tmp")"
INSTALL_DIR="/opt/remote"

echo "==> Updating OrbitNorth Remote at ${INSTALL_DIR}..."

if [ -f "${SCRIPT_DIR}/remote-latest.tar.gz" ]; then
  tar -xzf "${SCRIPT_DIR}/remote-latest.tar.gz" -C "${INSTALL_DIR}"
elif [ -d "${SCRIPT_DIR}/bundle" ]; then
  cp -rf "${SCRIPT_DIR}/bundle/"* "${INSTALL_DIR}/"
fi

echo "==> Reloading PM2..."
cd "${INSTALL_DIR}"
pm2 reload remote || pm2 restart remote

echo "==> Remote successfully updated!"
