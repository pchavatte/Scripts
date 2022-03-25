[float]$bios_version = (Get-CimInstance -Query "Select * from Win32_BIOS").SMBIOSBIOSVersion
if ($bios_version -ge 1.11.1 ){
    Write-Host 'compliant'
}