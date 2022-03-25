$explorerprocesses = @(Get-WmiObject -Query "Select * FROM Win32_Process WHERE Name='explorer.exe'" -ErrorAction SilentlyContinue)
If ($explorerprocesses.Count -eq 0)
{
    "No explorer process found / Nobody interactively logged on"
}
Else
{
    ForEach ($i in $explorerprocesses)
    {
        $Username = $i.GetOwner().User
        $Domain = $i.GetOwner().Domain        
    }
    $usernames = ("{0}\{1}" -f $Domain, $Username) | Sort-Object -Unique
}
$usernames