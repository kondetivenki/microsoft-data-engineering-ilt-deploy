        $InformationPreference = "Continue"
        cd 'C:\LabFiles\data-engineering-ilt-deployment\setup\04\artifacts\environment-setup\automation'
        if(Get-Module -Name solliance-synapse-automation){
                Remove-Module solliance-synapse-automation
        }
        Import-Module "..\solliance-synapse-automation"

        . C:\LabFiles\AzureCreds.ps1

        $userName = $AzureUserName                # READ FROM FILE
        $password = $AzurePassword                # READ FROM FILE
        $clientId = $TokenGeneratorClientId       # READ FROM FILE
        $global:sqlPassword = "password.1!!"         # READ FROM FILE
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

        $templatesPath = ".\artifacts\environment-setup\templates"
        $datasetsPath = ".\artifacts\environment-setup\datasets"
        $dataflowsPath = ".\artifacts\environment-setup\dataflows"
        $pipelinesPath = ".\artifacts\environment-setup\pipelines"
        $sqlScriptsPath = ".\artifacts\environment-setup\sql"


$resourceGroupName = (Get-AzResourceGroup | Where-Object { $_.ResourceGroupName -like "*DP203*" -and  $_.ResourceGroupName -notlike "*labrg*" }).ResourceGroupName

#$uniqueId =  (Get-AzResourceGroup -Name $resourceGroupName).Tags["DeploymentId"]
. C:\LabFiles\AzureCreds.ps1
$uniqueId = $deploymentID
$subscriptionId = (Get-AzContext).Subscription.Id
$tenantId = (Get-AzContext).Tenant.Id

$workspaceName = "asaworkspace$($uniqueId)"
$cosmosDbAccountName = "asacosmosdb$($uniqueId)"
$cosmosDbDatabase = "CustomerProfile"
$cosmosDbContainer = "OnlineUserProfile01"
$dataLakeAccountName = "asadatalake$($uniqueId)"
$blobStorageAccountName = "asastore$($uniqueId)"
$keyVaultName = "asakeyvault$($uniqueId)"
$keyVaultSQLUserSecretName = "SQL-USER-ASA"
$sqlPoolName = "SQLPool01"
$integrationRuntimeName = "AzureIntegrationRuntime01"
$sparkPoolName = "SparkPool01"
$global:sqlEndpoint = "$($workspaceName).sql.azuresynapse.net"
$global:sqlUser = "asa.sql.admin"

$global:synapseToken = ""
$global:synapseSQLToken = ""
$global:managementToken = ""

$global:tokenTimes = [ordered]@{
        Synapse = (Get-Date -Year 1)
        SynapseSQL = (Get-Date -Year 1)
        Management = (Get-Date -Year 1)
}

$overallStateIsValid = $true

Write-Information "Checking if PBI desktop is installed or not"
$filetocheck= "C:\Program Files\Microsoft Power BI Desktop\bin\PBIDesktop.exe"

if(!(Test-Path $filetocheck -PathType leaf))
{
 Write-Information "Powerbi is not installed, Installing it" 
 $overallStateIsValid= $false
}
else{
Write-Information "Powerbi ok"
}

$asaArtifacts = [ordered]@{

        "wwi02_sale_small_workload_01_asa" = @{ 
                Category = "datasets"
                Valid = $false
        }
        "wwi02_sale_small_workload_02_asa" = @{ 
                Category = "datasets"
                Valid = $false
        }
        "Lab 08 - Execute Business Analyst Queries" = @{
                Category = "pipelines"
                Valid = $false
        }
        "Lab 08 - Execute Data Analyst and CEO Queries" = @{
                Category = "pipelines"
                Valid = $false
        }

        "Lab 05 - Exercise 3 - Column Level Security" = @{
                Category = "sqlscripts"
                Valid = $false
        }
        "Lab 05 - Exercise 3 - Dynamic Data Masking" = @{
                Category = "sqlscripts"
                Valid = $false
        }
        "Lab 05 - Exercise 3 - Row Level Security" = @{
                Category = "sqlscripts"
                Valid = $false
        }
        "Activity 03 - Data Warehouse Optimization" = @{
                Category = "sqlscripts"
                Valid = $false
        }
        "sqlpool01_import01" = @{
                Category = "linkedServices"
                Valid = $false
        }
        "sqlpool01" = @{
                Category = "linkedServices"
                Valid = $false
        }
        "sqlpool01_highperf" = @{
                Category = "linkedServices"
                Valid = $false
        }
        "sqlpool01_workload01" = @{
                Category = "linkedServices"
                Valid = $false
        }
        "sqlpool01_workload02" = @{
                Category = "linkedServices"
                Valid = $false
        }
        "$($blobStorageAccountName)" = @{
                Category = "linkedServices"
                Valid = $false
        }
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

Write-Information "Start the $($sqlPoolName) SQL pool if needed."

$result = Get-SQLPool -SubscriptionId $subscriptionId -ResourceGroupName $resourceGroupName -WorkspaceName $workspaceName -SQLPoolName $sqlPoolName
if ($result.properties.status -ne "Online") {
    Control-SQLPool -SubscriptionId $subscriptionId -ResourceGroupName $resourceGroupName -WorkspaceName $workspaceName -SQLPoolName $sqlPoolName -Action resume
    Wait-ForSQLPool -SubscriptionId $subscriptionId -ResourceGroupName $resourceGroupName -WorkspaceName $workspaceName -SQLPoolName $sqlPoolName -TargetStatus Online
}

# the $asaArtifacts contains the current status of the workspace

Write-Information "Checking SQLPool $($sqlPoolName)..."
$sqlPool = Get-SQLPool -SubscriptionId $subscriptionId -ResourceGroupName $resourceGroupName -WorkspaceName $workspaceName -SQLPoolName $sqlPoolName
if ($sqlPool -eq $null) {
        Write-Warning "    The SQL pool $($sqlPoolName) was not found"
        $overallStateIsValid = $false
} else {
        Write-Information "OK"

        $tables = [ordered]@{
                "wwi.Date" = @{
                        Count = 3652
                        StrictCount = $true
                        Valid = $false
                        ValidCount = $false
                }
                "wwi.Product" = @{
                        Count = 5000
                        StrictCount = $true
                        Valid = $false
                        ValidCount = $false
                }
                "wwi.SaleSmall" = @{
                        Count = 1863080489
                        StrictCount = $true
                        Valid = $false
                        ValidCount = $false
                }
                "wwi_perf.Sale_Hash_Ordered" = @{
                        Count = 339507246
                        StrictCount = $true
                        Valid = $false
                        ValidCount = $false
                }
                "wwi_perf.Sale_Heap" = @{
                        Count = 339507246
                        StrictCount = $true
                        Valid = $false
                        ValidCount = $false
                }
                "wwi_perf.Sale_Index" = @{
                        Count = 339507246
                        StrictCount = $true
                        Valid = $false
                        ValidCount = $false
                }
                "wwi_perf.Sale_Partition01" = @{
                        Count = 339507246
                        StrictCount = $true
                        Valid = $false
                        ValidCount = $false
                }
                "wwi_perf.Sale_Partition02" = @{
                        Count = 339507246
                        StrictCount = $true
                        Valid = $false
                        ValidCount = $false
                }
                "wwi_security.CustomerInfo" = @{
                        Count = 110
                        StrictCount = $false
                        Valid = $false
                        ValidCount = $false
                }
                "wwi_security.Sale" = @{
                        Count = 52
                        StrictCount = $false
                        Valid = $false
                        ValidCount = $false
                }
 
                "wwi_poc.Sale" = @{
                        Count = 981995895
                        StrictCount = $false
                        Valid = $false
                        ValidCount = $false
                }
                "wwi_poc.Product" = @{
                        Count = 5000
                        StrictCount = $false
                        Valid = $false
                        ValidCount = $false
                }
                "wwi_poc.Customer" = @{
                        Count = 1000000
                        StrictCount = $false
                        Valid = $false
                        ValidCount = $false
                }
                "wwi_poc.Date" = @{
                        Count = 3652
                        StrictCount = $false
                        Valid = $false
                        ValidCount = $false
                }
        }
        
$query = @"
SELECT
        S.name as SchemaName
        ,T.name as TableName
FROM
        sys.tables T
        join sys.schemas S on
                T.schema_id = S.schema_id
"@

        #$result = Execute-SQLQuery -WorkspaceName $workspaceName -SQLPoolName $sqlPoolName -SQLQuery $query
        $result = Invoke-SqlCmd -Query $query -ServerInstance $sqlEndpoint -Database $sqlPoolName -Username $sqlUser -Password $sqlPassword

        #foreach ($dataRow in $result.data) {
        foreach ($dataRow in $result) {
                $schemaName = $dataRow[0]
                $tableName = $dataRow[1]
        
                $fullName = "$($schemaName).$($tableName)"
        
                if ($tables[$fullName]) {
                        
                        $tables[$fullName]["Valid"] = $true
                        $strictCount = $tables[$fullName]["StrictCount"]
        
                        Write-Information "Counting table $($fullName) with StrictCount = $($strictCount)..."
        
                        try {
                            $countQuery = "select count_big(*) from $($fullName)"

                            #$countResult = Execute-SQLQuery -WorkspaceName $workspaceName -SQLPoolName $sqlPoolName -SQLQuery $countQuery
                            #count = [int64]$countResult[0][0].data[0].Get(0)
                            $countResult = Invoke-Sqlcmd -Query $countQuery -ServerInstance $sqlEndpoint -Database $sqlPoolName -Username $sqlUser -Password $sqlPassword
                            $count = $countResult[0][0]
        
                            Write-Information "    Count result $($count)"
        
                            if (
                                ($strictCount -and ($count -eq $tables[$fullName]["Count"])) -or
                                ((-not $strictCount) -and ($count -ge $tables[$fullName]["Count"]))) {

                                    Write-Information "    OK - Records counted is correct."
                                    $tables[$fullName]["ValidCount"] = $true
                            }
                            else {
                                Write-Warning "    Records counted is NOT correct."
                                $overallStateIsValid = $false
                            }
                        }
                        catch { 
                            Write-Warning "    Error while querying table."
                            $overallStateIsValid = $false
                        }
        
                }
        }
        
        # $tables contains the current status of the necessary tables
        foreach ($tableName in $tables.Keys) {
                if (-not $tables[$tableName]["Valid"]) {
                        Write-Warning "Table $($tableName) was not found."
                        $overallStateIsValid = $false
                }
        }

        $users = [ordered]@{
                "CEO" = @{ Valid = $false }
                "DataAnalystMiami" = @{ Valid = $false }
                "DataAnalystSanDiego" = @{ Valid = $false }
                "asa.sql.workload01" = @{ Valid = $false }
                "asa.sql.workload02" = @{ Valid = $false }
                "asa.sql.import01" = @{ Valid = $false }
                "asa.sql.import02" = @{ Valid = $false }
                "asa.sql.highperf" = @{ Valid = $false }
                "$($userName)" = @{ Valid = $false }
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

Write-Information "Counting Cosmos DB item in database $($cosmosDbDatabase), container $($cosmosDbContainer)"
$documentCount = Count-CosmosDbDocuments -SubscriptionId $subscriptionId -ResourceGroupName $resourceGroupName -CosmosDbAccountName $cosmosDbAccountName `
                -CosmosDbDatabase $cosmosDbDatabase -CosmosDbContainer $cosmosDbContainer

if ($documentCount -ne 100000) {
        Write-Warning "    Invalid number of CosmosDb documents. Expected 100000 but found $($documentCount)."
        $overallStateIsValid = $false
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
                        "sale-small" = "folder path"
                        "sale-poc" = "folder path"
                        "online-user-profiles-01" = "folder path"
                         "online-user-profiles-02" = "folder path"
                        "sale-small\Year=2014" = "folder path"
                        "sale-small\Year=2015" = "folder path"
                        "sale-small\Year=2016" = "folder path"
                        "sale-small\Year=2017" = "folder path"
                        "sale-small\Year=2018" = "folder path"
                        "sale-small\Year=2019" = "folder path"
                        "sale-small\Year=2016\Quarter=Q4\Month=12\Day=20161231\sale-small-20161231-snappy.parquet" = "file path"
                        "sale-csv\wwi-factsale.csv"= "file path"
                        "campaign-analytics\dailycounts.txt" = "file path"
                        "campaign-analytics\sale-20161230-snappy.parquet" = "file path"
                        "campaign-analytics\campaignanalytics.csv" = "file path"
                        "customer-info\customerinfo.csv" ="file path"
                        "data-generators\generator-product\generator-product.csv"= "file path"
                        "data-generators\generator-customer-clean.csv"= "file path"
                        "data-generators\generator-customer.csv"= "file path"
                        "data-generators\generator-date.csv"= "file path"
                         "security\customerinfo.csv" = "file path"
                         "security\factsale.csv" ="file path"
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
