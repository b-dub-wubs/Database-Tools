/*┌─────────────────────────────────────────────────────────────────────────────────────────────┐
  │ TITLE: Stored Procedure DDL                                                                 │
  │   __DATABASE_NAME__.__SCHEMA_NAME__.__SPROC_NAME__
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤
  │ DESCRIPTION:                                                                                │
      
  └─────────────────────────────────────────────────────────────────────────────────────────────┘*/
USE __DATABASE_NAME__
GO

IF EXISTS 
  (
    SELECT 
      * 
    FROM 
      sys.objects 
    WHERE 
          [object_id] = OBJECT_ID(N'__SCHEMA_NAME__.__SPROC_NAME__') 
      AND [type] IN(N'P', N'PC')
  )
	DROP PROCEDURE 
    __SCHEMA_NAME__.__SPROC_NAME__
GO

CREATE PROCEDURE 
  __SCHEMA_NAME__.__SPROC_NAME__
    (
        @LineageRunLogID  BIGINT  = NULL
      , @Verbose          BIT     = 0
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

    --__MAIN_BODY____BALL_INTO_COMPONENTS_AS_NEEDED__


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

/*┌─────────────────────────────────────────────────────────────────────────────────────────────┐
  │                                                                                             │
  └─────────────────────────────────────────────────────────────────────────────────────────────┘*/

/*┌────────────────────────────────────────────────────────────────────┐
  │                                                                    │
  └────────────────────────────────────────────────────────────────────┘*/

/*┌───────────────────────────────────────────┐
  │                                           │
  └───────────────────────────────────────────┘*/

/*┌─────────────────────────────────────────────────────────────────────────────────────────────┐
  │ UNIT TESTING SCRIPTS:                                                                       │
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤

    EXEC __SCHEMA_NAME__.__SPROC_NAME__ 
        @param_1 = ''
      , @param_2 = ''
      , @param_3 = ''


    SET IDENTITY_INSERT __SCHEMA_NAME__._TABLE_NAME_ ON
    SET IDENTITY_INSERT __SCHEMA_NAME__._TABLE_NAME_ OFF

  └─────────────────────────────────────────────────────────────────────────────────────────────┘

  ┌─────────────────────────────────────────────────────────────────────────────────────────────┐
  │ EXAMPLE: Log An Event Message                                                               │
  └─────────────────────────────────────────────────────────────────────────────────────────────┘

  EXEC logging.usp_EventMessage_Log @EventMessage='__MSG_TXT__', @ProcName=@ProcName

  ┌─────────────────────────────────────────────────────────────────────────────────────────────┐
  │ EXAMPLE: Run Component Log Start & Finish                                                   │
  └─────────────────────────────────────────────────────────────────────────────────────────────┘

    /*┌────────────────────────────────────────────────────────────────────┐
      │ __RUN_COMPONENT_NAME__
      └────────────────────────────────────────────────────────────────────┘*__WHAK__
    SET @RunLogID_step = NULL
    EXEC logging.usp_RunLog_LogBegin 
        @ParentRunLogID   = @RunLogID_sproc
      , @RunComponentName = '__RUN_COMPONENT_NAME__'
      , @RunLogID         = @RunLogID_step OUTPUT


     --__COMPONENT_BODY__


    EXEC logging.usp_RunLog_LogEnd 
        @RunLogID   = @RunLogID_step
      , @ReturnCode = NULL
      , @DidSucceed = 1

  ┌─────────────────────────────────────────────────────────────────────────────────────────────┐
  │ EXAMPLE: Log an arbitray attribut against a run log component                               │
  └─────────────────────────────────────────────────────────────────────────────────────────────┘

    EXEC logging.usp_RunAttribute_Set 
        @RunLogID       = @RunLogID_step
      , @AttributeName  = '__RUN_ATTRIB___'
      , @AttributeValue = '__RUN_ATTRIB_VALUE__' 

  ┌─────────────────────────────────────────────────────────────────────────────────────────────┐
  │ EXAMPLE: Log Rows Affected Against Run Component                                            │
  └─────────────────────────────────────────────────────────────────────────────────────────────┘

    SET @RowsAffected = @@ROWCOUNT
    EXEC logging.usp_RowsAffected_Log 
        @RunLogID       = @RunLogID_step
      , @OperationType  = 'insert'
      , @RowsAffected   = @RowsAffected
      , @ObjectName     = 'Lead_Staging_Update'

   Operation Types:
      insert
      update
      delete
      archive

  ┌─────────────────────────────────────────────────────────────────────────────────────────────┐
  │ RUN COMPONENT CONFIG WIDGET                                                                 │
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤
    DECLARE 
        @RunComponentID_parent  SMALLINT 
      , @RunComponentID_child   SMALLINT 

    -- Master Sproc
    EXEC logging.usp_RunComponent_Add
        @RunComponentName     = '__SPROC_NAME__' 
      , @RunComponentDesc     = '__IT_DOES_THIS__'
      , @ParentRunComponentID = NULL
      , @SequentialPosition   = NULL
      , @RunComponentID       = @RunComponentID_parent OUTPUT


    -- Level 1 Child Components
    EXEC logging.usp_RunComponent_Add
        @RunComponentName     = '__A_CHILD_COMPOENENT___' 
      , @RunComponentDesc     = '__IT_DOES_THIS__'
      , @ParentRunComponentID = @RunComponentID_parent
      , @SequentialPosition   = 1
      , @RunComponentID       = @RunComponentID_child OUTPUT

    EXEC logging.usp_RunComponent_Add
        @RunComponentName     = '__A_CHILD_COMPOENENT___' 
      , @RunComponentDesc     = '__IT_DOES_THIS__'
      , @ParentRunComponentID = @RunComponentID_parent
      , @SequentialPosition   = 2
      , @RunComponentID       = @RunComponentID_child OUTPUT


    -- Level 2 Grandchile Components
    EXEC logging.usp_RunComponent_Add
        @RunComponentName     = '__A_GRANDCHILD_COMPOENENT___' 
      , @RunComponentDesc     = '__IT_DOES_THIS__'
      , @ParentRunComponentID = @RunComponentID_child
      , @SequentialPosition   = NULL
      , @RunComponentID       = @RunComponentID_child2 OUTPUT

  └─────────────────────────────────────────────────────────────────────────────────────────────┘*/