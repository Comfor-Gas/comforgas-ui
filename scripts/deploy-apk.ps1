<#
  Compila el APK de produccion y (opcional) lo publica en el VPS para descarga.
  Uso:
    powershell -ExecutionPolicy Bypass -File .\scripts\deploy-apk.ps1 -Version 1.0.1 -Build 2
    powershell -ExecutionPolicy Bypass -File .\scripts\deploy-apk.ps1 -Version 1.0.1 -Build 2 -Publish
  Con -Publish queda en https://TU-DOMINIO/descargas/comfor-gas.apk
#>
param(
  [Parameter(Mandatory = $true)][string]$Version,   # ej. 1.0.1  (version visible)
  [Parameter(Mandatory = $true)][int]$Build,        # ej. 2      (siempre mayor que el anterior)
  [string]$SshHost  = "comfor-vps",
  [string]$EnvFile  = "env.prod.json",
  [string]$RemoteDir = "/var/www/comfor-downloads",
  [switch]$Publish
)
$ErrorActionPreference = "Stop"
Set-Location (Split-Path $PSScriptRoot -Parent)

flutter pub get
if ($LASTEXITCODE -ne 0) { throw "flutter pub get fallo" }

flutter build apk --release --dart-define-from-file=$EnvFile --build-name=$Version --build-number=$Build
if ($LASTEXITCODE -ne 0) { throw "flutter build apk fallo" }

$Apk = "build\app\outputs\flutter-apk\app-release.apk"
Write-Host "APK generado: $Apk" -ForegroundColor Green

if ($Publish) {
  $Name = "comfor-gas-$Version+$Build.apk"
  scp $Apk "${SshHost}:$RemoteDir/$Name"
  if ($LASTEXITCODE -ne 0) { throw "scp fallo" }
  ssh $SshHost "cd $RemoteDir && chmod a+r '$Name' && ln -sfn '$Name' comfor-gas.apk && ls -lh"
  if ($LASTEXITCODE -ne 0) { throw "publicacion fallo" }
  Write-Host "Publicado como /descargas/comfor-gas.apk ($Name)" -ForegroundColor Green
}
