# Attentes ASYNC_NETWORK_IO

Deux clients PowerShell qui reproduisent ce qu'une table liée Access fait à SQL Server, et
un script SSMS pour l'observer. L'attente `ASYNC_NETWORK_IO` vient du client, pas du serveur :
SQL Server a les lignes, et le client ne les consomme pas. On ne la reproduit donc qu'avec un
vrai client, d'où PowerShell.

Base : `PachaDataFormation`, table `Contact.ProspectUS` (un million de lignes). Une autre
requête se passe par `-Requete`.

## Les fichiers

| Fichier | Rôle |
|---|---|
| `table-liee-ouverte.ps1` | lit un écran de 40 lignes puis plus rien, jusqu'à Entrée ou pendant `-Minutes` |
| `client-ligne-a-ligne.ps1` | traite chaque ligne (20 ms) avant de demander la suivante, pendant `-Minutes` (5 par défaut), puis affiche sa propre attente |
| `observer.sql` | la requête et son attente, le cumul par session, les verrous, et un `ALTER TABLE` qui reste bloqué |
| `connexion.ps1` | chaîne de connexion commune |

## Déroulé

Dans une fenêtre PowerShell :

```powershell
.\table-liee-ouverte.ps1                    # authentification Windows, serveur local
.\table-liee-ouverte.ps1 -Minutes 15        # se ferme seule au bout d'un quart d'heure
.\table-liee-ouverte.ps1 -Serveur 'localhost,11433' -Utilisateur sa   # mot de passe dans $env:SQLCMDPASSWORD
```

Puis, dans SSMS, `observer.sql` requête par requête :

1. la session est `suspended` sur `ASYNC_NETWORK_IO` aussi longtemps que la table reste ouverte ;
2. `wait_time` reste court (moins de deux secondes), alors que le cumul de
   `sys.dm_exec_session_wait_stats` suit l'horloge : c'est le cumul qui dit combien de temps le
   client a bloqué la requête ;
3. la session tient un `Sch-S` sur la table ;
4. l'`ALTER TABLE` échoue sur l'erreur 1222 au bout de cinq secondes : un utilisateur parti
   déjeuner avec sa table liée ouverte bloque une modification de structure. L'`ALTER` est dans
   une transaction annulée, la table n'est jamais modifiée.

Pour la comparaison, `client-ligne-a-ligne.ps1`, puis le même avec `-PauseMs 0` : l'attente
n'est jamais nulle, ce qui compte est sa part dans la durée.

## Mesuré

Le 3 novembre 2026, SQL Server 2022 CU26 sous Linux (conteneur), client PowerShell 7 sur la
même machine, base avec `READ_COMMITTED_SNAPSHOT` actif :

| Cas | Durée | `ASYNC_NETWORK_IO` cumulée |
|---|---|---|
| Table liée ouverte | observée à 100 s | 104 s en 54 attentes |
| Ligne à ligne, 20 ms par ligne | 2 962 lignes en 60 s | 60 s en 32 attentes |
| Sans pause | 1 000 000 lignes en 1,4 s | 0,4 s en 26 attentes |

Un `UPDATE` sur la table passe pendant que la table liée est ouverte, parce que la base est en
RCSI. Le cas d'une base sans RCSI n'a pas été mesuré.

Les scripts n'ont pas été lancés sous Windows PowerShell 5.1 ; ils n'emploient que
`System.Data.SqlClient`, présent dans les deux.
