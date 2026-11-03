# Un client qui traite chaque ligne avant de demander la suivante : une boucle
# applicative, ou Access qui parcourt un jeu d'enregistrements. Le serveur a les
# lignes et attend que le client les consomme : ASYNC_NETWORK_IO.
#
#   .\client-ligne-a-ligne.ps1                     # 20 ms par ligne, pendant 5 minutes
#   .\client-ligne-a-ligne.ps1 -PauseMs 0          # le même client sans traitement, pour comparer
param(
    [string]$Serveur = 'localhost',
    [string]$Base = 'PachaDataFormation',
    [string]$Utilisateur = '',
    [string]$Requete = 'SELECT * FROM Contact.ProspectUS;',
    [int]$PauseMs = 20,      # temps de traitement par ligne côté client
    [int]$Minutes = 5        # arrêt au bout de cette durée, même si toutes les lignes ne sont pas lues
)
. "$PSScriptRoot\connexion.ps1"
$cn = New-Object System.Data.SqlClient.SqlConnection (Get-ChaineConnexion $Serveur $Base $Utilisateur 'Demo ligne a ligne')
$cn.Open()
$cmd = $cn.CreateCommand(); $cmd.CommandText = $Requete; $cmd.CommandTimeout = 0
$sw = [Diagnostics.Stopwatch]::StartNew()
$r = $cmd.ExecuteReader()
$n = 0
while ($r.Read()) {
    $n++
    if ($PauseMs -gt 0) { Start-Sleep -Milliseconds $PauseMs }
    if ($n % 1000 -eq 0) { Write-Host ("{0} lignes lues en {1:N0} s" -f $n, $sw.Elapsed.TotalSeconds) }
    if ($sw.Elapsed.TotalMinutes -ge $Minutes) { $cmd.Cancel(); break }
}
$r.Close()
$duree = $sw.Elapsed.TotalSeconds
$cmd.CommandText = "SELECT wait_time_ms, waiting_tasks_count FROM sys.dm_exec_session_wait_stats " +
                   "WHERE session_id = @@SPID AND wait_type = N'ASYNC_NETWORK_IO';"
$r = $cmd.ExecuteReader()
if ($r.Read()) { $ms = $r[0]; $nb = $r[1] } else { $ms = 0; $nb = 0 }
$r.Close(); $cn.Close()
Write-Host ("{0} lignes en {1:N1} s ; ASYNC_NETWORK_IO : {2} ms en {3} attentes" -f $n, $duree, $ms, $nb)
