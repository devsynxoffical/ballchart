# Creates android/app/upload-keystore.jks for Play Store upload signing.
# Run from repo root:  powershell -ExecutionPolicy Bypass -File android\create-upload-keystore.ps1

$ErrorActionPreference = "Stop"
$keystorePath = Join-Path $PSScriptRoot "app\upload-keystore.jks"

if (Test-Path $keystorePath) {
    Write-Host "Keystore already exists: $keystorePath"
    Write-Host "Delete it first if you want to create a new one."
    exit 1
}

Write-Host "You will be asked for:"
Write-Host "  - Keystore password (storePassword in key.properties)"
Write-Host "  - Key password (keyPassword — can be same as store)"
Write-Host "  - Name, org, city, etc. (any values are OK for Play)"
Write-Host ""

$keytool = "keytool"
if (Get-Command keytool -ErrorAction SilentlyContinue) {
    $keytool = (Get-Command keytool).Source
} else {
    $javaHome = $env:JAVA_HOME
    if ($javaHome) {
        $candidate = Join-Path $javaHome "bin\keytool.exe"
        if (Test-Path $candidate) { $keytool = $candidate }
    }
}

& $keytool -genkey -v `
    -keystore $keystorePath `
    -storetype JKS `
    -keyalg RSA `
    -keysize 2048 `
    -validity 10000 `
    -alias upload

Write-Host ""
Write-Host "Created: $keystorePath"
Write-Host "Next:"
Write-Host "  1. copy android\key.properties.example android\key.properties"
Write-Host "  2. Put your passwords in android\key.properties"
Write-Host "  3. flutter clean && flutter build appbundle --release"
