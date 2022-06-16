# Créer un travail de l'agent SQL

1. Vérifiez que l'Agent SQL est bien lancé, si ce n'est pas le cas, lancez le service avec 
   un clic droit sur l'icône « SQL Server Agent » dans l'explorateur d'objets.

2. Créez un nouveau travail nommé **Export factures**.

3. Créez une étape de type execcmd, dans laquelle vous saisirez la commande bcp suivante :

    ``` 
    bcp.exe "PachadataFormation.Inscription.Facture" OUT "C:\Temp\facture.csv" -Slocalhost -T -m10 -c -r\n -t\t -a32764 -q
    ``` 

4. Stockez les informations retournées par la commande BCP dans le fichier `C:\temp\ExportFacture.log`,
   en vous assurant que les données s'ajoutent chaque jour dans le fichier au lieu de l'écraser.

5. Planifiez l'exécution de la tâche tous les jours de la semaine (du lundi au vendredi), 
   à six heures du matin.
    
6. Assurez-vous qu'en cas d'erreur, la tâche inscrive cette erreur dans le journal des événements
   d'application Windows.

7. Lancez la tâche manuellement afin de vérifier qu'elle s'exécute correctement. 
   Affichez l'historique pour voir une information détaillée. 
   Vérifiez le fichier d'export et le fichier de journal.

8. En cas d'erreur, vérifiez dans l'historique le message d'erreur retourné par la tâche.