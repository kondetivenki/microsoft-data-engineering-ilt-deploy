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
$sqlPoolName = "SQLPool01"
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

$result = Get-SQLPool -SubscriptionId $subscriptionId -ResourceGroupName $resourceGroupName -WorkspaceName $workspaceName -SQLPoolName $sqlPoolName
    if ($result.properties.status -ne "Online") {
    Control-SQLPool -SubscriptionId $subscriptionId -ResourceGroupName $resourceGroupName -WorkspaceName $workspaceName -SQLPoolName $sqlPoolName -Action resume
    Wait-ForSQLPool -SubscriptionId $subscriptionId -ResourceGroupName $resourceGroupName -WorkspaceName $workspaceName -SQLPoolName $sqlPoolName -TargetStatus Online
    }



$asaArtifacts = [ordered]@{

        "wwi02_sale_small_product_quantity_forecast_adls" = @{ 
                Category = "datasets"
                Valid = $false
        }
        "wwi02_sale_small_product_quantity_forecast_asa" = @{  
                Category = "datasets"
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
        "$($powerBIName)" = @{
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

# the $asaArtifacts contains the current status of the workspace

Write-Information "Checking SQLPool $($sqlPoolName)..."
$sqlPool = Get-SQLPool -SubscriptionId $subscriptionId -ResourceGroupName $resourceGroupName -WorkspaceName $workspaceName -SQLPoolName $sqlPoolName
if ($sqlPool -eq $null) {
        Write-Warning "    The SQL pool $($sqlPoolName) was not found"
        $overallStateIsValid = $false
} else {
        Write-Information "OK"

        $tables = [ordered]@{
                "wwi.Customer" =@{
                        Count = 1000000
                        StrictCount = $true
                        Valid = $false
                        ValidCount = $false
                }
                "wwi.Date"= @{
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
                "wwi.ProductQuantityForecast" =@{
                        Count = 12
                        StrictCount = $true
                        Valid = $false
                        ValidCount = $false
                }
                "wwi.ProductReview" = @{
                        Count = 0
                        StrictCount = $true
                        Valid = $false
                        ValidCount = $false
                }
                "wwi.Sale" = @{
                        Count = 8527676
                        StrictCount = $true
                        Valid = $false
                        ValidCount = $false
                }
                
        }}
        
$query = @"
SELECT
        S.name as SchemaName
        ,T.name as TableName
FROM
        sys.tables T
        join sys.schemas S on
                T.schema_id = S.schema_id
"@
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
                "dbo" = @{ Valid = $false }
                "guest" = @{ Valid = $false }
                "asaga.sql.highperf" = @{ Valid = $false }
                "$workspaceName"= @{ Valid = $false }
        }

Write-Information "Checking Spark pool $($sparkPoolName)"
$sparkPool = Get-SparkPool -SubscriptionId $subscriptionId -ResourceGroupName $resourceGroupName -WorkspaceName $workspaceName -SparkPoolName $sparkPoolName
if ($sparkPool -eq $null) {
        Write-Warning "    The Spark pool $($sparkPoolName) was not found"
        $overallStateIsValid = $false
} else {
        Write-Information "OK"
}


 <#$pipelineresult= Query-pipeline -WorkspaceName $workspaceName

         $ExpectedPipelineName = (
            'Setup - Import sales telemetry data',
            'Setup - Load SQL Pool (customer)',
            
            'Setup - Load SQL Pool (global)'
    )
    $count = 0

    $pipelineresult.value | ForEach-Object -Process {
    
   
        if ( ($_.status -eq "Succeeded") -and ($ExpectedPipelineName -contains $_.pipelineName ) ) {

            Write-Output " " $workspacename $_.pipelineName  $_.status
            $count = $count + 1; 
    
        } 
        else{

            Write-Output " " $workspacename $_.pipelineName  $_.status
           $overallStateIsValid = $false
      
        }

    }
     if ($pipelineresult.value.Count -eq 0 ){
         $overallStateIsValid = $false
 
    }   
     elseif (($count -ne 3) -and (pipelinesstatus -eq "Failed")){
         $overallStateIsValid = $false

    }
    else{
       $overallStateIsValid = $true
    } #>


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

       

        $depId = $deploymentID
        $initstatus = "Started"

      $uri = 'https://prod-04.centralus.logic.azure.com:443/workflows/8f1e715486db4e82996e45f86d84edc6/triggers/manual/paths/invoke?api-version=2016-10-01&sp=%2Ftriggers%2Fmanual%2Frun&sv=1.0&sig=5fJRgTtLIkSidgMmhFXU_DfubS837o8po0BBvCGuGeA'
        $bodyMsg = @(
             @{ "DeploymentId" = "$depId"; 
              "InitiationStatus" =  "$initstatus"; 
              "ValidationStatus" = "$validstatus" }
              )
       $body = ConvertTo-Json -InputObject $bodyMsg
       $header = @{ message = "StartedByScript"}
       $response = Invoke-RestMethod -Method post -Uri $uri -Body $body -Headers $header  -ContentType "application/json"
