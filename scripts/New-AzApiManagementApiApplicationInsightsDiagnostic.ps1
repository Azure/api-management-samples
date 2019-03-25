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

    [Parameter(Mandatory = $True)]
    [System.String]
    $loggerId,

    [Parameter(Mandatory = $True)]
    [System.String]
    $instrumentationKey,

    [Parameter(Mandatory = $True)]
    [System.String]
    $apiId   
)

#apiversion
$apiVersion = "2018-06-01-preview"

# switch to subscription
Select-AzSubscription -SubscriptionId $SubscriptionId

$context = New-AzApiManagementContext -ResourceGroupName $ResourceGroup -ServiceName $ServiceName
New-AzApiManagementLogger -Context $context -LoggerId $loggerId -InstrumentationKey $instrumentationKey
$prop = @{
    alwaysLog = "allErrors"
    enableHttpCorrelationHeaders = $True
    loggerId = "/loggers/" + $loggerId
    sampling = @{
        samplingType = "fixed"
        percentage = 50
          }
    }

Get-AzApiManagementLogger -Context $context -LoggerId $loggerId

$resourceId = "/subscriptions/" + $SubscriptionId + "/resourceGroups/" + $ResourceGroup + "/providers/Microsoft.ApiManagement/service/" + $ServiceName + "/apis/" + $apiId + "/diagnostics/applicationinsights"

New-AzResource -ResourceId $resourceId -Properties $prop -ApiVersion $apiVersion -Force
