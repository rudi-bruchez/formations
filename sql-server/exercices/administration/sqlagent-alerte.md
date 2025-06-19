# Pratique : créer une alerte

Dans cet exercice, vous allez créer une alerte de condition de performance qui vous avertira si le journal des transactions de la base **PachadataFormation** se remplit à plus de 70 %

- Créez un opérateur nommé **adminsql**, qui recevra les messages d'alerte à l'adresse e-mail **adminsql@pachadata.com**.
- Créez une nouvelle alerte, nommée **Journal de Transaction PachadataFormation > 70 %**
- Configurez-la pour utiliser un résultat de compteur SQL Server. Le compteur qui nous intéresse se trouve dans l'objet Databases de l'instance. Le compteur est « pourcentage de journal utilisé » (*percent log used*), sélectionnez uniquement la base **PachadataFormation**.
- Configurez le déclenchement de l'alerte au dépassement de 70%
- Faites en sorte que l'alerte ne se déclenche pas plus d'une fois toutes les dix minutes

Nous allons tester le fonctionnement de cette alerte :

- Assurez-vous que la base **PachadataFormation** est en mode de récupération **Complet** (full), et changez le comportement du fichier de journal, pour empêcher son augmentation automatique. Faites en une sauvegarde (sauvegarde complète).
- Saisissez ensuite la requête suivante, et exécutez-la. Elle va tourner en boucle jusqu'au remplissage du journal à 85%

```SQL
BEGIN TRAN

WHILE (SELECT cntr\_value

FROM sys.dm\_os\_performance\_counters

WHERE	Object\_Name = 'MSSQL$**SQL2022**:Databases' AND

`		`counter\_name = 'Percent Log Used' AND

`		`instance\_name = 'PachadataFormation') < 85

`	`INSERT INTO dbo.Poubelle (contenu) VALUES ('des choses')

COMMIT TRAN

GO
```

- Vérifiez que l'alerte s'est déclenchée en ouvrant la fenêtre de propriétés de l'alerte, onglet **Historique**

