import-module activedirectory
$BU18users = GEt-ADuser -SearchBase 'OU=Comptes Actif,OU=18,OU=UTILISATEURS,OU=FR,OU=BUs,DC=emea,DC=adecco,DC=net' -filter "Enabled -eq 'True'"
$BU91users = GEt-ADuser -SearchBase 'OU=Comptes Actif,OU=91,OU=UTILISATEURS,OU=FR,DC=fr,DC=adecco,DC=net' -filter "Enabled -eq 'True'" -Server 'DCINTFR06091.fr.adecco.net'

$BU18users | Export-csv -NoTypeInformation -Encoding UTF8   -Path 'C:\Temp\BU18-91users.csv'
$BU91users | Export-csv -Append -NoTypeInformation -Encoding UTF8   -Path 'C:\Temp\BU18-91users.csv'