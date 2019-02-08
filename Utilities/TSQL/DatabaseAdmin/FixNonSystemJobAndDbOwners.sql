/*┌─────────────────────────────────────────────────────────────────────────────────────────────┐*\.
  │ TITLE: Fix Job & DB Owner Issues                                                            │
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤
  │ DESCRIPTION:                                                                                │
     Looks for database and sql agent job owners that are not in a specified set of logins
     (when they are owned by users for example) and generates a report with a fix script 
     to reset the owner to a default
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤
  │ REVISION HISTORY:                                                                           │
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤
  │   DATE       AUTHOR          CHANGE DESCRIPTION                                             │
  │   ────────── ─────────────── ────────────────────────────────────────────────────────────── │
      2018.12.17 bwarner         Initial Draft
\*└─────────────────────────────────────────────────────────────────────────────────────────────┘*/

/*┌─────────────────────────────────────────────────────────────────────────────────────────────┐*\.
  │ Database Owners                                                                             │
\*└─────────────────────────────────────────────────────────────────────────────────────────────┘*/
USE master
GO

DECLARE 
    @default_DB_Owner SYSNAME = 'sa'

SELECT 
    CASE
        WHEN D.is_read_only = 1
          THEN '-- Remove ReadOnly State'
        WHEN D.state_desc = 'ONLINE'
          THEN 'ALTER AUTHORIZATION on DATABASE::[' + D.name + '] to [' + @default_DB_Owner + '];'
        ELSE '-- Turn On '
    END AS CommandToRun
  , D.name AS Database_Name
  , D.database_id Database_ID
  , L.Name AS Login_Name
  , D.state_desc AS Current_State
  , D.is_read_only AS ReadOnly
FROM 
  sys.databases D
  INNER JOIN
  sys.syslogins L
    ON D.owner_sid = L.sid
WHERE 
  L.Name NOT IN
    (
        'sa'
      , 'DWJobOwner'
      , 'CORP\fpcservice'
    )
ORDER BY 
    D.Name
 
/*┌─────────────────────────────────────────────────────────────────────────────────────────────┐*\.
  │ SQL Agent Job Owners                                                                        │
\*└─────────────────────────────────────────────────────────────────────────────────────────────┘*/

USE msdb
GO

DECLARE 
    @default_AgentJobOwner SYSNAME = 'DWJobOwner'

SELECT 
    J.name AS SQL_Agent_Job_Name
  , L.name AS Job_Owner
  , J.description
  , C.name
  , 'EXEC msdb.dbo.sp_update_job @job_id=N''' + CAST(job_id AS VARCHAR(150)) + ''', @owner_login_name=N''' + @default_AgentJobOwner + ''' ' AS RunCode
FROM 
  dbo.sysjobs j
  JOIN
  master.sys.syslogins L
    ON J.owner_sid = L.sid
  JOIN
  dbo.syscategories C
    ON C.category_id = J.category_id
WHERE 
  L.Name NOT IN
    (
        'sa'
      , 'DWJobOwner'
      , 'CORP\fpcservice'
    )

/*┌─────────────────────────────────────────────────────────────────────────────────────────────┐*\.
  │ s26                                                                                         │
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤
  │   2018.12.17                                                                                │
  │   ──────────                                                                                │

      ALTER AUTHORIZATION on DATABASE::[DirectMail] to [sa];
      ALTER AUTHORIZATION on DATABASE::[EDW] to [sa];
      ALTER AUTHORIZATION on DATABASE::[EDW_Stage] to [sa];
      ALTER AUTHORIZATION on DATABASE::[HomeBase] to [sa];
      ALTER AUTHORIZATION on DATABASE::[Xmap] to [sa];


      EXEC msdb.dbo.sp_update_job @job_id=N'58A1C4DC-BA7B-457E-82F9-64AA2A8EE57F', @owner_login_name=N'DWJobOwner' 
      EXEC msdb.dbo.sp_update_job @job_id=N'3EF7B75C-D031-4912-837E-6755381E6326', @owner_login_name=N'DWJobOwner' 
      EXEC msdb.dbo.sp_update_job @job_id=N'EA477464-1EA2-44E7-BCB9-02AD7866797F', @owner_login_name=N'DWJobOwner' 
      EXEC msdb.dbo.sp_update_job @job_id=N'F1E6C11F-9148-4F56-89A7-6B39D3078BE7', @owner_login_name=N'DWJobOwner' 
      EXEC msdb.dbo.sp_update_job @job_id=N'3589F630-278F-4047-8C60-75502F6754A6', @owner_login_name=N'DWJobOwner' 

  ├─────────────────────────────────────────────────────────────────────────────────────────────┤
  │ s28                                                                                         │
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤
  │   2018.12.17                                                                                │
  │   ──────────                                                                                │

      ALTER AUTHORIZATION on DATABASE::[EDW] to [sa];
      ALTER AUTHORIZATION on DATABASE::[EDW_Stage] to [sa];

\*└─────────────────────────────────────────────────────────────────────────────────────────────┘*/