$JobName = 'Post Bulk Lead Delete Replication Reset'

$Manifest = @(

, 'LeadHistory'
, 'OpportunityFieldHistory'
, 'Credit_Review__History'
, 'exception_requests__history'
, 'AccountHistory'
, 'CaseHistory'
)

$sql=@"

/*┌─────────────────────────────────────────────────────────────────────────────────────────────┐
  │ SQL AGENT JOB: $($JobName.PadRight(100-16-7))│    
  └─────────────────────────────────────────────────────────────────────────────────────────────┘*/

USE [msdb]
GO

DECLARE 
    @jobId      BINARY(16)

SELECT @jobId = job_id
FROM msdb.dbo.sysjobs
WHERE [name] = N'$($JobName)'

IF @jobId IS NOT NULL
  EXEC msdb.dbo.sp_delete_job @jobId
GO

DECLARE 
    @ReturnCode INT        = 0
  , @jobId      BINARY(16)

EXEC @ReturnCode = msdb.dbo.sp_add_job 
    @job_name                    = N'$($JobName)'
  , @enabled                     = 1
  , @notify_level_eventlog       = 0
  , @notify_level_email          = 3
  , @notify_level_netsend        = 0
  , @notify_level_page           = 0
  , @delete_level                = 0
  , @description                 = N'After a sufficently large bulk delete of leads in the backend of Salesforce, this job fixes tables that will need to be replicated in DBAmp in order to get the scheduled refreshes to work'
  , @category_name               = N'[Uncategorized (Local)]'
  , @owner_login_name            = N'DWJobOwner'
  , @notify_email_operator_name  = N'DWAdmins'
  , @job_id                      = @jobId OUTPUT

"@
$i=0
$Manifest|%{
$i++
if($i -eq $Manifest.Count)
  {$on_success_action = 1}
else
  {$on_success_action = 3}
    
$sql+=@"

/*┌────────────────────────────────────────────────────────────────────┐
  │ ADD JOB STEP: $($_.PadRight(53))│
  └────────────────────────────────────────────────────────────────────┘*/

EXEC @ReturnCode = msdb.dbo.sp_add_jobstep 
    @job_id               = @jobId
  , @step_name            = N'Replicate $($_) w/ PKChunk'
  , @step_id              = $($i)
  , @cmdexec_success_code = 0
  , @on_success_action    = $on_success_action
  , @on_success_step_id   = 0
  , @on_fail_action       = 2
  , @on_fail_step_id      = 0
  , @retry_attempts       = 0
  , @retry_interval       = 0
  , @os_run_priority      = 0
  , @subsystem            = N'TSQL'
  , @command              = N'

/*┌────────────────────────────────────────────────────────────────────┐
  │ REPLICATE TABLE : $($_.PadRight(49))│
  └────────────────────────────────────────────────────────────────────┘*/

EXEC Salesforce_Repl.dbo.SF_Replicate
    @table_server  = ''SALESFORCE''
  , @table_name    = ''$($_)''
  , @options       = ''PKChunk,BatchSize(100000)''

'
  , @database_name        = N'Salesforce_Repl'
  , @flags                = 4

"@

}

$sql+=@'


EXEC @ReturnCode = msdb.dbo.sp_add_jobserver 
    @job_id      = @jobId
  , @server_name = N'(local)'

'@


$sql|oh






