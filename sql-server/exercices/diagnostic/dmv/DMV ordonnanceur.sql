-- tâches générées par ordonnanceur
SELECT AVG(current_tasks_count) AS [Avg Task Count], 
AVG(runnable_tasks_count) AS [Avg Runnable Task Count]
FROM sys.dm_os_schedulers
WHERE scheduler_id < 255
AND [status] = 'VISIBLE ONLINE';

-- quel ordonnanceur s'occupe de quoi
SELECT 
	a.scheduler_id ,
	b.session_id,
	 (SELECT TOP 1 SUBSTRING(s2.text,statement_start_offset / 2+1 , 
		  ( (CASE WHEN statement_end_offset = -1 
			 THEN (LEN(CONVERT(nvarchar(max),s2.text)) * 2) 
			 ELSE statement_end_offset END)  - statement_start_offset) / 2+1))  AS sql_statement
FROM sys.dm_os_schedulers a 
INNER JOIN sys.dm_os_tasks b on a.active_worker_address = b.worker_address
INNER JOIN sys.dm_exec_requests c on b.task_address = c.task_address
CROSS APPLY sys.dm_exec_sql_text(c.sql_handle) AS s2;

-- comment vont les workers
SELECT *
FROM sys.dm_os_workers;