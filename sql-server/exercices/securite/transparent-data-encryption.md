# Transparent Data Encryption

## Créer un certificat dans Master à votre nom

```sql
USE PachaDataFormation;
GO
CREATE DATABASE ENCRYPTION KEY
WITH ALGORITHM = AES_256
ENCRYPTION BY SERVER CERTIFICATE <XXX>;
GO

3/ ALTER DATABASE PachadataFormation SET ENCRYPTION ON;

-- les bases chiffrées
SELECT name, is_encrypted
FROM sys.databases 

-- état du chiffrement

SELECT DB_NAME(database_id), *
FROM sys.dm_database_encryption_keys
```