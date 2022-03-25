#Script pour supprimer des comptes utilisateurs d'un 
function Write-log {
    [CmdletBinding()]
    Param(
          [parameter(Mandatory=$false)]
          [String]$Path = 'C:\Logs\MoveUsersFromGroupsToGroup.log' ,

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

Write-Log -Message '========DEBUT DU SCRIPT========='
import-module activedirectory

$CSVFile = "C:\Users\pierre.chavatte\Downloads\FR-GU-ADE-Outlook-Full-Cache_W2.csv"
$CSVData = Import-CSV -Path $CSVFile -Encoding UTF8

$GroupsToRemove = 'FR-GU-ADE-Outlook-90j-W10','FR-GU-ADE-NEW-Outlook-1years-W10', 'FR-GU-ADE-NEW-Outlook-1years-W10-UAT', 'FR-GU-ADE-Outlook-15jours', 'FR-GU-ADE-Outlook-45jours'
$GroupToAdd = 'FR-GU-ADE-Outlook-Full-Cache'
#--recup du groupe AD a ajouter
Write-Log -Message ("----------Récupération du groupe à ajouter: {0}" -f $GroupToAdd)
$GroupToAdd = Get-ADGroup -Identity $GroupToAdd  -Server 'DCINTNL000532.emea.adecco.net'   
$ADGroupsToRemove = @()
if (!$ADGroupsToRemove) {
    Foreach ($GroupToRemove in $GroupsToRemove){            
            Write-Log -Message ("----------Récupération du groupe à supprimer : {0}" -f $GroupToRemove)
            $ADGroupsToRemove += Get-ADGroup -Identity $GroupToRemove     
        }        
}
$UserArray = @()
#Recuperations des comptes AD users
Foreach ($line in $CSVData){
    if ($user) {Remove-Variable -Name user}
    $user = Get-ADUser -Filter ("UserPrincipalName -eq '{0}'" -f $line.UPN) -Server 'DCINTNL000532.emea.adecco.net'    
    Write-Log -Message ("===================== Utilisateur : {0}" -f $line.UPN)
    if (!$user){
        Write-Log -Message ("Utilisateur introuvable sur EMEA : {0}" -f $line.UPN)
        $user = Get-ADUser -Filter ("UserPrincipalName -eq '{0}'" -f $line.UPN) -Server 'DCINTFR06091.fr.adecco.net'
        Write-Log -Message ("Récupération de l'utilisateur sur domaine FR : {0}" -f $user.Name)
    }
    else {
        Write-Log -Message ("Récupération de l'utilisateur sur domaine EMEA : {0}" -f $user.Name)
    }
    #Creation tableau avec tous les objets user
    $UserArray += $user
}
#----------AJOUT users dans le groupe
Try {
    Write-Log -Message ("Ajout des utilisateur dans le groupe : {0}" -f $GroupToAdd.Name)
    $GroupToAdd | Add-ADGroupMember -Members $UserArray -Confirm:$false
}
catch {
    Write-Log -Message ("Impossible d'ajouter les utilisateurs dans le groupe : {0}" -f $GroupToAdd.Name) -Type Error
    Write-Log -Message ("Erreur : {0}" -f $error[0]) -Type Error
}
#----------SUPRESSION dans les groupes
Foreach ($ADGroup in $ADGroupsToRemove) {
    Try {    
        $ADGroup | Remove-ADGroupMember -Members $UserArray -Confirm:$false
        Write-Log -Message ("Suppression des utilisateurs du groupe : {0}" -f $ADGroup.Name)
    }
    catch {
        Write-Log -Message ("Impossible de supprimer les utilisateurs du groupe : {0}" -f $GroupToAdd.Name) -Type Error
        Write-Log -Message ("Erreur : {0}" -f $error[0]) -Type Error
    }
}
Write-Log -Message '========FIN DU SCRIPT========='