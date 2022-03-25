$Install = Get-WindowsCapability -Online | Where-Object {$_.Name -like "Rsat*" -AND $_.State -eq "NotPresent"}
if ($Install) {
    foreach ($Item in $Install) {
        $RsatItem = $Item.Name
        Write-Verbose -Verbose "Adding $RsatItem to Windows"
        try {
            Add-WindowsCapability -Online -Name $RsatItem
            }
        catch [System.Exception]
            {
            Write-Verbose -Verbose "Failed to add $RsatItem to Windows"
            Write-Warning -Message $_.Exception.Message
            }
    }
}
