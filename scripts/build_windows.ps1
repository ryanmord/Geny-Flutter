$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectDir = Split-Path -Parent $ScriptDir
$BackendDir = Join-Path (Split-Path -Parent $ProjectDir) "Geny\backend"

Write-Host "==> Building backend..."
Set-Location $BackendDir
npm install
npm run build

Write-Host "==> Building Flutter app..."
Set-Location $ProjectDir
flutter build windows

Write-Host "==> Bundling backend into app..."
$BuildDir = Join-Path $ProjectDir "build\windows\x64\runner\Release"
$BackendDest = Join-Path $BuildDir "backend"

New-Item -ItemType Directory -Force -Path $BackendDest | Out-Null
Copy-Item -Recurse -Force "$BackendDir\dist" "$BackendDest\dist"
Copy-Item -Recurse -Force "$BackendDir\node_modules" "$BackendDest\node_modules"
Copy-Item -Force "$BackendDir\package.json" "$BackendDest\package.json"

if (Test-Path "$BackendDir\agents") {
    Copy-Item -Recurse -Force "$BackendDir\agents" "$BackendDest\agents"
}

Write-Host "==> Build complete: $BuildDir"
