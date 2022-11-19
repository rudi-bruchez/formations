```sql
USE Master;
GO

-- créer une première fois la master key de Master
CREATE MASTER KEY
ENCRYPTION BY PASSWORD = 'toto';
GO

-- Créer un certificat pour le chiffrement
-- des sauvegardes
CREATE CERTIFICATE backup_cert
WITH SUBJECT = 'sauvegardes';
GO

-- sauvegarder le certificat
BACKUP CERTIFICATE backup_cert
TO FILE = 'd:\sqldata\backup_cert.pub'
WITH PRIVATE KEY (
    ENCRYPTION BY PASSWORD = '9875t6#6rfid7vble7r' ,
    FILE = 'd:\sqldata\backup_cert.priv'
)
GO

-- exemple de sauvegarde
BACKUP DATABASE [PachaDataFormation]
TO  DISK = N'D:\sqldata\MSSQL15.SQL2019\MSSQL\Backup\coco' WITH FORMAT, INIT,  NAME = N'PachaDataFormation-Full Database Backup', SKIP, NOREWIND, NOUNLOAD,
ENCRYPTION(
    ALGORITHM = AES_256,
    SERVER CERTIFICATE = [backup_cert]),
STATS = 10
GO
```

## Pour restaurer sur un autre serveur

```sql
----------------------------------------
-- pour restaurer sur un autre serveur
----------------------------------------
USE Master
GO

CREATE CERTIFICATE backup_cert
FROM FILE = 'd:\sqldata\backup_cert.pub'
WITH PRIVATE KEY (
    DECRYPTION BY PASSWORD = '9875t6#6rfid7vble7r' ,
    FILE = 'd:\sqldata\backup_cert.priv'
)
GO
```