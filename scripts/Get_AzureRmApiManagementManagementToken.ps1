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

$sub = Select-AzureRmSubscription -SubscriptionId $subscriptionId

$context = New-AzureRmApiManagementContext -ResourceGroupName $ResourceGroup -ServiceName $ServiceName
$expiry = (Get-Date).ToUniversalTime() + $ExpiryTimespan

$parameters = @{
    "keyType"= $KeyType
    "expiry"= ('{0:yyyy-MM-ddTHH:mm:ss.000Z}' -f $expiry)
}


$managementAccess = Get-AzureRmApiManagementTenantAccess -Context $context
$userId = $managementAccess.Id

$resourceName = $ServiceName + "/" +$userId

$managementToken = Invoke-AzureRmResourceAction  -ResourceGroupName $ResourceGroup -ResourceType 'Microsoft.ApiManagement/service/users' -Action 'token' -ResourceName $resourceName -ApiVersion "2017-03-01" -Parameters $parameters -Force

return @{
Token='SharedAccessSignature ' + $managementToken.value
}

