
Import-Module "C:\_Work_Folder\Scripts\OneDriveLib.dll"

$results = @()

$tresults = New-Object PSObject

$textfile = 'status.log'

$ucontents = Get-ChildItem $env:USERPROFILE | Where-Object {(($_ -like "*OneDrive*") -or ($_ -like "*SharePoint*")) -and (-not ($_ -contains "Unsynced"))}