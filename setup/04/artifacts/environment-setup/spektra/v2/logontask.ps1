Set-ExecutionPolicy -ExecutionPolicy bypass -Force
Start-Transcript -Path C:\WindowsAzure\Logs\logontasklogs.txt -Append

#Install power Bi desktop
Start-Process -FilePath "C:\LabFiles\PBIDesktop_x64.exe" -ArgumentList '-quiet','ACCEPT_EULA=1'

Cd 'C:\LabFiles\data-engineering-ilt-deployment\setup\04\artifacts\environment-setup\automation'

.\environment-setup-v2.ps1

sleep 5

.\02-environment-validate-v2.ps1

Unregister-ScheduledTask -TaskName "Setup" -Confirm:$false

cd C:\
Remove-Item 'C:\LabFiles\data-engineering-ilt-deployment' -Recurse -force
Remove-Item  'C:\Packages\Plugins\Microsoft.Compute.CustomScriptExtension' -Recurse -force

Remove-Item 'C:\LabFiles\logontask.ps1' -Recurse -force

Stop-Transcript
