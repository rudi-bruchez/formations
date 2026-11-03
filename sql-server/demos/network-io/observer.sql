-- À lancer dans SSMS pendant que l'un des deux clients PowerShell tourne.

-- 1. La requête en cours et son attente. wait_time est l'attente en cours et
--    non le cumul : elle peut être bien plus courte que l'arrêt du client.
SELECT r.session_id, r.status, r.wait_type, r.wait_time, s.program_name, t.text
FROM sys.dm_exec_requests AS r
JOIN sys.dm_exec_sessions AS s ON s.session_id = r.session_id
CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) AS t
WHERE s.program_name LIKE N'Demo%';

-- 2. Le cumul des attentes de la session depuis sa connexion.
SELECT ws.session_id, ws.wait_type, ws.waiting_tasks_count, ws.wait_time_ms
FROM sys.dm_exec_session_wait_stats AS ws
JOIN sys.dm_exec_sessions AS s ON s.session_id = ws.session_id
WHERE s.program_name LIKE N'Demo%'
ORDER BY ws.wait_time_ms DESC;

-- 3. Les verrous que tient la table liée ouverte.
SELECT l.request_session_id, l.resource_type, l.request_mode, l.request_status,
       CASE WHEN l.resource_type = N'OBJECT'
            THEN OBJECT_NAME(CONVERT(int, l.resource_associated_entity_id)) END AS objet
FROM sys.dm_tran_locks AS l
JOIN sys.dm_exec_sessions AS s ON s.session_id = l.request_session_id
WHERE s.program_name LIKE N'Demo%';

-- 4. Ce qu'elle bloque : une modification de structure ne peut pas obtenir son
--    verrou Sch-M tant que la table liée est ouverte. Erreur 1222 au bout de 5 s ;
--    la transaction est annulée dans tous les cas, la table n'est pas modifiée.
SET LOCK_TIMEOUT 5000;
BEGIN TRANSACTION;
ALTER TABLE Contact.ProspectUS ADD DemoBloquee int NULL;
ROLLBACK TRANSACTION;
SET LOCK_TIMEOUT -1;
