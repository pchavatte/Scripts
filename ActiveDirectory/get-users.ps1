import-module activedirectory
$UsersFR = Get-ADUser -Filter * -SearchBase 'OU=UTILISATEURS,OU=FR,DC=fr,DC=adecco,DC=net' -Server 'DCINTFR06091.fr.adecco.net'

$UsersFR.count
