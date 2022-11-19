# Query Store

```sql	
USE PachaDataFormation;
GO

SELECT * FROM sys.query_store_options;
GO

USE [master]
GO
ALTER DATABASE PachadataFormation SET QUERY_STORE = ON
ALTER DATABASE PachadataFormation SET QUERY_STORE (OPERATION_MODE = READ_WRITE)
GO

```