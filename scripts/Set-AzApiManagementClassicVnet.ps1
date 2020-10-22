param
(
    [Parameter(Mandatory=$true)]
    [ValidateSet("AzureCloud", "AzureChinaCloud", "AzureUSGovernment", "AzureGermanCloud", "AzureUSSec", "AzureUSNat")]
    [string]$Environment,

    [Parameter(Mandatory = $True)]
    [System.String]
    $SubscriptionId,

    [Parameter(Mandatory = $True)]
    [System.String]
    $ResourceGroup,

    [Parameter(Mandatory = $True)]
    [System.String]
    $ServiceName,

    [Parameter(Mandatory = $True)]
    [System.Int32]
    $Capacity
)

#apiversion
$apiVersion = "2019-12-01"

Write-Host "Connecting to " $Environment
Connect-AzAccount -Environment $Environment 

# switch to subscription
Write-Host "Switching to subscription " $SubscriptionId
Select-AzSubscription -SubscriptionId $SubscriptionId

# get the apim resource
Write-Host "Fetching Api Management resource " $ServiceName
$apimResource = Get-AzResource -ResourceType "microsoft.apimanagement/service" -ResourceGroupName $ResourceGroup -ResourceName $ServiceName -ApiVersion $apiVersion

# update capacity
Write-Host "Updating Capacity from " $apimResource.Sku.Capacity " to " $Capacity
$apimResource.Sku.Capacity =$Capacity

# Execute the operation
$apimResource | Set-AzResource -Force 

Write-Host "Update Completed" 
# get the apim resource
$apimResource = Get-AzResource -ResourceType "microsoft.apimanagement/service" -ResourceGroupName $ResourceGroup -ResourceName $ServiceName -ApiVersion $apiVersion

Write-Host "New Capacity: " $apimResource.Sku.Capacity

