Set-ExecutionPolicy -ExecutionPolicy bypass -Force
Start-Transcript -Path C:\WindowsAzure\Logs\logontasklogs.txt -Append

#Install power Bi desktop
Start-Process -FilePath "C:\LabFiles\PBIDesktop_x64.exe" -ArgumentList '-quiet','ACCEPT_EULA=1'

Cd 'C:\LabFiles\data-engineering-ilt-deployment\setup\04\artifacts\environment-setup\automation'

.\01-environment-setup.ps1

sleep 5

.\02-environment-validate.ps1

Unregister-ScheduledTask -TaskName "Setup" -Confirm:$false

cd C:\
Remove-Item 'C:\LabFiles\data-engineering-ilt-deployment' -Recurse -force

Stop-Transcript
