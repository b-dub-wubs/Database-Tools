/*┌─────────────────────────────────────────────────────────────────────────────────────────────┐*\
  │ TITLE: Stored Procedure DDL                                                                 │
  │   DirectMail.logging.usp_EventMessage_Log
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤
  │ DESCRIPTION:                                                                                │
      Logs an event message to logging.EventMessage, also using RAISERROR w/ NOWAIT option to
      print message immediatly to the message stream
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤
  │ REVISION HISTORY:                                                                           │
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤
  │   DATE       AUTHOR          CHANGE DESCRIPTION                                             │
  │   ────────── ─────────────── ────────────────────────────────────────────────────────────── │
      2018.12.12 bwarner         Initial Draft
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤
  │ NOTES:                                                                                      │
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤

      BOL RAISEERROR Severity: 
      ========================

      https://docs.microsoft.com/en-us/sql/relational-databases/errors-events/database-engine-error-severities?view=sql-server-2017

      severity
      Is the user-defined severity level associated with this message. When using msg_id 
      to raise a user-defined message created using sp_addmessage, the severity specified 
      on RAISERROR overrides the severity specified in sp_addmessage.

      Severity levels from 0 through 18 can be specified by any user. Severity levels from 
      19 through 25 can only be specified by members of the sysadmin fixed server role or 
      users with ALTER TRACE permissions. For severity levels from 19 through 25, the WITH LOG 
      option is required. Severity levels less than 0 are interpreted as 0. Severity levels 
      greater than 25 are interpreted as 25.

      On Message ID:
      ==============

      msg_id
      ──────
      Is a user-defined error message number stored in the sys.messages catalog view 
      using sp_addmessage. Error numbers for user-defined error messages should be greater than 
      50000. When msg_id is not specified, RAISERROR raises an error message with an error 
      number of 50000.

      see also system table sys.messages

USE DirectMail
GO

\*└─────────────────────────────────────────────────────────────────────────────────────────────┘*/


IF EXISTS 
  (
    SELECT 
      * 
    FROM 
      sys.objects 
    WHERE 
          [object_id] = OBJECT_ID(N'logging.usp_EventMessage_Log') 
      AND [type] IN(N'P', N'PC')
  )
	DROP PROCEDURE 
    logging.usp_EventMessage_Log
GO

CREATE PROCEDURE 
  logging.usp_EventMessage_Log
    (
        @EventMessage     NVARCHAR(MAX)
      , @MsgID            INT           = 50000
      , @ErrSeverity      INT           = 0
      , @ErrState         INT           = 0
      , @ProcName         SYSNAME       = NULL
      , @Line             INT           = NULL
      , @Verbose          BIT           = 0
      , @DisplayTimeStamp BIT           = 1
    )
AS
BEGIN

  SET NOCOUNT ON

  DECLARE 
      @DisplayMsg             NVARCHAR(MAX)   = ''
    , @ScanProgressCharIndex  BIGINT          = 1
    , @RaiserrorMaxLen        INT             = 2047
    , @BufferScanChunkLen     INT             = 2047

    , @DisplayBuffer          NVARCHAR(2047)
    , @MsgLenOrig             INT             = LEN(@EventMessage)
    , @DonePipingToDisplay    BIT             = 0
    , @DisplayGroupCalcPos    SMALLINT        = 1
    , @DisplayStrLen          BIGINT          = 0

    , @NLLB_Buffer            NVARCHAR(2047)
    , @NLLB_BufferLen         SMALLINT   
    , @NLLB_ThisChar          CHAR(1) 
    , @NLLB_SearchDone        BIT             = 0
    , @NLLB_NewlineFound      BIT             = 0
    , @NLLB_LookbackLen       INT             = 0     
    
  IF @DisplayTimeStamp = 1
    SET @DisplayMsg = CONVERT(NVARCHAR(50), GETDATE(), 21) + N' '

  IF @Verbose = 1
    SET @DisplayMsg += N'{' + ISNULL(CAST(@MsgID AS NVARCHAR(MAX)), N'0') + N',' +  ISNULL(CAST(@ErrSeverity AS NVARCHAR(MAX)), N'0') + N',' + ISNULL(CAST(@ErrState AS NVARCHAR(MAX)), N'0') + N'} '
        
  SET @DisplayMsg +=  REPLACE(@EventMessage,N'%',N'%%') 

  IF @ProcName IS NOT NULL AND @Verbose = 1
    SET @DisplayMsg += N' SPROC: ' + @ProcName
 
  IF @Line IS NOT NULL AND @Verbose = 1
    SET @DisplayMsg += N'[LN:' + CAST(@Line AS NVARCHAR(MAX)) + N']'

  SET @DisplayStrLen = ISNULL(LEN(@DisplayMsg),0) + ISNULL(LEN(@EventMessage),0)

  INSERT
    logging.EventMessage
      (
          EventMessage
        , ErrSeverity
        , ErrState
        , ProcName
        , Line
      )
  VALUES
    (
        ISNULL(@EventMessage, N'<CORRUPTED>')
      , ISNULL(@ErrSeverity, 0)
      , ISNULL(@ErrState, 0)
      , ISNULL(@ProcName, N'?')
      , ISNULL(@Line, -1)
    )

/*┌────────────────────────────────────────────────────────────────────┐*\.
  │ RAISERROR can only display 2044 characters; if our event message   │
  │ is longer than that, chunk through the message and throw out a     │
  │ RAISERROR /w NOWAIT for each chunk. In case the error severity is  │
  │ halting, make sure we override the actual severity with 0 until    │
  │ we have reached the very last message chunk.                       │
\*└────────────────────────────────────────────────────────────────────┘*/
  IF LEN(@DisplayMsg) <= @RaiserrorMaxLen
    RAISERROR(@DisplayMsg, @ErrSeverity, @ErrState) WITH NOWAIT
  ELSE  
    BEGIN

      -- Loop till the whole message text has been processed
      WHILE @DonePipingToDisplay = 0 
        BEGIN

          /*┌────────────────────────────────────────────────────────────────────┐
              Find the tailing newline/carriage return in this buffered message
              chunk if it exists
            └────────────────────────────────────────────────────────────────────┘*/
          SELECT 
              @NLLB_SearchDone    = 0
            , @NLLB_NewlineFound  = 0
            , @NLLB_LookbackLen   = 0
            , @NLLB_ThisChar      = NULL
            , @NLLB_Buffer        = SUBSTRING(@DisplayMsg, @ScanProgressCharIndex, @BufferScanChunkLen)

          SET @NLLB_BufferLen = LEN(@NLLB_Buffer)

          IF @NLLB_Buffer LIKE '%' + CHAR(10) + '%' OR @NLLB_Buffer LIKE '%' + CHAR(13) + '%'
            WHILE @NLLB_SearchDone = 0
              BEGIN
                SET @NLLB_ThisChar = SUBSTRING(@NLLB_Buffer, @NLLB_BufferLen - @NLLB_LookbackLen - 1, 1)
                IF @NLLB_ThisChar IN(CHAR(10), CHAR(13))
                  SELECT 
                      @NLLB_SearchDone    = 1
                    , @NLLB_NewlineFound  = 1
                SET @NLLB_LookbackLen += 1
                IF @NLLB_LookbackLen >= @NLLB_BufferLen
                  SELECT 
                      @NLLB_SearchDone    = 1
                    , @NLLB_NewlineFound  = 0
                    , @NLLB_LookbackLen   = 0
              END

          /*┌────────────────────────────────────────────────────────────────────┐
              Increment the scan buffer: 
                Scan the next chunk
                Increment the progress index
            └────────────────────────────────────────────────────────────────────┘*/ 
          SET @DisplayBuffer = SUBSTRING(@DisplayMsg, @ScanProgressCharIndex, @BufferScanChunkLen - @NLLB_LookbackLen)  
          SET @ScanProgressCharIndex += @BufferScanChunkLen - @NLLB_LookbackLen

          --Is this the last message chunk?
          IF @ScanProgressCharIndex >= @DisplayStrLen
            RAISERROR(@DisplayBuffer, @ErrSeverity, @ErrState) WITH NOWAIT
          ELSE
            RAISERROR(@DisplayBuffer, 0, 0) WITH NOWAIT

          --SELECT 
          --    DisplayStrLen = @DisplayStrLen
          --  , NewlineBacktrackLen = @NLLB_LookbackLen
          --  , ScanProgressCharIndex = @ScanProgressCharIndex
          --  , LinebreakSearchBuffer = @NLLB_Buffer

          IF @ScanProgressCharIndex >= @DisplayStrLen
            SET @DonePipingToDisplay = 1

        END
    END
END
GO

/*┌─────────────────────────────────────────────────────────────────────────────────────────────┐
  │ UNIT TESTING SCRIPTS:                                                                       │
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤

      SELECT * FROM logging.EventMessage

      -- Try-Catch scenario from within a stored procedure
      IF EXISTS 
        (
          SELECT 
            * 
          FROM 
            sys.objects 
          WHERE 
                [object_id] = OBJECT_ID(N'logging.usp_testLogging') 
            AND [type] IN(N'P', N'PC')
        )
        DROP PROCEDURE 
          logging.usp_testLogging
      GO


      CREATE PROCEDURE 
        logging.usp_testLogging
      AS
      BEGIN

        SET NOCOUNT ON

        BEGIN TRY
          RAISERROR('dummy error try-catch',12,0)
        END TRY
        BEGIN CATCH

          DECLARE
              @EventMessage   NVARCHAR(MAX) = ERROR_MESSAGE()
            , @MsgID          INT           = ERROR_NUMBER()
            , @ErrSeverity    INT           = ERROR_SEVERITY()
            , @ErrState       INT           = ERROR_STATE()
            , @ProcName       SYSNAME       = ERROR_PROCEDURE()
            , @Line           INT           = ERROR_LINE()
            , @SchemaName     SYSNAME       = OBJECT_SCHEMA_NAME(@@PROCID)
            , @ObjectName     SYSNAME       = OBJECT_NAME(@@PROCID)
            , @RowsAffected   BIGINT        = NULL --@@ROWCOUNT 

          EXEC logging.usp_EventMessage_Log 
              @EventMessage   = @EventMessage
            , @MsgID          = @MsgID
            , @ErrSeverity    = @ErrSeverity
            , @ErrState       = @ErrState
            , @ProcName       = @ProcName
            , @Line           = @Line
            , @SchemaName     = @SchemaName
            , @ObjectName     = @ObjectName
            , @RowsAffected   = @RowsAffected

          --THROW

        END CATCH

      END
      GO


      EXEC logging.usp_testLogging

      SELECT * FROM logging.EventMessage

      SELECT TOP 500
          rc.RunComponentName
        , rl.Executed
        , rl.DidSucceed
        , ra.AttributeName
        , ra.AttributeValue
      FROM 
        logging.RunLog rl
        JOIN
        logging.RunAttribute ra
          ON rl.RunLogID = ra.RunLogID
        JOIN
        logging.RunComponent rc
          ON rc.RunComponentID = rl.RunComponentID
      ORDER BY
        rl.Executed DESC

      SELECT * FROM logging.RunAttribute
      SELECT * FROM logging.runlog

  └─────────────────────────────────────────────────────────────────────────────────────────────┘*/



