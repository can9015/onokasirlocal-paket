# ============================================================
# OnoKasir Local Control Center - FINAL STABLE
#
# Apache + MariaDB service control via native Windows SCM
# Status / RUN / STOP / RUN ALL / STOP ALL
# Auto Run Windows
# Live Log / File Log
# Open Local Site / phpMyAdmin
#
# Environment:
#   Root      : D:\OnokasirLocal
#   Apache    : OnokasirApache
#   MariaDB   : OnokasirMariaDB
#   MariaDB   : 3306
#   Apache    : 80
# ============================================================

$ErrorActionPreference = 'Stop'

# ============================================================
# CONFIGURATION
# ============================================================

$Root            = 'D:\OnokasirLocal'

$ApacheService   = 'OnokasirApache'
$MariaDbService  = 'OnokasirMariaDB'

$ApacheUrl       = 'http://onokasir.local'
$PhpMyAdminUrl   = 'http://onokasir.local/phpmyadmin'

$LogDirectory    = Join-Path $Root 'logs'
$LogFile         = Join-Path $LogDirectory 'control-center.log'

$RefreshInterval = 2000

# ============================================================
# WINDOWS FORMS
# ============================================================

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# ============================================================
# CREATE LOG DIRECTORY
# ============================================================

if (-not (Test-Path -LiteralPath $LogDirectory)) {

    New-Item `
        -ItemType Directory `
        -Path $LogDirectory `
        -Force | Out-Null
}

# ============================================================
# ADMIN
# ============================================================

function Is-Admin {

    $identity =
        [Security.Principal.WindowsIdentity]::GetCurrent()

    $principal =
        New-Object System.Security.Principal.WindowsPrincipal(
            $identity
        )

    return $principal.IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator
    )
}

function Relaunch-AsAdmin {

    if (Is-Admin) {
        return $false
    }

    $powershellPath =
        "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"

    $arguments =
        '-NoProfile -ExecutionPolicy Bypass -File "' +
        $PSCommandPath +
        '"'

    $process =
        New-Object System.Diagnostics.ProcessStartInfo

    $process.FileName =
        $powershellPath

    $process.Arguments =
        $arguments

    $process.Verb =
        'runas'

    $process.WorkingDirectory =
        $Root

    try {

        [System.Diagnostics.Process]::Start(
            $process
        ) | Out-Null

        return $true
    }
    catch {

        [System.Windows.Forms.MessageBox]::Show(
            'Control Center membutuhkan hak Administrator.',
            'OnoKasir Local',
            'OK',
            'Warning'
        ) | Out-Null

        return $true
    }
}

if (Relaunch-AsAdmin) {
    exit
}

# ============================================================
# LOGGING
# ============================================================

function Write-Log {

    param(
        [string]$Message,

        [ValidateSet(
            'INFO',
            'SUCCESS',
            'WARNING',
            'ERROR'
        )]
        [string]$Level = 'INFO'
    )

    $timestamp =
        Get-Date -Format 'yyyy-MM-dd HH:mm:ss'

    $line =
        "[{0}] [{1}] {2}" -f `
            $timestamp,
            $Level,
            $Message

    try {

        Add-Content `
            -LiteralPath $LogFile `
            -Value $line `
            -Encoding UTF8
    }
    catch {
        # Jangan menghentikan aplikasi jika log gagal.
    }

    if (
        $null -ne $script:logBox -and
        -not $script:logBox.IsDisposed
    ) {

        try {

            $script:logBox.AppendText(
                $line + [Environment]::NewLine
            )

            $script:logBox.SelectionStart =
                $script:logBox.TextLength

            $script:logBox.ScrollToCaret()
        }
        catch {
        }
    }
}

function Load-Log {

    if (-not (Test-Path -LiteralPath $LogFile)) {
        return
    }

    try {

        $lines =
            Get-Content `
                -LiteralPath $LogFile `
                -Tail 250 `
                -ErrorAction SilentlyContinue

        if ($null -eq $script:logBox) {
            return
        }

        $script:logBox.Clear()

        foreach ($line in $lines) {

            $script:logBox.AppendText(
                $line + [Environment]::NewLine
            )
        }

        $script:logBox.SelectionStart =
            $script:logBox.TextLength

        $script:logBox.ScrollToCaret()
    }
    catch {
    }
}

# ============================================================
# SERVICE
# ============================================================

function Get-ServiceObject {

    param(
        [string]$Name
    )

    return Get-Service `
        -Name $Name `
        -ErrorAction SilentlyContinue
}

function Get-ServiceState {

    param(
        [string]$Name
    )

    $service =
        Get-ServiceObject $Name

    if ($null -eq $service) {
        return 'NOT INSTALLED'
    }

    try {
        $service.Refresh()
    }
    catch {
    }

    return [string]$service.Status
}

function Get-ServiceStartupType {

    param(
        [string]$Name
    )

    $service =
        Get-ServiceObject $Name

    if ($null -eq $service) {
        return 'N/A'
    }

    try {
        return [string]$service.StartType
    }
    catch {
        return 'Unknown'
    }
}

# ============================================================
# STATUS BUTTON
# ============================================================

function Set-ButtonState {

    param(
        $Button,
        [string]$State
    )

    switch ($State) {

        'Running' {

            $Button.Text =
                '● RUNNING'

            $Button.ForeColor =
                [System.Drawing.Color]::DarkGreen
        }

        'Stopped' {

            $Button.Text =
                '● STOPPED'

            $Button.ForeColor =
                [System.Drawing.Color]::Firebrick
        }

        'NOT INSTALLED' {

            $Button.Text =
                '● NOT INSTALLED'

            $Button.ForeColor =
                [System.Drawing.Color]::DarkOrange
        }

        'Starting' {

            $Button.Text =
                '● STARTING'

            $Button.ForeColor =
                [System.Drawing.Color]::DarkOrange
        }

        'Stopping' {

            $Button.Text =
                '● STOPPING'

            $Button.ForeColor =
                [System.Drawing.Color]::DarkOrange
        }

        default {

            $Button.Text =
                "● $State"

            $Button.ForeColor =
                [System.Drawing.Color]::DarkOrange
        }
    }
}

# ============================================================
# ENABLE / DISABLE ACTION BUTTON
# ============================================================

function Set-ActionButtons {

    $apacheState =
        Get-ServiceState $ApacheService

    $mariaDbState =
        Get-ServiceState $MariaDbService

    $apacheRun.Enabled =
        ($apacheState -eq 'Stopped')

    $apacheStop.Enabled =
        ($apacheState -eq 'Running')

    $mariaDbRun.Enabled =
        ($mariaDbState -eq 'Stopped')

    $mariaDbStop.Enabled =
        ($mariaDbState -eq 'Running')

    $runAll.Enabled =
        (
            $apacheState -ne 'Running' -or
            $mariaDbState -ne 'Running'
        )

    $stopAll.Enabled =
        (
            $apacheState -eq 'Running' -or
            $mariaDbState -eq 'Running'
        )
}

# ============================================================
# SERVICE ACTION
# Native Windows Service Control Manager
# PowerShell 5.1 SAFE
# ============================================================

function Service-Action {

    param(
        [string]$Name,

        [ValidateSet('Start','Stop')]
        [string]$Action
    )

    $service = Get-ServiceObject $Name

    if ($null -eq $service) {

        throw "Service '$Name' belum terpasang."
    }

    $service.Refresh()

    # ========================================================
    # START
    # ========================================================

    if ($Action -eq 'Start') {

        if ($service.Status -eq 'Running') {

            Write-Log "Service sudah RUNNING: $Name" 'INFO'
            return
        }

        Write-Log "Starting service: $Name" 'INFO'

        $output =
            & sc.exe start $Name 2>&1

        $exitCode =
            $LASTEXITCODE

        $outputText =
            ($output | Out-String).Trim()

        if ($exitCode -eq 0) {

            Write-Log "Perintah start dikirim: $Name" 'INFO'
        }
        elseif ($exitCode -eq 1053) {

            Write-Log `
                "SCM timeout 1053 untuk $Name. Memeriksa status service..." `
                'WARNING'
        }
        else {

            $errorMessage =
                "sc.exe start gagal untuk $Name. ExitCode=$exitCode"

            if ($outputText) {
                $errorMessage =
                    "$errorMessage. $outputText"
            }

            throw $errorMessage
        }

        for ($i = 0; $i -lt 60; $i++) {

            Start-Sleep -Milliseconds 500

            $service =
                Get-ServiceObject $Name

            if ($null -eq $service) {

                throw `
                    "Service '$Name' tidak ditemukan setelah start."
            }

            $service.Refresh()

            $state =
                [string]$service.Status

            if ($state -eq 'Running') {

                Write-Log `
                    "Service RUNNING: $Name" `
                    'SUCCESS'

                return
            }

            if ($state -eq 'Stopped') {

                $errorMessage =
                    "Service '$Name' kembali STOPPED setelah percobaan start."

                if ($outputText) {

                    $errorMessage =
                        "$errorMessage Output SCM: $outputText"
                }

                throw $errorMessage
            }

            if ($state -eq 'StartPending') {

                if (($i % 10) -eq 0) {

                    Write-Log `
                        "Service masih START_PENDING: $Name" `
                        'INFO'
                }

                continue
            }
        }

        throw `
            "Timeout menunggu service '$Name' menjadi RUNNING."
    }

    # ========================================================
    # STOP
    # ========================================================

    if ($Action -eq 'Stop') {

        if ($service.Status -eq 'Stopped') {

            Write-Log `
                "Service sudah STOPPED: $Name" `
                'INFO'

            return
        }

        Write-Log `
            "Stopping service: $Name" `
            'INFO'

        $output =
            & sc.exe stop $Name 2>&1

        $exitCode =
            $LASTEXITCODE

        $outputText =
            ($output | Out-String).Trim()

        if ($exitCode -eq 0) {

            Write-Log `
                "Perintah stop dikirim: $Name" `
                'INFO'
        }
        elseif ($exitCode -eq 1062) {

            Write-Log `
                "Service $Name sudah tidak berjalan." `
                'INFO'

            return
        }
        else {

            $errorMessage =
                "sc.exe stop gagal untuk $Name. ExitCode=$exitCode"

            if ($outputText) {

                $errorMessage =
                    "$errorMessage. $outputText"
            }

            throw $errorMessage
        }

        for ($i = 0; $i -lt 60; $i++) {

            Start-Sleep -Milliseconds 500

            $service =
                Get-ServiceObject $Name

            if ($null -eq $service) {

                Write-Log `
                    "Service '$Name' sudah tidak ditemukan." `
                    'WARNING'

                return
            }

            $service.Refresh()

            $state =
                [string]$service.Status

            if ($state -eq 'Stopped') {

                Write-Log `
                    "Service STOPPED: $Name" `
                    'SUCCESS'

                return
            }

            if ($state -eq 'StopPending') {

                if (($i % 10) -eq 0) {

                    Write-Log `
                        "Service masih STOP_PENDING: $Name" `
                        'INFO'
                }

                continue
            }
        }

        throw `
            "Timeout menunggu service '$Name' menjadi STOPPED."
    }
}

# ============================================================
# OPEN URL
# ============================================================

function Open-Url {

    param(
        [string]$Url
    )

    try {

        Write-Log `
            "Opening URL: $Url" `
            'INFO'

        Start-Process `
            -FilePath $Url | Out-Null
    }
    catch {

        Write-Log `
            "Gagal membuka URL $Url : $($_.Exception.Message)" `
            'ERROR'

        throw
    }
}

# ============================================================
# FORM
# ============================================================

$form =
    New-Object System.Windows.Forms.Form

$form.Text =
    'OnoKasir Local Control Center'

$form.StartPosition =
    'CenterScreen'

$form.Size =
    New-Object System.Drawing.Size(760,650)

$form.MinimumSize =
    New-Object System.Drawing.Size(760,650)

$form.MaximizeBox =
    $false

$form.BackColor =
    [System.Drawing.Color]::WhiteSmoke

# ============================================================
# TITLE
# ============================================================

$title =
    New-Object System.Windows.Forms.Label

$title.Text =
    'ONOKASIR LOCAL'

$title.Font =
    New-Object System.Drawing.Font(
        'Segoe UI',
        18,
        [System.Drawing.FontStyle]::Bold
    )

$title.AutoSize =
    $true

$title.Location =
    New-Object System.Drawing.Point(24,18)

$form.Controls.Add($title)

$subtitle =
    New-Object System.Windows.Forms.Label

$subtitle.Text =
    'Local Web Server Control Center'

$subtitle.Font =
    New-Object System.Drawing.Font(
        'Segoe UI',
        10
    )

$subtitle.AutoSize =
    $true

$subtitle.Location =
    New-Object System.Drawing.Point(27,53)

$form.Controls.Add($subtitle)

# ============================================================
# APACHE
# ============================================================

$apacheLabel =
    New-Object System.Windows.Forms.Label

$apacheLabel.Text =
    'Apache + PHP'

$apacheLabel.Font =
    New-Object System.Drawing.Font(
        'Segoe UI',
        11,
        [System.Drawing.FontStyle]::Bold
    )

$apacheLabel.Location =
    New-Object System.Drawing.Point(30,95)

$apacheLabel.Size =
    New-Object System.Drawing.Size(180,30)

$form.Controls.Add($apacheLabel)

$apacheStatus =
    New-Object System.Windows.Forms.Button

$apacheStatus.Location =
    New-Object System.Drawing.Point(220,90)

$apacheStatus.Size =
    New-Object System.Drawing.Size(145,38)

$apacheStatus.FlatStyle =
    'Flat'

$apacheStatus.TabStop =
    $false

$form.Controls.Add($apacheStatus)

$apacheRun =
    New-Object System.Windows.Forms.Button

$apacheRun.Text =
    'RUN'

$apacheRun.Location =
    New-Object System.Drawing.Point(375,90)

$apacheRun.Size =
    New-Object System.Drawing.Size(80,38)

$form.Controls.Add($apacheRun)

$apacheStop =
    New-Object System.Windows.Forms.Button

$apacheStop.Text =
    'STOP'

$apacheStop.Location =
    New-Object System.Drawing.Point(465,90)

$apacheStop.Size =
    New-Object System.Drawing.Size(80,38)

$form.Controls.Add($apacheStop)

# ============================================================
# MARIADB
# ============================================================

$mariaDbLabel =
    New-Object System.Windows.Forms.Label

$mariaDbLabel.Text =
    'MariaDB 11.8.9'

$mariaDbLabel.Font =
    New-Object System.Drawing.Font(
        'Segoe UI',
        11,
        [System.Drawing.FontStyle]::Bold
    )

$mariaDbLabel.Location =
    New-Object System.Drawing.Point(30,145)

$mariaDbLabel.Size =
    New-Object System.Drawing.Size(180,30)

$form.Controls.Add($mariaDbLabel)

$mariaDbStatus =
    New-Object System.Windows.Forms.Button

$mariaDbStatus.Location =
    New-Object System.Drawing.Point(220,140)

$mariaDbStatus.Size =
    New-Object System.Drawing.Size(145,38)

$mariaDbStatus.FlatStyle =
    'Flat'

$mariaDbStatus.TabStop =
    $false

$form.Controls.Add($mariaDbStatus)

$mariaDbRun =
    New-Object System.Windows.Forms.Button

$mariaDbRun.Text =
    'RUN'

$mariaDbRun.Location =
    New-Object System.Drawing.Point(375,140)

$mariaDbRun.Size =
    New-Object System.Drawing.Size(80,38)

$form.Controls.Add($mariaDbRun)

$mariaDbStop =
    New-Object System.Windows.Forms.Button

$mariaDbStop.Text =
    'STOP'

$mariaDbStop.Location =
    New-Object System.Drawing.Point(465,140)

$mariaDbStop.Size =
    New-Object System.Drawing.Size(80,38)

$form.Controls.Add($mariaDbStop)

# ============================================================
# RUN ALL / STOP ALL / REFRESH
# ============================================================

$runAll =
    New-Object System.Windows.Forms.Button

$runAll.Text =
    '▶  RUN ALL'

$runAll.Font =
    New-Object System.Drawing.Font(
        'Segoe UI',
        11,
        [System.Drawing.FontStyle]::Bold
    )

$runAll.Location =
    New-Object System.Drawing.Point(30,205)

$runAll.Size =
    New-Object System.Drawing.Size(160,50)

$form.Controls.Add($runAll)

$stopAll =
    New-Object System.Windows.Forms.Button

$stopAll.Text =
    '■  STOP ALL'

$stopAll.Font =
    New-Object System.Drawing.Font(
        'Segoe UI',
        11,
        [System.Drawing.FontStyle]::Bold
    )

$stopAll.Location =
    New-Object System.Drawing.Point(205,205)

$stopAll.Size =
    New-Object System.Drawing.Size(160,50)

$form.Controls.Add($stopAll)

$statusAll =
    New-Object System.Windows.Forms.Button

$statusAll.Text =
    '⟳  REFRESH'

$statusAll.Location =
    New-Object System.Drawing.Point(380,205)

$statusAll.Size =
    New-Object System.Drawing.Size(165,50)

$form.Controls.Add($statusAll)

# ============================================================
# AUTO RUN
# ============================================================

$autoLabel =
    New-Object System.Windows.Forms.Label

$autoLabel.Text =
    'AUTO RUN WINDOWS'

$autoLabel.Font =
    New-Object System.Drawing.Font(
        'Segoe UI',
        10,
        [System.Drawing.FontStyle]::Bold
    )

$autoLabel.Location =
    New-Object System.Drawing.Point(30,285)

$autoLabel.Size =
    New-Object System.Drawing.Size(170,28)

$form.Controls.Add($autoLabel)

$autoCheck =
    New-Object System.Windows.Forms.CheckBox

$autoCheck.Text =
    'Start Apache + MariaDB automatically'

$autoCheck.AutoSize =
    $true

$autoCheck.Location =
    New-Object System.Drawing.Point(205,287)

$form.Controls.Add($autoCheck)

# ============================================================
# URL BUTTONS
# ============================================================

$openPhpmyadmin =
    New-Object System.Windows.Forms.Button

$openPhpmyadmin.Text =
    'OPEN phpMyAdmin'

$openPhpmyadmin.Location =
    New-Object System.Drawing.Point(30,325)

$openPhpmyadmin.Size =
    New-Object System.Drawing.Size(160,42)

$form.Controls.Add($openPhpmyadmin)

$openSite =
    New-Object System.Windows.Forms.Button

$openSite.Text =
    'OPEN LOCAL SITE'

$openSite.Location =
    New-Object System.Drawing.Point(205,325)

$openSite.Size =
    New-Object System.Drawing.Size(160,42)

$form.Controls.Add($openSite)

$closeBtn =
    New-Object System.Windows.Forms.Button

$closeBtn.Text =
    'CLOSE'

$closeBtn.Location =
    New-Object System.Drawing.Point(380,325)

$closeBtn.Size =
    New-Object System.Drawing.Size(165,42)

$form.Controls.Add($closeBtn)

# ============================================================
# LIVE LOG
# ============================================================

$logLabel =
    New-Object System.Windows.Forms.Label

$logLabel.Text =
    'LIVE LOG'

$logLabel.Font =
    New-Object System.Drawing.Font(
        'Segoe UI',
        10,
        [System.Drawing.FontStyle]::Bold
    )

$logLabel.Location =
    New-Object System.Drawing.Point(30,390)

$logLabel.Size =
    New-Object System.Drawing.Size(100,25)

$form.Controls.Add($logLabel)

$script:logBox =
    New-Object System.Windows.Forms.RichTextBox

$script:logBox.Location =
    New-Object System.Drawing.Point(30,415)

$script:logBox.Size =
    New-Object System.Drawing.Size(675,145)

$script:logBox.ReadOnly =
    $true

$script:logBox.BackColor =
    [System.Drawing.Color]::White

$script:logBox.Font =
    New-Object System.Drawing.Font(
        'Consolas',
        8.5
    )

$script:logBox.BorderStyle =
    'FixedSingle'

$form.Controls.Add($script:logBox)

# ============================================================
# LOG BUTTONS
# ============================================================

$clearLog =
    New-Object System.Windows.Forms.Button

$clearLog.Text =
    'CLEAR LOG'

$clearLog.Location =
    New-Object System.Drawing.Point(515,575)

$clearLog.Size =
    New-Object System.Drawing.Size(90,30)

$form.Controls.Add($clearLog)

$openLog =
    New-Object System.Windows.Forms.Button

$openLog.Text =
    'OPEN LOG'

$openLog.Location =
    New-Object System.Drawing.Point(615,575)

$openLog.Size =
    New-Object System.Drawing.Size(90,30)

$form.Controls.Add($openLog)

# ============================================================
# FOOTER
# ============================================================

$footer =
    New-Object System.Windows.Forms.Label

$footer.Text =
    'Host: onokasir.local • PHP melalui Apache • MariaDB :3306'

$footer.Font =
    New-Object System.Drawing.Font(
        'Segoe UI',
        8
    )

$footer.AutoSize =
    $true

$footer.Location =
    New-Object System.Drawing.Point(30,605)

$form.Controls.Add($footer)

# ============================================================
# REFRESH UI
# ============================================================

function Refresh-UI {

    try {

        $apacheState =
            Get-ServiceState $ApacheService

        $mariaDbState =
            Get-ServiceState $MariaDbService

        Set-ButtonState `
            $apacheStatus `
            $apacheState

        Set-ButtonState `
            $mariaDbStatus `
            $mariaDbState

        $apacheSvc =
            Get-ServiceObject $ApacheService

        $mariaDbSvc =
            Get-ServiceObject $MariaDbService

        # Hindari event CheckedChanged saat refresh.
        $script:isRefreshing =
            $true

        try {

            if (
                $null -ne $apacheSvc -and
                $null -ne $mariaDbSvc
            ) {

                $autoCheck.Checked =
                    (
                        $apacheSvc.StartType -eq 'Automatic' -and
                        $mariaDbSvc.StartType -eq 'Automatic'
                    )
            }
            else {

                $autoCheck.Checked =
                    $false
            }
        }
        finally {

            $script:isRefreshing =
                $false
        }

        Set-ActionButtons
    }
    catch {
        # Timer tidak menulis error setiap 2 detik.
    }
}

# ============================================================
# APACHE RUN
# ============================================================

$apacheRun.Add_Click({

    try {

        Write-Log `
            'User action: RUN Apache' `
            'INFO'

        $apacheRun.Enabled =
            $false

        Service-Action `
            $ApacheService `
            'Start'

        Refresh-UI
    }
    catch {

        Write-Log `
            "RUN Apache gagal: $($_.Exception.Message)" `
            'ERROR'

        [System.Windows.Forms.MessageBox]::Show(
            $_.Exception.Message,
            'Apache',
            'OK',
            'Error'
        ) | Out-Null

        Refresh-UI
    }
})

# ============================================================
# APACHE STOP
# ============================================================

$apacheStop.Add_Click({

    try {

        Write-Log `
            'User action: STOP Apache' `
            'INFO'

        $apacheStop.Enabled =
            $false

        Service-Action `
            $ApacheService `
            'Stop'

        Refresh-UI
    }
    catch {

        Write-Log `
            "STOP Apache gagal: $($_.Exception.Message)" `
            'ERROR'

        [System.Windows.Forms.MessageBox]::Show(
            $_.Exception.Message,
            'Apache',
            'OK',
            'Error'
        ) | Out-Null

        Refresh-UI
    }
})

# ============================================================
# MARIADB RUN
# ============================================================

$mariaDbRun.Add_Click({

    try {

        Write-Log `
            'User action: RUN MariaDB' `
            'INFO'

        $mariaDbRun.Enabled =
            $false

        Service-Action `
            $MariaDbService `
            'Start'

        Refresh-UI
    }
    catch {

        Write-Log `
            "RUN MariaDB gagal: $($_.Exception.Message)" `
            'ERROR'

        [System.Windows.Forms.MessageBox]::Show(
            $_.Exception.Message,
            'MariaDB',
            'OK',
            'Error'
        ) | Out-Null

        Refresh-UI
    }
})

# ============================================================
# MARIADB STOP
# ============================================================

$mariaDbStop.Add_Click({

    try {

        Write-Log `
            'User action: STOP MariaDB' `
            'INFO'

        $mariaDbStop.Enabled =
            $false

        Service-Action `
            $MariaDbService `
            'Stop'

        Refresh-UI
    }
    catch {

        Write-Log `
            "STOP MariaDB gagal: $($_.Exception.Message)" `
            'ERROR'

        [System.Windows.Forms.MessageBox]::Show(
            $_.Exception.Message,
            'MariaDB',
            'OK',
            'Error'
        ) | Out-Null

        Refresh-UI
    }
})

# ============================================================
# RUN ALL
# ============================================================

$runAll.Add_Click({

    try {

        Write-Log `
            '========================================' `
            'INFO'

        Write-Log `
            'User action: RUN ALL' `
            'INFO'

        $runAll.Enabled =
            $false

        # ----------------------------------------------------
        # MariaDB harus hidup terlebih dahulu.
        # ----------------------------------------------------

        Service-Action `
            $MariaDbService `
            'Start'

        # ----------------------------------------------------
        # Apache setelah MariaDB.
        # ----------------------------------------------------

        Service-Action `
            $ApacheService `
            'Start'

        Write-Log `
            'RUN ALL selesai' `
            'SUCCESS'

        Refresh-UI
    }
    catch {

        Write-Log `
            "RUN ALL gagal: $($_.Exception.Message)" `
            'ERROR'

        [System.Windows.Forms.MessageBox]::Show(
            $_.Exception.Message,
            'RUN ALL',
            'OK',
            'Error'
        ) | Out-Null

        Refresh-UI
    }
})

# ============================================================
# STOP ALL
# ============================================================

$stopAll.Add_Click({

    try {

        Write-Log `
            '========================================' `
            'INFO'

        Write-Log `
            'User action: STOP ALL' `
            'INFO'

        $stopAll.Enabled =
            $false

        # Apache terlebih dahulu.
        Service-Action `
            $ApacheService `
            'Stop'

        # MariaDB setelah Apache.
        Service-Action `
            $MariaDbService `
            'Stop'

        Write-Log `
            'STOP ALL selesai' `
            'SUCCESS'

        Refresh-UI
    }
    catch {

        Write-Log `
            "STOP ALL gagal: $($_.Exception.Message)" `
            'ERROR'

        [System.Windows.Forms.MessageBox]::Show(
            $_.Exception.Message,
            'STOP ALL',
            'OK',
            'Error'
        ) | Out-Null

        Refresh-UI
    }
})

# ============================================================
# REFRESH BUTTON
# ============================================================

$statusAll.Add_Click({

    Write-Log `
        'Manual refresh status' `
        'INFO'

    Refresh-UI
})

# ============================================================
# AUTO RUN
# ============================================================

$autoCheck.Add_CheckedChanged({

    if ($script:isRefreshing) {
        return
    }

    if (-not $form.Visible) {
        return
    }

    try {

        $startupMode =
            if ($autoCheck.Checked) {
                'auto'
            }
            else {
                'demand'
            }

        $startupLabel =
            if ($autoCheck.Checked) {
                'Automatic'
            }
            else {
                'Manual'
            }

        Write-Log `
            "Mengubah AUTO RUN Apache + MariaDB -> $startupLabel" `
            'INFO'

        $apacheSvc =
            Get-ServiceObject $ApacheService

        $mariaDbSvc =
            Get-ServiceObject $MariaDbService

        if ($null -eq $apacheSvc) {

            throw `
                "Service '$ApacheService' belum terpasang."
        }

        if ($null -eq $mariaDbSvc) {

            throw `
                "Service '$MariaDbService' belum terpasang."
        }

        # ----------------------------------------------------
        # Native Windows Service Control Manager
        # ----------------------------------------------------

        $apacheOutput =
            & sc.exe config `
                $ApacheService `
                start= $startupMode `
                2>&1

        $apacheExitCode =
            $LASTEXITCODE

        if ($apacheExitCode -ne 0) {

            throw (
                "Gagal mengubah startup Apache. " +
                (($apacheOutput | Out-String).Trim())
            )
        }

        $mariaDbOutput =
            & sc.exe config `
                $MariaDbService `
                start= $startupMode `
                2>&1

        $mariaDbExitCode =
            $LASTEXITCODE

        if ($mariaDbExitCode -ne 0) {

            throw (
                "Gagal mengubah startup MariaDB. " +
                (($mariaDbOutput | Out-String).Trim())
            )
        }

        Write-Log `
            "AUTO RUN berhasil diubah menjadi $startupLabel" `
            'SUCCESS'

        Refresh-UI
    }
    catch {

        Write-Log `
            "AUTO RUN gagal: $($_.Exception.Message)" `
            'ERROR'

        [System.Windows.Forms.MessageBox]::Show(
            $_.Exception.Message,
            'AUTO RUN',
            'OK',
            'Error'
        ) | Out-Null

        Refresh-UI
    }
})

# ============================================================
# OPEN PHPMYADMIN
# ============================================================

$openPhpmyadmin.Add_Click({

    try {

        Open-Url `
            $PhpMyAdminUrl
    }
    catch {

        [System.Windows.Forms.MessageBox]::Show(
            $_.Exception.Message,
            'phpMyAdmin',
            'OK',
            'Error'
        ) | Out-Null
    }
})

# ============================================================
# OPEN LOCAL SITE
# ============================================================

$openSite.Add_Click({

    try {

        Open-Url `
            $ApacheUrl
    }
    catch {

        [System.Windows.Forms.MessageBox]::Show(
            $_.Exception.Message,
            'Local Site',
            'OK',
            'Error'
        ) | Out-Null
    }
})

# ============================================================
# CLEAR LOG
# ============================================================

$clearLog.Add_Click({

    try {

        $result =
            [System.Windows.Forms.MessageBox]::Show(
                'Hapus seluruh isi log Control Center?',
                'CLEAR LOG',
                'YesNo',
                'Question'
            )

        if ($result -ne 'Yes') {
            return
        }

        if (Test-Path -LiteralPath $LogFile) {

            Clear-Content `
                -LiteralPath $LogFile
        }

        $script:logBox.Clear()

        Write-Log `
            'Log dibersihkan oleh user' `
            'INFO'
    }
    catch {

        [System.Windows.Forms.MessageBox]::Show(
            $_.Exception.Message,
            'CLEAR LOG',
            'OK',
            'Error'
        ) | Out-Null
    }
})

# ============================================================
# OPEN LOG
# ============================================================

$openLog.Add_Click({

    try {

        if (-not (Test-Path -LiteralPath $LogFile)) {

            New-Item `
                -ItemType File `
                -Path $LogFile `
                -Force | Out-Null
        }

        Write-Log `
            'Membuka file log' `
            'INFO'

        Start-Process `
            -FilePath 'notepad.exe' `
            -ArgumentList "`"$LogFile`""
    }
    catch {

        [System.Windows.Forms.MessageBox]::Show(
            $_.Exception.Message,
            'OPEN LOG',
            'OK',
            'Error'
        ) | Out-Null
    }
})

# ============================================================
# CLOSE
# ============================================================

$closeBtn.Add_Click({

    Write-Log `
        'Control Center ditutup oleh user' `
        'INFO'

    $form.Close()
})

# ============================================================
# TIMER
# ============================================================

$timer =
    New-Object System.Windows.Forms.Timer

$timer.Interval =
    $RefreshInterval

$timer.Add_Tick({

    Refresh-UI
})

# ============================================================
# FORM SHOWN
# ============================================================

$form.Add_Shown({

    try {

        # Load log lama.
        Load-Log

        Write-Log `
            '========================================' `
            'INFO'

        Write-Log `
            'OnoKasir Local Control Center started' `
            'SUCCESS'

        Write-Log `
            "Root: $Root" `
            'INFO'

        Write-Log `
            "Apache Service: $ApacheService" `
            'INFO'

        Write-Log `
            "MariaDB Service: $MariaDbService" `
            'INFO'

        Write-Log `
            "Apache State: $(Get-ServiceState $ApacheService)" `
            'INFO'

        Write-Log `
            "MariaDB State: $(Get-ServiceState $MariaDbService)" `
            'INFO'

        Write-Log `
            "Apache Startup: $(Get-ServiceStartupType $ApacheService)" `
            'INFO'

        Write-Log `
            "MariaDB Startup: $(Get-ServiceStartupType $MariaDbService)" `
            'INFO'

        Write-Log `
            "Local Host: $ApacheUrl" `
            'INFO'

        Refresh-UI

        Write-Log `
            'Control Center siap digunakan' `
            'SUCCESS'

        $timer.Start()
    }
    catch {

        Write-Log `
            "Startup Control Center gagal: $($_.Exception.Message)" `
            'ERROR'
    }
})

# ============================================================
# FORM CLOSING
# ============================================================

$form.Add_FormClosing({

    try {
        $timer.Stop()
    }
    catch {
    }
})

# ============================================================
# SHOW
# ============================================================

[void]$form.ShowDialog()