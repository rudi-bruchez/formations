# DBCC CLONEDATABASE

 https://docs.microsoft.com/en-us/sql/t-sql/database-console-commands/dbcc-clonedatabase-transact-sql?view=sql-server-ver15

## Description

The DBCC CLONEDATABASE command creates a clone of a database. The clone is a read-only copy of the database that can be used for testing, reporting, and other purposes. The clone is created in a new database with a new name. The clone is created in the same database engine instance as the source database.

## Solution

```sql
DBCC CLONEDATABASE (AdventureWorks2019, AdventureWorks2019_clone) WITH VERIFY_CLONEDB, BACKUP_CLONEDB
```