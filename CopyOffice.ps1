foreach ($computer in (Get-Content "E:\Applis\Sources\Office 16.0.12527.21330\listePC.txt")) { 
    if (Test-Connection $computer) {
        robocopy "\\ntfrd1100001\e$\Applis\Sources\Office 16.0.12527.21330" "\\$computer\c$\temp\Office 16.0.12527.21330" /E /w:1 /r:1 /log+:c:\temp\copyoffice2.log
    }
 }