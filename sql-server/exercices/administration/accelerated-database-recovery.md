
```sql
USE PachaDataFormation;

ALTER DATABASE SCOPED CONFIGURATION
SET VERBOSE_TRUNCATION_WARNINGS = ON

-- SET ANSI_WARNINGS ON

CREATE TABLE #t (truc VARCHAR(10))

INSERT INTO #t 
VALUES ('qsdqdsqsdqsdqsdqsd')


SELECT *
FROM sys.dm_tran_version_store_space_usage



BEGIN TRAN

.......

KILL 


ALTER DATABASE PachadataFormation 
SET ACCELERATED_DATABASE_RECOVERY = ON
(PERSISTENT_VERSION_STORE_FILEGROUP = FG2)

SELECT *
FROM sys.dm_tran_persistent_version_store_stats 

EXEC sys.sp_persistent_version_cleanup
```