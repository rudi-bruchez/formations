--quelques infos générales, dont les infos de base sur l'occupation mémoire
SELECT *
FROM sys.dm_os_sys_info;

--informations générales sur la mémoire
SELECT 
	total_physical_memory_kb/(1024) as total_physical_memory_mb,
	available_physical_memory_kb/(1024) as available_physical_memory_mb,
	system_cache_kb/(1024) as system_cache_mb,
	(kernel_paged_pool_kb+kernel_nonpaged_pool_kb)/(1024) as kernel_pool_mb,
	total_page_file_kb/(1024) as total_page_file_mb,
	available_page_file_kb/(1024) as available_page_file_mb,
	system_memory_state_desc
from sys.dm_os_sys_memory
go
 
-- mémoire utilisée par le processus, vu du point de vue de Windows (GetMemoryProcessInfo() API)
SELECT 
	physical_memory_in_use_kb/(1024) as physical_memory_in_use_mb,
	locked_page_allocations_kb/(1024) as locked_page_allocations_mb,
	total_virtual_address_space_kb/(1024) as total_virtual_address_space_mb,
	virtual_address_space_committed_kb/(1024) as virtual_address_space_committed_mb,
	memory_utilization_percentage,
	virtual_address_space_available_kb/(1024) as virtual_address_space_available_mb,
	process_physical_memory_low as is_there_external_pressure,
	process_virtual_memory_low as is_there_vas_pressure
FROM sys.dm_os_process_memory
GO
 
-- mémoire par noeud
SELECT *
FROM sys.dm_os_memory_nodes
WHERE memory_node_id != 64
go
  
-- les clerks qui conomme de la mémoire
SELECT * 
FROM sys.dm_os_memory_clerks
WHERE virtual_memory_committed_kb > 0
OR awe_allocated_kb > 0
ORDER BY virtual_memory_committed_kb DESC
go
 
-- mémoire utilisée par les caches
SELECT	
	name, 
	type, 
	SUM(pages_kb) as sum_pages_kb,
	SUM(pages_in_use_kb) as sum_pages_in_use_kb,
	SUM(entries_count) as sum_entries_count,
	SUM(entries_in_use_count) as sum_entries_in_use_count
FROM sys.dm_os_memory_cache_counters
WHERE type like 'CACHESTORE%'
GROUP BY name, type
ORDER BY sum_pages_in_use_kb DESC;
GO

-- mémoire utilisée par les user stores
SELECT	
	name, 
	type, 
	SUM(pages_kb) as sum_pages_kb,
	SUM(pages_in_use_kb) as sum_pages_in_use_kb,
	SUM(entries_count) as sum_entries_count,
	SUM(entries_in_use_count) as sum_entries_in_use_count
FROM sys.dm_os_memory_cache_counters
WHERE type like 'USERSTORE%'
GROUP BY name, type
ORDER BY sum_pages_in_use_kb DESC;
GO

-- mémoire utilisée par les object stores
SELECT	
	name, 
	type, 
	SUM(pages_kb) as sum_pages_kb,
	SUM(pages_in_use_kb) as sum_pages_in_use_kb,
	SUM(entries_count) as sum_entries_count,
	SUM(entries_in_use_count) as sum_entries_in_use_count
FROM sys.dm_os_memory_cache_counters
WHERE type like 'OBJECTSTORE%'
GROUP BY name, type
ORDER BY sum_pages_in_use_kb DESC;
GO
 
-- la taille du buffer pool par base de données
SELECT db_name(database_id),(cast(count(*) as bigint)*8192)/1024/1024 as taille_mb 
FROM sys.dm_os_buffer_descriptors
GROUP BY db_name(database_id)

-- les objets en mémoire
SELECT 
	SUM (mo.pages_in_bytes)/1024 as taille_kb, 
	mo.type as [Memory Object Type], 
	mc.type as [Memory Clerk Type]
FROM sys.dm_os_memory_objects mo
join sys.dm_os_memory_clerks mc on mo.page_allocator_address=mc.page_allocator_address
GROUP BY mo.type, mc.type, mc.type
ORDER BY taille_kb DESC;
