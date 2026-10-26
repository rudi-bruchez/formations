USE PachadataTraining
GO

CREATE OR ALTER VIEW Benchmark.VectorQueryPerformance
-- SELECT * FROM Benchmark.VectorQueryPerformance
AS

SELECT
    qsq.query_id,
    SUBSTRING(qsqt.query_sql_text, 1, 200) AS query_preview,
    qsrs.count_executions,
    qsrs.avg_duration / 1000.0 AS avg_duration_ms,
    qsrs.last_duration / 1000.0 AS last_duration_ms,
    qsrs.min_duration / 1000.0 AS min_duration_ms,
    qsrs.max_duration / 1000.0 AS max_duration_ms,
    qsrs.stdev_duration / 1000.0 AS stdev_duration_ms,
    qsrs.avg_cpu_time / 1000.0 AS avg_cpu_ms,
    qsrs.avg_logical_io_reads,
    qsrs.first_execution_time,
    qsrs.last_execution_time
FROM sys.query_store_query_text qsqt
JOIN sys.query_store_query qsq
    ON qsqt.query_text_id = qsq.query_text_id
JOIN sys.query_store_plan qsp
    ON qsq.query_id = qsp.query_id
JOIN sys.query_store_runtime_stats qsrs
    ON qsp.plan_id = qsrs.plan_id
WHERE qsqt.query_sql_text LIKE '%VECTOR_DISTANCE%'
   OR qsqt.query_sql_text LIKE '%VECTOR_SEARCH%';
GO