# ==============================================================================
# OrbitNorth Remote — One-Command Push to Remote VPS (PowerShell)
# Usage: .\deploy.ps1 -Target user@vps-ip [-Domain myagent.example.com]
# ==============================================================================

param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]$Target,

    [Parameter(Mandatory=$false, Position=1)]
    [string]$Domain = ""
)

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$Tarball = Join-Path $ScriptDir "remote-latest.tar.gz"
$Installer = Join-Path $ScriptDir "install.sh"

if (-not (Test-Path $Tarball)) {
    Write-Error "Release tarball not found at $Tarball. Run 'pnpm release' first."
    exit 1
}

Write-Host "==> Deploying OrbitNorth Remote to $Target..." -ForegroundColor Cyan
Write-Host "    Preparing remote directory /tmp/remote-deploy..." -ForegroundColor DarkGray
ssh $Target "mkdir -p /tmp/remote-deploy"

Write-Host "    Uploading release package and installer..." -ForegroundColor DarkGray
scp $Tarball "${Target}:/tmp/remote-deploy/remote-latest.tar.gz"
scp $Installer "${Target}:/tmp/remote-deploy/install.sh"

Write-Host "    Executing installer on VPS..." -ForegroundColor Cyan
if ($Domain) {
    ssh -t $Target "cd /tmp/remote-deploy && sudo bash install.sh $Domain && rm -rf /tmp/remote-deploy"
} else {
    ssh -t $Target "cd /tmp/remote-deploy && sudo bash install.sh && rm -rf /tmp/remote-deploy"
}

Write-Host "==> Deployment finished!" -ForegroundColor Green
