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
  │ TITLE: Stored Procedure DDL                                                                 │
  │   Analytics_WS.dbo.usp_PostBulkLeadDeleteReplicationRebasline
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤
  │ DESCRIPTION:                                                                                │
      
  └─────────────────────────────────────────────────────────────────────────────────────────────┘*/
USE Analytics_WS
GO

IF EXISTS 
  (
    SELECT 
      * 
    FROM 
      sys.objects 
    WHERE 
          [object_id] = OBJECT_ID(N'dbo.usp_PostBulkLeadDeleteReplicationRebasline') 
      AND [type] IN(N'P', N'PC')
  )
	DROP PROCEDURE 
    dbo.usp_PostBulkLeadDeleteReplicationRebasline
GO

CREATE PROCEDURE 
  dbo.usp_PostBulkLeadDeleteReplicationRebasline
    (
        @LineageRunLogID  BIGINT  = NULL
    )
AS
BEGIN
  /*┌────────────────────────────────────────────────────────────────────┐
    │ Variable Declarations & Logging Initialization                     │ 
    └────────────────────────────────────────────────────────────────────┘*/  
  DECLARE 
      @EventMessage         NVARCHAR(MAX)
    , @ProcName             SYSNAME       = OBJECT_NAME(@@PROCID)
    , @RunLogID_sproc       BIGINT
    , @RunLogID_step        BIGINT
    , @RowsAffected         BIGINT
    , @MsgID                INT 
    , @ErrSeverity          INT 
    , @ErrState             INT 
    , @Line                 INT
    , @DidSucceed           BIT           = 1
    , @ReturnCode           INT           = 0

  EXEC logging.usp_RunLog_LogBegin 
      @RunComponentName = @ProcName
    , @ParentRunLogID   = @LineageRunLogID     
    , @RunLogID         = @RunLogID_sproc OUTPUT

  EXEC logging.usp_EventMessage_Log @EventMessage='__MSG_TXT__', @ProcName=@ProcName

  /*┌────────────────────────────────────────────────────────────────────┐
    │ Master Try-Catch                                                   │ 
    └────────────────────────────────────────────────────────────────────┘*/  
  BEGIN TRY




"@
$RunComponentConfigSql = @"

/*┌─────────────────────────────────────────────────────────────────────────────────────────────┐
  │ RUN COMPONENT CONFIG WIDGET                                                                 │
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤
    DECLARE 
        @RunComponentID_parent  SMALLINT 
      , @RunComponentID_child   SMALLINT 

    -- Master Sproc
    EXEC logging.usp_RunComponent_Add
        @RunComponentName     = 'usp_PostBulkLeadDeleteReplicationRebasline' 
      , @RunComponentDesc     = 'Puts the Salesforce replication tables back into a state where normal refresh jobs can be run after a bulk lead delete has been performed'
      , @ParentRunComponentID = NULL
      , @SequentialPosition   = NULL
      , @RunComponentID       = @RunComponentID_parent OUTPUT

"@
$i=0
$Manifest|%{
$ThisRunComponentName = "Rebaseline $($_) Replication"
$i++
if($i -eq $Manifest.Count)
  {$on_success_action = 1}
else
  {$on_success_action = 3}
    
$sql+=@"

    /*┌────────────────────────────────────────────────────────────────────┐*\.
      │ BEGIN: $ThisRunComponentName
    \*└────────────────────────────────────────────────────────────────────┘*/
    SET @RunLogID_step = NULL
    EXEC logging.usp_RunLog_LogBegin 
        @ParentRunLogID   = @RunLogID_sproc
      , @RunComponentName = '$ThisRunComponentName'
      , @RunLogID         = @RunLogID_step OUTPUT

    BEGIN TRY

      EXEC Salesforce_Repl.dbo.SF_Replicate
          @table_server  = 'SALESFORCE'
        , @table_name    = '$($_)'
        , @options       = 'PKChunk,BatchSize(100000)'

    END TRY

    BEGIN CATCH
 
      SELECT
          @EventMessage       = ERROR_MESSAGE()
        , @MsgID              = ERROR_NUMBER()
        , @ErrSeverity        = ERROR_SEVERITY()
        , @ErrState           = ERROR_STATE()
        , @ProcName           = ERROR_PROCEDURE()
        , @Line               = ERROR_LINE()
        , @ReturnCode         = -1
        , @DidSucceed         = 0

      /*┌────────────────────────────────────────────────────────────────────┐
        │ Override error severity and state to prevent error from halting    │
        │ execution                                                          │
        └────────────────────────────────────────────────────────────────────┘*/
      IF @ErrSeverity <> 0 OR @ErrState <> 0
        BEGIN          
          SELECT
              @ErrSeverity  = 0
            , @ErrState     = 0
          SET @EventMessage += N'\n\n\t >> [OVERRIDDEN SEVERITY,STATE:' + CAST(@ErrSeverity AS NVARCHAR(MAX)) + N',' + CAST(@ErrState AS NVARCHAR(MAX)) + N']'
        END

      EXEC logging.usp_EventMessage_Log 
          @EventMessage   = @EventMessage
        , @MsgID          = @MsgID
        , @ErrSeverity    = @ErrSeverity
        , @ErrState       = @ErrState
        , @ProcName       = @ProcName
        , @Line           = @Line

    END CATCH
 
    EXEC logging.usp_RunLog_LogEnd 
        @RunLogID   = @RunLogID_step
      , @ReturnCode = @ReturnCode
      , @DidSucceed = @DidSucceed
      



"@



$RunComponentConfigSql += @"



    -- Level 1 Child Components
    EXEC logging.usp_RunComponent_Add
        @RunComponentName     = '$ThisRunComponentName' 
      , @RunComponentDesc     = 'Replicates $_ using PK Chunk to rebaselines this particular table after a bulk lead delete operation in the backend of Salesforce '
      , @ParentRunComponentID = @RunComponentID_parent
      , @SequentialPosition   = $i
      , @RunComponentID       = @RunComponentID_child OUTPUT



"@

}

$sql+=@'


  END TRY
  BEGIN CATCH

    SELECT
        @EventMessage   = ERROR_MESSAGE()
      , @MsgID          = ERROR_NUMBER()
      , @ErrSeverity    = ERROR_SEVERITY()
      , @ErrState       = ERROR_STATE()
      , @ProcName       = ERROR_PROCEDURE()
      , @Line           = ERROR_LINE()
      , @DidSucceed     =  0
      , @ReturnCode     = -1

  END CATCH 

  /*┌───────────────────────────────────────────┐
    │  Log Precedure Completion                 │
    └───────────────────────────────────────────┘*/
  IF @RunLogID_step IS NOT NULL
    EXEC logging.usp_RunLog_LogEnd 
        @RunLogID   = @RunLogID_step
      , @ReturnCode = @ReturnCode
      , @DidSucceed = @DidSucceed

  EXEC logging.usp_RunLog_LogEnd 
      @RunLogID   = @RunLogID_sproc
    , @ReturnCode = @ReturnCode
    , @DidSucceed = @DidSucceed

  IF @DidSucceed = 0   
    EXEC logging.usp_EventMessage_Log 
        @EventMessage   = @EventMessage
      , @MsgID          = @MsgID
      , @ErrSeverity    = @ErrSeverity
      , @ErrState       = @ErrState
      , @ProcName       = @ProcName
      , @Line           = @Line    
END
GO

'@


$sql|oh



$RunComponentConfigSql|oh



