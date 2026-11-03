# Journal des versions de pachaworkload

## [Non publié]

## [1.0.0] - 2026-11-03

Première version publiée sur GitHub. `pachaworkload` rejoue sur `PachaDataFormation` le trafic d'une application de gestion de formation (49 requêtes, saines ou problématiques, sur plusieurs threads) pour faire travailler une instance comme en production : cache de plans, Query Store, événements étendus, attentes, blocages, index manquants. Le même tir peut viser tous les postes d'une salle.

### Ajouté

- `-windows` : connexion avec le compte Windows de la session (SSPI), sans identifiant ni mot de passe. Le compte doit avoir un login sur chaque instance visée. Refusé hors de Windows.
- `-version` : affiche la version.
- Une archive Windows par version sur la page des releases du dépôt, avec sa somme SHA-256, à la place de l'archive déposée à la main sur files.pachadata.com.

### Modifié

- `-env` lit par défaut `.env` dans le dossier courant.

### Limites

- L'exécutable Windows est compilé et testé sous Linux. Il n'a pas encore été lancé sous Windows, et une connexion `-windows` réelle n'a pas encore été faite.
