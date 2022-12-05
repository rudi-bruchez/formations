-- création de la session d'événements
-- !! ===== changez le session_id ===== !!
CREATE EVENT SESSION query_hash_histogram ON SERVER 
ADD EVENT sqlserver.sql_statement_completed(
    ACTION(sqlserver.database_id,sqlserver.query_hash,sqlserver.session_id, sqlserver.sql_text)
    WHERE (sqlserver.session_id = 52))
ADD TARGET package0.histogram(
	SET filtering_event_name = N'sqlserver.sql_statement_completed',
		source_type = 1, -- Action
		source = N'sqlserver.query_hash'),
ADD TARGET package0.ring_buffer;
GO

ALTER EVENT SESSION query_hash_histogram ON SERVER
STATE=START;

---------------------------
-- exécutez la requête ! --
---------------------------

-- requêtage sur l'histogramme
SELECT 
	n.value('(value)[1]', 'nvarchar(1000)') AS WaitType,
	n.value('(@count)[1]', 'int') AS WaitCount
FROM
(SELECT CAST(target_data AS XML) target_data
	FROM sys.dm_xe_sessions AS s 
	INNER JOIN sys.dm_xe_session_targets AS t
		ON s.address = t.event_session_address
	WHERE s.name = N'query_hash_histogram'
	AND t.target_name = N'histogram' ) AS tab
CROSS APPLY target_data.nodes('HistogramTarget/Slot') AS q(n);
GO

-- requêtage sur le détail
; WITH tab AS (
	SELECT CAST(target_data AS XML) target_data
	FROM sys.dm_xe_sessions AS s 
	INNER JOIN sys.dm_xe_session_targets AS t
		ON s.address = t.event_session_address
	WHERE s.name = N'query_hash_histogram'
	AND t.target_name = N'ring_buffer'
)
SELECT 
	n.value('(data[@name="statement"]/value)[1]', 'nvarchar(1000)') as requete,
	n.query('.') as tout
FROM tab
CROSS APPLY tab.target_data.nodes('RingBufferTarget/event[@name="sql_statement_completed"]') as q(n)
WHERE n.value('(action[@name="query_hash"]/value)[1]', 'nvarchar(1000)') = N'1511416159799035827'; 
-- !! ===== changez le query_hash ===== !!


-- nettoyage
DROP EVENT SESSION query_hash_histogram ON SERVER
GO
