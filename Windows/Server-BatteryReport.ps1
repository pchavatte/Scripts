
#----------------------------------------------------------[Declarations]----------------------------------------------------------
$CSVPath = 'C:\Temp' 
$destination = '\\ntfrd1100001\BatteryReport$' 
$Processed = Join-Path -Path $destination -ChildPath 'Processed\'


$LogName = 'BatteryReport.log'
$LogFile = Join-Path -Path $destination -ChildPath $LogName

#-----------------------------------------------------------[Functions]------------------------------------------------------------

function Write-log {
    [CmdletBinding()]
    Param(
          [parameter(Mandatory=$false)]
          [String]$Path = $LogFile ,

          [parameter(Mandatory=$true)]
          [String]$Message,

          [parameter(Mandatory=$false)]
          [String]$Component = 'Main',

          [Parameter(Mandatory=$false)]
          [ValidateSet("Info", "Warning", "Error")]
          [String]$Type = 'Info'
    )

    switch ($Type) {
        "Info" { [int]$Type = 1 }
        "Warning" { [int]$Type = 2 }
        "Error" { [int]$Type = 3 }
    }

    # Create a log entry
    $Content = "<![LOG[$Message]LOG]!>" +`
        "<time=`"$(Get-Date -Format "HH:mm:ss.ffffff")`" " +`
        "date=`"$(Get-Date -Format "M-d-yyyy")`" " +`
        "component=`"$Component`" " +`
        "context=`"$([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)`" " +`
        "type=`"$Type`" " +`
        "thread=`"$([Threading.Thread]::CurrentThread.ManagedThreadId)`" " +`
        "file=`"`">"

    # Write the line to the log file
    Add-Content -Path $Path -Value $Content -Encoding UTF8
}

#-----------------------------------------------------------[Execution]------------------------------------------------------------
Write-Log -Message '========SCRIPT START========='
$xmlFiles = Get-ChildItem -Path $destination -Filter '*.xml'
$DATA = @()
foreach ($xmlFile  in $xmlFiles) {
    [xml]$content = Get-Content -Path $xmlFile.FullName

    $DesignC = $content.BatteryReport.RuntimeEstimates.DesignCapacity.Capacity
    $CurrentC = $content.BatteryReport.RuntimeEstimates.FullChargeCapacity.Capacity
    [TimeSpan]$DesignCRunTime =  [System.Xml.XmlConvert]::ToTimeSpan($content.BatteryReport.RuntimeEstimates.DesignCapacity.ActiveRuntime)
    [TimeSpan]$CurrentCRunTime =  [System.Xml.XmlConvert]::ToTimeSpan($content.BatteryReport.RuntimeEstimates.FullChargeCapacity.ActiveRuntime)

    $BatteryHealth = [math]::Round(($CurrentC/$DesignC * 100),2)
    #---Si 2 batteries
    if ($content.BatteryReport.Batteries.Battery.CycleCount[1]){
        $B1DesignC = $content.BatteryReport.Batteries.Battery.DesignCapacity[0]
        $B1CurrentC = $content.BatteryReport.Batteries.Battery.FullChargeCapacity[0]
        $B1Health = [math]::Round(($B1CurrentC/$B1DesignC * 100),2)
        $B1Cycles = $content.BatteryReport.Batteries.Battery.CycleCount[0]

        $B2DesignC = $content.BatteryReport.Batteries.Battery.DesignCapacity[1]
        $B2CurrentC = $content.BatteryReport.Batteries.Battery.FullChargeCapacity[1]
        $B2Health = [math]::Round(($B2CurrentC/$B2DesignC * 100),2)
        $B2Cycles = $content.BatteryReport.Batteries.Battery.CycleCount[1]
    }
    #Si 1 seule batterie
    else {
        $B1DesignC = $content.BatteryReport.Batteries.Battery.DesignCapacity
        $B1CurrentC = $content.BatteryReport.Batteries.Battery.FullChargeCapacity
        $B1Health = [math]::Round(($B1CurrentC/$B1DesignC * 100),2)
        $B1Cycles = $content.BatteryReport.Batteries.Battery.CycleCount

        $B2DesignC = 'N/A'
        $B2CurrentC = 'N/A'
        $B2Health = 'N/A'
        $B2Cycles = 'N/A'
    }
    

    [datetime]$ScanTime = $content.BatteryReport.ReportInformation.LocalScanTime 
    
    $HtmlReportF = Join-Path -Path $Processed -ChildPath ($xmlFile.Name -replace ('xml', 'html'))
        

    $line = New-Object PSObject
    $line | Add-Member -type NoteProperty -Name 'ComputerName' -Value $content.BatteryReport.SystemInformation.ComputerName
    $line | Add-Member -type NoteProperty -Name 'Manufacturer' -Value $content.BatteryReport.SystemInformation.SystemManufacturer
    $line | Add-Member -type NoteProperty -Name 'Model' -Value $content.BatteryReport.SystemInformation.SystemProductName
    $line | Add-Member -type NoteProperty -Name 'Serial Number' -Value $content.BatteryReport.SystemInformation.SerialNumber.InnerText
    $line | Add-Member -type NoteProperty -Name 'Design Capacity mWh' -Value $DesignC 
    $line | Add-Member -type NoteProperty -Name 'Current Capacity mWh' -Value $CurrentC
    $line | Add-Member -type NoteProperty -Name 'Design Run Time' -Value $DesignCRunTime
    $line | Add-Member -type NoteProperty -Name 'Current Run Time' -Value $CurrentCRunTime
    $line | Add-Member -type NoteProperty -Name 'BatteryHealth %' -Value $BatteryHealth
    $line | Add-Member -type NoteProperty -Name 'Battery 1 Design Capacity mWh' -Value $B1DesignC
    $line | Add-Member -type NoteProperty -Name 'Battery 1 Current Capacity mWh' -Value $B1CurrentC
    $line | Add-Member -type NoteProperty -Name 'Battery 1 Cycle Count' -Value $B1Cycles
    $line | Add-Member -type NoteProperty -Name 'Battery 1 Health %' -Value $B1Health
    $line | Add-Member -type NoteProperty -Name 'Battery 2 Design Capacity mWh' -Value $B2DesignC
    $line | Add-Member -type NoteProperty -Name 'Battery 2 Current Capacity mWh' -Value $B2CurrentC
    $line | Add-Member -type NoteProperty -Name 'Battery 2 Cycle Count' -Value $B2Cycles
    $line | Add-Member -type NoteProperty -Name 'Battery 2 Health %' -Value $B2Health
    $line | Add-Member -type NoteProperty -Name 'ReportDate' -Value $ScanTime 
    $line | Add-Member -type NoteProperty -Name 'ReportLink' -Value $HtmlReportF
    $DATA  += $line
    $Message = ('Ajout des informations du poste {0}' -f $content.BatteryReport.SystemInformation.ComputerName)
    Write-Log -Message $Message 
}


$DATA | Export-Csv -NoTypeInformation -Encoding UTF8 -Delimiter ';' -Path (Join-Path -Path $destination -ChildPath 'BatteryReport.csv')
 #COPIE XML dans le dossier PROCESSED
foreach ($xmlFile  in $xmlFiles) {
    $XMLReport = $xmlFile.FullName
    Try {
        $Message = ('{0} - Copie du fichier XML' -f $content.BatteryReport.SystemInformation.ComputerName)
        Write-Log -Message $Message
        Copy-Item -Path $XMLReport -Destination $Processed -Force    
    }
    Catch {
        $Message = ('ERROR : Echec copie XML')
        Write-Log -Message $Message -Type Error
        $Message = "Error message : {0}" -f $error[0]
        Write-Log -Message $Message -Type Error
    }
}
 #COPIE HTML dans le dossier PROCESSED
foreach ($xmlFile  in $xmlFiles) {
    $HtmlReport = $xmlFile.FullName -replace ('xml', 'html')
    Try {
        $Message = ('{0} - Copie du fichier HTML ' -f $content.BatteryReport.SystemInformation.ComputerName)
        Write-Log -Message $Message
        Copy-Item -Path $HtmlReport -Destination $Processed -Force    
    }
    Catch {
        $Message = ('ERROR : Echec copie HTML')
        Write-Log -Message $Message -Type Error
        $Message = "Error message : {0}" -f $error[0]
        Write-Log -Message $Message -Type Error
    }
}
#SUPPRESSION FICHIERS TRAITES
foreach ($xmlFile  in $xmlFiles) {
    $HtmlReport = $xmlFile.FullName -replace ('xml', 'html')
    Try {
        $Message = ('{0} - Suppression des fichiers traites' -f $content.BatteryReport.SystemInformation.ComputerName)
        Write-Log -Message $Message
        Remove-Item -Path $XMLReport -Force   
        Remove-Item -Path $HtmlReport  -Force   
    }
    Catch {
        $Message = ('ERROR : Suppression des fichiers traites')
        Write-Log -Message $Message -Type Error
        $Message = "Error message : {0}" -f $error[0]
        Write-Log -Message $Message -Type Error
    }
}
Write-Log -Message '========SCRIPT END========='