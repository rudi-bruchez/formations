Cette sauvegarde a été réalisée par l'utilitaire pg_dump.
Pour la restaurer, vous pouvez utiliser la commande suivante :

psql pachadataformation < pachadataformation.pgdump

Il faut avoir d'abord créé la base de données pachadataformation à partir du template0,
par exemple avec la commande suivante :
createdb -T template0 pachadataformation