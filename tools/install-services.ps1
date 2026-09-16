# ============================================================
# OnoKasir Local
# Install Apache + MariaDB as Windows Services
# Run this script AS ADMINISTRATOR.
# ============================================================

$ErrorActionPreference = 'Stop'

$Root = 'D:\OnokasirLocal'

# ============================================================
# PATH
# ============================================================

$ApacheExe = Join-Path $Root 'apache\bin\httpd.exe'
$ApacheConf = Join-Path $Root 'apache\conf\httpd.conf'

$MariaDbExe = Join-Path $Root 'mariadb\bin\mariadbd.exe'
$MariaDbIni = Join-Path $Root 'mariadb\my.ini'

# ============================================================
# SERVICE
# ============================================================

$ApacheService = 'OnokasirApache'
$MariaDbService = 'OnokasirMariaDB'

# Legacy service yang dulu dipakai.
$LegacyMySqlService = 'OnokasirMySQL'

# ============================================================
# ADMIN
# ============================================================

function Assert-Admin {

    $id = [Security.Principal.WindowsIdentity]::GetCurrent()

    $principal = New-Object `
        Security.Principal.WindowsPrincipal(
            $id
        )

    if (
        -not $principal.IsInRole(
            [Security.Principal.WindowsBuiltInRole]::Administrator
        )
    ) {
        throw 'Jalankan script ini dengan Run as administrator.'
    }
}

# ============================================================
# FILE CHECK
# ============================================================

function Assert-File {

    param(
        [string]$Path,
        [string]$Name
    )

    if (
        -not (
            Test-Path `
                -LiteralPath $Path `
                -PathType Leaf
        )
    ) {

        throw "$Name tidak ditemukan: $Path"
    }
}

# ============================================================
# START
# ============================================================

Assert-Admin

Assert-File `
    $ApacheExe `
    'Apache httpd.exe'

Assert-File `
    $ApacheConf `
    'Apache httpd.conf'

Assert-File `
    $MariaDbExe `
    'MariaDB mariadbd.exe'

Assert-File `
    $MariaDbIni `
    'MariaDB my.ini'

Write-Host ''
Write-Host '============================================' `
    -ForegroundColor Cyan

Write-Host ' ONOKASIR LOCAL - INSTALL SERVICES' `
    -ForegroundColor Cyan

Write-Host '============================================' `
    -ForegroundColor Cyan

Write-Host ''

Write-Host "Root    : $Root"
Write-Host "Apache  : $ApacheService"
Write-Host "MariaDB : $MariaDbService"
Write-Host ''

# ============================================================
# VALIDATE APACHE
# ============================================================

Write-Host 'Validating Apache configuration...' `
    -ForegroundColor Yellow

& $ApacheExe `
    -f $ApacheConf `
    -t

if ($LASTEXITCODE -ne 0) {

    throw `
        'Konfigurasi Apache tidak valid. Service tidak dipasang.'
}

Write-Host '[OK] Apache configuration valid.' `
    -ForegroundColor Green

Write-Host ''

# ============================================================
# REMOVE LEGACY MYSQL SERVICE
# ============================================================

$legacyService = Get-Service `
    -Name $LegacyMySqlService `
    -ErrorAction SilentlyContinue

if ($null -ne $legacyService) {

    Write-Host `
        "Legacy service ditemukan: $LegacyMySqlService" `
        -ForegroundColor Yellow

    if (
        $legacyService.Status -ne 'Stopped'
    ) {

        Write-Host `
            "Stopping legacy service..." `
            -ForegroundColor Yellow

        Stop-Service `
            -Name $LegacyMySqlService `
            -Force `
            -ErrorAction SilentlyContinue

        Start-Sleep -Seconds 2
    }

    Write-Host `
        "Removing legacy service: $LegacyMySqlService" `
        -ForegroundColor Yellow

    & sc.exe delete $LegacyMySqlService

    if ($LASTEXITCODE -ne 0) {

        throw `
            "Gagal menghapus service legacy $LegacyMySqlService."
    }

    Start-Sleep -Seconds 2

    Write-Host `
        "[OK] Legacy MySQL service dihapus." `
        -ForegroundColor Green
}

# ============================================================
# REMOVE OLD MARIADB SERVICE IF INVALID
# ============================================================

$existingMariaDb = Get-Service `
    -Name $MariaDbService `
    -ErrorAction SilentlyContinue

if ($null -ne $existingMariaDb) {

    Write-Host `
        "MariaDB service sudah ada: $MariaDbService" `
        -ForegroundColor DarkGray
}
else {

    # ========================================================
    # INSTALL MARIADB SERVICE
    # ========================================================

    Write-Host `
        "Installing MariaDB service: $MariaDbService" `
        -ForegroundColor Green

    & $MariaDbExe `
        --install `
        $MariaDbService `
        --defaults-file="$MariaDbIni"

    if ($LASTEXITCODE -ne 0) {

        throw `
            'Gagal memasang service MariaDB.'
    }

    Write-Host `
        '[OK] MariaDB service berhasil dipasang.' `
        -ForegroundColor Green
}

# ============================================================
# APACHE SERVICE
# ============================================================

$existingApache = Get-Service `
    -Name $ApacheService `
    -ErrorAction SilentlyContinue

if ($null -ne $existingApache) {

    Write-Host `
        "Apache service sudah ada: $ApacheService" `
        -ForegroundColor DarkGray
}
else {

    Write-Host `
        "Installing Apache service: $ApacheService" `
        -ForegroundColor Green

    & $ApacheExe `
        -f $ApacheConf `
        -k install `
        -n $ApacheService

    if ($LASTEXITCODE -ne 0) {

        throw `
            'Gagal memasang service Apache.'
    }

    Write-Host `
        '[OK] Apache service berhasil dipasang.' `
        -ForegroundColor Green
}

# ============================================================
# AUTOMATIC START
# ============================================================

Set-Service `
    -Name $ApacheService `
    -StartupType Automatic

Set-Service `
    -Name $MariaDbService `
    -StartupType Automatic

# ============================================================
# FINAL STATUS
# ============================================================

Write-Host ''

Write-Host '============================================' `
    -ForegroundColor Cyan

Write-Host ' SERVICE STATUS' `
    -ForegroundColor Cyan

Write-Host '============================================' `
    -ForegroundColor Cyan

Write-Host ''

Get-Service `
    -Name $MariaDbService, $ApacheService `
    | Select-Object Name, Status, StartType `
    | Format-Table -AutoSize

Write-Host ''

Write-Host 'SERVICE INSTALL SELESAI.' `
    -ForegroundColor Green

Write-Host 'Apache  : OnokasirApache' `
    -ForegroundColor Green

Write-Host 'MariaDB : OnokasirMariaDB' `
    -ForegroundColor Green

Write-Host 'AUTO RUN Windows : ON' `
    -ForegroundColor Green

Write-Host ''

Write-Host 'Berikutnya:' `
    -ForegroundColor Cyan

Write-Host 'tools\control-center.bat' `
    -ForegroundColor Cyan

Write-Host ''
