#!/usr/bin/env bash
# ==============================================================================
# OrbitNorth Remote — One-Command Push to Remote VPS
# Usage: ./deploy.sh user@vps-ip [domain]
# ==============================================================================

set -euo pipefail

TARGET="${1:-}"
DOMAIN="${2:-}"

if [ -z "$TARGET" ]; then
  echo "Usage: $0 <user@vps-ip> [domain]"
  echo "Example: $0 root@142.93.10.20 myagent.example.com"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARBALL="${SCRIPT_DIR}/remote-latest.tar.gz"

if [ ! -f "$TARBALL" ]; then
  echo "Error: $TARBALL not found. Run 'pnpm release' first."
  exit 1
fi

echo "==> Deploying Remote to $TARGET..."
echo "    Uploading release package..."
ssh "$TARGET" "mkdir -p /tmp/remote-deploy"
scp "$TARBALL" "${SCRIPT_DIR}/install.sh" "$TARGET:/tmp/remote-deploy/"

echo "    Running remote installation script..."
ssh -t "$TARGET" "cd /tmp/remote-deploy && sudo bash install.sh $DOMAIN && rm -rf /tmp/remote-deploy"

echo "==> Deployment complete!"
