$resourceGroupName = "Formation-North"
$location = "northeurope"

$adminSqlLogin = "adminsql"
$password = "Admin1234!"
$serverName = "formation-linkedin-learning-north"

$startIp = "144.2.229.0"
$endIp = "144.2.229.0"

# Définir l'abonnement 
Set-AzContext -SubscriptionId '31d345c7-a174-41fb-838b-53e961139f47'

# Créer le groupe de ressources
New-AzResourceGroup -Name $resourceGroupName -Location $location

# Créer le serveur
New-AzSqlServer -ResourceGroupName $resourceGroupName `
    -ServerName $serverName `
    -Location $location `
    -SqlAdministratorCredentials $(New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $adminSqlLogin, $(ConvertTo-SecureString -String $password -AsPlainText -Force))

# Créer une règle de pare-feu
New-AzSqlServerFirewallRule -ResourceGroupName $resourceGroupName `
    -ServerName $serverName `
    -FirewallRuleName "AllowedIPs" -StartIpAddress $startIp -EndIpAddress $endIp


$database = Get-AzSqlDatabase -DatabaseName "pachadata" `
    -ResourceGroupName "Formation" `
    -ServerName "formation-linkedin-learning"

$database | New-AzSqlDatabaseSecondary `
    -PartnerResourceGroupName $resourceGroupName `
    -PartnerServerName $serverName -AllowConnections "All"