Connect-AzAccount

Get-AzSubscription | Format-List Id

$SubscriptionId = '31d345c7-a174-41fb-838b-53e961139f47'
$SqlMIName = "pachaqslmi"
$ResourceGroupName = "Pacha"

$UriPrefix = "https://management.azure.com/subscriptions/" + $SubscriptionId + "/resourceGroups/" + $RgName + 
"/providers/Microsoft.Sql/managedInstances/"

$UriSuffix = "?api-version=2021-08-01-preview"

Select-AzSubscription -SubscriptionName $SubscriptionID


$azContext = Get-AzContext
$azProfile = [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile
$profileClient = New-Object -TypeName Microsoft.Azure.Commands.ResourceManager.Common.RMProfileClient -ArgumentList ($azProfile)
# Get authentication token
Write-Host "Getting authentication token for REST API call ..."
$token = $profileClient.AcquireAccessToken($azContext.Subscription.TenantId)
$authHeader = @{'Content-Type'='application/json';'Authorization'='Bearer ' + $token.AccessToken}
# Define Instance GET uri
$instanceGetUri = $UriPrefix + $SqlMIName + $UriSuffix