param
(
    [Parameter(Mandatory=$true)]
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

Connect-AzAccount -Environment $Environment 

# switch to subscription
Select-AzSubscription -SubscriptionId $SubscriptionId

# get the apim resource
$apimResource = Get-AzResource -ResourceType "microsoft.apimanagement/service" -ResourceGroupName $ResourceGroup -ResourceName $ServiceName -ApiVersion $apiVersion

# update capacity
$apimResource.Sku.Capacity =$Capacity

# Execute the operation
$apimResource | Set-AzResource -Force 

