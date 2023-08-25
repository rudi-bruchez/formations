# Définir l'abonnement 
Set-AzContext -SubscriptionId '31d345c7-a174-41fb-838b-53e961139f47'

# On crée une base de données
New-AzSqlDatabase `
    -ResourceGroupName "Formation" `
    -ServerName "formation-linkedin-learning" `
    -DatabaseName "pacha2" `
    -RequestedServiceObjectiveName "S0" `
    -SampleName "AdventureWorksLT"

Get-AzSqlDatabase -ResourceGroupName "Formation" -ServerName "formation-linkedin-learning" | Format-List DatabaseName

Remove-AzSqlDatabase -ResourceGroupName "Formation" -ServerName "formation-linkedin-learning" -DatabaseName "pacha2"