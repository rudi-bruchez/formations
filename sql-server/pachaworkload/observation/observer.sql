-- Ce que le workload laisse sur le serveur : sessions par application et par poste,
-- plans en cache, requêtes les plus coûteuses au Query Store, index manquants.
-- Changer le USE pour observer une copie.
SET NOCOUNT ON;
USE PachaDataFormation;
-- 1. Qui est connecté
SELECT s.program_name, s.host_name, COUNT(*) AS sessions
FROM sys.dm_exec_sessions AS s
WHERE s.program_name LIKE N'PachaFormation-%'
GROUP BY s.program_name, s.host_name
ORDER BY s.program_name, s.host_name;
-- 2. Plans en cache par type
SELECT cp.objtype, COUNT(*) AS plans, SUM(CAST(cp.usecounts AS bigint)) AS usages,
       SUM(CASE WHEN cp.usecounts = 1 THEN 1 ELSE 0 END) AS usage_unique
FROM sys.dm_exec_cached_plans AS cp
CROSS APPLY sys.dm_exec_sql_text(cp.plan_handle) AS st
WHERE st.dbid = DB_ID()
GROUP BY cp.objtype;
-- 3. Les requêtes les plus coûteuses en CPU dans le Query Store, dernière heure
SELECT TOP (10) q.query_id, LEFT(qt.query_sql_text, 80) AS texte,
       SUM(rs.count_executions) AS executions,
       CAST(SUM(rs.avg_cpu_time * rs.count_executions) / 1000 AS bigint) AS cpu_ms,
       COUNT(DISTINCT p.plan_id) AS plans
FROM sys.query_store_query AS q
JOIN sys.query_store_query_text AS qt ON qt.query_text_id = q.query_text_id
JOIN sys.query_store_plan AS p ON p.query_id = q.query_id
JOIN sys.query_store_runtime_stats AS rs ON rs.plan_id = p.plan_id
JOIN sys.query_store_runtime_stats_interval AS i ON i.runtime_stats_interval_id = rs.runtime_stats_interval_id
WHERE i.end_time > DATEADD(hour, -1, SYSUTCDATETIME())
GROUP BY q.query_id, qt.query_sql_text
ORDER BY cpu_ms DESC;
-- 4. Index manquants proposés depuis le démarrage de l'instance
SELECT TOP (10) d.statement AS table_visee, d.equality_columns, d.inequality_columns, d.included_columns,
       s.user_seeks + s.user_scans AS demandes, CAST(s.avg_user_impact AS int) AS gain_pct
FROM sys.dm_db_missing_index_details AS d
JOIN sys.dm_db_missing_index_groups AS g ON g.index_handle = d.index_handle
JOIN sys.dm_db_missing_index_group_stats AS s ON s.group_handle = g.index_group_handle
WHERE d.database_id = DB_ID()
ORDER BY (s.user_seeks + s.user_scans) * s.avg_user_impact DESC;
