# Migration par sauvegarde vers SQL MI

## Dans Azure

1. créer un compte de stockage
1. ajouter un conteneur
1. attribuer une stratégie d'accès stockée avec toutes les permissions
1. Créer un jeton d'accès partagé en HTTPS sur la stratégie

## Sur la source

```sql
SELECT * FROM sys.credentials

-- création d'un credential pour la sauvegarde vers Azure Blob Storage
CREATE CREDENTIAL [https://pachasql.blob.core.windows.net/backups]
WITH IDENTITY = 'SHARED ACCESS SIGNATURE',  
SECRET = 'si=backups&spr=https&sv=2022-11-02&sr=c&sig=PiooKNXJ6fW6RH8C7vHhGFGzr2jyaSclh50zCE6zImY%3D';  
-- coller le jeton SAS dans le secret.
GO

-- sauvegarde vers Azure Blob Storage
BACKUP DATABASE PachadataFormation
TO URL = 'https://pachasql.blob.core.windows.net/backups/pachadataformation.bak'
WITH CHECKSUM, FORMAT, INIT, COMPRESSION, STATS = 5;
GO
```

## Sur la destination

1. créer le même credential
1. restaurer la ou les bases

```sql
SELECT * FROM sys.credentials

CREATE CREDENTIAL [https://pachasql.blob.core.windows.net/backups]
WITH IDENTITY = 'SHARED ACCESS SIGNATURE',  
SECRET = 'si=backups&spr=https&sv=2022-11-02&sr=c&sig=PiooKNXJ6fW6RH8C7vHhGFGzr2jyaSclh50zCE6zImY%3D';  
GO
```