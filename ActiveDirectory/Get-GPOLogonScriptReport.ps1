<#
    .SYSNOPSIS
        Generates a report showing all logon scripts being used in a GPO.

    .DESCRIPTION
        Generates a report showing all logon scripts being used in a GPO. Scans all of the GPOs in a domain.

    .NOTES
        Name: Get-GPOLogonScriptReport
        Author: Boe Prox
        Created: 05 Oct 2013

    .EXAMPLE
        .\Get-GPOLogonScriptReport.ps1 | Export-Csv -NoTypeInformation -Path 'GPOLogonScripts.csv'

        Description
        -----------
        Generates a report of all GPOs using logon scripts and then exports the data to a CSV file.
#>
Try {
    Import-Module GroupPolicy -ErrorAction Stop
    $gpos = @(Get-GPO -Guid 'A0FBCBE8-340B-4457-B0FC-F3F535A79E2B' -Domain fr.adecco.net -Server 'DCINTNL000545.fr.adecco.net')
    $count = $gpos.count
    $i=0
    ForEach ($gpo in $gpos) {
        Start-Sleep -Seconds 5
        $i++
        Write-Progress -Activity 'GPO Scan' -Status ("GPO: {0}" -f $gpo.DisplayName) -PercentComplete (($i/$count)*100)
        $xml = [xml]($gpo | Get-GPOReport -ReportType XML)
        $xml.save("C:\Temp\xml-{0}.xml" -f $gpo.DisplayName)

        #User logon script
        $Names = @($xml.GPO.User.ExtensionData.Name)
        $Names = @($xml.GPO.Computer.ExtensionData.Name)
        $Links = @($xml.GPO.LinksTo.SOMPath)
        New-Object PSObject -Property @{
            GPOName = $gpo.DisplayName
            ID = $gpo.ID
            GPOState = $gpo.GpoStatus
            GPOType = 'User'
            Type = $_.Type
            Script = $_.command
            ScriptType = $_.command -replace '.*\.(.*)','$1'
            
        }


        #     }
        # }
        # #Computer logon script
        # $computerScripts = @($xml.GPO.Computer.ExtensionData | Where {$_.Name -eq 'Scripts'})
        # If ($computerScripts.count -gt 0) {
        #     $computerScripts.extension.Script | ForEach {
        #         New-Object PSObject -Property @{
        #             GPOName = $gpo.DisplayName
        #             ID = $gpo.ID
        #             GPOState = $gpo.GpoStatus
        #             GPOType = 'Computer'
        #             Type = $_.Type
        #             Script = $_.command
        #             ScriptType = $_.command -replace '.*\.(.*)','$1'
        #         }
        #     }
        # }
    }
} Catch {
    Write-Warning ("{0}" -f $_.exception.message)
}

