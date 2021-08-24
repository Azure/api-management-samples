param(
 [String]$fwName,
 [String]$rgName,
 [String]$location,
 [String]$workspaceId,
 [String]$templatePath = "D:\github\api-management-samples\tutorials\setting-up-secure-vnet-injection\Test_NRP",
 [String[]]$subnetPrefixes = @("10.0.1.0/24") #apim-subnet
)
$separator = "---------------------------------------------------------------------------"

function Get-OutboundNetworkDependencies {
    param(
        [String]$workspaceId
    )
    $fqdnsFromAPI = Invoke-Expression -Command "$($templatePath)\call-api.ps1 -apimServiceId $($workspaceId)"    
    return $fqdnsFromAPI.value
}

function Set-FirewallRules {
    param(
        [Object]$fqdnsFromAPI
    )

    $applicationRules = New-Object -TypeName System.Collections.ArrayList
    $networkRules = New-Object -TypeName System.Collections.ArrayList

    foreach($rule in $fqdnsFromAPI)
    {
        $targetFqdns = New-Object -TypeName System.Collections.ArrayList
        $targetIPs = New-Object -TypeName System.Collections.ArrayList

        foreach($endpoint in $rule.endpoints)
        {
            if($endpoint.PSObject.Properties.Name -contains "domainName") {                
                $targetFqdns.Add($endpoint.domainName) 
            }
            else {                
                $targetIPs.Add($endpoint.endpointDetails[0].ipAddress)
            }
        }
        if($targetFqdns.Count -gt 0) {
            $ruleToSet = New-AzFirewallApplicationRule -Name $rule.category.Replace(' ','') `
             -SourceAddress $subnetPrefixes -TargetFqdn $targetFqdns -Protocol https
            $applicationRules.Add($ruleToSet)
        }
        if($targetIPs.Count -gt 0) {
            $ruleToSet = New-AzFirewallNetworkRule -Name $rule.category.Replace(' ','') `
                -SourceAddress $subnetPrefixes -DestinationAddress $targetIPs `
                -DestinationPort $endpoint.endpointDetails[0].port -Protocol Any
                $networkRules.Add($ruleToSet)
        }

    }

    $fwApplicationRulesGroup = New-AzFirewallApplicationRuleCollection -Name apim-app-rules -Priority 200 -ActionType Allow -Rule $applicationRules -Verbose    

    $fw = Get-AzFirewall -Name $fwName -ResourceGroupName $rgName -Verbose

    $fw.ApplicationRuleCollections.Add($fwApplicationRulesGroup)
    $fw.NetworkRuleCollections = $null

    Set-AzFirewall -AzureFirewall $fw
}

Write-Host $separator
Write-Host "Setting up firewall..."
$fqdns = Get-OutboundNetworkDependencies -workspaceId $workspaceId
Set-FirewallRules -fqdnsFromAPI $fqdns
Write-Host "Sucessfully set up firewall..."
