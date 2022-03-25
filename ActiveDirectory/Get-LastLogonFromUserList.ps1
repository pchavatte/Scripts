#requires -version 2  
#Requires -RunAsAdministrator
<#
.SYNOPSIS
  Ce script sert à récupérer les LastLogon Timestamp d'une liste d'utilisateurs
.DESCRIPTION
  Le script va sortir un fichier csv avec le LastLogon Timestamp de chaque utilisateur de la liste 
.INPUTS
  fichier rapport.csv délimiteur ; avec entete nommée ComputerName, emplacement par défaut "C:\temp\Userlist.csv"
.OUTPUTS
 Fichier LOG Script : Get-LastLogonFromUserList_1.0.log
 Fchier CSV LastLogon.csv
.NOTES
  Version:        1.0
  Author:         Pierre CHAVATTE
  Creation Date:  10/11/2020
  Purpose/Change: Initial script development
  
.EXAMPLE
  N/A
#>

#---------------------------------------------------------[Initialisations]--------------------------------------------------------

#Set Error Action to Silently Continue
#$ErrorActionPreference = "SilentlyContinue"

#Dot Source required Function Libraries
# . "C:\Scripts\Functions\Logging_Functions.ps1"

#----------------------------------------------------------[Declarations]----------------------------------------------------------
#Work folder and files
$CSVFilePath = "C:\temp\Userlist.csv"
#Script Version
$ScriptVersion = "1.0"
#Log Info
$LogName = "Get-LastLogonFromUserList_{0}.log" -f $ScriptVersion
$LogFile = Join-Path -Path 'C:\Logs' -ChildPath $LogName
$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
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
Write-Log -Message '========DEBUT DU SCRIPT========='
$results = @()
$CSVFile = Import-csv  -Path $CSVFilePath -Delimiter ';'
foreach ($username in $CSVFile) {
    #Recupération user AD et ses propriétés
    $User = $username.UserName.Split('\')
    if ($User[0]  -eq 'FR'){
        $Server = 'DCINTFR06091.fr.adecco.net'
    }
    elseif ($User[0]  -eq 'EMEA') {
        $Server = 'DCINTNL000532.emea.adecco.net'
    }
    $ADuser = Get-ADUser $User[1] -Server $Server -Properties LastLogonTimestamp, LastLogon
    #conversion timestamps
    $LastLogonTimestamp = [datetime]::FromFileTime($ADuser.LastLogonTimestamp)
    $LastLogon = [datetime]::FromFileTime($ADuser.LastLogon)
    #Comparaison des 2 dates
    if ($LastLogonTimestamp -gt $LastLogon){
        $LastLogon  = $LastLogonTimestamp
    }
    $details = @{            
        UserName = $User[1]             
        Lastlogon = $LastLogon               
    }
    $results += New-Object PSObject -Property $details     
}                  
$results | Export-CSV -Path (Join-Path -Path $scriptPath -ChildPath 'LastLogon.csv') -Delimiter ';' -Encoding 'UTF8' -NoTypeInformation
