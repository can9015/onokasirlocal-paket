# ============================================================
# OnoKasir Local - STEP 07
# Install Apache + MySQL as Windows Services
# Run this script AS ADMINISTRATOR.
# ============================================================

$ErrorActionPreference = 'Stop'

$Root = 'D:\OnokasirLocal'
$ApacheExe = Join-Path $Root 'apache\bin\httpd.exe'
$ApacheConf = Join-Path $Root 'apache\conf\httpd.conf'
$MySqlExe = Join-Path $Root 'mysql\bin\mysqld.exe'
$MyIni = Join-Path $Root 'mysql\my.ini'

$ApacheService = 'OnokasirApache'
$MySqlService = 'OnokasirMySQL'

function Assert-Admin {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    $p = New-Object Security.Principal.WindowsPrincipal($id)
    if (-not $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        throw 'Jalankan PowerShell / script ini dengan Run as administrator.'
    }
}

function Assert-File($Path, $Name) {
    if (-not (Test-Path -LiteralPath $Path)) {
        throw "$Name tidak ditemukan: $Path"
    }
}

Assert-Admin
Assert-File $ApacheExe 'Apache httpd.exe'
Assert-File $ApacheConf 'Apache httpd.conf'
Assert-File $MySqlExe 'MySQL mysqld.exe'
Assert-File $MyIni 'MySQL my.ini'

Write-Host ''
Write-Host '=== OnoKasir Local - Install Services ===' -ForegroundColor Cyan
Write-Host ''

# Validate Apache config before installation.
& $ApacheExe -f $ApacheConf -t
if ($LASTEXITCODE -ne 0) {
    throw 'Konfigurasi Apache tidak valid. Service tidak dipasang.'
}

# Remove our old service definitions if present, but do NOT remove any unrelated services.
foreach ($svc in @($ApacheService, $MySqlService)) {
    $existing = Get-Service -Name $svc -ErrorAction SilentlyContinue
    if ($null -ne $existing) {
        if ($existing.Status -ne 'Stopped') {
            Write-Host "Stopping $svc ..." -ForegroundColor Yellow
            Stop-Service -Name $svc -Force -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 2
        }
    }
}

# Apache service.
$apacheExisting = Get-Service -Name $ApacheService -ErrorAction SilentlyContinue
if ($null -eq $apacheExisting) {
    Write-Host "Installing Apache service: $ApacheService" -ForegroundColor Green
    & $ApacheExe -f $ApacheConf -k install -n $ApacheService
    if ($LASTEXITCODE -ne 0) { throw 'Gagal memasang service Apache.' }
} else {
    Write-Host "Apache service sudah ada: $ApacheService" -ForegroundColor DarkGray
}

# MySQL service. --defaults-file must be specified as part of the ImagePath.
$mysqlExisting = Get-Service -Name $MySqlService -ErrorAction SilentlyContinue
if ($null -eq $mysqlExisting) {
    Write-Host "Installing MySQL service: $MySqlService" -ForegroundColor Green
    & $MySqlExe --install $MySqlService --defaults-file=$MyIni
    if ($LASTEXITCODE -ne 0) { throw 'Gagal memasang service MySQL.' }
} else {
    Write-Host "MySQL service sudah ada: $MySqlService" -ForegroundColor DarkGray
}

# Automatic startup: this is the requested AUTO RUN behavior.
Set-Service -Name $ApacheService -StartupType Automatic
Set-Service -Name $MySqlService -StartupType Automatic

# Display installed services.
Write-Host ''
Get-Service -Name $MySqlService, $ApacheService | Select-Object Name, Status, StartType | Format-Table -AutoSize

Write-Host ''
Write-Host 'SERVICE INSTALL SELESAI.' -ForegroundColor Green
Write-Host 'AUTO RUN Windows: ON (Automatic).' -ForegroundColor Green
Write-Host ''
Write-Host 'Berikutnya jalankan: tools\control-center.bat' -ForegroundColor Cyan
