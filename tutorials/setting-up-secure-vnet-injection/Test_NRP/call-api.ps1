param(
    [String]$apimServiceId,
    [String]$azureManagementUrl = "https://management.azure.com",
    [String]$apiVersion = "2021-04-01-preview"
)

function Get-OutboundNetworkDependenciesAPI {
    $azContext = Get-AzContext
    $azProfile = [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile
    $profileClient = New-Object -TypeName Microsoft.Azure.Commands.ResourceManager.Common.RMProfileClient -ArgumentList ($azProfile)
    $token = $profileClient.AcquireAccessToken($azContext.Subscription.TenantId)
    $authHeader = @{
        'Content-Type'='application/json'
        'Authorization'='Bearer ' + $token.AccessToken
    }

    # Invoke the REST API
    $restUri = "$($azureManagementUrl)$($apimServiceId)/OutboundNetworkDependenciesEndpoints/?api-version=$($apiVersion)"

    Write-Host "ReqUri : " $restUri

    $response = Invoke-RestMethod -Uri $restUri -Method Get -Headers $authHeader

    Write-Host $response.value
    return $response
    
}

return Get-OutboundNetworkDependenciesAPI