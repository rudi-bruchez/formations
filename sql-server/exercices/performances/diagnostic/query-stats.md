# Query Stats

```sql
SELECT *
FROM sys.dm_exec_query_stats

SELECT *
FROM sys.dm_exec_procedure_stats

SELECT OBJECT_NAME(object_id), *
FROM sys.dm_exec_function_stats

SELECT OBJECT_NAME(object_id), *
FROM sys.dm_exec_trigger_stats
```