# Optimize for adhoc workloads

```sql	
SELECT SUM(size_in_bytes) 
FROM sys.dm_exec_cached_plans
WHERE usecounts = 1

SELECT *
FROM sys.dm_exec_cached_plans

SELECT * FROM Person.Person WHERE LastName = 'sqdfsdf'
SELECT * FROM Person.Person WHERE LastName = 'azaazaz'
SELECT * FROM Person.Person WHERE LastName = 'azaaraz'
SELECT * FROM Person.Person WHERE LastName = 'azaafaz'
SELECT * FROM Person.Person WHERE LastName = 'azaaaaz'
SELECT * FROM Person.Person WHERE LastName = 'azaauaz'


DBCC FREEPROCCACHE

ALTER DATABASE SCOPED CONFIGURATION 
CLEAR PROCEDURE_CACHE


SELECT * FROM Person.Person WHERE LastName = 'sqdfsdf'
```