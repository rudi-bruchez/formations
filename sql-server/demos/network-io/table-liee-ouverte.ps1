# Une table liée Access laissée ouverte : le client lit le premier écran de
# lignes, puis plus rien. Côté serveur, la requête reste en cours, en attente
# ASYNC_NETWORK_IO, et garde son verrou Sch-S sur la table.
#
#   .\table-liee-ouverte.ps1                       # jusqu'à ce qu'on appuie sur Entrée
#   .\table-liee-ouverte.ps1 -Minutes 10           # se ferme seul au bout de dix minutes
#   .\table-liee-ouverte.ps1 -Serveur 'localhost,11433' -Utilisateur sa
param(
    [string]$Serveur = 'localhost',
    [string]$Base = 'PachaDataFormation',
    [string]$Utilisateur = '',
    [string]$Requete = 'SELECT * FROM Contact.ProspectUS;',
    [int]$Lignes = 40,       # un écran de feuille de données
    [int]$Minutes = 0        # 0 : attendre la touche Entrée
)
. "$PSScriptRoot\connexion.ps1"
$cn = New-Object System.Data.SqlClient.SqlConnection (Get-ChaineConnexion $Serveur $Base $Utilisateur 'Demo table liee')
$cn.Open()
$cmd = $cn.CreateCommand(); $cmd.CommandText = $Requete; $cmd.CommandTimeout = 0
$r = $cmd.ExecuteReader()
for ($i = 0; $i -lt $Lignes -and $r.Read(); $i++) { }
$debut = Get-Date
if ($Minutes -gt 0) {
    Write-Host "$i lignes affichées. Table ouverte pendant $Minutes min (Ctrl+C pour arrêter)."
    while (((Get-Date) - $debut).TotalMinutes -lt $Minutes) {
        Start-Sleep -Seconds 30
        Write-Host ("  ouverte depuis {0:mm\:ss}" -f ((Get-Date) - $debut))
    }
} else {
    Read-Host "$i lignes affichées. Table ouverte : Entrée pour la fermer" | Out-Null
}
$cmd.Cancel()            # sans Cancel, Close() lirait d'abord toutes les lignes restantes
$r.Close(); $cn.Close()
Write-Host ("Fermée après {0:mm\:ss}" -f ((Get-Date) - $debut))
