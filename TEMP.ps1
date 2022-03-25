#Get-CimInstance -Query "SELECT Name from Win32_NetworkAdapter Where NetConnectionID like '%wireless%' OR NetConnectionID like '%Wi-Fi%'"

$x86Key = 'HKLM:\SOFTWARE\WOW6432Node\Classes\CLSID\{F8E61EDD-EA25-484e-AC8A-7447F2AAE2A9}'
$x64Key = 'HKLM:\SOFTWARE\Classes\CLSID\{F8E61EDD-EA25-484e-AC8A-7447F2AAE2A9}'
If ((test-Path -Path $x86Key) -and (test-Path -Path $x64Key)){
    Write-Host 'not compliant'
}
else {
    Write-Host 'compliant'
}
 