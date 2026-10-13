<#
  Vuelve a la release anterior a la que esta activa.
  Uso: powershell -ExecutionPolicy Bypass -File .\scripts\rollback-web.ps1
#>
param(
  [string]$SshHost    = "comfor-vps",
  [string]$RemoteBase = "/var/www/comfor-web"
)
$ErrorActionPreference = "Stop"

$Remote = @"
set -e
R='$RemoteBase'
CUR=`$(basename "`$(readlink -f `$R/current)")
PREV=`$(ls -1 "`$R/releases" | sort | awk -v c="`$CUR" '`$0 < c' | tail -n 1)
if [ -z "`$PREV" ]; then echo "No hay release anterior a `$CUR"; exit 1; fi
ln -sfn "`$R/releases/`$PREV" "`$R/current"
echo "Rollback: `$CUR -> `$PREV"
"@ -replace "`r", ""

$Remote | ssh $SshHost "bash -s"
if ($LASTEXITCODE -ne 0) { throw "Rollback fallo" }
