Param (
  [Parameter(Mandatory = $true)]
  [string]
  $azureUsername,

  [string]
  $azurePassword,

  [string]
  $azureTenantID,

  [string]
  $azureSubscriptionID,

  [string]
  $odlId,
    
  [string]
  $deploymentId,
  
   [string]
  $InstallCloudLabsShadow
)

function InstallGit()
{
  Write-Host "Installing Git." -ForegroundColor Green -Verbose

  #download and install git...		
  $output = "$env:TEMP\git.exe";
  Invoke-WebRequest -Uri https://github.com/git-for-windows/git/releases/download/v2.27.0.windows.1/Git-2.27.0-64-bit.exe -OutFile $output; 

  $productPath = "$env:TEMP";
  $productExec = "git.exe"	
  $argList = "/SILENT"
  start-process "$productPath\$productExec" -ArgumentList $argList -wait

}

function InstallAzureCli()
{
  Write-Host "Installing Azure CLI." -ForegroundColor Green -Verbose

  #install azure cli
  Invoke-WebRequest -Uri https://aka.ms/installazurecliwindows -OutFile C:\AzureCLI.msi -usebasicparsing; 
  Start-Process msiexec.exe -Wait -ArgumentList '/I C:\AzureCLI.msi /quiet'; 
  rm C:\AzureCLI.msi
}

 #Install edge browser
 Function InstallEdgeChromium
    {
        #Download and Install edge
        $WebClient = New-Object System.Net.WebClient
        $WebClient.DownloadFile("http://dl.delivery.mp.microsoft.com/filestreamingservice/files/6d88cf6b-a578-468f-9ef9-2fea92f7e733/MicrosoftEdgeEnterpriseX64.msi","C:\Packages\MicrosoftEdgeBetaEnterpriseX64.msi")
        sleep 5
        
	    Start-Process msiexec.exe -Wait '/I C:\Packages\MicrosoftEdgeBetaEnterpriseX64.msi /qn' -Verbose 
        sleep 5
        $WshShell = New-Object -comObject WScript.Shell
        $Shortcut = $WshShell.CreateShortcut("C:\Users\Public\Desktop\Azure Portal.lnk")
        $Shortcut.TargetPath = """C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"""
        $argA = """https://portal.azure.com"""
        $Shortcut.Arguments = $argA 
        $Shortcut.Save()

    }

#Disable-InternetExplorerESC
function DisableInternetExplorerESC
{
  $AdminKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}"
  $UserKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}"
  Set-ItemProperty -Path $AdminKey -Name "IsInstalled" -Value 0 -Force -ErrorAction SilentlyContinue -Verbose
  Set-ItemProperty -Path $UserKey -Name "IsInstalled" -Value 0 -Force -ErrorAction SilentlyContinue -Verbose
  Write-Host "IE Enhanced Security Configuration (ESC) has been disabled." -ForegroundColor Green -Verbose
}

#Enable-InternetExplorer File Download
function EnableIEFileDownload
{
  $HKLM = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\3"
  $HKCU = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\3"
  Set-ItemProperty -Path $HKLM -Name "1803" -Value 0 -ErrorAction SilentlyContinue -Verbose
  Set-ItemProperty -Path $HKCU -Name "1803" -Value 0 -ErrorAction SilentlyContinue -Verbose
  Set-ItemProperty -Path $HKLM -Name "1604" -Value 0 -ErrorAction SilentlyContinue -Verbose
  Set-ItemProperty -Path $HKCU -Name "1604" -Value 0 -ErrorAction SilentlyContinue -Verbose
}

function DisableServerMgrNetworkPopup
{
  cd HKLM:\
  New-Item -Path HKLM:\System\CurrentControlSet\Control\Network -Name NewNetworkWindowOff -Force 
  Get-ScheduledTask -TaskName ServerManager | Disable-ScheduledTask -Verbose
}
    
#Create InstallAzPowerShellModule
function InstallAzPowerShellModule
{
  Write-Host "Installing Azure PowerShell (NuGet)." -ForegroundColor Green -Verbose

  Install-PackageProvider NuGet -Force
  Set-PSRepository PSGallery -InstallationPolicy Trusted
  Install-Module Az -Repository PSGallery -Force -AllowClobber
}

function InstallAzPowerShellModuleMSI
{
  Write-Host "Installing Azure PowerShell (MSI)." -ForegroundColor Green -Verbose
  #download and install git...		
  Invoke-WebRequest -Uri https://github.com/Azure/azure-powershell/releases/download/v4.5.0-August2020/Az-Cmdlets-4.5.0.33237-x64.msi -usebasicparsing -OutFile .\AzurePS.msi;
  Start-Process msiexec.exe -Wait -ArgumentList '/I AzurePS.msi /quiet'; 
  rm .\AzurePS.msi
}

#Create-LabFilesDirectory
function CreateLabFilesDirectory
{
  New-Item -ItemType directory -Path C:\LabFiles -force
}

#Cloudlabs shadow
Function InstallCloudLabsShadow($odlid, $InstallCloudLabsShadow)
    {
        if($InstallCloudLabsShadow -eq 'yes')
        {
            $WebClient = New-Object System.Net.WebClient
            $url1 = "https://spektrasystems.screenconnect.com/Bin/ConnectWiseControl.ClientSetup.msi?h=instance-ma1weu-relay.screenconnect.com&p=443&k=BgIAAACkAABSU0ExAAgAAAEAAQDhrCYwK%2BhPzyOyTYW71BahP4Q7hsWvkU20udO6d7cGuH8VAADzVNnsk39zavkgVu2uLHR1mfAL%2BUd6iAJOofhlcjO%2FB%2FVAEwvqtQ7403Nqm6rGvy6%2FxHEiqvzvn42JADRxdGVFaw9SYyTi4QckGjG0OnG69mW2RBQdWOZ3FKmhJD6zWRPZVTbl7gJkpIdMZx0BbWKiYVsvJYgoCWNXIqqH77rigu5dsmEnWeC9J0Or1KaU%2Bzsd6QJwAzEwomhiGp3FII4wbGBnCiHLD%2FrtNgR%2BJ1H3bKgYkesdxuFvO5DzUc3eEOVBSwR0crd06J%2BJP4DolgWWNZN6ZmQ1s5aOQgSq&e=Access&y=Guest&t=&c="
            $url3 = "&c=&c=&c=&c=&c=&c=&c="
            $finalurl = $url1 + $odlid + $url3
            $WebClient.DownloadFile("$finalurl","C:\Packages\cloudlabsshadow.msi")
            Start-Process msiexec.exe -Wait '/I C:\Packages\cloudlabsshadow.msi /qn' -Verbose
        }
    }

#Create Azure Credential File on Desktop
function CreateCredFile($azureUsername, $azurePassword, $azureTenantID, $azureSubscriptionID, $deploymentId)
{
  $WebClient = New-Object System.Net.WebClient
  $WebClient.DownloadFile("https://raw.githubusercontent.com/solliancenet/azure-synapse-analytics-workshop-400/master/artifacts/environment-setup/spektra/AzureCreds.txt","C:\LabFiles\AzureCreds.txt")
  $WebClient.DownloadFile("https://raw.githubusercontent.com/solliancenet/azure-synapse-analytics-workshop-400/master/artifacts/environment-setup/spektra/AzureCreds.ps1","C:\LabFiles\AzureCreds.ps1")

  (Get-Content -Path "C:\LabFiles\AzureCreds.txt") | ForEach-Object {$_ -Replace "ClientIdValue", ""} | Set-Content -Path "C:\LabFiles\AzureCreds.ps1"
  (Get-Content -Path "C:\LabFiles\AzureCreds.txt") | ForEach-Object {$_ -Replace "AzureUserNameValue", "$azureUsername"} | Set-Content -Path "C:\LabFiles\AzureCreds.txt"
  (Get-Content -Path "C:\LabFiles\AzureCreds.txt") | ForEach-Object {$_ -Replace "AzurePasswordValue", "$azurePassword"} | Set-Content -Path "C:\LabFiles\AzureCreds.txt"
  (Get-Content -Path "C:\LabFiles\AzureCreds.txt") | ForEach-Object {$_ -Replace "AzureSQLPasswordValue", "$azurePassword"} | Set-Content -Path "C:\LabFiles\AzureCreds.ps1"
  (Get-Content -Path "C:\LabFiles\AzureCreds.txt") | ForEach-Object {$_ -Replace "AzureTenantIDValue", "$azureTenantID"} | Set-Content -Path "C:\LabFiles\AzureCreds.txt"
  (Get-Content -Path "C:\LabFiles\AzureCreds.txt") | ForEach-Object {$_ -Replace "AzureSubscriptionIDValue", "$azureSubscriptionID"} | Set-Content -Path "C:\LabFiles\AzureCreds.txt"
  (Get-Content -Path "C:\LabFiles\AzureCreds.txt") | ForEach-Object {$_ -Replace "DeploymentIDValue", "$deploymentId"} | Set-Content -Path "C:\LabFiles\AzureCreds.txt"               
  (Get-Content -Path "C:\LabFiles\AzureCreds.txt") | ForEach-Object {$_ -Replace "ODLIDValue", "$odlId"} | Set-Content -Path "C:\LabFiles\AzureCreds.txt"  
  (Get-Content -Path "C:\LabFiles\AzureCreds.ps1") | ForEach-Object {$_ -Replace "ClientIdValue", ""} | Set-Content -Path "C:\LabFiles\AzureCreds.ps1"
  (Get-Content -Path "C:\LabFiles\AzureCreds.ps1") | ForEach-Object {$_ -Replace "AzureUserNameValue", "$azureUsername"} | Set-Content -Path "C:\LabFiles\AzureCreds.ps1"
  (Get-Content -Path "C:\LabFiles\AzureCreds.ps1") | ForEach-Object {$_ -Replace "AzurePasswordValue", "$azurePassword"} | Set-Content -Path "C:\LabFiles\AzureCreds.ps1"
  (Get-Content -Path "C:\LabFiles\AzureCreds.ps1") | ForEach-Object {$_ -Replace "AzureSQLPasswordValue", "$azurePassword"} | Set-Content -Path "C:\LabFiles\AzureCreds.ps1"
  (Get-Content -Path "C:\LabFiles\AzureCreds.ps1") | ForEach-Object {$_ -Replace "AzureTenantIDValue", "$azureTenantID"} | Set-Content -Path "C:\LabFiles\AzureCreds.ps1"
  (Get-Content -Path "C:\LabFiles\AzureCreds.ps1") | ForEach-Object {$_ -Replace "AzureSubscriptionIDValue", "$azureSubscriptionID"} | Set-Content -Path "C:\LabFiles\AzureCreds.ps1"
  (Get-Content -Path "C:\LabFiles\AzureCreds.ps1") | ForEach-Object {$_ -Replace "DeploymentIDValue", "$deploymentId"} | Set-Content -Path "C:\LabFiles\AzureCreds.ps1"
  (Get-Content -Path "C:\LabFiles\AzureCreds.ps1") | ForEach-Object {$_ -Replace "ODLIDValue", "$odlId"} | Set-Content -Path "C:\LabFiles\AzureCreds.ps1"
  Copy-Item "C:\LabFiles\AzureCreds.txt" -Destination "C:\Users\Public\Desktop"
}

Start-Transcript -Path C:\WindowsAzure\Logs\CloudLabsCustomScriptExtension.txt -Append

[Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls
[Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls" 

DisableInternetExplorerESC

EnableIEFileDownload

DisableServerMgrNetworkPopup

InstallAzPowerShellModule
#InstallAzPowerShellModuleMSI

InstallGit
        
InstallAzureCli

InstallEdgeChromium

Uninstall-AzureRm -ea SilentlyContinue

CreateLabFilesDirectory

InstallCloudLabsShadow $odlId $InstallCloudLabsShadow

$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine")

cd "c:\labfiles";

CreateCredFile $azureUsername $azurePassword $azureTenantID $azureSubscriptionID $deploymentId $odlId

#download the git repo...
Write-Host "Download Git repo." -ForegroundColor Green -Verbose
git clone https://github.com/CloudLabs-MOC/microsoft-data-engineering-ilt-deploy.git data-engineering-ilt-deployment


. C:\LabFiles\AzureCreds.ps1

$userName = $AzureUserName                # READ FROM FILE
$password = $AzurePassword                # READ FROM FILE
$clientId = $TokenGeneratorClientId       # READ FROM FILE
$global:sqlPassword = $AzureSQLPassword          # READ FROM FILE

$securePassword = $password | ConvertTo-SecureString -AsPlainText -Force
$cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $userName, $SecurePassword

Connect-AzAccount -Credential $cred | Out-Null
 
# Template deployment
$resourceGroupName = (Get-AzResourceGroup | Where-Object { $_.ResourceGroupName -like "*DP203-L4*" -and  $_.ResourceGroupName -notlike "*labrg*" }).ResourceGroupName
#$deploymentId =  (Get-AzResourceGroup -Name $resourceGroupName).Tags["DeploymentId"]

. C:\LabFiles\AzureCreds.ps1
$deploymentId = $deploymentID

$url = "https://raw.githubusercontent.com/CloudLabs-MOC/microsoft-data-engineering-ilt-deploy/main/setup/04/artifacts/environment-setup/automation/deploy.parameters.post.json"
$output = "c:\LabFiles\parameters.json";
$wclient = New-Object System.Net.WebClient;
$wclient.CachePolicy = new-object System.Net.Cache.RequestCachePolicy([System.Net.Cache.RequestCacheLevel]::NoCacheNoStore);
$wclient.Headers.Add("Cache-Control", "no-cache");
$wclient.DownloadFile($url, $output)
(Get-Content -Path "c:\LabFiles\parameters.json") | ForEach-Object {$_ -Replace "GET-AZUSER-PASSWORD", "$AzurePassword"} | Set-Content -Path "c:\LabFiles\parameters.json"
(Get-Content -Path "c:\LabFiles\parameters.json") | ForEach-Object {$_ -Replace "GET-DEPLOYMENT-ID", "$deploymentId"} | Set-Content -Path "c:\LabFiles\parameters.json"

Write-Host "Starting main deployment." -ForegroundColor Green -Verbose
New-AzResourceGroupDeployment -ResourceGroupName $resourceGroupName -TemplateUri "https://raw.githubusercontent.com/CloudLabs-MOC/microsoft-data-engineering-ilt-deploy/main/setup/04/artifacts/environment-setup/automation/v2-asa-workspace-core.json" -TemplateParameterFile "c:\LabFiles\parameters.json"

#install sql server cmdlets
Write-Host "Installing SQL Module." -ForegroundColor Green -Verbose
Install-Module -Name SqlServer

#install cosmosdb
Write-Host "Installing CosmosDB Module." -ForegroundColor Green -Verbose
Install-Module -Name Az.CosmosDB -AllowClobber
Import-Module Az.CosmosDB

Remove-AzResourceGroupDeployment -ResourceGroupName $resourceGroupName -Name "v2-asa-workspace-core"

#Download PowerBI
$WebClient = New-Object System.Net.WebClient
$WebClient.DownloadFile("https://download.microsoft.com/download/8/8/0/880BCA75-79DD-466A-927D-1ABF1F5454B0/PBIDesktopSetup_x64.exe","C:\LabFiles\PBIDesktop_x64.exe")

#Install Microsoft Online Services Sign-In Assistant for IT Professionals RTW
$WebClient = New-Object System.Net.WebClient
$WebClient.DownloadFile("https://download.microsoft.com/download/7/1/E/71EF1D05-A42C-4A1F-8162-96494B5E615C/msoidcli_64bit.msi","C:\Packages\msoidcli_64bit.msi")
sleep 3

Start-Process msiexec.exe -Wait '/I C:\Packages\msoidcli_64bit.msi /qn' -Verbose 

$LabFilesDirectory = "C:\LabFiles"
$WebClient = New-Object System.Net.WebClient
$WebClient.DownloadFile("https://raw.githubusercontent.com/CloudLabs-MOC/microsoft-data-engineering-ilt-deploy/main/setup/04/artifacts/environment-setup/spektra/v2/logontask.ps1","C:\LabFiles\logontask.ps1")

Invoke-WebRequest -Uri "https://github.com/MicrosoftLearning/DP-203T00-Data-Engineering-on-Microsoft-Azure/blob/master/Instructions/Labs/07/sale-small-20100102-snappy.parquet?raw=true" -OutFile "C:\LabFiles\sale-small-20100102-snappy.parquet" 
Invoke-WebRequest -Uri "https://solliancepublicdata.blob.core.windows.net/notebooks/Lab%202%20-%20Explore%20with%20Spark.ipynb" -OutFile "C:\LabFiles\Lab 2 - Explore with Spark.ipynb"

#Enable Autologon
$AutoLogonRegPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
Set-ItemProperty -Path $AutoLogonRegPath -Name "AutoAdminLogon" -Value "1" -type String 
Set-ItemProperty -Path $AutoLogonRegPath -Name "DefaultUsername" -Value "$($env:ComputerName)\labuser" -type String  
Set-ItemProperty -Path $AutoLogonRegPath -Name "DefaultPassword" -Value "Password.1!!" -type String
Set-ItemProperty -Path $AutoLogonRegPath -Name "AutoLogonCount" -Value "1" -type DWord

# Scheduled Task
$Trigger= New-ScheduledTaskTrigger -AtLogOn
$User= "$($env:ComputerName)\labuser" 
$Action= New-ScheduledTaskAction -Execute "C:\Windows\System32\WindowsPowerShell\v1.0\Powershell.exe" -Argument "-executionPolicy Unrestricted -File $LabFilesDirectory\logontask.ps1"
Register-ScheduledTask -TaskName "Setup" -Trigger $Trigger -User $User -Action $Action -RunLevel Highest -Force 

Restart-Computer -Force

Stop-Transcript
