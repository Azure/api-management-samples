param
(
    [Parameter(Mandatory=$true)]
    [string]$environment,

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
    [System.Int]
    $capacity
)

#apiversion
$apiVersion = "2019-12-01"

Connect-AzAccount -Environment $environment 

# switch to subscription
Select-AzSubscription -SubscriptionId $SubscriptionId

# get the apim resource
$apimResource = Get-AzResource -ResourceType "microsoft.apimanagement/service" -ResourceGroupName $ResourceGroup -ResourceName $ServiceName -ApiVersion $apiVersion

# update capacity
$apimResource.Sku.Capacity =$capacity

# Execute the operation
$apimResource | Set-AzResource -Force 

