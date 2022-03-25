
$computername = 'LTFRA7011383'
$RegPath = 'HKLM:\SOFTWARE\Wow6432Node\McAfee\DesktopProtection\Tasks' 

$McAfeeRegistry = Get-ChildItem -Path $RegPath 
foreach ($Entry in $McAfeeRegistry){
    $Guid = Split-Path -Path $Entry.Name -Leaf
    $FullPath = Join-Path -Path $RegPath -ChildPath $Guid
    $Properties = Get-ItemProperty -Path $FullPath 
    if ($Properties.szTaskName -eq 'IDS_ODS_TASKNAME_FULL_SCAN'){
        $ScanGuid = $guid
    }
}
$ScanToolPath = Join-Path -Path ${env:ProgramFiles(x86)} -ChildPath '\McAfee\VirusScan Enterprise\scan32.exe'

Try {
    Start-Process -FilePath $ScanToolPath -ArgumentList ('/Task {0}' -f $ScanGuid) -Wait -PassThru
}
Catch {
    Write-Debug $error[0]
}

