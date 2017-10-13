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

    [Parameter(Mandatory = $False)]
    [System.String]
    $publisherEmail,

    [Parameter(Mandatory = $False)]
    [System.String]
    $organizationName,

    [Parameter(Mandatory = $False)]
    [System.String]
    $notificationEmail    
)

# Switch to Subscription
$sub = Select-AzureRmSubscription -SubscriptionId $SubscriptionId


$Resource = Get-AzureRmResource -ResourceType "microsoft.apimanagement/service" -ResourceGroupName $ResourceGroup -ResourceName $ServiceName -ApiVersion "2017-03-01"

# update publisherEmail if provided
if (![string]::IsNullOrEmpty($publisherEmail))
{
    $Resource.Properties.publisherEmail = $publisherEmail
}

# update organisationName if provided
if (![string]::IsNullOrEmpty($organizationName))
{
    $Resource.Properties.publisherName = $organizationName
}

# update notificationEmail if provided
if (![string]::IsNullOrEmpty($notificationEmail))
{
    $Resource.Properties.notificationSenderEmail = $notificationEmail
}

# Execute the operation
$Resource | Set-AzureRmResource -Force 



