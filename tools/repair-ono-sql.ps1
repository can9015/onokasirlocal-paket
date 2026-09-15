$ErrorActionPreference = "Stop"

$Source = "D:\OnokasirLocal\public_html\dbbacup\u495470286_ono.sql"
$Target = "D:\OnokasirLocal\public_html\dbbacup\u495470286_ono_local.sql"

if (-not (Test-Path -LiteralPath $Source)) {
    throw "File sumber tidak ditemukan: $Source"
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " ONOKASIR SQL LOCAL REPAIR" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "SOURCE : $Source"
Write-Host "TARGET : $Target"
Write-Host ""

# Baca seluruh file sebagai array baris.
$lines = Get-Content -LiteralPath $Source -Encoding UTF8

$collationReplacements = 0
$trailingCommaFixes = 0

# Ganti hanya collation MariaDB yang tidak tersedia
# pada MySQL lokal. File sumber TIDAK disentuh.
for ($i = 0; $i -lt $lines.Count; $i++) {

    if ($lines[$i] -match "utf8mb4_uca1400_ai_ci") {
        $lines[$i] = $lines[$i] -replace `
            "utf8mb4_uca1400_ai_ci", `
            "utf8mb4_0900_ai_ci"

        $collationReplacements++
    }
}

# Perbaiki trailing comma pada akhir INSERT statement.
#
# Contoh sumber:
#   (...),
#
#   -- --------------------------------------------------------
#   CREATE TABLE ...
#
# Menjadi:
#   (...);
#
# Kita hanya memperbaiki comma jika baris berikutnya yang
# tidak kosong memang merupakan awal statement/comment berikutnya.
for ($i = 0; $i -lt ($lines.Count - 1); $i++) {

    $current = $lines[$i]

    # Cari baris yang berakhir dengan "),"
    if ($current -match "^\s*\(.*\),\s*$") {

        $nextIndex = $i + 1

        while ($nextIndex -lt $lines.Count -and
               [string]::IsNullOrWhiteSpace($lines[$nextIndex])) {
            $nextIndex++
        }

        if ($nextIndex -lt $lines.Count) {

            $next = $lines[$nextIndex].TrimStart()

            $isStatementBoundary =
                $next.StartsWith("--") -or
                $next.StartsWith("CREATE ") -or
                $next.StartsWith("ALTER ") -or
                $next.StartsWith("DROP ") -or
                $next.StartsWith("INSERT ") -or
                $next.StartsWith("UPDATE ") -or
                $next.StartsWith("DELETE ") -or
                $next.StartsWith("SET ") -or
                $next.StartsWith("LOCK ") -or
                $next.StartsWith("UNLOCK ") -or
                $next.StartsWith("COMMIT") -or
                $next.StartsWith("/*!")

            if ($isStatementBoundary) {
                $lines[$i] = $current -replace ",\s*$", ";"
                $trailingCommaFixes++
            }
        }
    }
}

# Simpan sebagai file baru.
Set-Content `
    -LiteralPath $Target `
    -Value $lines `
    -Encoding UTF8

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host " REPAIR SELESAI" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Collation diperbaiki : $collationReplacements"
Write-Host "Trailing comma       : $trailingCommaFixes"
Write-Host ""
Write-Host "Original tetap aman:"
Write-Host "  $Source"
Write-Host ""
Write-Host "File lokal:"
Write-Host "  $Target"
Write-Host ""

# Tampilkan ukuran file.
$sourceInfo = Get-Item -LiteralPath $Source
$targetInfo = Get-Item -LiteralPath $Target

Write-Host ("Ukuran original : {0:N0} bytes" -f $sourceInfo.Length)
Write-Host ("Ukuran local    : {0:N0} bytes" -f $targetInfo.Length)
Write-Host ""

Write-Host "Verifikasi akhir..."

if ($sourceInfo.Length -eq 0) {
    throw "File sumber kosong."
}

if ($targetInfo.Length -eq 0) {
    throw "File hasil kosong."
}

Write-Host "OK - file hasil valid secara filesystem." -ForegroundColor Green