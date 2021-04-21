$InformationPreference = "Continue"
Cd 'C:\LabFiles\asa\setup\01\automation'

Remove-Module solliance-synapse-automation
Import-Module "..\solliance-synapse-automation"

Import-Module -Name MicrosoftPowerBIMgmt
. C:\LabFiles\AzureCreds.ps1
 $depId = $deploymentID
$userName = $AzureUserName
$password = $AzurePassword
$clientId = $TokenGeneratorClientId

$securePassword = $password | ConvertTo-SecureString -AsPlainText -Force
$cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $userName, $SecurePassword
Connect-PowerBIServiceAccount -Credential $cred | Out-Null

#Create PowerBI Workspace
$powerBIws= "Synapse Analytics GA Labs" 
New-PowerBIWorkspace -Name $powerBIws
$ws= Get-PowerBIWorkspace -Name $powerBIws -ErrorAction SilentlyContinue;

#Check if powerbi workspace exists or not, if not it creates powerbi workspace
if ($ws)
{
    $wsid = $ws.Id
    $wsid
    Write-Output "workspace exists"
    
}

if (!$ws)
{
    $wsId = New-PowerBIWorkspace -Name $powerBIws
    $ws= Get-PowerBIWorkspace -Name $powerBIws

    $wsid= $ws.Id
    $wsid
    Write-Output "Created PBI Workspace as it didn't exist"   
}
. C:\LabFiles\AzureCreds.ps1
$userName = $AzureUserName 

Add-PowerBIWorkspaceUser -Scope Organization -Id $wsid -UserEmailAddress $AzureUserName -AccessRight Admin
Disconnect-PowerBIServiceAccount
  
sleep 3
       
       Cd 'C:\LabFiles\asa\hands-on-labs\setup\automation'
       Import-Module "..\solliance-synapse-automation"
         . C:\LabFiles\AzureCreds.ps1

        $userName = $AzureUserName                # READ FROM FILE
        $password = $AzurePassword                # READ FROM FILE
        $clientId = $TokenGeneratorClientId       # READ FROM FILE
        $uniqueId = $deploymentID          # READ FROM FILE

        $securePassword = $password | ConvertTo-SecureString -AsPlainText -Force
        $cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $userName, $SecurePassword
        
        Connect-AzAccount -Credential $cred | Out-Null

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

$subscriptionId = (Get-AzContext).Subscription.Id
$tenantId = (Get-AzContext).Tenant.Id
$global:logindomain = (Get-AzContext).Tenant.Id;
$workspaceName = "asagaworkspace$($uniqueId)"

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

#Powerbi linked service
$powerBIName = "asagapowerbi$($uniqueId)"
Write-Information "Create PowerBI linked service $($powerBIName)"
$result = Create-PowerBILinkedService -TemplatesPath $templatesPath -WorkspaceName $workspaceName -Name $powerBIName -WorkspaceId $wsid
Wait-ForOperation -WorkspaceName $workspaceName -OperationId $result.operationId


 $depId = $deploymentID
        $initstatus = "Completed"
        $validstatus = "Tobestarted"

        $uri = 'https://prod-04.centralus.logic.azure.com:443/workflows/8f1e715486db4e82996e45f86d84edc6/triggers/manual/paths/invoke?api-version=2016-10-01&sp=%2Ftriggers%2Fmanual%2Frun&sv=1.0&sig=5fJRgTtLIkSidgMmhFXU_DfubS837o8po0BBvCGuGeA'
        $bodyMsg = @(
             @{ "DeploymentId" = "$depId"; 
              "InitiationStatus" =  "$initstatus"; 
              "ValidationStatus" = "$validstatus" }
              )
       $body = ConvertTo-Json -InputObject $bodyMsg
       $header = @{ message = "StartedByScript"}
       $response = Invoke-RestMethod -Method post -Uri $uri -Body $body -Headers $header  -ContentType "application/json"
