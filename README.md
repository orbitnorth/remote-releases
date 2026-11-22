# OrbitNorth Remote Releases (v0.1.0)

This directory contains the **pre-compiled, standalone, closed program** distribution of **OrbitNorth Remote**. 

Because the source repository is private, this release bundle contains everything compiled into a single unified binary + pre-rendered static frontend. **No git clone, no GitHub tokens, no pnpm, and no compilation are needed on the VPS.**

---

## ⚡ Quick Start: One-Command VPS Installation

### Option 1: Direct 1-Line Install (Piped via curl)
Run this directly on any clean Ubuntu/Debian/Linux VPS:
```bash
curl -fsSL https://raw.githubusercontent.com/orbitnorth/remote-releases/main/install.sh | sudo bash
```
*(To configure a custom domain with automated SSL, pass your domain: `curl -fsSL https://raw.githubusercontent.com/orbitnorth/remote-releases/main/install.sh | sudo bash -s -- agent.yourdomain.com`)*

---

### Option 2: Clone and Run
```bash
git clone https://github.com/orbitnorth/remote-releases.git
cd remote-releases && sudo bash install.sh [optional-domain.com]
```

---

### Option 3: Direct Deploy from your Local Machine
From your local computer, push and install over SSH in one command:
```bash
# From Bash / WSL:
./deploy.sh root@YOUR_VPS_IP [optional-domain.com]

# From Windows PowerShell:
.\deploy.ps1 -Target root@YOUR_VPS_IP [-Domain optional-domain.com]
```

The automated installer will:
1. Detect or install Node.js 20 LTS.
2. Deploy the self-contained program to `/opt/remote`.
3. Set up PM2 for automated 24/7 background process management and auto-start on boot.
4. Configure UFW firewall for ports 80, 443, 7682, and project preview ranges (3000-3050).
5. Optionally configure Caddy with automatic SSL certificates if a domain is provided.
6. Verify service health and display your dashboard URL.

---

## 📦 Directory Structure

```
remote-releases/
├── bundle/                         # Extracted standalone program
│   ├── server.mjs                  # Single 1.4MB bundled backend (Express, WS, Tools)
│   ├── public/                     # Pre-rendered static Next.js frontend
│   ├── bin/remote                  # CLI launcher
│   ├── ecosystem.config.cjs        # PM2 cluster configuration
│   └── remote.service              # Systemd service unit definition
├── remote-latest.tar.gz            # Latest release archive
├── remote-v0.1.0-linux-x64.tar.gz # Versioned release archive
├── install.sh                      # One-command installer for VPS
├── deploy.sh                       # One-command remote SSH deployer
├── doctor.sh                       # System health diagnostics
├── update.sh                       # In-place updater
└── README.md                       # This guide
```

---

## 🛠️ VPS Management Commands

Once installed, manage Remote from anywhere on your server:

```bash
# Check status
remote status
# or
pm2 status

# View live streaming logs
pm2 logs remote

# Restart server
pm2 restart remote

# Run diagnostics
bash /opt/remote/doctor.sh
```

---

## 🔒 Security & Credentials
All project workspaces, Git histories, and provider credentials (API keys and CLI OAuth sessions) are isolated inside `/opt/remote/data/`.
