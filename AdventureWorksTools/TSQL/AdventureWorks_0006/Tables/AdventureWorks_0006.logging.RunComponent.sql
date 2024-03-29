/*┌─────────────────────────────────────────────────────────────────────────────────────────────┐*\
  │ TITLE: Table DDL                                                                            │
  │   AdventureWorks_0006.logging.RunComponent
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤
  │ DESCRIPTION:                                                                                │
  │   Represents a component of a direct mail proccess which can optionally be arranged into    │
  │   a hierarchy vie the ParentRunComponentID                                                  │
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤
  │ REVISION HISTORY:                                                                           │
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤
  │   DATE       AUTHOR          CHANGE DESCRIPTION                                             │
  │   ────────── ─────────────── ───────────────────────────────────────────────────────────────┤
      2018.12.13 bwarner         Initial Draft


  ├─────────────────────────────────────────────────────────────────────────────────────────────┤
  │ UNIT TESTING SCRIPTS:                                                                       │
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤


  -- Create a new component record
    INSERT
      logging.RunComponent
        (
            RunComponentName
          , RunComponentDesc
          , SequentialPosition
          , ParentRunComponentID
        )
      VALUES
        (
            ''    -- RunComponentName
          , NULL  -- RunComponentDesc
          , NULL  -- SequentialPosition
          , NULL  -- ParentRunComponentID
        )
        
    -- View existing

    SELECT * FROM logging.RunComponent
  
\*└─────────────────────────────────────────────────────────────────────────────────────────────┘*/
USE AdventureWorks_0006
GO

IF EXISTS (SELECT *
           FROM sys.objects
           WHERE object_id = OBJECT_ID(N'logging.RunComponent')
                 AND type IN (N'U'))
    DROP TABLE 
      logging.RunComponent
GO

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

IF NOT EXISTS (SELECT *
               FROM sys.objects
               WHERE object_id = OBJECT_ID(N'logging.RunComponent')
                     AND type IN (N'U'))
  BEGIN
    CREATE TABLE
      logging.RunComponent
        (
            RunComponentID        SMALLINT     NOT NULL
                                  IDENTITY(1,1)
                                  CONSTRAINT 
                                    PK_logging_RunComponent
                                  PRIMARY KEY CLUSTERED
          , ParentRunComponentID  SMALLINT      NULL
                                  CONSTRAINT
                                    FK_logging_RunComponent_ParentRunComponentID
                                  FOREIGN KEY REFERENCES
                                    logging.RunComponent(RunComponentID)
          , SequentialPosition    TINYINT       NULL
          , RunComponentName      SYSNAME       NOT NULL
                                  CONSTRAINT
                                    UN_logging_RunComponent_RunComponentName
                                  UNIQUE
          , RunComponentDesc      VARCHAR(512)  NULL
          , CreatedDate           DATETIME        NOT NULL
                                  CONSTRAINT
                                    DF_RunComponent_CreatedDate
                                  DEFAULT 
                                    GETDATE()
          , CreatedBy             SYSNAME         NOT NULL
                                  CONSTRAINT
                                    DF_RunComponent_CreatedBy
                                  DEFAULT 
                                    SUSER_NAME()
          , ModifiedDate          DATETIME        NOT NULL
                                  CONSTRAINT
                                    DF_RunComponent_ModifiedDate
                                  DEFAULT 
                                    GETDATE()
          , ModifiedBy            SYSNAME         NOT NULL
                                  CONSTRAINT
                                    DF_RunComponent_ModifiedBy
                                  DEFAULT 
                                    SUSER_NAME()
        )
  END
GO






