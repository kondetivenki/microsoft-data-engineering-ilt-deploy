$InformationPreference = "Continue"

Cd 'C:\LabFiles\asa\setup\01\automation'

Remove-Module solliance-synapse-automation
Import-Module "..\solliance-synapse-automation"
. C:\LabFiles\AzureCreds.ps1

        $userName = $AzureUserName                # READ FROM FILE
        $password = $AzurePassword                # READ FROM FILE
        $clientId = $TokenGeneratorClientId       # READ FROM FILE
        $global:sqlPassword = "password.1!!"      # READ FROM FILE
        $uniqueId = $deploymentID
        
         $OdlId = $odlId
        $DeploymentId = $deploymentID
        $validstatus = "started"
        
        $securePassword = $password | ConvertTo-SecureString -AsPlainText -Force
        $cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $userName, $SecurePassword
        
        Connect-AzAccount -Credential $cred | Out-Null
       
        $global:logindomain = (Get-AzContext).Tenant.Id
        $ropcBodyCore = "client_id=$($clientId)&username=$($userName)&password=$($password)&grant_type=password"
        $global:ropcBodySynapse = "$($ropcBodyCore)&scope=https://dev.azuresynapse.net/.default"
        $global:ropcBodyManagement = "$($ropcBodyCore)&scope=https://management.azure.com/.default"
        $global:ropcBodySynapseSQL = "$($ropcBodyCore)&scope=https://sql.azuresynapse.net/.default"
        $global:ropcBodyPowerBI = "$($ropcBodyCore)&scope=https://analysis.windows.net/powerbi/api/.default"

        $artifactsPath = "..\..\"
        $reportsPath = "..\reports"
        $templatesPath = "..\templates"
        $datasetsPath = "..\datasets"
        $dataflowsPath = "..\dataflows"
        $pipelinesPath = "..\pipelines"
        $sqlScriptsPath = "..\sql"

       $resourceGroupName = (Get-AzResourceGroup | Where-Object { $_.ResourceGroupName -like "*DP203-M1*" -and  $_.ResourceGroupName -notlike "*internal*" -and  $_.ResourceGroupName -notlike "*databricks*" }).ResourceGroupName
$subscriptionId = (Get-AzContext).Subscription.Id
$tenantId = (Get-AzContext).Tenant.Id
$global:logindomain = (Get-AzContext).Tenant.Id;

$workspaceName = "asagaworkspace$($uniqueId)"
$dataLakeAccountName = "asagadatalake$($uniqueId)"
$keyVaultName = "asagakeyvault$($uniqueId)"
$keyVaultSQLUserSecretName = "SQL-USER-ASA"
$integrationRuntimeName = "AutoResolveIntegrationRuntime"
$sparkPoolName = "SparkPool01"
$powerBIName = "asagapowerbi$($uniqueId)"
$global:sqlEndpoint = "$($workspaceName).sql.azuresynapse.net"
$global:sqlUser = "asaga.sql.admin"

$global:synapseToken = ""
$global:synapseSQLToken = ""
$global:managementToken = ""
$global:powerbiToken = "";

$global:tokenTimes = [ordered]@{
        Synapse = (Get-Date -Year 1)
        SynapseSQL = (Get-Date -Year 1)
        Management = (Get-Date -Year 1)
        PowerBI = (Get-Date -Year 1)
}


$overallStateIsValid = $true

<#Write-Information "Checking if PBI desktop is installed or not"
$filetocheck= "C:\Program Files\Microsoft Power BI Desktop\bin\PBIDesktop.exe"

if(!(Test-Path $filetocheck -PathType leaf))
{
 Write-Information "Powerbi is not installed, Installing it" 
 $overallStateIsValid= $false
}
else{
Write-Information "Powerbi ok"
} #>

$asaArtifacts = [ordered]@{
        "$($dataLakeAccountName)" = @{
                Category = "linkedServices"
                Valid = $false
        }
        "$($keyVaultName)" = @{
                Category = "linkedServices"
                Valid = $false
        }
}

foreach ($asaArtifactName in $asaArtifacts.Keys) {
        try {
                Write-Information "Checking $($asaArtifactName) in $($asaArtifacts[$asaArtifactName]["Category"])"
                $result = Get-ASAObject -WorkspaceName $workspaceName -Category $asaArtifacts[$asaArtifactName]["Category"] -Name $asaArtifactName
                $asaArtifacts[$asaArtifactName]["Valid"] = $true
                Write-Information "OK"
        }
        catch { 
                Write-Warning "Not found!"
                $overallStateIsValid = $false
        }
}



Write-Information "Checking Spark pool $($sparkPoolName)"
$sparkPool = Get-SparkPool -SubscriptionId $subscriptionId -ResourceGroupName $resourceGroupName -WorkspaceName $workspaceName -SparkPoolName $sparkPoolName
if ($sparkPool -eq $null) {
        Write-Warning "    The Spark pool $($sparkPoolName) was not found"
        $overallStateIsValid = $false
} else {
        Write-Information "OK"
}

Write-Information "Checking datalake account $($dataLakeAccountName)..."
$dataLakeAccount = Get-AzStorageAccount -ResourceGroupName $resourceGroupName -Name $dataLakeAccountName
if ($dataLakeAccount -eq $null) {
        Write-Warning "    The datalake account $($dataLakeAccountName) was not found"
        $overallStateIsValid = $false
} else {
        Write-Information "OK"

        Write-Information "Checking data lake file system wwi-02"
        $dataLakeFileSystem = Get-AzDataLakeGen2Item -Context $dataLakeAccount.Context -FileSystem "wwi-02"
        if ($dataLakeFileSystem -eq $null) {
                Write-Warning "    The data lake file system wwi-02 was not found"
                $overallStateIsValid = $false
        } else {
                Write-Information "OK"

                $dataLakeItems = [ordered]@{           
                        "data-generators\generator-product\generator-product.csv"= "file path"
                        "data-generators\generator-customer-clean.csv"= "file path"
                        "data-generators\generator-date.csv"= "file path"
                        "sale-small\Year=2019" = "folder path"
                        "sale-small-product-quantity-forecast\ProductQuantity-20201209-11.csv" = "file path"
                        "sale-small-product-reviews\ProductReviews.csv" = "file path"
                        "sale-small-stats-final\sale-small-stats.snappy.parquet" = "file path"

                      "sale-small-telemetry\sale-small-telemetry-20191201.csv" = "file path"
                      "sale-small-telemetry\sale-small-telemetry-20191202.csv" = "file path"
                      "sale-small-telemetry\sale-small-telemetry-20191203.csv" = "file path"
                      "sale-small-telemetry\sale-small-telemetry-20191204.csv" = "file path"
                      "sale-small-telemetry\sale-small-telemetry-20191205.csv" = "file path"
                      "sale-small-telemetry\sale-small-telemetry-20191206.csv" = "file path"
                      "sale-small-telemetry\sale-small-telemetry-20191207.csv" = "file path"
                      "sale-small-telemetry\sale-small-telemetry-20191208.csv" = "file path"
                }
        
                foreach ($dataLakeItemName in $dataLakeItems.Keys) {
        
                        Write-Information "Checking data lake $($dataLakeItems[$dataLakeItemName]) $($dataLakeItemName)..."
                        $dataLakeItem = Get-AzDataLakeGen2Item -Context $dataLakeAccount.Context -FileSystem "wwi-02" -Path $dataLakeItemName
                        if ($dataLakeItem -eq $null) {
                                Write-Warning "    The data lake $($dataLakeItems[$dataLakeItemName]) $($dataLakeItemName) was not found"
                                $overallStateIsValid = $false
                        } else {
                                Write-Information "OK"
                        }
        
                }  
        }      
}


if ($overallStateIsValid -eq $true) {
    Write-Information "Validation Passed"
    
    $result = Get-SQLPool -SubscriptionId $subscriptionId -ResourceGroupName $resourceGroupName -WorkspaceName $workspaceName -SQLPoolName $sqlPoolName
    if ($result.properties.status -eq "Online") {
    Control-SQLPool -SubscriptionId $subscriptionId -ResourceGroupName $resourceGroupName -WorkspaceName $workspaceName -SQLPoolName $sqlPoolName -Action pause
    Wait-ForSQLPool -SubscriptionId $subscriptionId -ResourceGroupName $resourceGroupName -WorkspaceName $workspaceName -SQLPoolName $sqlPoolName -TargetStatus Paused
    }
     
    $validstatus = "Successfull"
}
else {
    Write-Warning "Validation Failed - see log output"
     $validstatus = "Failed"
}

       

    $uri = 'https://prod-84.eastus.logic.azure.com:443/workflows/005f93b9e5804534aaf5e2e891936fd7/triggers/manual/paths/invoke?api-version=2016-10-01&sp=%2Ftriggers%2Fmanual%2Frun&sv=1.0&sig=9mXa-Wts-DhG7eOYmAHiArZ0fPUFB34m0J_W2JEs9Z8'
     $bodyMsg = @(
    @{ "OdlId" = "$OdlId";
       "DeploymentId" =  "$DeploymentId";
       "validstatus" = "$validstatus" }
        )
       $body = ConvertTo-Json -InputObject $bodyMsg
       $header = @{ message = "StartedByScript"}
       $response = Invoke-RestMethod -Method post -Uri $uri -Body $body -Headers $header  -ContentType "application/json"
