<#
.SYNOPSIS
  <Overview of script>
.DESCRIPTION
  <Brief description of script>
.PARAMETER <Parameter_Name>
    <Brief description of parameter input required. Repeat this attribute if required>
.INPUTS
  <Inputs if any, otherwise state None>
.OUTPUTS
  <Outputs if any, otherwise state None - example: Log file stored in C:\Windows\Temp\<name>.log>
.NOTES
  Version:        1.0
  Author:         Pierre CHAVATTE
  Creation Date:  <Date>
  Purpose/Change: Initial script development
  
.EXAMPLE
  <Example goes here. Repeat this attribute for more than one example>
#>

#---------------------------------------------------------[Initialisations]--------------------------------------------------------

#Set Error Action to Silently Continue
#$ErrorActionPreference = "SilentlyContinue"

#Dot Source required Function Libraries
# . "C:\Scripts\Functions\Logging_Functions.ps1"

#----------------------------------------------------------[Declarations]----------------------------------------------------------

#Script Version
$ScriptVersion = "1.0"

#Log File Info
$LogPath = 'C:\Logs'

#Variables script
$CSVFile = Join-Path -Path $PSScriptRoot -ChildPath '\accounts.csv'       #Fichier avec les comptes a unlock
$CSVremoved = Join-Path -Path $PSScriptRoot -ChildPath '\removed.csv'     #Fichier avec les comptes supprimés de la liste accounts.csv (Removeafter)
$Boucle = 60                #Duree de la boucle #   Defaut 60 sec
$Removeafter = 15        #Apres X jours sans etre lock : suppression du deverouillage + alerte mail
#$WarningAfter = 15       #Apres X jours en étant lock : Alerte mail 
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
  $Content | Out-File -FilePath $Path -Append -Encoding UTF8
}

#-----------------------------------------------------------[Execution]------------------------------------------------------------
$LogName = ("Unlock-ADAccount_{0}.log" -f (Get-Date -Format 'yyyy-MM-dd'))
$LogFile = Join-Path -Path $LogPath  -ChildPath $LogName
Write-Log -Message '========DEBUT DU SCRIPT========='
#Importation CSV
$Launched = Get-Date -Format 'dd/MM/yyyy HH:mm'
$i=1
While ($true) {
  #NOM DU LOG
  $LogName = ("Unlock-ADAccount_{0}.log" -f (Get-Date -Format 'yyyy-MM-dd'))
  $LogFile = Join-Path -Path $LogPath  -ChildPath $LogName
  #ARCHIVELOG
  $oldlogs= Get-ChildItem -Path "$LogPath\*"  | Where-Object { ($_.Name -like 'Unlock-ADAccount*') -and ($_.Name -ne $LogName)}
  foreach ($log in $oldlogs){
    $log | Move-item -Destination "$LogPath\UnlockArchive\" -Force
  }
  Write-Log -Message ('------------------------BOUCLE : {0} - Lancement script : {1}' -f $i,$Launched)
  #Exportation CSV
  $CSVData = Import-Csv -Path $CSVFile -Delimiter ';'  
  $CSVexport = @()
  $CSVremoveData = @()
  Foreach ($account in $CSVData){
    $domain = ($account.account).Split('\')[0]
    $username = ($account.account).Split('\')[1]
    Write-Log -Message ('==USER : {0}' -f $account.account)
    try {
      Write-Log -Message 'Verification compte AD'
      $ADUser = Get-ADUser -Identity $username -Properties LockedOut -Server $domain -ErrorAction Stop
      if($ADUser.LockedOut){
        #Si compte verouille - deverouillage
        Write-Log -Message '-Compte verouille' -Type Warning
        Unlock-ADAccount -Identity $username -Server $domain
        $account.Last_locked = Get-Date -Format 'dd/MM/yyyy HH:mm'
        Write-Log -Message '-Compte deverouille avec succes' -Type Warning
      }
      else {
        Write-Log -Message '-Compte non verouille'
      }
    }
    catch {
      Write-Log -Message 'Erreur recuperation compte AD' -Type Error
      Write-Log -Message ('Erreur message : {0}' -f $error[0]) -Type Error
    }      
    if ($account.First_checked){
      $First_checked = $account.First_checked
    }
    else{
      $First_checked = Get-Date -Format 'dd/MM/yyyy HH:mm'
    }
    $Last_checked = Get-Date -Format 'dd/MM/yyyy HH:mm'
    #Verification si compte est deverouille depuis plus que le delai RemoveAfter
    $remove = 0    
    if ($account.Last_locked){
      $Last_checked_date = [datetime]::parseexact($Last_checked, 'dd/MM/yyyy HH:mm', $null)
      $Last_locked_date = [datetime]::parseexact(($account.Last_locked), 'dd/MM/yyyy HH:mm', $null)
        $DaysUnlocked = ($Last_checked_date - $Last_locked_date).Days        
        if ($DaysUnlocked -ge $Removeafter){
          Write-log -Message ('compte deverouille depuis plus de {0} jours' -f $Removeafter) -Type Warning
          $remove = 1
        }
    }
    else {
      $First_checked_date = [datetime]::parseexact($First_checked, 'dd/MM/yyyy HH:mm', $null)
      $Last_locked_date = [datetime]::parseexact(($account.Last_locked), 'dd/MM/yyyy HH:mm', $null)
      $Dayschecked = ($Last_checked_date - $First_checked_date).Days
      if ($Dayschecked -ge $Removeafter){
        Write-log -Message ('compte verifie depuis plus de {0} jours sans verouillage' -f $Removeafter) -Type Warning
        $remove = 1
      }
    }
    #SI DEVEROULLE DEPUIS PLUIS DE X jours : Export dans fichier removed et envoi mail
    if ($remove -eq 1){
       Write-Log -Message 'Supppression du deverouillage'
      $CSVremoveData += [PSCustomObject]@{
        account = $account.account
        Last_locked = $account.Last_locked 
        First_checked = $First_checked 
        Last_checked = $Last_checked
        }
        #Send mail Auto
    Write-Log -Message 'Envoi mail alerte de supppression'
		$Body = ("Bonjour,


    Le compte utilisateur {0} n'a pas été verouillé depuis plus de {1} jours, il a été supprimé du deverouillage automatique.
    En piece jointe la liste des comptes supprimés.

    Cordialement,
    
    Adecco Ingenierie" -f $account.account,$Removeafter)
		$parameters = @{
			From 						= 'adecco_ingenierie@fr.scc.com'
			To							= 'guilhen.dubourdieu@adeccogroup.com', 'camille.froulin@adeccogroup.com'
			Subject						= 'Rapport Verrouillage des comptes'
			Attachments					= @($CSVremoved)
			#BCC							= 
			Body						= $Body
			BodyAsHTML					= $False
			CC							= 'Adecco_Ingenierie@fr.scc.com'
			#DeliveryNotificationOption	= 'onSuccess'
			Encoding					= 'UTF8'
			Port						= '25'
			#Priority					= 'High'
			SmtpServer					= 'smtpmail.lce.adecco.net'
			#UseSSL						= $True
		}
		#Send-MailMessage @parameters
    $CSVremoveData | Export-Csv -Path $CSVremoved -Delimiter ';' -NoTypeInformation -Append 
    }
    #sinon enregistrement dans accounts.csv
    else {
      $CSVexport += [PSCustomObject]@{
        account = $account.account
        Last_locked = $account.Last_locked 
        First_checked = $First_checked 
        Last_checked = $Last_checked
        }#EndPSCustomObject
    }  
  }
  $CSVexport | Export-Csv -Path $CSVFile -Delimiter ';' -NoTypeInformation  
  #Pause entre boucles
  Write-Log -Message ('Attente boucle : {0} secondes' -f $Boucle)
  Start-Sleep -Seconds $Boucle
  $i++
}






Write-Log -Message '========FIN DU SCRIPT========='