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
    $ExpiryTimespan = (New-Timespan -Hours 2),
        
    [Parameter()]    
    [System.String]
    $UserId = 1 #Administrator UserId
    
)

## Switch to Subscription
$sub = Select-AzureRmSubscription -SubscriptionId $subscriptionId

$context = New-AzureRmApiManagementContext -ResourceGroupName $ResourceGroup -ServiceName $ServiceName
$expiry = (Get-Date).ToUniversalTime() + $ExpiryTimespan

$parameters = @{
    "keyType"= $KeyType
    "expiry"= ('{0:yyyy-MM-ddTHH:mm:ss.000Z}' -f $expiry)
}

$resourceName = $ServiceName + "/" + $UserId

$managementToken = Invoke-AzureRmResourceAction  -ResourceGroupName $ResourceGroup -ResourceType 'Microsoft.ApiManagement/service/users' -Action 'token' -ResourceName $resourceName -ApiVersion "2017-03-01" -Parameters $parameters -Force

$generateSsoUrlResult = Invoke-AzureRmResourceAction  -ResourceGroupName $ResourceGroup -ResourceType 'Microsoft.ApiManagement/service/users' -Action 'generateSsoUrl' -ResourceName $resourceName -ApiVersion "2017-03-01" -Force

## Split the https://apimService1.portal.azure-api.net/signin-sso?token=57127d485157a511ace86ae7%26201706051624%267VY18MlwAom***********2bYr2bDQHg21OzQsNakExQ%3d%3d
$ssoUrl = $generateSsoUrlResult.value.Split("=")[0]

## Url Encode the Token
$urlEncodedToken = [System.Web.HttpUtility]::UrlEncode($managementToken.value) 

## Create the Url
$resultSsoUrl = $ssoUrl + "=" + $urlEncodedToken

return @{
SsoUrl=$resultSsoUrl
}

