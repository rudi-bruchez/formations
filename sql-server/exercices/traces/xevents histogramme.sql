-- une liste des wait_types
SELECT map_key, map_value 
FROM sys.dm_xe_map_values
WHERE name = 'wait_types'
ORDER BY map_key;

-- création de la session d'événements
-- !! ===== changez le session_id ===== !!
CREATE EVENT SESSION wait_histogram ON SERVER 
ADD EVENT sqlos.wait_info(
    WHERE (sqlserver.session_id = 60))
ADD TARGET package0.histogram(
	SET filtering_event_name = N'sqlos.wait_info',
		source_type = 0, -- Event
		source = N'wait_type'),
ADD TARGET package0.ring_buffer;
GO

ALTER EVENT SESSION wait_histogram ON SERVER
STATE=START;

---------------------------
-- exécutez la requête ! --
---------------------------

-- requêtage
WITH cte AS (
	SELECT 
		n.value('(value)[1]', 'int') AS WaitType,
		n.value('(@count)[1]', 'int') AS WaitCount
	FROM
	(SELECT CAST(target_data AS XML) target_data
	 FROM sys.dm_xe_sessions AS s 
	 INNER JOIN sys.dm_xe_session_targets AS t
		 ON s.address = t.event_session_address
	 WHERE s.name = N'wait_histogram'
	 AND t.target_name = N'histogram' ) AS tab
	CROSS APPLY target_data.nodes('HistogramTarget/Slot') AS q(n)
)
SELECT 
	mv.map_value as wait_type,
	cte.WaitCount
FROM cte 
JOIN sys.dm_xe_map_values mv ON cte.WaitType = mv.map_key
WHERE mv.name = 'wait_types'
ORDER BY cte.WaitCount DESC;
GO


-- nettoyage
DROP EVENT SESSION wait_histogram ON SERVER
GO

---------------------------------------------------------------------
-- pour info : les champs de configuration de la cible histogramme --
---------------------------------------------------------------------
SELECT 
    oc.name AS column_name,
    oc.column_id,
    oc.type_name,
    oc.capabilities_desc,
    oc.description
FROM sys.dm_xe_packages AS p
JOIN sys.dm_xe_objects AS o 
    ON p.guid = o.package_guid
JOIN sys.dm_xe_object_columns AS oc 
    ON o.name = oc.OBJECT_NAME 
    AND o.package_guid = oc.object_package_guid
WHERE (p.capabilities IS NULL OR p.capabilities & 1 = 0)
  AND (o.capabilities IS NULL OR o.capabilities & 1 = 0)
  AND o.object_type = N'target'
  AND o.name = N'histogram';