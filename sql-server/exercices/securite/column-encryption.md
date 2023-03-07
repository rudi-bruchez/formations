# Chiffrement de colonne

Objectif : Chiffrer le contenu d'une colonne dans une base de données en utilisant des clés de chiffrement.

```sql	
CREATE DATABASE [ColumnEncryptionDB]
GO

USE [ColumnEncryptionDB]
GO


Prérequis :

- Avoir des connaissances de base en SQL Server.
- Avoir une base de données nommée "PachadataFormation" avec une table nommée "Employe" contenant une colonne "Salaire".

```sql
CREATE TABLE Contact.Employe (
    EmployeId INT NOT NULL PRIMARY KEY IDENTITY(1, 1),
    Nom VARCHAR(50) NOT NULL,
    Prenom VARCHAR(50) NOT NULL,
    DateEmbauche DATE NOT NULL,
    Salaire DECIMAL(10,2) NOT NULL
);
```

## Étape 1 : Création d'un certificat

Créez un certificat pour utiliser comme clé de chiffrement en utilisant la commande suivante :

```sql
CREATE CERTIFICATE EmployeSalaireCert  
WITH SUBJECT = 'Chiffrement de colonne Salaire';  
```

## Étape 2 : Création d'une clé de chiffrement

Créez une clé de chiffrement en utilisant le certificat créé dans l'étape 1 avec la commande suivante :

```sql
CREATE SYMMETRIC KEY EmployeSalaireKey  
WITH ALGORITHM = AES_256  
ENCRYPTION BY CERTIFICATE EmployeSalaireCert;  
```

## Étape 3 : Chiffrer la colonne "Salaire"

Créez une UDF pour encapsuler le code de chiffrement de la colonne "Salaire" en utilisant la commande suivante :

```sql
CREATE FUNCTION dbo.fnEncryptSalaire(@Salaire DECIMAL(10,2))  
RETURNS VARBINARY(8000)  
WITH ENCRYPTION  
AS BEGIN  
    DECLARE @Result VARBINARY(8000);  
    SET @Result = EncryptByKey(Key_GUID('EmployeeSalaireKey'), @Salaire);  
    RETURN @Result;  
END;  
```

## Étape 4 : Insérer les données chiffrées

Chiffrez la colonne "Salaire" en utilisant la clé de chiffrement "EmployeSalaireKey" créée dans l'étape 2 en utilisant la commande suivante :

```sql
INSERT INTO Employe (EmployeID, Nom, Prenom, DateEmbauche, Salaire)  
VALUES 
    (1, 'Bouzidi', 'Amina', '2022-01-01', dbo.fnEncryptSalaire(50000.00)),
    (2, 'Mandela', 'Amina', '2022-02-01', dbo.fnEncryptSalaire(60000.00)),
    (3, 'Lee', 'Jung-Mi', '2022-03-01', dbo.fnEncryptSalaire(55000.00)),
    (4, 'Garcia', 'Maria', '2022-04-01', dbo.fnEncryptSalaire(45000.00)),
    (5, 'Patel', 'Priya', '2022-05-01', dbo.fnEncryptSalaire(65000.00)),
    (6, 'Ali', 'Fatima', '2022-06-01', dbo.fnEncryptSalaire(50000.00));

```

Cette commande va chiffrer la colonne "Salaire" en utilisant la clé de chiffrement "EmployeSalaireKey" créée dans l'étape 2.

## Étape 5 : Tester le chiffrement
Testez le chiffrement en exécutant la commande suivante :

```sql
SELECT Salaire  
FROM Contact.Employe  
WHERE employee_id = 1;  

```

Cette commande devrait renvoyer une valeur chiffrée pour la colonne "Salaire".

## Étape 6 : Déchiffrer la colonne "Salaire"
Déchiffrez la colonne "Salaire" en utilisant la commande suivante :

```sql
OPEN SYMMETRIC KEY EmployeSalaireKey  
DECRYPTION BY CERTIFICATE EmployeSalaireCert  

SELECT  
    employee_id,  
    CONVERT(VARCHAR(50), DECRYPTBYKEY(Salaire)) AS Salaire  
FROM Contact.Employe  
WHERE employee_id = 1;  

```

Cette commande va ouvrir la clé de chiffrement "EmployeSalaireKey" et déchiffrer la colonne "Salaire" pour l'employé ayant un ID de 1.

## Conclusion

L'exercice ci-dessus démontre comment utiliser des clés de chiffrement pour chiffrer le contenu d'une colonne dans une base de données SQL Server. Les participants devraient être en mesure de comprendre le processus et d'appliquer cette méthode à leur propre base de données SQL Server.

