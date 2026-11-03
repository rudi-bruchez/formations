-- Lit la session workload_rapports : nombre d'événements et durée moyenne par poste.
SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
WITH ev AS (
    SELECT x.e.value('@name', 'nvarchar(50)') AS evenement,
           x.e.value('(action[@name="client_hostname"]/value)[1]', 'nvarchar(50)') AS hote,
           x.e.value('(data[@name="duration"]/value)[1]', 'bigint') / 1000 AS duree_ms
    FROM (SELECT CAST(t.target_data AS xml) AS d
          FROM sys.dm_xe_session_targets AS t
          JOIN sys.dm_xe_sessions AS s ON s.address = t.event_session_address
          WHERE s.name = N'workload_rapports') AS r
    CROSS APPLY r.d.nodes('/RingBufferTarget/event') AS x(e)
)
SELECT hote, evenement, COUNT(*) AS n, AVG(duree_ms) AS duree_moy_ms
FROM ev GROUP BY hote, evenement;
