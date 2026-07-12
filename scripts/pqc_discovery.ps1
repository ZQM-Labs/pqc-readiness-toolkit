<#
.SYNOPSIS
PQC Readiness discovery for ZQM-Node-3
#>

$ErrorActionPreference = 'SilentlyContinue'
$evidenceDir = Join-Path $PSScriptRoot '..\evidence'
$null = New-Item -Path $evidenceDir -ItemType Directory -Force

function Write-Evidence {
    param([string]$Path, [string]$Content)
    Set-Content -LiteralPath $Path -Value $Content -Encoding UTF8
    Write-Host "  wrote $(Split-Path $Path)"
}

$cng = Get-Certificate -CertStoreLocation Cert:\LocalMachine\My | Where-Object { $_.PublicKey.Key.KeySize -gt 0 }
$cngRows = foreach ($c in $cng) {
    [pscustomobject]@{
        Store = 'LocalMachine\My'
        Thumbprint = $c.Thumbprint
        Subject = $c.Subject
        Algorithm = $c.PublicKey.Key.Algorithm
        KeySize = $c.PublicKey.Key.KeySize
        FriendlyName = $c.FriendlyName
    }
}
Write-Evidence (Join-Path $evidenceDir 'pqc_cng_keys.json') ($cngRows | ConvertTo-Json -Depth 5)

$tlsRows = [ordered]@{ TLS_12_Server = 'Unknown'; TLS_13_Server = 'Unknown'; CipherSuites = @() }
if (Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Server' -ErrorAction SilentlyContinue) { $tlsRows.TLS_12_Server = 'Enabled' }
if (Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.3\Server' -ErrorAction SilentlyContinue) { $tlsRows.TLS_13_Server = 'Enabled' }
$cipherPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Ciphers'
if (Test-Path $cipherPath) { $tlsRows.CipherSuites = Get-ChildItem $cipherPath | Select-Object -ExpandProperty Name }
Write-Evidence (Join-Path $evidenceDir 'pqc_tls_schannel.json') ([pscustomobject]$tlsRows | ConvertTo-Json -Depth 5)

$bitlocker = Get-BitLockerVolume -ErrorAction SilentlyContinue
$blRows = foreach ($v in $bitlocker) {
    $kp = $v.KeyProtector | Select-Object KeyProtectorType,RecoveryPassword,Password,Name
    [pscustomobject]@{ Drive = $v.MountPoint; EncryptionMethod = $v.EncryptionMethod; KeyProtectors = $kp }
}
Write-Evidence (Join-Path $evidenceDir 'pqc_bitlocker.json') ($blRows | ConvertTo-Json -Depth 6)

$scEvent = if (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\smartCard' -ErrorAction SilentlyContinue) { 'Installed' } else { 'NotDetected' }
$signEku = '1.3.6.1.5.5.7.3.3'
$codeSign = $cng | Where-Object { $_.Extensions | Where-Object { $_.Oid.Value -eq $signEku } }
$csRows = foreach ($c in $codeSign) {
    [pscustomobject]@{ Thumbprint = $c.Thumbprint; NotAfter = $c.NotAfter; HasPrivateKey = $c.HasPrivateKey }
}
Write-Evidence (Join-Path $evidenceDir 'pqc_codesign_certs.json') ($csRows | ConvertTo-Json -Depth 5)

$rootCAs = Get-Certificate -CertStoreLocation Cert:\LocalMachine\Root
$intCAs = Get-Certificate -CertStoreLocation Cert:\LocalMachine\CA
Write-Evidence (Join-Path $evidenceDir 'pqc_ca_roots.json') ([pscustomobject]@{ RootCount = $rootCAs.Count; IntermediateCount = $intCAs.Count } | ConvertTo-Json)

$algos = $cng | Group-Object { $_.PublicKey.Key.Algorithm } | Sort-Object Count -Descending
$algoRows = foreach ($a in $algos) { [pscustomobject]@{ Algorithm = $a.Name; Count = $a.Count } }
Write-Evidence (Join-Path $evidenceDir 'pqc_algorithm_counts.json') ($algoRows | ConvertTo-Json -Depth 5)

$legacy = certutil -store My
Write-Evidence (Join-Path $evidenceDir 'pqc_legacy_certutil.txt') $legacy

Write-Host "`nDiscovery complete. Evidence files written to"
Write-Output $evidenceDir
