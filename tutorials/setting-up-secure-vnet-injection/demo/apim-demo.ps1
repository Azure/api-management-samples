param(
[String]$tenantId = "72f988bf-XXXX-41af-XXXX-2d7cd011db47",
[String]$subscriptionID = "75f50714-XXXX-4aab-XXXX-3afd65053b9a",
[String]$location = "eastus",
[string]$resourceGroupName = "demo-rg-apim-aug",
[String]$templatePath = "D:\Scripts\vanguard_vnet_injection\Test_NRP",
[Switch]$cleanup = $false
)
$separator = "---------------------------------------------------------------------------"
$global:Deployments = [System.Collections.ArrayList]@()

function Connect-AzureAccountUsingSPN {
    $servicePrincipalID = "712ebbbc-80ca-XXXX-b6a5-XXXXXXX"
    $servicePrincipalAppID = "XXXXXXX-1cb8-47a9-9931-XXXXXXXX"
    $servicePrincipalPassID = Get-Content "$PSScriptRoot\pass.txt"

    $ctx = Get-AzSubscription -SubscriptionId $subscriptionID -ErrorAction SilentlyContinue

    if($ctx -eq $null)
    {
        $SecurePassword = ConvertTo-SecureString $servicePrincipalPassID -AsPlainText -Force
        $psCredential = New-Object System.Management.Automation.PSCredential ($servicePrincipalAppID, $SecurePassword)
        Connect-AzAccount -Credential $psCredential -ServicePrincipal -Tenant $tenantId -Subscription $subscriptionID
    }
    
    Select-AzSubscription -Subscription $subscriptionID -Tenant $tenantId
}

function Create-AzureResourceGroup{
    $rg = Get-AzResourceGroup -Name $resourceGroupName -Location $location -ErrorAction SilentlyContinue

    if($rg -eq $null)
    {
        New-AzResourceGroup -Name $resourceGroupName -Location $location
    }
    $rg
}

function Create-VnetInjected-APIM-Prereq {
    param(
        [String]$workspaceName,
        [String]$vnetName,
        [String]$resourceGroupName
    )

    $uniqueId = [guid]::NewGuid()
    $vnetResourceParams = Get-Content -Path $templatePath\CreateExternalApimVnet.prereq.parameters.json | ConvertFrom-Json
    $vnetResourceParams.parameters.virtualNetworkName.value = $vnetName
    $vnetResourceParams | ConvertTo-Json -Depth 10 | Out-File $templatePath\CreateVnetApim.preq.generatedparams.json -Force
    $deploymentName = "$($workspaceName)-preq-$($uniqueId)"
    Write-Host "Deployment Name: $($deploymentName)"
    $vnet = New-AzResourceGroupDeployment -Name $deploymentName `
            -ResourceGroupName $resourceGroupName -TemplateFile $templatePath\CreateExternalApimVnet.prereq.template.json `
            -TemplateParameterFile $templatePath\CreateVnetApim.preq.generatedparams.json -Verbose
    $Deployments.Add($deploymentName) | Out-Null
    return $vnet.Outputs.existingVNETId.Value
}

function Create-VnetInjected-APIM {
    param(
        [String]$workspaceName,
        [String]$vnetName
    )

    $uniqueId = [guid]::NewGuid()

    $prerequisitesParams = Get-Content -Path $templatePath\CreateExternalApimService.parameters.json | ConvertFrom-Json
    $prerequisitesParams.parameters.virtualNetworkName.value = $vnetName
    $prerequisitesParams.parameters.apiManagementServiceName.value = $workspaceName    
    $prerequisitesParams | ConvertTo-Json | Out-File $templatePath\CreateExternalApimService.generatedparams.json -Force
    $deploymentName = "$($workspaceName)-preq-$($uniqueId)"
    Write-Host "Deployment Name: $($deploymentName)"
    $ws = New-AzResourceGroupDeployment -Name $deploymentName `
            -ResourceGroupName $resourceGroupName -TemplateFile $templatePath\CreateExternalApimService.template.json `
            -TemplateParameterFile $templatePath\CreateExternalApimService.generatedparams.json -Verbose
    $Deployments.Add($deploymentName) | Out-Null
    return $ws.Outputs.workspaceId.Value
}

function Create-AzureFirewall {
    param(
        [String]$fwName,
        [String]$resourceGroupName,
        [String]$fwPublicIPName,
        [String]$vnetName
    )

    $publicIp = New-AzPublicIpAddress -Name $fwPublicIPName `
                -ResourceGroupName $resourceGroupName -Location $location -Sku Standard -AllocationMethod Static

    $fw = New-AzFirewall -Name $fwName -ResourceGroupName $resourceGroupName `
            -Location $location -VirtualNetworkName $vnetName -PublicIpName $fwPublicIPName -EnableDnsProxy
    return $fw
}

function Create-AzureRouteTable {
    param(
        [String]$routeTableName
    )

    $routeTable = New-AzRouteTable -ResourceGroupName $resourceGroupName -Name $routeTableName -Location $location
    return $routeTable
}

function Attach-AzureRouteTableToSubnets {
    param(
        [String]$routeTableName,
        [String]$vnetName,
        [String]$pubSub,
        [Object]$routeTable
    )
    $vnet = Get-AzVirtualNetwork -Name $vnetname -ResourceGroupName $resourceGroupName
    $publicSubnet = Get-AzVirtualNetworkSubnetConfig -Name $pubSub -VirtualNetwork $vnet
    Set-AzVirtualNetworkSubnetConfig -Name $publicSubnet.Name -AddressPrefix $publicSubnet.AddressPrefix -VirtualNetwork $vnet -RouteTable $routeTable
    $vnet | Set-AzVirtualNetwork
    return $vnet
}

function Cleanup-Resources {
    param (
        [String]$resourceGroupName
    )
    foreach ($dep in $Deployments) {
        Remove-AzResourceGroupDeployment -ResourceGroupName $resourceGroupName -Name $dep
    }
    Remove-AzResourceGroup -Name $resourceGroupName -Force
}

Write-Host "Start time: $([DateTime]::UtcNow)"

#region login az account
Write-Host $separator
Write-Host "Connecting to Azure account..."
Connect-AzureAccountUsingSPN
Write-Host "Successfully connected to Azure account SubscriptionId: $subscriptionID"
Write-Host $separator
#endregion

#region Create Resource Group
Write-Host $separator
Write-Host "Creating Resource Group..."
Create-AzureResourceGroup
Write-Host "Successfully created Resource Group: $($resourceGroupName)"
Write-Host $separator
#endregion

#region Create Public IP apimservice
Write-Host $separator
$workspaceName = "apim-injected-demo"
$vnetName = "$($workspaceName)-vnet"
Write-Host "Creating Prerequisites for apimservice: $($workspaceName)"
$vnetId = Create-VnetInjected-APIM-Prereq -workspaceName $workspaceName -vnetName $vnetName -resourceGroupName $resourceGroupName
Write-Host "Successfully created Vnet with vnetId: $($vnetId)"
Write-Host "Creating apimservice: $($workspaceName)"
$publicIpWorkspaceId = Create-VnetInjected-APIM -workspaceName $workspaceName -vnetName $vnetName
Write-Host "Successfully created apimservice with workspaceId: $($publicIpWorkspaceId)"
Write-Host $separator
#endregion

#region Create Azure Firewall
Write-Host $separator
$vnetName = "$($workspaceName)-vnet"
$fwName = "demo-fw"
$fwPublicIpName = "demo-fw-publicip"
Write-Host "Creating Firewall: $($fwName)"
$fw = Create-AzureFirewall -fwName $fwName -resourceGroupName $resourceGroupName -fwPublicIPName $fwPublicIpName -vnetName $vnetName
Write-Host "Successfully created apimservice firewall: $($fw.Name)"
Write-Host $separator
#endregion

#region Create Route Table
Write-Host $separator
Write-Host "Creating Route table..."
$routeTableName = "demo-routetable"
$routeTable = Create-AzureRouteTable -routeTableName $routeTableName
Write-Host "Successfully created Route Table: $($routeTable.Name)"
Write-Host $separator
#endregioncls

#region Attach Route Table to subnets
Write-Host $separator
Write-Host "Attach Route table to subnets..."
$vnet = Attach-AzureRouteTableToSubnets -routeTableName $routeTableName `
        -vnetName $vnetName -pubSub "apim" -routeTable $routeTable
Write-Host "Attached Route table to subnets in vnet : $($vnet.Id)"
Write-Host $separator
#endregion

#region Set All traffic route to firewall
$routeTable = Get-AzRouteTable -ResourceGroupName $resourceGroupName -Name $routeTableName
$routeTable | Add-AzRouteConfig -Name "to-firewall" `
    -AddressPrefix "0.0.0.0/0" -NextHopType VirtualAppliance -NextHopIpAddress $fw.IpConfigurations[0].PrivateIPAddress
$routeTable | Set-AzRouteTable
#endregion

#region Configure Firewall rules
Invoke-Expression -Command "$($templatePath)\Configure-FirewallRules.ps1 -fwName $($fwName) -rgName $($resourceGroupName) -location $($location) -workspaceId $($publicIpWorkspaceId)"
#endregion

#region Set Service tag to Route table in case of Public IP Workspace to avoid asymmetric routing
$routeTable = Get-AzRouteTable -ResourceGroupName $resourceGroupName -Name $routeTableName
$routeTable | Add-AzRouteConfig -Name "ApiManagementTraffic" -AddressPrefix "ApiManagement" -NextHopType "Internet"
$routeTable | Set-AzRouteTable
#endregion

#region Clean up
if ($cleanup -eq $true){
    Cleanup-Resources -resourceGroupName $resourceGroupName
}
#endregion
