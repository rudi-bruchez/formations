Cette sauvegarde a �t� r�alis�e par l'utilitaire pg_dump.
Pour la restaurer, vous pouvez utiliser la commande suivante :

psql pachadataformation < pachadataformation.pgdump

Il faut avoir d'abord cr�� la base de donn�es pachadataformation � partir du template0,
par exemple avec la commande suivante :
createdb -T template0 pachadataformation