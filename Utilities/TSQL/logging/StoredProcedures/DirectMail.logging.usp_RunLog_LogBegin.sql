/*┌─────────────────────────────────────────────────────────────────────────────────────────────┐*\
  │ TITLE: Stored Procedure DDL                                                                 │
  │   DirectMail.logging.usp_RunLog_LogBegin
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤
  │ DESCRIPTION:                                                                                │
      
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤
  │ REVISION HISTORY:                                                                           │
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤
  │   DATE       AUTHOR          CHANGE DESCRIPTION                                             │
  │   ────────── ─────────────── ────────────────────────────────────────────────────────────── │
      2018.12.17 bwarner         Initial Draft
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤
  │ UNIT TESTING SCRIPTS:                                                                       │

      DECLARE 
          @RunLogID BIGINT

      EXEC logging.usp_RunLog_LogBegin 
          @ParentRunLogID   = NULL
        , @RunComponentName = '__RUN_COMPONENT_NAME__'
        , @RunLogID         = @RunLogID OUTPUT

        -- DO STUFF

      EXEC logging.usp_RunLog_LogEnd 
          @RunLogID   =  @RunLogID
        , @ReturnCode = NULL
        , @DidSucceed   = 1

\*└─────────────────────────────────────────────────────────────────────────────────────────────┘*/
--USE DirectMail
--GO

IF EXISTS 
  (
    SELECT 
      * 
    FROM 
      sys.objects 
    WHERE 
          [object_id] = OBJECT_ID(N'logging.usp_RunLog_LogBegin') 
      AND [type] IN(N'P', N'PC')
  )
	DROP PROCEDURE 
    logging.usp_RunLog_LogBegin
GO

CREATE PROCEDURE 
  logging.usp_RunLog_LogBegin
    (
        @ParentRunLogID   BIGINT = NULL
      , @RunComponentName SYSNAME 
      , @RunLogID         BIGINT OUTPUT
    )
AS
BEGIN
 
  DECLARE
      @RunComponentID SMALLINT
    , @ThisProcName   SYSNAME       = OBJECT_NAME(@@PROCID)
    , @EventMessage   NVARCHAR(MAX)

  SELECT
    @RunComponentID = RunComponentID
  FROM
    logging.RunComponent
  WHERE
    RunComponentName = @RunComponentName

  IF @RunComponentID IS NULL
    BEGIN
      SET @EventMessage = N'Could not find run component: ' + ISNULL(@RunComponentName,N'NULL') + N'; Correct the component name or create a new record in logging.RunComponent to support logging against this component'
      EXEC logging.usp_EventMessage_Log
          @ProcName     = @ThisProcName
        , @EventMessage = @EventMessage
        , @ErrSeverity  = 11 
    END

  IF @ParentRunLogID IS NOT NULL AND NOT EXISTS( SELECT 1 FROM logging.RunLog WHERE RunLogID = @ParentRunLogID) 
    BEGIN
      SET @EventMessage = N'Invalid ParentRunLogID. Could not find parent RunLogID : ' + CAST(@ParentRunLogID AS NVARCHAR(MAX)) + N' in logging.RunLog.'
      EXEC logging.usp_EventMessage_Log
          @ProcName     = @ThisProcName
        , @EventMessage = @EventMessage
        , @ErrSeverity  = 11
    END

  INSERT
    logging.RunLog
      (
          ParentRunLogID
        , RunComponentID
      )
    VALUES
      (
          @ParentRunLogID
        , @RunComponentID
      )
    
  SET @RunLogID = SCOPE_IDENTITY()

  SET @EventMessage = N'
┌─────────────────────────────────────────────────────────────────────────────────────────────┐'
  IF @ParentRunLogID IS NOT NULL
    SET @EventMessage +=
N'
│ ' + ( SELECT 
          ParentRunComponentName = rc.RunComponentName 
        FROM 
          logging.RunLog rl 
          JOIN 
          logging.RunComponent rc 
            ON rl.RunComponentID = rc.RunComponentID 
            AND rl.RunLogID = @ParentRunLogID
                 ) + N' <started component>
│     ►►► ' + @RunComponentName
  ELSE
    SET @EventMessage +=
N'
│ COMPONENT STARTED  ►►► ' + @RunComponentName

  SET @EventMessage += N'
└─────────────────────────────────────────────────────────────────────────────────────────────┘
'
  EXEC logging.usp_EventMessage_Log @EventMessage=@EventMessage,@ProcName=@ThisProcName

END
GO

/*
┌─────────────────────────────────────────────────────────────────────────────────────────────┐
│ sp_setSfStagingAcq_vNext <started component>
│     ►►► Acq Mail Staging Table Load : Lead Update
└─────────────────────────────────────────────────────────────────────────────────────────────┘
*/