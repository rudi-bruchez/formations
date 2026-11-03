# Chaîne de connexion commune aux deux clients de démonstration.
# Sans -Utilisateur : authentification Windows. Avec : authentification SQL,
# mot de passe lu dans la variable d'environnement SQLCMDPASSWORD.
function Get-ChaineConnexion {
    param([string]$Serveur, [string]$Base, [string]$Utilisateur, [string]$Application)
    $cs = "Server=$Serveur;Database=$Base;TrustServerCertificate=True;Application Name=$Application;"
    if ($Utilisateur) { $cs + "User ID=$Utilisateur;Password=$env:SQLCMDPASSWORD;" }
    else { $cs + "Integrated Security=True;" }
}
