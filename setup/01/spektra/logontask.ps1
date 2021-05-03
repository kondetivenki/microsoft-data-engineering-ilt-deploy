Start-Transcript -Path C:\WindowsAzure\Logs\logontasklogs.txt -Append

#Install power Bi desktop
Start-Process -FilePath "C:\LabFiles\PBIDesktop_x64.exe" -ArgumentList '-quiet','ACCEPT_EULA=1'

Cd 'C:\LabFiles\asa\setup\01\automation'

./environment-setup.ps1

sleep 5
./lab-01-setup.ps1

sleep 5
./lab-02-setup.ps1

sleep 5
./powerbi-setup.ps1

Unregister-ScheduledTask -TaskName "Setup" -Confirm:$false

cd C:\
Remove-Item 'C:\LabFiles\asa' -force
Remove-Item 'C:\LabFiles\logontask.ps1' -force

Stop-Transcript
