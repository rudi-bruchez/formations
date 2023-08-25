# 1. installer Azure Powershell si nécessaire

Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
Install-Module -Name Az -Repository PSGallery -Force
# pour mettre à jour
Update-Module -Name Az -Force

# Se connecter au compte Azure
Connect-AzAccount

Get-AzSubscription | Format-List Id

$SubscriptionId = '31d345c7-a174-41fb-838b-53e961139f47'
$resourceGroupName = "Formation"

Get-AzLocation | Where-Object DisplayName -eq "West Europe" | Format-List Location

$location = "westeurope"

$adminSqlLogin = "adminsql"
$password = "mot de passe"
$serverName = "formation-linkedin-learning"
$databaseName = "pacha2"

$startIp = "0.0.0.0"
$endIp = "0.0.0.0"

# Définir l'abonnement 
Set-AzContext -SubscriptionId $subscriptionId 

# Créer le groupe de ressources
$resourceGroup = New-AzResourceGroup -Name $resourceGroupName -Location $location

# Créer le serveur
$server = New-AzSqlServer -ResourceGroupName $resourceGroupName `
    -ServerName $serverName `
    -Location $location `
    -SqlAdministratorCredentials $(New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $adminSqlLogin, $(ConvertTo-SecureString -String $password -AsPlainText -Force))

# Créer une règle de pare-feu
$serverFirewallRule = New-AzSqlServerFirewallRule -ResourceGroupName $resourceGroupName `
    -ServerName $serverName `
    -FirewallRuleName "AllowedIPs" -StartIpAddress $startIp -EndIpAddress $endIp

# Créer une base de données
$database = New-AzSqlDatabase  -ResourceGroupName $resourceGroupName `
    -ServerName $serverName `
    -DatabaseName $databaseName `
    -RequestedServiceObjectiveName "S0" `
    -SampleName "AdventureWorksLT"
