param
(
    [Parameter(Mandatory = $True)]
    [System.String]
    $SubscriptionId,

    [Parameter(Mandatory = $True)]
    [System.String]
    $ResourceGroup,

    [Parameter(Mandatory = $True)]
    [System.String]
    $ServiceName,

    [Parameter()]
    [ValidateSet('primary','secondary')]
    [System.String]
    $KeyType = 'primary',

    [Parameter()]
    [timespan]
    $ExpiryTimespan = (New-Timespan -Hours 2)
    
)

## Switch to Subscription
$sub = Select-AzureRmSubscription -SubscriptionId $subscriptionId

$context = New-AzureRmApiManagementContext -ResourceGroupName $ResourceGroup -ServiceName $ServiceName
$expiry = (Get-Date).ToUniversalTime() + $ExpiryTimespan

$parameters = @{
    "keyType"= $KeyType
    "expiry"= ('{0:yyyy-MM-ddTHH:mm:ss.000Z}' -f $expiry)
}


$gitAccess = Get-AzureRmApiManagementTenantGitAccess -Context $context
$userId = $gitAccess.Id

$resourceName = $ServiceName + "/" +$userId

$gitUserName = 'apim'
$gitPassword = Invoke-AzureRmResourceAction  -ResourceGroupName $ResourceGroup -ResourceType 'Microsoft.ApiManagement/service/users' -Action 'token' -ResourceName $resourceName -ApiVersion "2017-03-01" -Parameters $parameters -Force

return @{
GitUserName=$gitUserName
GitPassword=$gitPassword.value
}

