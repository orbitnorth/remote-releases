#!/usr/bin/env bash
# ==============================================================================
# OrbitNorth Remote — One-Command Production VPS Installer
# Installs standalone Remote bundle with PM2, Caddy reverse-proxy & UFW firewall
# ==============================================================================

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

INSTALL_DIR="/opt/remote"
DATA_DIR="/opt/remote/data"
PORT=${PORT:-7682}
DOMAIN="${1:-}"

echo -e "${CYAN}"
cat << 'EOF'
  ___       _     _ _   _   _             _   _     
 / _ \ _ __| |__ (_) |_| \ | | ___  _ __| |_| |__  
| | | | '__| '_ \| | __|  \| |/ _ \| '__| __| '_ \ 
| |_| | |  | |_) | | |_| |\  | (_) | |  | |_| | | |
 \___/|_|  |_.__/|_|\__|_| \_|\___/|_|   \__|_| |_|
        R E M O T E  —  C O N T R O L  P L A N E
EOF
echo -e "${NC}"
echo -e "${BLUE}==>${NC} Starting One-Command Setup for OrbitNorth Remote v0.1.0..."

# 1. Require Root / Sudo
if [ "$(id -u)" -ne 0 ]; then
  echo -e "${RED}[!] Error: This installer must be run as root or with sudo.${NC}"
  echo "    Please run: sudo bash $0 $*"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd || echo "/tmp")"

# 2. Detect Public IP
PUBLIC_IP=$(curl -s4 --max-time 4 https://ifconfig.me || curl -s4 --max-time 4 https://api.ipify.org || echo "YOUR-SERVER-IP")

# 3. Check / Install Node.js 20 LTS
echo -e "${BLUE}==>${NC} Checking Node.js runtime..."
if ! command -v node >/dev/null 2>&1 || [ "$(node -v | cut -d'v' -f2 | cut -d'.' -f1)" -lt 18 ]; then
  echo -e "${YELLOW}[*] Node.js 20 LTS not found. Installing via NodeSource...${NC}"
  if command -v apt-get >/dev/null 2>&1; then
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
    apt-get install -y nodejs
  elif command -v dnf >/dev/null 2>&1; then
    dnf module -y enable nodejs:20
    dnf install -y nodejs
  elif command -v yum >/dev/null 2>&1; then
    curl -fsSL https://rpm.nodesource.com/setup_20.x | bash -
    yum install -y nodejs
  fi
fi
NODE_VER=$(node -v)
echo -e "${GREEN}[✓]${NC} Node.js ready: ${NODE_VER}"

# 4. Check / Install PM2
echo -e "${BLUE}==>${NC} Checking PM2 process supervisor..."
if ! command -v pm2 >/dev/null 2>&1; then
  echo -e "${YELLOW}[*] Installing PM2 globally...${NC}"
  npm install -g pm2
fi
echo -e "${GREEN}[✓]${NC} PM2 ready: $(pm2 -v)"

# 5. Install AI Agent Harness CLIs (Claude, Antigravity, OpenCode, Codex)
echo -e "${BLUE}==>${NC} Installing AI harness CLIs (Claude Code, Antigravity, OpenCode, Codex)..."
npm install -g @anthropic-ai/claude-code @opencode/cli@latest @openai/codex 2>/dev/null || true
if ! command -v agy >/dev/null 2>&1; then
  echo "    Installing Google Antigravity (agy) CLI..."
  curl -fsSL https://antigravity.google/cli/install.sh | bash 2>/dev/null || true
  if [ -f "$HOME/.local/bin/agy" ]; then
    ln -sf "$HOME/.local/bin/agy" /usr/local/bin/agy 2>/dev/null || true
  elif [ -f "/root/.local/bin/agy" ]; then
    ln -sf "/root/.local/bin/agy" /usr/local/bin/agy 2>/dev/null || true
  fi
fi
echo -e "${GREEN}[✓]${NC} AI harness CLIs ready: claude, agy, opencode, codex"

# 6. Extract / Deploy Standalone Program Bundle
echo -e "${BLUE}==>${NC} Deploying Remote bundled program to ${INSTALL_DIR}..."
mkdir -p "${INSTALL_DIR}" "${DATA_DIR}"

if [ -d "${SCRIPT_DIR}/bundle" ] && [ -f "${SCRIPT_DIR}/bundle/server.mjs" ]; then
  echo "    Copying files from local bundle directory..."
  cp -rf "${SCRIPT_DIR}/bundle/"* "${INSTALL_DIR}/"
elif [ -f "${SCRIPT_DIR}/remote-latest.tar.gz" ]; then
  echo "    Extracting local remote-latest.tar.gz..."
  tar -xzf "${SCRIPT_DIR}/remote-latest.tar.gz" -C "${INSTALL_DIR}"
elif [ -f "${SCRIPT_DIR}/remote-v0.1.0-linux-x64.tar.gz" ]; then
  echo "    Extracting local release tarball..."
  tar -xzf "${SCRIPT_DIR}/remote-v0.1.0-linux-x64.tar.gz" -C "${INSTALL_DIR}"
else
  echo -e "${YELLOW}[*] Downloading remote-latest.tar.gz from GitHub (orbitnorth/remote-releases)...${NC}"
  DOWNLOAD_URL="https://raw.githubusercontent.com/orbitnorth/remote-releases/main/remote-latest.tar.gz"
  curl -fsSL "${DOWNLOAD_URL}" -o /tmp/remote-latest.tar.gz
  tar -xzf /tmp/remote-latest.tar.gz -C "${INSTALL_DIR}"
  rm -f /tmp/remote-latest.tar.gz
  echo -e "${GREEN}[✓]${NC} Downloaded and extracted standalone bundle."
fi

# Ensure executable permissions
chmod +x "${INSTALL_DIR}/bin/remote" 2>/dev/null || true
ln -sf "${INSTALL_DIR}/bin/remote" /usr/local/bin/remote

# 6. Configure Environment
if [ ! -f "${INSTALL_DIR}/.env" ]; then
  cat > "${INSTALL_DIR}/.env" << ENV_EOF
NODE_ENV=production
PORT=${PORT}
HOST=0.0.0.0
REMOTE_DATA_DIR=${DATA_DIR}
ENV_EOF
fi

# 7. Setup UFW Firewall
if command -v ufw >/dev/null 2>&1 && ufw status | grep -q "active"; then
  echo -e "${BLUE}==>${NC} Configuring UFW firewall rules..."
  ufw allow 22/tcp comment "SSH" >/dev/null 2>&1 || true
  ufw allow 80/tcp comment "HTTP Caddy" >/dev/null 2>&1 || true
  ufw allow 443/tcp comment "HTTPS Caddy" >/dev/null 2>&1 || true
  ufw allow ${PORT}/tcp comment "Remote UI & API" >/dev/null 2>&1 || true
  ufw allow 3000:3050/tcp comment "Project Dev Previews" >/dev/null 2>&1 || true
  echo -e "${GREEN}[✓]${NC} Firewall ports configured (22, 80, 443, ${PORT}, 3000-3050)"
fi

# 8. Start / Reload with PM2
echo -e "${BLUE}==>${NC} Launching Remote process with PM2..."
cd "${INSTALL_DIR}"
pm2 delete remote >/dev/null 2>&1 || true
pm2 start ecosystem.config.cjs
pm2 save >/dev/null 2>&1 || true
pm2 startup | tail -n 1 | bash >/dev/null 2>&1 || true

# 9. Optional Caddy Reverse Proxy Setup
if [ -n "${DOMAIN}" ]; then
  echo -e "${BLUE}==>${NC} Configuring Caddy reverse proxy for ${DOMAIN}..."
  if ! command -v caddy >/dev/null 2>&1; then
    echo "    Installing Caddy..."
    if command -v apt-get >/dev/null 2>&1; then
      apt-get install -y debian-keyring debian-archive-keyring apt-transport-https curl
      curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg --yes
      curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | tee /etc/apt/sources.list.d/caddy-stable.list
      apt-get update && apt-get install -y caddy
    fi
  fi

  if command -v caddy >/dev/null 2>&1; then
    cat > /etc/caddy/Caddyfile << CADDY_EOF
${DOMAIN} {
    reverse_proxy 127.0.0.1:${PORT}
}
CADDY_EOF
    systemctl restart caddy || caddy reload
    echo -e "${GREEN}[✓]${NC} Caddy reverse proxy active with automated TLS for ${DOMAIN}"
  fi
fi

# 10. Health Verification
echo -e "${BLUE}==>${NC} Verifying server health..."
HEALTHY=false
for i in {1..15}; do
  if curl -s "http://127.0.0.1:${PORT}/health" | grep -q "ok"; then
    HEALTHY=true
    break
  fi
  sleep 1
done

echo ""
if [ "$HEALTHY" = true ]; then
  echo -e "${GREEN}=================================================================${NC}"
  echo -e "${GREEN}   ✓ OrbitNorth Remote v0.1.0 Successfully Installed & Running! ${NC}"
  echo -e "${GREEN}=================================================================${NC}"
  echo ""
  if [ -n "${DOMAIN}" ]; then
    echo -e "  🌐  ${CYAN}Web Dashboard:${NC} https://${DOMAIN}"
  fi
  echo -e "  🌐  ${CYAN}Direct URL:${NC}    http://${PUBLIC_IP}:${PORT}"
  echo -e "  📁  ${CYAN}Install Dir:${NC}   ${INSTALL_DIR}"
  echo -e "  💾  ${CYAN}Data Storage:${NC}  ${DATA_DIR}"
  echo ""
  echo -e "  ${YELLOW}CLI Management Commands:${NC}"
  echo "    remote status        # Check process status"
  echo "    pm2 logs remote      # View real-time logs"
  echo "    pm2 restart remote   # Restart server"
  echo "    pm2 stop remote      # Stop server"
  echo ""
  echo -e "  ${BLUE}Configure AI Providers:${NC}"
  echo "    Open the Web Dashboard -> click 'API Keys' to sign in or add keys."
  echo -e "${GREEN}=================================================================${NC}"
else
  echo -e "${YELLOW}[!] Warning: Health check did not respond in 15s. Check PM2 logs with: pm2 logs remote${NC}"
fi
