# Script assumes you have already logged your PowerShell session into Azure.
# But if not, run  Connect-AzAccount (or  Connect-AzAccount), just one time.

#Connect-AzAccount;   # Same as  Connect-AzAccount.


# Ensure the current date is between
# the Expiry and Start time values that you edit here.

$resourceGroupName   = 'Formation';

$policySasExpiryTime = '2018-08-28T23:44:56Z';
$policySasStartTime  = '2017-10-01';

$storageAccountLocation = 'westeurope';
$storageAccountName     = 'sql_storage';
$containerName          = 'xevents';
$policySasToken         = ' ? ';

$policySasPermission = 'rwl';  # Leave this value alone, as 'rwl'.

# On choisit l'abonnement. On peut passer en paramètre le nom de l'abonnement
# avec le paramètre -Subscription
# ou l'identifiant de l'abonnement avec le paramètre
# -SubscriptionId

# $subscriptionName = 'YOUR_SUBSCRIPTION_NAME';
# Select-AzSubscription -Subscription $subscriptionName;

Set-AzContext -SubscriptionId '31d345c7-a174-41fb-838b-53e961139f47'

# TODO - suppression du compte de stockage s'il existe
# if ($storageAccountName) {
#     Remove-AzStorageAccount `
#         -Name              $storageAccountName `
#         -ResourceGroupName $resourceGroupName;
# }

New-AzStorageAccount `
    -Name              $storageAccountName `
    -Location          $storageAccountLocation `
    -ResourceGroupName $resourceGroupName `
    -SkuName           'Standard_LRS';


# On récupère l'access key

$accessKey_ForStorageAccount = `
    (Get-AzStorageAccountKey `
        -Name              $storageAccountName `
        -ResourceGroupName $resourceGroupName
        ).Value[0];

"`$accessKey_ForStorageAccount = $accessKey_ForStorageAccount";

# The context will be needed to create a container within the storage account.

'Create a context object from the storage account and its primary access key.
';

$context = New-AzStorageContext `
    -StorageAccountName $storageAccountName `
    -StorageAccountKey  $accessKey_ForStorageAccount;

'Create a container within the storage account.
';

$containerObjectInStorageAccount = New-AzStorageContainer `
    -Name    $containerName `
    -Context $context;

'Create a security policy to be applied to the SAS token.
';

New-AzStorageContainerStoredAccessPolicy `
    -Container  $containerName `
    -Context    $context `
    -Policy     $policySasToken `
    -Permission $policySasPermission `
    -ExpiryTime $policySasExpiryTime `
    -StartTime  $policySasStartTime;

'
Generate a SAS token for the container.
';
try {
    $sasTokenWithPolicy = New-AzStorageContainerSASToken `
        -Name    $containerName `
        -Context $context `
        -Policy  $policySasToken;
}
catch {
    $Error[0].Exception.ToString();
}

#-------------- 7 ------------------------

'Display the values that YOU must edit into the Transact-SQL script next!:
';

"storageAccountName: $storageAccountName";
"containerName:      $containerName";
"sasTokenWithPolicy: $sasTokenWithPolicy";

'
REMINDER: sasTokenWithPolicy here might start with "?" character, which you must exclude from Transact-SQL.
';

'
(Later, return here to delete your Azure Storage account. See the preceding  Remove-AzStorageAccount -Name $storageAccountName)';

'
Now shift to the Transact-SQL portion of the two-part code sample!';

# EOFile