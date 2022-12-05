SELECT
	s.host_name, 
	t.text, 
	r.start_time, 
	r.status, 
	r.total_elapsed_time, 
	r.logical_reads, 
	r.granted_query_memory 
FROM sys.dm_exec_requests r
JOIN sys.dm_exec_sessions s ON r.session_id = s.session_id
CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) t;