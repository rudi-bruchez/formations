# Tables temporelles

Les tables temporelles sont des tables qui contiennent des données historiques. Elles sont très utiles pour les applications qui doivent gérer des données historiques. Les tables temporelles sont disponibles depuis SQL Server 2016.

## Créer une table temporelle

Pour créer une table temporelle, il faut utiliser la clause `WITH (SYSTEM_VERSIONING = ON)` dans la clause `CREATE TABLE`.

```sql
CREATE TABLE Client (
	ClientId INT NOT NULL IDENTITY(1, 1) PRIMARY KEY,
	Nom VARCHAR(50) NOT NULL,
	Prenom VARCHAR(50) NOT NULL,
	Email VARCHAR(50) NOT NULL,
	DateDebut DATETIME2(3),
	DateFin DATETIME2(3)
)

CREATE TABLE Client (
	ClientId INT NOT NULL IDENTITY(1, 1) PRIMARY KEY,
	Nom VARCHAR(50) NOT NULL,
	Prenom VARCHAR(50) NOT NULL,
	Email VARCHAR(50) NOT NULL,
	DateDebut DATETIME2(3) GENERATED ALWAYS AS ROW START,
	DateFin DATETIME2(3) GENERATED ALWAYS AS ROW END,
	PERIOD FOR SYSTEM_TIME (DateDebut, DateFin)
) WITH (SYSTEM_VERSIONING = ON /*(HISTORY_TABLE = dbo.ClientHistorique)*/);
```

## Insérer des données dans une table temporelle

Pour insérer des données dans une table temporelle, il faut utiliser la clause `INSERT INTO` avec la clause `FOR SYSTEM_TIME ALL`.

```sql
INSERT INTO Client (Nom, Prenom, Email)
VALUES ('Trump', 'Emilie', 'emilie.trump@gmail.com');

-- récupérez la valeur
SELECT SCOPE_IDENTITY()

UPDATE Client
SET Email = 'emilie.trump@yahoo.com'
WHERE ClientId = 1;
```	

## Récupérer les données d'une table temporelle

Pour récupérer les données d'une table temporelle, il faut utiliser la clause `SELECT` avec la clause `FOR SYSTEM_TIME ALL`.

```sql
SELECT * 
FROM Client FOR SYSTEM_TIME ALL
WHERE ClientId = 1;

SELECT * 
FROM Client FOR SYSTEM_TIME AS OF '2022-11-08 08:30:10'
WHERE ClientId = 1;

SELECT * 
FROM Client FOR SYSTEM_TIME BETWEEN '' AND ''
WHERE ClientId = 1;
```
