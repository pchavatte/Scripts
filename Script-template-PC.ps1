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
$LogPath = "C:\Logs"
$LogName = "<script_name>.log"
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
  $Content | Out-File -FilePath $Path -Append -Encoding UTF8
}

#-----------------------------------------------------------[Execution]------------------------------------------------------------
Write-Log -Message '========DEBUT DU SCRIPT========='