-- Session Extended Events limitée aux rapports (nom d'application de la connexion).
-- Lire par xe-rapports-lire.sql ; supprimer par DROP EVENT SESSION workload_rapports ON SERVER;
CREATE EVENT SESSION workload_rapports ON SERVER
ADD EVENT sqlserver.rpc_completed (
    ACTION (sqlserver.client_app_name, sqlserver.client_hostname, sqlserver.sql_text)
    WHERE sqlserver.client_app_name = N'PachaFormation-rapports'),
ADD EVENT sqlserver.sql_batch_completed (
    ACTION (sqlserver.client_app_name, sqlserver.client_hostname)
    WHERE sqlserver.client_app_name = N'PachaFormation-rapports')
ADD TARGET package0.ring_buffer;
ALTER EVENT SESSION workload_rapports ON SERVER STATE = START;
