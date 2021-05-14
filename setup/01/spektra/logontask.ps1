Start-Transcript -Path C:\WindowsAzure\Logs\logontasklogs.txt -Append

#Install power Bi desktop
Start-Process -FilePath "C:\LabFiles\PBIDesktop_x64.exe" -ArgumentList '-quiet','ACCEPT_EULA=1'

C:\dotnet.exe /silent /install

<#Write-Information "Checking if Dotnet is installed or not"
$filetocheck= "C:\dotnet.exe"

if(!(Test-Path $filetocheck -PathType leaf))
{
 Write-Information "Powerbi is not installed, Installing it" 
 C:\dotnet.exe /silent /install
} #>

sleep 2
Cd 'C:\LabFiles\asa\setup\01\automation'

./environment-setup.ps1

sleep 5
./lab-01-setup.ps1

<#sleep 5
./lab-02-setup.ps1 #>

sleep 5
./powerbi-setup.ps1

./environment-validate.ps1

cd C:\
Remove-Item 'C:\LabFiles\asa' -Recurse -force
Remove-Item  'C:\Packages\Plugins\Microsoft.Compute.CustomScriptExtension' -Recurse -force

Unregister-ScheduledTask -TaskName "Setup" -Confirm:$false

Remove-Item 'C:\LabFiles\logontask.ps1' -Recurse -force

Stop-Transcript
