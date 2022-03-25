$date = Get-Date -Format yyyyMMddhhmmss
$file = "C:\GPOreport\gpos_$date.csv"
 Add-Content $file "GPOName,GPO ID,Owner,Scope GPO,WMI Filter,CreatedTime,ModifiedTime,CompVerDir,CompVerSys,UserVerDir,UserVerSys,CompEnabled,UserEnabled,SecurityFilter,GPO Enabled,Enforced"
$OU = “OU=FR,OU=ADECCO,OU=BUs,DC=emea,DC=adecco,DC=net”
$LinkedGPOs = Get-ADOrganizationalUnit -filter * -searchbase $ou -searchscope subtree | Select-object -ExpandProperty LinkedGroupPolicyObjects
$GPOList = $LinkedGPOs | ForEach-object{$_.Substring(4,36)}
# $GPOList = (Get-Content -path "C:\GPOreport\gpo_list.txt")
$colGPOLinks = @()
$LinksPaths = @()
foreach ($GUID in $GPOList){
 
      $LinksPaths = "" 
      $LinksPath = ""
 
    [xml]$gpocontent =  Get-GPOReport -Guid $guid -ReportType xml
 
       $LinksPaths = $gpocontent.GPO.LinksTo # | %{$_.SOMPath}
    
    $Wmi = Get-GPO -guid $GUID | Select-Object WmiFilter

    $Owner = Get-GPO -guid $GUID | Select-Object Owner
    $GPOName = $gpocontent.GPO.name
    $CreatedTime = $gpocontent.GPO.CreatedTime
    $ModifiedTime = $gpocontent.GPO.ModifiedTime
    $CompVerDir = $gpocontent.GPO.Computer.VersionDirectory
    $CompVerSys = $gpocontent.GPO.Computer.VersionSysvol
    $CompEnabled = $gpocontent.GPO.Computer.Enabled
    $UserVerDir = $gpocontent.GPO.User.VersionDirectory
    $UserVerSys = $gpocontent.GPO.User.VersionSysvol
    $UserEnabled = $gpocontent.GPO.User.Enabled
    $SecurityFilter = ((Get-GPPermissions -Guid $GUID -All | ?{$_.Permission -eq "GpoApply"}).Trustee | ?{$_.SidType -ne "Unknown"}).name -Join ','
   if($LinksPaths -ne $null)
   {
        foreach ($LinksPath in $LinksPaths)
        {
            Add-Content $file "$GPOName,$GUID,$Owner,$($LinksPath.SOMPath),$(($wmi.WmiFilter).Name),$CreatedTime,$ModifiedTime,$CompVerDir,$CompVerSys,$UserVerDir,$UserVerSys,$CompEnabled,$UserEnabled,""$($SecurityFilter)"",$($LinksPath.Enabled),$($LinksPath.NoOverride)"
        }
    
    }
    else
    {#Write-Host "Empty Links"  
            Add-Content $file "$GPOName,$GUID,$Owner,$($LinksPath.SOMPath),$(($wmi.WmiFilter).Name),$CreatedTime,$ModifiedTime,$CompVerDir,$CompVerSys,$UserVerDir,$UserVerSys,$CompEnabled,$UserEnabled,""$($SecurityFilter)"",$($LinksPath.Enabled),$($LinksPath.NoOverride)"
    } 
}
$gpocontent.GPO.LinksTo # | %{$_.SOMPath} mes sort toutes les OU sur lesquelles sont liées les GPO