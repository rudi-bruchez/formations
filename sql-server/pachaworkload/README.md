# Workload de PachaDataFormation

`pachaworkload` rejoue sur `PachaDataFormation` le trafic d'une application de gestion de formation : un site public, un back-office, une plateforme e-learning, un outil d'envoi de courriels et des rapports. Ses 49 requêtes sont tirées au sort selon leur poids, sur plusieurs threads qui jouent chacun un utilisateur, avec des paramètres pris dans la base. Chaque application se connecte sous son propre nom et, sur demande, depuis ses propres machines. Le même tir peut viser un serveur ou plusieurs à la fois, par exemple les postes des participants d'une salle de formation.

Le trafic sert à observer une instance qui travaille : cache de plans, Query Store, Extended Events, attentes, blocages, index manquants, et l'effet d'un index ou d'un réglage avant et après.

Écrit le 30 octobre 2026, vérifié le même jour sur `sql2022` (SQL Server 2022, base de référence et copie jetable de la sauvegarde du 26 octobre 2026).

## Contenu du dossier

| Chemin | Rôle |
|---|---|
| `main.go` | le lanceur, un seul fichier |
| `main_test.go` | ses épreuves : lecture de l'en-tête, concaténation des valeurs, nom des postes, fichier de cibles |
| `internal/dotenv/` | lecture du fichier `.env`, copiée de `outils/sylloge` |
| `requetes/` | les 49 requêtes, un fichier `.sql` chacune |
| `observation/` | requêtes et session Extended Events pour regarder ce que le workload laisse sur le serveur |
| `.env.example` | la forme du fichier `.env` |
| `cibles.exemple.txt` | la forme du fichier de serveurs de `-cibles` |
| `LISEZMOI-WINDOWS.txt` | la notice PowerShell jointe à l'archive Windows |

## Prérequis

- Go 1.27 ou plus récent pour compiler. Le binaire produit ne demande rien d'autre.
- Une instance SQL Server qui porte `PachaDataFormation` ou une copie. Le labo de cette machine : conteneur `sql2022` sur le port 11433, `sql2025` sur le port 11533.
- Un identifiant qui peut lire la base, et écrire avec `-ecritures` : `sa` par défaut, ou le compte Windows courant avec `-windows`.

## Télécharger pour Windows

Chaque version est publiée sur la page des releases du dépôt, sous un tag `pachaworkload-vX.Y.Z` : https://github.com/rudi-bruchez/formations/releases. L'archive `pachaworkload_X.Y.Z_windows_amd64.zip` contient l'exécutable, `requetes/`, `observation/`, ce README, les deux fichiers d'exemple et `LISEZMOI-WINDOWS.txt`, la notice PowerShell ; le fichier `pachaworkload_X.Y.Z_checksums.txt` donne sa somme SHA-256. `pachaworkload.exe -version` affiche la version.

Le programme cherche ses requêtes dans `requetes/` à partir du dossier courant : se placer dans le dossier décompressé, ou donner le chemin par `-requetes`.

## Compiler

```bash
cd sql-server/pachaworkload
go build -o pachaworkload .
go test ./...
GOOS=windows GOARCH=amd64 go build -o pachaworkload.exe .     # pour Windows, depuis Linux ou Windows
```

## Publier une version

La release se fait par le workflow `.github/workflows/pachaworkload-release.yml`, au push d'un tag `pachaworkload-v*`. Avant le tag, écrire la section de la version dans `CHANGELOG.md` : elle devient la note de la release, et le workflow refuse de publier sans elle. Puis :

```bash
git tag pachaworkload-v1.0.1 && git push origin pachaworkload-v1.0.1
```

Pour relire la note telle qu'elle partira :

```bash
RELEASE_TAG_PREFIX=pachaworkload-v ../../scripts/release-notes.sh 1.0.1 rudi-bruchez/formations \
  pachaworkload_1.0.1_checksums.txt CHANGELOG.md
```

## Mot de passe et connexion

Le mot de passe se lit, dans cet ordre, dans `SQLCMDPASSWORD` puis dans `MSSQL_SA_PASSWORD`. Les deux viennent de l'environnement ou d'un fichier `.env`, désigné par `-env`. Une variable déjà présente dans l'environnement l'emporte sur le fichier. Un fichier absent est ignoré, sans message.

Par défaut, `-env` lit `.env` dans le dossier courant : copier `.env.example` en `.env` et le remplir. Le `.env` est ignoré par git.

`WORKLOAD_USER` change l'identifiant (`sa` par défaut).

Sous Windows, `-windows` se connecte avec le compte Windows courant (SSPI), sans identifiant ni mot de passe : le compte doit avoir un login sur chaque instance visée, et `WORKLOAD_USER` et le mot de passe sont alors ignorés. Hors de Windows, l'option est refusée (sortie 2). Ajoutée le 3 novembre 2026 : la chaîne de connexion est éprouvée, mais une connexion SSPI réelle n'a pas encore été faite.

La connexion se fait en TLS avec `TrustServerCertificate`, ce qui convient au labo et non à une instance de production.

## Démarrage rapide

En lecture seule, sur la base de référence :

```bash
./pachaworkload -base PachaDataFormation -threads 8 -duree 5m
```

Avec les écritures, sur une copie de la base restaurée sous un autre nom (ici `revue_00000a`) :

```bash
./pachaworkload -base revue_00000a -ecritures -verifier           # chaque requête une fois
./pachaworkload -base revue_00000a -ecritures -threads 16 -postes 12 -duree 10m
```

Le lanceur refuse `-ecritures` sur une base nommée `PachaDataFormation` (sortie 2), sauf avec `-forcer-ecritures`, prévu pour une salle où chaque `PachaDataFormation` est la copie d'un participant.

Un tir en lecture seule ne modifie pas les données, mais il remplit le Query Store et le cache de plans de la base visée ; la sauvegarde de référence n'est pas touchée. Après un tir sur la base de référence : `ALTER DATABASE PachaDataFormation SET QUERY_STORE CLEAR`, qui efface tout l'historique du Query Store et pas seulement celui du tir. Fait le 30 octobre 2026 sur `sql2022` et `sql2025` après les tirs de vérification.

## Options

| Option | Défaut | Effet |
|---|---|---|
| `-base` | (obligatoire) | base visée ; avec `-cibles`, base par défaut des lignes qui n'en donnent pas |
| `-serveur` | `localhost:11433` | `hôte:port` ; `localhost:11533` pour `sql2025` |
| `-cibles` | | fichier de serveurs visés, une ligne `hôte:port [base]` par serveur ; remplace `-serveur` (section « Plusieurs serveurs ») |
| `-env` | `.env` | fichier où lire le mot de passe |
| `-windows` | | authentification Windows avec le compte courant, Windows seulement |
| `-version` | | affiche la version et quitte |
| `-requetes` | `requetes` | dossier des fichiers `.sql` |
| `-threads` | 8 | utilisateurs simultanés, par serveur visé |
| `-duree` | 5m | durée du tir, au format Go : `30s`, `10m`, `1h30m` |
| `-pause` | 200ms | après chaque requête, un thread attend une durée tirée entre 0 et cette valeur ; `0` charge au maximum |
| `-postes` | 0 | simule des machines clientes (section suivante) ; 0 garde le vrai nom de la machine |
| `-ecritures` | non | inclut les requêtes qui écrivent |
| `-forcer-ecritures` | non | lève le refus de `-ecritures` sur une base nommée `PachaDataFormation`, pour les copies des participants d'une salle |
| `-adhoc` | non | envoie toutes les requêtes en texte, valeurs concaténées, au lieu de `sp_executesql` |
| `-longueurs-variables` | non | déclare les chaînes à la longueur de chaque valeur, comme le pilote par défaut |
| `-appli` | | ne garde que les requêtes d'une application |
| `-filtre` | | expression régulière sur le nom des fichiers, sans `.sql` |
| `-graine` | horloge | rend le tirage reproductible ; même graine, même suite de requêtes et de paramètres par thread |
| `-timeout` | 2m | durée maximale d'une requête, au-delà elle est annulée et comptée en erreur |
| `-verifier` | | exécute chaque requête une fois, dans l'ordre, et sort en 1 si l'une échoue |
| `-liste` | | liste les requêtes retenues, leur application, leur poids et leur part, sans se connecter |

`-appli`, `-filtre` et `-ecritures` se combinent avec `-liste` et `-verifier` : `./pachaworkload -liste -appli backoffice -ecritures` montre ce qu'un tir de cette forme exécuterait.

Ctrl-C arrête le tir proprement et affiche le bilan.

## Plusieurs serveurs

Dans une salle de formation, chaque participant a son instance, et le formateur lance le trafic sur toutes depuis son poste :

```bash
./pachaworkload -cibles salle.txt -base PachaDataFormation -threads 6 -postes 8 -duree 20m
```

`salle.txt` donne un serveur par ligne, `hôte:port`, suivi d'une base quand elle diffère de `-base` ; `cibles.exemple.txt` en donne la forme.

Chaque serveur reçoit le tir complet : ses `-threads` threads, ses connexions, ses machines simulées et ses propres réserves de paramètres, lues sur ses données, qui peuvent avoir divergé après les manipulations du participant. Seize serveurs à six threads font 96 threads, ce que le lanceur tient sans peine : un thread est une goroutine Go. La limite est plutôt la machine qui lance et le réseau de la salle.

Au démarrage, chaque serveur est contacté (dix secondes au plus). Un serveur injoignable est écarté avec son message d'erreur et le tir continue sur les autres. Une instance qui tombe pendant le tir n'est pas écartée : ses requêtes sont comptées en erreur ; la reprise après son redémarrage n'a pas été essayée.

Le bilan rassemble les requêtes de tous les serveurs, puis ajoute une ligne par serveur :

```text
cible                                        exéc.  erreurs  par sec.
localhost:11433 PachaDataFormation             824        0      27.5
localhost:11533 PachaDataFormation             857        0      28.6
```

`-verifier` passe chaque requête sur chaque serveur, l'un après l'autre, sous un titre `== serveur base`.

Ce que les instances des participants doivent accepter :

- l'authentification SQL Server (mode mixte), avec le même identifiant et le même mot de passe partout : le lanceur n'en connaît qu'un ;
- les connexions TCP depuis le réseau, sur le port donné (1433 par défaut pour une instance par défaut), pare-feu Windows compris ;
- pour une instance nommée, un port fixe, donné dans le fichier : le lanceur n'accepte que `hôte:port`, pas `hôte\instance`.

Le refus de `-ecritures` sur une base nommée `PachaDataFormation` vaut pour chaque ligne. Il protège la base de référence du labo ; dans une salle, où chaque `PachaDataFormation` est la copie d'un participant, `-forcer-ecritures` le lève. Les écritures modifient alors les bases des participants : les restaurer depuis la sauvegarde avant l'exercice suivant.

## Applications et machines simulées

Chaque application ouvre ses propres connexions, sous le nom `PachaFormation-<appli>`. Ce nom apparaît dans `program_name` de `sys.dm_exec_sessions`, dans `APP_NAME()` et dans l'action `client_app_name` des Extended Events.

Avec `-postes N`, chaque thread déclare aussi un nom de machine, que SQL Server affiche sans le vérifier : `host_name` de `sys.dm_exec_sessions`, `HOST_NAME()`, l'action `client_hostname`, la colonne HostName de `sp_who2` et du Moniteur d'activité. Le back-office se connecte depuis `N` postes de bureau, les autres applications depuis un petit nombre de serveurs :

| Application | Machines avec `-postes N` | Requêtes | Part du tirage | Caractère |
|---|---|---|---|---|
| `portail` | `SRV-WEB-01` à `SRV-WEB-04` | 12 | 49 % | lectures courtes et fréquentes, deux écritures |
| `backoffice` | `PC-BUREAU-01` à `PC-BUREAU-N` | 15 | 25 % | recherches, comptes clients, quatre écritures transactionnelles |
| `elearning` | `SRV-LMS-01` et `SRV-LMS-02` | 5 | 15 % | lectures par clé, une écriture sérialisée, un balayage de 7,8 millions de lignes |
| `marketing` | `SRV-MAILING-01` | 4 | 6 % | mises à jour par clé, campagnes de taille très inégale |
| `rapports` | `SRV-RAPPORTS-01` | 13 | 5 % | agrégats lourds, anti-modèles, un traitement de nuit |

Le thread numéro `w` prend la machine `w modulo nombre de machines` : avec 16 threads et `-postes 6`, chaque poste de bureau sert deux ou trois threads, et chaque serveur web quatre. Moins de postes que de threads revient donc à plusieurs utilisateurs sur un même poste. Une application qui n'est pas dans ce tableau se connecte depuis `POSTE-<APPLI>-01` à `-NN`. Le tableau des machines est la variable `parc` de `main.go`.

L'adresse IP, elle, ne se simule pas : `client_net_address` est l'adresse réelle de la connexion. Depuis podman, toutes les connexions arrivent de la passerelle du conteneur.

Chaque couple application et machine a son pool de connexions, qui garde deux connexions ouvertes entre deux requêtes, comme le pool d'une application. Mesuré le 30 octobre 2026, 16 threads et `-postes 6` : 14 couples, deux sessions chacun, six pour `SRV-RAPPORTS-01`.

## Paramètres et cache de plans

Par défaut, une requête qui a des paramètres part par `sp_executesql`, comme une application qui paramètre. Trois réglages changent ce qu'en voit le cache :

- `mode: adhoc` dans l'en-tête d'un fichier envoie toujours cette requête en texte, valeurs concaténées. Deux requêtes le font : `portail-06-connexion-email` et `rapports-11-ventes-du-jour`.
- `-adhoc` fait de même pour toutes les requêtes du tir.
- `-longueurs-variables` déclare chaque chaîne à la longueur de sa valeur (`varchar(6)` pour Simon, `varchar(7)` pour Martin), ce que font le pilote Go par défaut et `AddWithValue` en .NET : un plan par longueur. Sans l'option, les chaînes sont déclarées `varchar(max)` ou `nvarchar(max)`, une seule déclaration par requête ; la recherche par nom reste un `Index Seek` dans `nix_contact_nom` (vérifié le 30 octobre 2026).

Les paramètres sont toujours déclarés dans l'ordre alphabétique de leur nom : la déclaration fait partie du texte, donc de la clé du cache.

Les dates partent en `varchar` au format `AAAAMMJJ`, et SQL Server les convertit vers la colonne `date`.

## Lire le bilan

Toutes les dix secondes, le lanceur écrit sur la sortie d'erreur le temps écoulé et le nombre d'exécutions. À la fin, sur la sortie standard :

```text
requête                                      exéc. erreurs   moy. ms    p95 ms    max ms
backoffice-01-contacts-par-nom                 573       0      27.9      50.1     510.0
...
11712 exécutions en 2m0s, 97.6 par seconde
dernière erreur de backoffice-14-annuler : mssql: L'inscription est déjà annulée.
```

Les durées sont mesurées côté client, lecture complète des résultats comprise : elles incluent le réseau et l'attente d'une connexion. Une requête interrompue par la fin du tir n'est pas comptée.

Les erreurs métier sont attendues sous charge : une inscription déjà annulée par un autre thread (50112), un trop-perçu quand une même facture est tirée plusieurs fois (50136), une session pleine. Les valeurs des paramètres sont lues une fois au démarrage, alors que l'état de la base change pendant le tir. Une autre erreur, en revanche, signale un défaut de la requête ou de sa réserve : la relancer seule avec `-verifier -filtre <nom>`.

## Observer côté serveur

Le dossier `observation/` contient de quoi regarder un tir en cours :

| Fichier | Ce qu'il rend |
|---|---|
| `observer.sql` | les sessions par application et par machine, les plans en cache par type, les dix requêtes les plus coûteuses en CPU au Query Store sur la dernière heure, les index manquants proposés |
| `xe-rapports-creer.sql` | une session Extended Events `workload_rapports`, en mémoire, limitée aux connexions `PachaFormation-rapports` |
| `xe-rapports-lire.sql` | le contenu de cette session : nombre d'événements et durée moyenne par machine |

`observer.sql` vise `PachaDataFormation` : changer son `USE` pour une copie. La session XE se supprime après usage :

```sql
DROP EVENT SESSION workload_rapports ON SERVER;
```

Ce qu'ils ont rendu le 30 octobre 2026, après quelques tirs sur `sql2022` : les quatre premiers index manquants proposés étaient ceux que le workload laisse exprès (`Inscription.Inscription (ContactId)`, `Contact.Contact (Email)`, `Inscription.SuiviFacture (FactureCd)`, `Contact.Contact (SocieteId)`), et la session XE filtrée n'a reçu que des événements de `SRV-RAPPORTS-01`.

Depuis un shell du labo, sans SSMS :

```bash
set -a; . ./.env; set +a
podman exec -i -e SQLCMDPASSWORD sql2022 \
  /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -C -W -i /dev/stdin < observation/observer.sql
```

## Ce que les requêtes montrent

Les requêtes saines servent de fond : fiches par clé, sommaires, plannings par plage de dates. Les problèmes posés exprès :

| Requête | Problème |
|---|---|
| `portail-06-connexion-email` | valeurs concaténées dans le texte, et aucun index sur `Contact.Email` |
| `portail-07-mes-inscriptions`, `portail-08-mes-factures`, `backoffice-09-contacts-societe` | pas d'index sur les colonnes `ContactId` et `SocieteId` des clés étrangères |
| `portail-12-villes` | `LIKE 'abc%'` sans index sur `NomVille` |
| `portail-04-recherche-mot`, `backoffice-08-facture-par-reference` | `LIKE '%mot%'`, joker en tête |
| `backoffice-01-contacts-par-nom` | détection de paramètres : Simon 782 lignes, la plupart des noms une ou deux |
| `backoffice-02-contacts-par-nom-unicode` | paramètre `nvarchar` sur une colonne `varchar` |
| `backoffice-05-recherche-sessions` | paramètres facultatifs `(Col = @p OR @p IS NULL)` |
| `backoffice-12-dernier-envoi-societe`, `elearning-05-activites-page`, `rapports-08`, `rapports-09`, `rapports-12`, `rapports-13` | les versions lentes des paires `Demo.*` ; les versions corrigées existent dans la base |
| `elearning-03-reprendre` | le tas `Elearning.Activite` lu en entier à chaque appel |
| `elearning-04-enregistrer-activite` | `MAX + 1` sous `UPDLOCK, HOLDLOCK` : tous les écrivains attendent les uns derrière les autres |
| `marketing-02-statistiques-campagne`, `marketing-03-envois-campagne` | campagnes de quelques envois à des centaines de milliers : plan répartiteur (PSP) |
| `rapports-06-lecteurs-perdus` | fonctions de fenêtrage sur quatre millions de lignes, parallélisme et octroi de mémoire |
| `rapports-11-ventes-du-jour` | date concaténée sur une table seule, que le paramétrage simple ne reprend pas |

Le commentaire en tête de chaque fichier dit ce que la requête fait et, le cas échéant, ce qu'elle montre.

## Scénarios

- Ligne de base et index : un tir de dix minutes, puis l'index sur `Inscription.Inscription (ContactId)` ou sur `Contact.Email`, un second tir, et la comparaison des deux périodes dans le Query Store (rapport « Requêtes régressées » de SSMS, ou `observer.sql` après chaque tir).
- Cache de plans : le même tir avec et sans `-adhoc`, puis avec `optimize for ad hoc workloads` ou `PARAMETERIZATION FORCED`, en comptant les plans `Adhoc` à usage unique dans `observer.sql`. Avec `-longueurs-variables`, compter les plans `Prepared` par texte.
- Blocages : `-appli elearning -ecritures -threads 32 -pause 0` pour ne garder que l'e-learning et observer la chaîne d'attente de `elearning-04` (`sys.dm_os_waiting_tasks`, rapport `blocked_process_report`).
- Détection de paramètres : `-filtre backoffice-01 -threads 4`, vider le cache entre deux tirs (`ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE`), et comparer les plans selon le premier nom compilé.
- Isoler une application ou un poste : `xe-rapports-creer.sql`, ou un filtre sur `client_hostname = N'PC-BUREAU-03'` dans une session Extended Events, pour suivre un utilisateur au milieu des autres.
- Fond de démonstration : un tir en lecture seule sur `PachaDataFormation` pendant un cours, pour que l'instance ne soit pas au repos.
- Comparaison de versions : la même graine sur `sql2022` (`-serveur localhost:11433`) et `sql2025` (`-serveur localhost:11533`), pour rejouer la même suite de requêtes et de paramètres sur les deux.

Douze exercices guidés dans les rapports du Query Store, avec leur corrigé mesuré : `sql-server/exercices/performances/query-store-rapports-workload.md`.

## Écrire une requête

Un fichier dans `requetes/`, nommé `<appli>-NN-<objet>.sql`. L'en-tête est fait de commentaires `-- clé: valeur` ; les autres lignes, commentaires compris, forment le corps envoyé au serveur.

```sql
-- appli: portail
-- poids: 20
-- ecriture: oui
-- mode: adhoc
-- param: @StageId int, @LangueCd char = SELECT StageId, LangueCd FROM Stage.StageLangue
-- param: @Jour date = SELECT DISTINCT DateDebut FROM Stage.Session WHERE DateDebut > '20261018'
-- Commentaire libre : ce que la requête montre.
SELECT ... WHERE s.StageId = @StageId AND sl.LangueCd = @LangueCd AND se.DateDebut >= @Jour;
```

| Clé | Défaut | Rôle |
|---|---|---|
| `appli` | `portail` | l'application qui l'envoie ; fixe le nom de connexion et les machines |
| `poids` | 1 | fréquence relative du tirage, entier positif ou nul ; 0 la garde pour `-verifier` sans la tirer |
| `ecriture` | `non` | `oui` : modifie la base, exclue sans `-ecritures` |
| `mode` | | `adhoc` : toujours envoyée en texte, valeurs concaténées |
| `param` | | un ou plusieurs paramètres, leur type, et la requête qui fournit leurs valeurs |

La requête de réserve d'un `param` rend autant de colonnes que la ligne déclare de paramètres, dans le même ordre. À chaque exécution, une ligne est tirée et ses colonnes donnent leurs valeurs aux paramètres : plusieurs paramètres sur une même ligne `param` restent donc cohérents entre eux. Des lignes `param` distinctes sont tirées indépendamment. Une réserve est lue une fois, au premier tirage, et plafonnée à 20 000 lignes ; sur une grande table, `TABLESAMPLE` évite de lire toujours les mêmes premières lignes (`marketing-01-ouverture`). Une réserve vide est une erreur.

Types reconnus : `int`, `bigint`, `decimal`, `bit`, `varchar`, `char`, `date`, `nvarchar`. Tout type inconnu part en `varchar`.

Le corps peut contenir plusieurs instructions et rendre plusieurs résultats, que le lanceur lit en entier. Un paramètre de sortie se déclare dans le corps (`marketing-04-creer-campagne`). Une requête qui ouvre une transaction commence par `SET XACT_ABORT ON`, pour qu'une erreur ne rende pas au pool une connexion avec une transaction ouverte.

La date du jour des données est le 18 octobre 2026, figée dans les procédures de la base : écrire `'20261018'` et non `GETDATE()` dans une requête qui en dépend.

Avant de l'ajouter au tir :

```bash
./pachaworkload -liste -ecritures -filtre <nom>
./pachaworkload -base revue_00000a -ecritures -verifier -filtre <nom>
```

## Dépannage

| Message | Cause |
|---|---|
| `mot de passe absent` | ni `SQLCMDPASSWORD` ni `MSSQL_SA_PASSWORD`, ni dans l'environnement ni dans le fichier `-env`, qui est peut-être absent ou mal nommé ; sous Windows, `-windows` s'en passe |
| `-windows ne fonctionne que sous Windows` | l'option a été donnée sous Linux ou macOS |
| `aucune requête retenue` | `-filtre`, `-appli` ou l'absence de `-ecritures` ont tout exclu, ou `-requetes` ne pointe pas sur le bon dossier |
| `refus : <serveur>, les écritures ne tournent pas sur la base de référence` | `-ecritures` sur `PachaDataFormation` ; restaurer une copie, ou ajouter `-forcer-ecritures` si ce n'est pas la référence |
| `réserve de @X : réserve vide` | la requête de réserve ne rend aucune ligne sur cette base |
| `réserve de @X : 1 colonnes pour 2 paramètres` | la requête de réserve rend moins de colonnes que la ligne `param` ne déclare de paramètres |
| `unable to open tcp connection ... connection refused` | l'instance est arrêtée (`podman start sql2022`) ou le port est faux |
| `cible écartée, <serveur> <base> : ...` | ce serveur n'a pas répondu au démarrage ; le tir continue sans lui |
| `aucune cible joignable` | aucun serveur du fichier n'a répondu |
| `<fichier>, ligne N : « hôte:port [base] » attendu` | une ligne de `-cibles` a plus de deux champs, ou pas de base ni de `-base` |
| `context deadline exceeded` | la requête a dépassé `-timeout` |
| `toutes les requêtes retenues ont un poids nul` | le filtre n'a gardé que des requêtes de poids 0, que seul `-verifier` exécute |

## Mesures du 30 octobre 2026

Sur `sql2022`.

- `-verifier`, écritures comprises, sur une copie : 49 requêtes sur 49 sans erreur, après correction de deux réserves (`backoffice-14` tirait des inscriptions déjà suivies en e-learning, refusées par 50117 ; `backoffice-15` des sessions confirmées, alors que seule une session terminée se facture).
- Tir de 2 minutes à 16 threads, écritures comprises : 11 712 exécutions, 97,6 par seconde, 16 erreurs, toutes « L'inscription est déjà annulée ». Les plus longues en moyenne : `rapports-06-lecteurs-perdus` 8,2 s, `marketing-04-creer-campagne` 2,2 s, `rapports-08-ca-par-stage-lente` 1,0 s, `backoffice-14-annuler` 0,9 s, `elearning-03-reprendre` 0,6 s.
- Cache de plans après ce tir : 514 plans `Adhoc` pour 517 exécutions de `portail-06-connexion-email`, 84 pour 84 de `rapports-11-ventes-du-jour`.
- Avec la déclaration à longueur variable, 37 plans pour la seule mise à jour de coordonnées et 15 pour la recherche par nom. Avec `varchar(max)` et l'ordre fixe des paramètres, 43 plans `Prepared` pour 37 requêtes paramétrées : quatre viennent de `marketing-02` (plan répartiteur et variantes), deux d'un même texte de `backoffice-05-recherche-sessions`, cause non cherchée.

- Plusieurs serveurs : `sql2022`, `sql2025` et un port fermé, 4 threads chacun, 30 secondes en lecture seule. Le port fermé a été écarté au démarrage ; 824 et 857 exécutions sans erreur sur les deux autres. `-verifier` sur les deux : sans échec.

Non mesuré : le lanceur sur Windows, des serveurs sur d'autres machines du réseau, une salle entière, un tir de plus de deux minutes, la croissance de la base pendant un long tir avec écritures.
