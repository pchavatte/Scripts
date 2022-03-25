'Dim WshShell
Set WshShell = CreateObject("WScript.Shell") 
WshShell.Run chr(34) & "C:\Applications\BGI_2021\active\RunPowershell.bat" & Chr(34), 0
Set WshShell = Nothing