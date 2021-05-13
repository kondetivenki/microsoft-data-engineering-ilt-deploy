Start-Transcript -Path C:\WindowsAzure\Logs\logontasklogs.txt -Append

sleep 2
Cd 'C:\LabFiles\asa\setup\01\automation'

./environment-setup.ps1

sleep 5
./lab-01-setup.ps1

sleep 2
./environment-validate.ps1

cd C:\
Remove-Item 'C:\LabFiles\asa' -Recurse -force
Remove-Item  'C:\Packages\Plugins\Microsoft.Compute.CustomScriptExtension' -Recurse -force

Unregister-ScheduledTask -TaskName "Setup" -Confirm:$false

Remove-Item 'C:\LabFiles\logontask.ps1' -Recurse -force

Stop-Transcript
