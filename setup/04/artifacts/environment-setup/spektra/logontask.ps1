Start-Transcript -Path C:\WindowsAzure\Logs\logontasklogs.txt -Append

#Install power Bi desktop
Start-Process -FilePath "C:\LabFiles\PBIDesktop_x64.exe" -ArgumentList '-quiet','ACCEPT_EULA=1'

Cd 'C:\LabFiles\ata-engineering-ilt-deployment\setup\04\artifacts\environment-setup\automation'

.\01-environment-setup.ps1

Unregister-ScheduledTask -TaskName "Setup" -Confirm:$false
Stop-Transcript
