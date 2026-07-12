<#
.SYNOPSIS
Build a reproducible PQC Readiness Toolkit release zip from the repo root.
Requires PowerShell 5.1+.
#>
[CmdletBinding()]
param(
    [string]$OutDir = '.\\dist',
    [string]$Version = '1.0.0'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$RepoRoot = (Resolve-Path .).Path
$OutDir   = Join-Path $RepoRoot $OutDir
$OutZip   = Join-Path $OutDir ('pqc_readiness_release_package_v{0}.zip' -f $Version)
$Staging  = Join-Path $Env:TEMP ('pqc_release_stage_{0}' -f [guid]::NewGuid().ToString('N'))

function Write-HashFile([string]$Path, [hashtable]$Hashes) {
    $sb = [System.Text.StringBuilder]::new()
    foreach ($kv in ($Hashes.GetEnumerator() | Sort-Object Name)) {
        [void]$sb.AppendLine(('{0}  {1}' -f $kv.Value, $kv.Name))
    }
    $text = $sb.ToString()
    if ($text.Length -gt 0) { $text = $text.Substring(0, $text.Length - [Environment]::NewLine.Length) }
    Set-Content -Path $Path -Value $text -Encoding UTF8
}

$skipPrefixes = @($Staging.ToLowerInvariant(), $OutDir.ToLowerInvariant())
$includeDirs = @('scripts','docs','.github','templates','evidence','dist')
$includeRootFiles = @('README.md','README-offer.md','ADOPTERS.md','CLAUDE.md','LICENSE','PAYMENT_INSTRUCTIONS.md','sku-bundle.md','social_proof_refs.md','SECURITY.md')
$excludePrefixes = @('.git')

New-Item -ItemType Directory -Path $OutDir -Force | Out-Null
New-Item -ItemType Directory -Path $Staging -Force | Out-Null

# Remove stale release artifacts so they aren't nested in the new package
Get-ChildItem -LiteralPath $OutDir -Filter 'pqc_readiness_release_package_*.zip' -File -ErrorAction SilentlyContinue | Remove-Item -Force

foreach ($f in $includeRootFiles) {
    $src = Join-Path $RepoRoot $f
    if (Test-Path -LiteralPath $src) {
        Copy-Item -LiteralPath $src -Destination (Join-Path $Staging $f) -Force
    }
}
foreach ($d in $includeDirs) {
    $srcDir = Join-Path $RepoRoot $d
    if (-not (Test-Path -LiteralPath $srcDir)) { continue }
    $destDir = Join-Path $Staging $d
    New-Item -ItemType Directory -Path $destDir -Force | Out-Null
    $files = Get-ChildItem -LiteralPath $srcDir -Recurse -File
    if (-not $files) { continue }
    foreach ($f in $files) {
        $rel = $f.FullName.Substring($RepoRoot.Length + 1)
        $target = Join-Path $Staging $rel
        $targetDir = Split-Path -Parent $target
        if (-not (Test-Path -Path $targetDir)) {
            New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
        }
        Copy-Item -LiteralPath $f.FullName -Destination $target -Force
    }
}

$norms = @{}
# Normalize any leading dot-segment artifacts in staged paths
Get-ChildItem -LiteralPath $Staging -Recurse -File | ForEach-Object {
    $rel = $_.FullName.Substring($Staging.Length + 1)
    $clean = $rel -replace '^[.\\]+[\\/]',''
    if ($clean -ne $rel) {
        $norms[$rel] = $clean
    }
}
foreach ($kv in $norms.GetEnumerator() | Sort-Object Name) {
    $old = Join-Path $Staging $kv.Key
    $new = Join-Path $Staging $kv.Value
    if (-not $new.Contains([IO.Path]::DirectorySeparatorChar)) { continue }
    $parent = Split-Path -Parent $new
    if (-not (Test-Path -Path $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }
    Move-Item -LiteralPath $old -Destination $new -Force
}

$hashes = @{}
Get-ChildItem -Path $Staging -Recurse -File | ForEach-Object {
    $rel = $_.FullName.Substring($Staging.Length + 1)
    $h = (Get-FileHash -Path $_.FullName -Algorithm SHA256).Hash
    $hashes[$rel] = $h
}
Write-HashFile -Path (Join-Path $Staging 'CHECKSUM_SHA256.txt') -Hashes $hashes

if (Test-Path -Path $OutZip) { Remove-Item -Path $OutZip -Force }
Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::CreateFromDirectory($Staging, $OutZip, [System.IO.Compression.CompressionLevel]::Optimal, $false)

$inner = (Get-ChildItem -Path $OutZip | Measure-Object).Count
$outer = (Get-FileHash -Path $OutZip -Algorithm SHA256).Hash
Write-Host ('Release built: {0}' -f $OutZip)
Write-Host ('Zip bytes: {0:N0}' -f (Get-Item $OutZip).Length)
Write-Host ('Inner files: {0}' -f $inner)
Write-Host ('Outer SHA256: {0}' -f $outer)

Remove-Item -Path $Staging -Recurse -Force
