# Réparer PachadataFormation quand elle est corrompue

```sql
USE Master;
GO

ALTER DATABASE [PachaDataFormation]
SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
GO

DBCC CHECKDB (PachaDataFormation, REPAIR_ALLOW_DATA_LOSS)
GO

ALTER DATABASE [PachaDataFormation]
SET MULTI_USER
GO

DBCC CHECKDB
GO
```