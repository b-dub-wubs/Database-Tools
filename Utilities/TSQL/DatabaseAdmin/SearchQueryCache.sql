/*┌─────────────────────────────────────────────────────────────────────────────────────────────┐*\.
  │ TITLE: Search SQL Server Query Cache                                                        │
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤
  │ DESCRIPTION:                                                                                │
      Find that recent query that you were working on but lost the file somehow
\*└─────────────────────────────────────────────────────────────────────────────────────────────┘*/

SELECT 
    Query   = dest.[TEXT] 
  , [Count] = deqs.execution_count 
  , [Time]  = deqs.last_execution_time
FROM 
  sys.dm_exec_query_stats deqs
  CROSS APPLY
  sys.dm_exec_sql_text
  (deqs.sql_handle) dest
WHERE 
  dest.[TEXT] LIKE '%RunLog%'
ORDER BY 
  deqs.last_execution_time DESC

