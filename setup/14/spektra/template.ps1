. C:\LabFiles\AzureCreds.ps1

$userName = $AzureUserName                # READ FROM FILE
$password = $AzurePassword                # READ FROM FILE
$clientId = $TokenGeneratorClientId       # READ FROM FILE
$global:sqlPassword = $AzureSQLPassword          # READ FROM FILE

$securePassword = $password | ConvertTo-SecureString -AsPlainText -Force
$cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $userName, $SecurePassword

Connect-AzAccount -Credential $cred | Out-Null
 
# Template deployment
$resourceGroupName = (Get-AzResourceGroup | Where-Object { $_.ResourceGroupName -like "*DP203-M4*" }).ResourceGroupName
#$deploymentId =  (Get-AzResourceGroup -Name $resourceGroupName).Tags["DeploymentId"]

. C:\LabFiles\AzureCreds.ps1
$deploymentId = $deploymentID

$url = "https://raw.githubusercontent.com/CloudLabs-MOC/microsoft-data-engineering-ilt-deploy/main/setup/14/spektra/deploy.parameters.post.json"
$output = "c:\LabFiles\parameters.json";
$wclient = New-Object System.Net.WebClient;
$wclient.CachePolicy = new-object System.Net.Cache.RequestCachePolicy([System.Net.Cache.RequestCacheLevel]::NoCacheNoStore);
$wclient.Headers.Add("Cache-Control", "no-cache");
$wclient.DownloadFile($url, $output)
(Get-Content -Path "c:\LabFiles\parameters.json") | ForEach-Object {$_ -Replace "GET-AZUSER-PASSWORD", "$AzurePassword"} | Set-Content -Path "c:\LabFiles\parameters.json"
(Get-Content -Path "c:\LabFiles\parameters.json") | ForEach-Object {$_ -Replace "GET-DEPLOYMENT-ID", "$deploymentId"} | Set-Content -Path "c:\LabFiles\parameters.json"

Write-Host "Starting main deployment." -ForegroundColor Green -Verbose
New-AzResourceGroupDeployment -ResourceGroupName $resourceGroupName -TemplateUri "https://raw.githubusercontent.com/CloudLabs-MOC/microsoft-data-engineering-ilt-deploy/main/setup/14/spektra/deploy.json" -TemplateParameterFile "c:\LabFiles\parameters.json"

#install sql server cmdlets
Write-Host "Installing SQL Module." -ForegroundColor Green -Verbose
Install-Module -Name SqlServer

#install cosmosdb
Write-Host "Installing CosmosDB Module." -ForegroundColor Green -Verbose
Install-Module -Name Az.CosmosDB -AllowClobber
Import-Module Az.CosmosDB

New-AzRoleAssignment -ResourceGroupName $resourceGroupName -ErrorAction Ignore -ObjectId "37548b2e-e5ab-4d2b-b0da-4d812f56c30e" -RoleDefinitionName "Owner"

Remove-AzResourceGroupDeployment -ResourceGroupName $resourceGroupName -Name "deploy"
