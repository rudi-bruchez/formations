# Appliquer des hints avec le Query Store

## Requête exemple

```sql
SELECT *
FROM Contact.Contact
ORDER BY Nom, Prenom;
```

## Trouver la requête dans le Query Store

```sql
DECLARE @text_to_find NVARCHAR(2000) = N'FROM Contact.Contact';

SELECT 
    qsq.query_id,
    qsq.last_execution_time,
    qsqt.query_sql_text
FROM sys.query_store_query qsq
JOIN sys.query_store_query_text qsqt
    ON qsq.query_text_id = qsqt.query_text_id
WHERE
    qsqt.query_sql_text LIKE CONCAT('%', TRIM(@text_to_find), '%')
OPTION (RECOMPILE, MAXDOP 1);
```

## Créer un hint

```sql
EXEC sp_query_store_set_hints 
	@query_id = 716, 
	@value = N'OPTION (MAXDOP 1)';
GO
```

## Vérifier les hints déjà placés

```sql
SELECT	query_hint_id,
        query_id,
        query_hint_text,
        last_query_hint_failure_reason,
        last_query_hint_failure_reason_desc,
        query_hint_failure_count,
        source,
        source_desc
FROM sys.query_store_query_hints;
```

## On le voit dans le plan d'exécution

```xml
        <StmtSimple ... QueryStoreStatementHintId="1" QueryStoreStatementHintText="OPTION (MAXDOP 1)" QueryStoreStatementHintSource="User">
          <QueryPlan DegreeOfParallelism="0" NonParallelPlanReason="MaxDOPSetToOne" >
```