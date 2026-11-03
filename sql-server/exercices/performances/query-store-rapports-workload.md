# Les rapports du Query Store sur une charge applicative

Ces exercices se font dans les rapports du Query Store de SSMS, sur une base `PachaDataFormation` qui a tourné sous `pachaworkload`, le simulateur d'application du dépôt (`sql-server/pachaworkload`, exécutable Windows sur la page des releases). Chaque exercice pose une question qu'un administrateur se pose réellement, dit dans quel rapport chercher et ce qu'il faut régler, puis demande d'expliquer ce qu'on trouve.

Les noms des rapports et des options sont ceux de SSMS en anglais. Le corrigé, en fin de fichier, donne ce qu'un tir de huit minutes a produit le 3 novembre 2026 : vos chiffres seront différents, les requêtes en tête devraient être en grande partie les mêmes.

## Préparation

### Régler le Query Store

Les rapports agrègent les mesures par intervalle. Avec l'intervalle par défaut de 60 minutes, une question sur « les dix dernières minutes » n'a pas de réponse : on règle l'intervalle à une minute pour la durée des exercices.

```sql
ALTER DATABASE PachaDataFormation SET QUERY_STORE CLEAR;
ALTER DATABASE PachaDataFormation SET QUERY_STORE
    (OPERATION_MODE = READ_WRITE, INTERVAL_LENGTH_MINUTES = 1, QUERY_CAPTURE_MODE = ALL);

SELECT actual_state_desc, interval_length_minutes, query_capture_mode_desc, wait_stats_capture_mode_desc
FROM PachaDataFormation.sys.database_query_store_options;
```

`QUERY_CAPTURE_MODE = ALL` garde aussi les requêtes rares et bon marché, ce dont l'exercice 8 a besoin.

### Lancer la charge

Sur votre propre copie de la base, écritures comprises, pendant un quart d'heure :

```powershell
cd C:\pachaworkload
.\pachaworkload.exe -serveur localhost:1433 -base PachaDataFormation -windows -ecritures -forcer-ecritures -threads 12 -postes 6 -duree 15m
```

`-windows` utilise votre session Windows ; sans elle, `sa` et `$env:SQLCMDPASSWORD`. Notez l'heure de début. Les exercices peuvent commencer pendant que le tir tourne : les rapports lisent aussi les mesures que le Query Store n'a pas encore écrites sur disque.

### Trouver les rapports

Dans l'Explorateur d'objets : Bases de données, `PachaDataFormation`, Query Store. Chaque rapport a un bouton Configure, où se choisissent la métrique (CPU Time, Duration, Memory Consumption…), la statistique (Avg, Max, Total…) et la fenêtre de temps (choisir Custom pour une fenêtre précise, par exemple les dix dernières minutes).

Un rapport montre des numéros de requête (`query id`) et de plan (`plan id`). Pour savoir à quelle partie de l'application une requête appartient, lire son texte dans le volet du bas : beaucoup viennent de procédures stockées (`Rapport.*`, `Marketing.*`, `Demo.*`), et le texte suffit le plus souvent à reconnaître le fichier de `requetes/` qui l'a envoyée.

## Exercices

### 1. Le moment le plus chargé

Rapport : Overall Resource Consumption. Configure : fenêtre Custom couvrant le tir, agrégation à la minute.

- À quelle minute le CPU total a-t-il été le plus élevé ?
- Les courbes de durée, de lectures logiques et de nombre d'exécutions ont-elles leur pic à la même minute ? Si non, qu'est-ce que cela dit de la nature de la charge de cette minute-là ?
- Cliquer sur la barre la plus haute : quelles requêtes y apparaissent ?

### 2. La requête qui a consommé le plus de CPU sur les dix dernières minutes

Rapport : Top Resource Consuming Queries. Configure : CPU Time, Total, fenêtre Custom des dix dernières minutes.

- Quelle requête est en tête, et de quelle procédure vient-elle ?
- Passer la statistique de Total à Avg : le classement change-t-il ? Quelle requête monte, laquelle descend, et pourquoi ?

### 3. La requête qui a consommé le plus de mémoire

Même rapport. Configure : Memory Consumption, Max, puis Total, sur les dix dernières minutes.

- Quelle requête a le plus gros octroi de mémoire en une exécution ? Combien ?
- Ouvrir son plan (double-clic sur le plan dans le graphique de droite) : quels opérateurs demandent cette mémoire ?
- Reste-t-elle en tête en Total ? Laquelle prend sa place, et à cause de quoi : la taille de chaque octroi ou le nombre d'exécutions ?

### 4. Ce qui déborde dans tempdb

Même rapport. Configure : Temp DB Memory Used, Max.

- Quelle requête utilise le plus tempdb ? Est-ce la même qu'à l'exercice 3 ?
- Dans son plan réel (le rapport donne le plan estimé : la réexécuter dans SSMS avec le plan réel), l'avertissement de débordement (`Spill`) apparaît-il sur un tri ou un hachage ?

### 5. La requête la plus exécutée

Même rapport. Configure : Execution Count, Total.

- La requête en tête est-elle une requête que l'application envoie ? Lire son texte.
- Comparer son nombre d'exécutions avec le bilan affiché par `pachaworkload` à la fin du tir, qui compte les appels de l'application. Expliquer l'écart.

### 6. Les lectures logiques

Même rapport. Configure : Logical Reads, Total, puis Avg.

- Quelles requêtes lisent le plus de pages au total ?
- En moyenne par exécution, laquelle lit le plus ? Chercher dans son plan l'opérateur responsable (Table Scan, Clustered Index Scan) et l'index qui manque.

### 7. Ce qu'attendent les requêtes

Rapport : Query Wait Statistics. Fenêtre : le tir entier.

- Quelle catégorie d'attente domine ? Cliquer dessus : quelle requête en est la cause principale ?
- Trouver la catégorie Lock : quelles requêtes attendent des verrous ? Lire leur texte et retrouver le motif qui les fait attendre les unes derrière les autres (indice : `MAX(...) + 1`).

### 8. Une requête qui n'en est pas une seule

Le rapport Top Resource Consuming Queries, en Execution Count, montre une longue liste de requêtes exécutées une seule fois dont le texte se ressemble. Les rapports ne regroupent pas ces requêtes ; le T-SQL le fait par `query_hash`, l'empreinte du texte une fois les littéraux retirés :

```sql
USE PachaDataFormation;
SELECT TOP (5) q.query_hash, COUNT(DISTINCT q.query_id) AS requetes, SUM(rs.count_executions) AS executions,
       MIN(LEFT(qt.query_sql_text, 120)) AS exemple
FROM sys.query_store_query AS q
JOIN sys.query_store_query_text AS qt ON qt.query_text_id = q.query_text_id
JOIN sys.query_store_plan AS p ON p.query_id = q.query_id
JOIN sys.query_store_runtime_stats AS rs ON rs.plan_id = p.plan_id
GROUP BY q.query_hash
HAVING COUNT(DISTINCT q.query_id) > 1
ORDER BY requetes DESC;
```

- Combien de requêtes distinctes le Query Store a-t-il enregistrées pour un seul écran de l'application ? Lequel ?
- Pourquoi le paramétrage simple de SQL Server ne les a-t-il pas regroupées ? Quelles corrections sont possibles, côté application et côté serveur ?

### 9. Les requêtes dont la durée varie

Rapport : Queries With High Variation. Configure : Duration, Std Dev.

- Quelles requêtes ont la durée la plus irrégulière ?
- Pour chacune, la variation vient-elle de plusieurs plans (plusieurs points de couleur différente dans le graphique) ou d'un seul plan dont la durée dépend des paramètres ?

### 10. Une requête qui a changé de plan

Rapport : Regressed Queries. Configure : Duration, Avg ; période récente, les cinq dernières minutes ; période de référence, les cinq premières minutes du tir.

- Une requête a-t-elle régressé ? Combien de plans a-t-elle, et à quelle heure le nouveau est-il apparu ?
- Comparer les deux plans (sélectionner les deux points, bouton Compare Plans). Qu'est-ce qui a changé ?
- Qu'est-ce qui a pu provoquer la recompilation au milieu du tir ? Indice : la charge écrit, et le Query Store a aussi capturé des requêtes `SELECT StatMan(...)`.

Si aucune requête n'a régressé, la même question se pose depuis le rapport Tracked Queries sur une requête à deux plans, que ce T-SQL liste :

```sql
USE PachaDataFormation;
SELECT p.query_id, p.plan_id, SUM(rs.count_executions) AS executions,
       CAST(SUM(rs.avg_duration * rs.count_executions) / SUM(rs.count_executions) / 1000 AS decimal(10,1)) AS duree_moy_ms,
       MIN(rs.first_execution_time) AS premiere_execution
FROM sys.query_store_plan AS p
JOIN sys.query_store_runtime_stats AS rs ON rs.plan_id = p.plan_id
WHERE p.query_id IN (SELECT query_id FROM sys.query_store_plan GROUP BY query_id HAVING COUNT(*) > 1)
GROUP BY p.query_id, p.plan_id
ORDER BY p.query_id, premiere_execution;
```

### 11. Forcer le bon plan

Dans Regressed Queries ou Tracked Queries, sur la requête de l'exercice 10 :

- Sélectionner le plan le plus rapide et cliquer sur Force Plan.
- Relancer `pachaworkload` cinq minutes. Dans le rapport Queries With Forced Plans, la requête apparaît-elle ? Sa durée moyenne est-elle revenue à celle du bon plan ?
- Retirer le forçage (Unforce Plan). Pourquoi forcer un plan est-il un pansement et pas une correction ?

### 12. Les variantes de plan selon le paramètre (SQL Server 2022 et plus)

Deux écrans du module de courriels interrogent des campagnes de quelques envois comme de plusieurs centaines de milliers. SQL Server 2022 peut alors compiler plusieurs variantes d'une même requête (optimisation des plans sensibles aux paramètres, PSP). Dans les rapports, chaque variante apparaît comme une requête distincte, dont le texte est celui de la requête suivi d'une clause `OPTION (PLAN PER VALUE(...))` qui dit sa plage de valeurs. Le T-SQL montre le lien :

```sql
USE PachaDataFormation;
SELECT v.parent_query_id, v.query_variant_query_id, v.dispatcher_plan_id,
       LEFT(qt.query_sql_text, 100) AS texte
FROM sys.query_store_query_variant AS v
JOIN sys.query_store_query AS q ON q.query_id = v.parent_query_id
JOIN sys.query_store_query_text AS qt ON qt.query_text_id = q.query_text_id
ORDER BY v.parent_query_id, v.query_variant_query_id;
```

- Combien de variantes pour chaque requête parente ? Ouvrir dans Tracked Queries une variante, puis une autre : les plans diffèrent-ils ?
- Sur SQL Server 2019 ou une base en niveau de compatibilité inférieur à 160, la requête n'a pas de variante : comment le problème se voit-il alors dans les rapports ?

## Remettre la base en état

```sql
ALTER DATABASE PachaDataFormation SET QUERY_STORE CLEAR;
ALTER DATABASE PachaDataFormation SET QUERY_STORE (INTERVAL_LENGTH_MINUTES = 60);
```

Si des écritures ont tourné, restaurer la base avant l'exercice suivant.

## Corrigé

Mesuré le 3 novembre 2026 sur SQL Server 2022 CU26 (conteneur Linux, 22 cœurs), copie de `PachaDataFormation` en niveau de compatibilité 160, `pachaworkload` avec `-ecritures -threads 12 -postes 6 -duree 8m -graine 42` : 24 541 appels de l'application en huit minutes. Les chiffres viennent des vues `sys.query_store_*`, qui alimentent les rapports.

1. Non mesuré à la minute dans ce tir : la réponse dépend de la machine et du tirage des requêtes. À regarder en premier, les minutes où tourne `Rapport.LecteursPerdus`, la requête la plus chère des exercices suivants.
2. `Rapport.LecteursPerdus` (fichier `rapports-06-lecteurs-perdus`, fonctions de fenêtrage sur quatre millions de lignes) : 1 941 s de CPU au total, sept fois la deuxième, la vue `Inscription.vFacture` interrogée par `backoffice-06-factures-societe` (281 s). En moyenne, `Rapport.LecteursPerdus` reste en tête ; les requêtes fréquentes et bon marché disparaissent du haut du classement.
3. Encore `Rapport.LecteursPerdus` : 1,4 Go de mémoire utilisée en une exécution. En deuxième, `Rapport.PerformanceCampagnes` (612 Mo). En Total, `Rapport.LecteursPerdus` reste premier, suivi de `backoffice-06-factures-societe` et de `backoffice-01-contacts-par-nom` : de petits octrois, mais nombreux.
4. `Rapport.LecteursPerdus`, 541 Mo de tempdb en une exécution : malgré son gros octroi, la requête déborde. Les suivantes n'en utilisent que 3 Mo.
5. Le `FETCH` du curseur de `Demo.ChiffreAffairesParStage_Lente` (`rapports-08-ca-par-stage-lente`) : 7,4 millions d'exécutions pour 67 appels de l'application. Chaque `FETCH` est une exécution, une par ligne lue ; la version corrigée, `Demo.ChiffreAffairesParStage_Corrigee`, existe dans la base pour comparer.
6. En total, l'`INSERT Marketing.Envoi ... SELECT` de `Marketing.CreerCampagne` (43,9 millions de lectures logiques), puis le curseur de l'exercice 5 (29,9 millions) et `Demo.ActivitesPage_Lente` (19,9 millions, pagination par `OFFSET` sur le tas `Elearning.Activite`).
7. Parallelism domine, de loin (3 787 s), presque entièrement par `Rapport.LecteursPerdus` (2 904 s) : des attentes de threads parallèles qui s'attendent entre eux, pas un manque de ressource. Memory suit (536 s), encore `Rapport.LecteursPerdus`, qui attend son octroi. En Lock, `Marketing.EnregistrerOuverture` (44 s) et `Marketing.CreerCampagne` (41 s), dont le `SELECT ISNULL(MAX(CampagneId), 0) + 1 ... WITH (UPDLOCK, HOLDLOCK)` fait passer les créations une par une. `elearning-04-enregistrer-activite`, construit sur le même motif, n'a attendu que 0,1 s dans ce tir : elle n'est contendue que lancée seule et sur beaucoup de threads (`-appli elearning -threads 32 -pause 0`).
8. 1 449 requêtes distinctes pour la seule connexion par adresse électronique (`portail-06-connexion-email`), une par adresse : l'application concatène la valeur dans le texte. Le paramétrage simple n'a rien repris : il ne s'applique qu'à une petite classe de requêtes, et celle-ci, avec sa jointure, n'en fait pas partie. Corrections : paramétrer côté application ; à défaut, `PARAMETERIZATION FORCED` sur la base, ou un repère de plan de modèle sur cette forme.
9. `Rapport.LecteursPerdus` (écart type 7,5 s), `Demo.ContactsSansEnvoi_Lente` (6,3 s, le `NOT IN` sur une sous-requête), `Rapport.ActiviteParAppareil` (4,6 s). Dans les trois cas, un seul plan : la variation vient des paramètres et de la concurrence, pas d'un changement de plan.
10. `Inscription.vFacture` interrogée par `backoffice-06-factures-societe` (`query_id` 59) : premier plan, 163 ms en moyenne sur 261 exécutions ; second plan apparu quatre minutes après le début du tir, 1 357 ms sur 208 exécutions, huit fois plus lent. Pendant le tir, le Query Store a capturé des dizaines de requêtes `StatMan`, les mises à jour automatiques de statistiques déclenchées par les écritures : une statistique mise à jour invalide le plan, et la recompilation qui suit a pris le paramètre du moment (cause probable, non démontrée ici). La requête des sessions `backoffice-04-planning-mois` a aussi changé de plan au même moment, sans effet sur sa durée (58 ms avant comme après).
11. Non exécuté dans ce tir.
12. Deux requêtes parentes : `marketing-02-statistiques-campagne` avec trois variantes, `Rapport.EnvoisParCampagne` (`marketing-03-envois-campagne`) avec deux. Sans PSP, une seule requête et un seul plan, compilé pour le premier paramètre reçu : le problème se voit dans Queries With High Variation, une durée très irrégulière sur un plan unique.
