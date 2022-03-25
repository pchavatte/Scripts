#Déclaration des variables


$name = Get-adcomputer -Filter * -SearchBase 'OU=Laptops,OU=Computers,OU=FR,OU=ADECCO,OU=BUs,DC=emea,DC=adecco,DC=net' -Properties  Name, Enabled, DistinguishedName, LastLogonTimestamp
$Logs = "DesactivePosteAD_$((Get-Date).ToString('dd-MM-yyyy')).csv"
$chemin = "C:\_SCC\Shares\ScriptLogs\LogsDisableAccount\$Logs"
$JourInactivite = 180
$Date = (Get-Date).Adddays(-($JourInactivite))

#Test si le fichier log existe + création de celui-ci

if((Test-Path $chemin) -eq $false)
{
    New-Item -ItemType File -Path "\\NTINTNL070076.emea.adecco.net\_scc$\LogsDisableAccount\$Logs" -Force
}


#Récupération des postes dans le fichier disable

foreach ($var in $name) {

try{
    #$variable=Get-ADComputer -Identity $var -Server 'emea.adecco.net' -Properties  Name, Enabled, DistinguishedName, LastLogonTimestamp
    $variable = $var | Select-Object Name, Enabled, DistinguishedName, LastLogonTimestamp -ErrorAction Stop
    $LastLogon = [datetime]::FromFileTime($variable.LastLogonTimestamp)

#Si le poste est actif et que sa dernière connexion est inférieure à 90 jours => Pas de désactivation
    if(($variable.Enabled -like $true) -and ($LastLogon -ge $Date)) { 


        #add-content -Path $chemin -Value ("{0},encore actif,dernière connexion le {1}" -f $variable.Name, $LastLogon) -Force

        }
        else
        {
        #add-Content -Path $chemin -Value "$($variable.name) - $($_.exception.message)" -force 
        }
            
#Si le poste est actif et que sa dernière connexion est supérieure à 90 jours => Désactivation
    if(($variable.Enabled -like $true) -and ($LastLogon -lt $Date)) { 
    

        Disable-ADAccount -identity $variable.DistinguishedName -Server 'emea.adecco.net'
        if ($? -like $true) {
            add-content -Path $chemin -Value ("{0},désactivé,non connecté depuis le {1}" -f $variable.Name, $LastLogon) -Force
        }
        else {
            Add-Content -Path $chemin -Value "$($variable.name) - $($_.exception.message)" -force 
        }



#Ecriture de log si le poste est déjà désactivé
} if($variable.Enabled -like $false) {
    #add-content -Path $chemin -Value  ("{0},déjà désactivé, dernière connexion le {1}" -f $variable.Name, $LastLogon) -Force
}


}catch{
    #Add-Content -path $chemin -Value "$($var) - $($_.exception.message)" -force
}


}

#ENVOI MAIL
$Body = ("Bonjour,

Veuillez trouver en pièce jointe, le rapport des postes désactivés suite à une d'inactivité depuis plus de {0} jours.

Cordialement,

SCC" -f $JourInactivite)

$Date = (Get-Date -UFormat %d-%m-%Y)
$parameters = @{
    From 						= 'Adecco_Ingenierie@fr.scc.com'
    To							= 'pierre-yves.lanier@adeccogroup.com', 'michel.lacambre@adeccogroup.com'
    Subject						= ('Désactivation des postes inactifs depuis plus de {0} jours ')
    Attachments					= @("\\NTINTNL070076.emea.adecco.net\_scc$\LogsDisableAccount\$Logs")
    #BCC							= 'aorgeret@fr.scc.com'
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
	Send-MailMessage @parameters