#requires -version 2  
#requires -RunAsAdministrator

<#
.SYNOPSIS
  Ce script sert à reactiver l'interdiction des PST sur le poste.
.DESCRIPTION
  Le script va recuperer le SID de l'utilisateur connecte pour ecrire dans sa ruche HKU.
  Il va changer la valeur de la cle : DisablePST dans HKEY_CURRENT_USER\Software\Policies\Microsoft\office\16.0\outlook pour la repasser à 2
  S'utiliser avec le script AllowPST pour desactiver l'interdiction des PST sur le poste.
.INPUTS
  none
.OUTPUTS
 Fichier LOG : C:\Logs\DisableST_version.log
.NOTES
  Version:        1.0
  Author:         Pierre CHAVATTE
  Creation Date:  17/09/2020
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

#Script Version
$ScriptVersion = "1.0"

#Log Info
$LogPath = "C:\Logs"
$LogName = "Disable_{0}.log" -f $ScriptVersion
$LogFile = Join-Path -Path $LogPath -ChildPath $LogName

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
#Montage du lecteur HKU
New-PSDrive HKU -PSProvider Registry -Root HKEY_USERS -ErrorAction SilentlyContinue  
#Recuperation de l'utilisateur connecte (owner du process explorer)
Try {
  $ExplorerProcess = Get-WmiObject -class win32_process   | Where-Object name -Match explorer
  if(!$ExplorerProcess) {
      $LoggedOnUser = "Utilisateur non trouve"
  }
  else{
      $LoggedOnUser = $ExplorerProcess.getowner().user
  }
  #Recuperation du SID à partir du username
  $objUser = New-Object System.Security.Principal.NTAccount($LoggedOnUser)
  $UserSID = $objUser.Translate([System.Security.Principal.SecurityIdentifier]).Value
  Write-Log -Message ('Utilisateur connecte : {0}' -f $LoggedOnUser)
  Write-Log -Message ('SID de l utilisateur connecte : {0}' -f $UserSID)
}
Catch {
  Write-Log -Message "Erreur de recuperation de l'utilisateur connecte" -Type Error
  Write-Log -Message ("Erreur : {0}" -f $error[0]) -Type Error
}
#Verification de la presence de DisablePST
if ($UserSID){
    $RegPath = 'HKU:\{0}\Software\Policies\Microsoft\office\16.0\outlook' -f $UserSID
    If ( Get-ItemProperty -Path $RegPath -Name DisablePST) {
    Try {
        Set-ItemProperty -Path $RegPath -Name DisablePST -Value 2 
        Write-Log -Message 'Desactivation PST reussie'
    }
    Catch {
        Write-Log -Message 'Desactivation PST en echec' -Type Error
        Write-Log -Message ("Erreur : {0}" -f $error[0]) -Type Error
    }
    }
    Else {
        Write-Log -Message "La cle n'est pas presente : creation de la cle" -Type Warning
    Try {
      New-ItemProperty -Path $RegPath -Name DisablePST -Value 0 -PropertyType DWORD
      Write-Log -Message 'Desactivation PST reussie'
    }
    Catch {
      Write-Log -Message 'Desactivation PST en echec' -Type Error
      Write-Log -Message ("Erreur : {0}" -f $error[0]) -Type Error
    }
  }
}
Write-Log -Message '========FIN DU SCRIPT========='



