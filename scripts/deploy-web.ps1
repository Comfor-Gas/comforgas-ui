<#
  Deploy de Flutter Web al VPS por SSH.
  Uso (desde la raiz del proyecto):
    powershell -ExecutionPolicy Bypass -File .\scripts\deploy-web.ps1
    powershell -ExecutionPolicy Bypass -File .\scripts\deploy-web.ps1 -SkipBuild   # reusa build\web
  Requisitos: Flutter en el PATH, OpenSSH de Windows, alias "comfor-vps" en ~/.ssh/config
#>
param(
  [string]$SshHost    = "comfor-vps",
  [string]$RemoteBase = "/var/www/comfor-web",
  [string]$EnvFile    = "env.prod.json",
  [int]$Keep          = 5,
  [switch]$SkipBuild
)

$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path $PSScriptRoot -Parent
Set-Location $ProjectRoot

function Assert-Ok($what) {
  if ($LASTEXITCODE -ne 0) { throw "Fallo: $what (codigo $LASTEXITCODE)" }
}

# 1) Build
if (-not $SkipBuild) {
  if (-not (Test-Path $EnvFile)) { throw "No existe $EnvFile en $ProjectRoot (copia env.prod.example.json)" }
  Write-Host "==> flutter pub get" -ForegroundColor Cyan
  flutter pub get; Assert-Ok "flutter pub get"
  Write-Host "==> flutter build web --release" -ForegroundColor Cyan
  flutter build web --release --dart-define-from-file=$EnvFile; Assert-Ok "flutter build web"
}
if (-not (Test-Path "build\web\index.html")) { throw "No se encontro build\web\index.html" }

# 2) Empaquetar (tar viene incluido en Windows 11)
$Release = Get-Date -Format "yyyyMMdd-HHmmss"
$Tarball = Join-Path $env:TEMP "comfor-web-$Release.tar.gz"
Write-Host "==> Empaquetando release $Release" -ForegroundColor Cyan
tar -czf $Tarball -C build\web .; Assert-Ok "tar"

# 3) Subir
Write-Host "==> Subiendo al VPS" -ForegroundColor Cyan
scp $Tarball "${SshHost}:/tmp/"; Assert-Ok "scp"

# 4) Activar la release en el servidor (cambio de symlink = sin downtime)
$Remote = @"
set -e
R='$RemoteBase'
REL='$Release'
mkdir -p "`$R/releases/`$REL"
tar -xzf "/tmp/comfor-web-`$REL.tar.gz" -C "`$R/releases/`$REL"
rm -f "/tmp/comfor-web-`$REL.tar.gz"
test -f "`$R/releases/`$REL/index.html"
chmod -R a+rX "`$R/releases/`$REL"
ln -sfn "`$R/releases/`$REL" "`$R/current"
cd "`$R/releases" && ls -1 | sort -r | tail -n +$($Keep + 1) | xargs -r rm -rf
echo "Release activa: `$(readlink -f `$R/current)"
"@ -replace "`r", ""

Write-Host "==> Activando release" -ForegroundColor Cyan
$Remote | ssh $SshHost "bash -s"; Assert-Ok "activacion remota"

Remove-Item $Tarball -ErrorAction SilentlyContinue
Write-Host "==> Deploy OK ($Release)" -ForegroundColor Green
