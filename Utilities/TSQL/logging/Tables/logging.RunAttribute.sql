/*┌─────────────────────────────────────────────────────────────────────────────────────────────┐*\
  │ TITLE: Table DDL                                                                            │
  │   Analytics_WS.logging.RunAttribute
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤
  │ DESCRIPTION:                                                                                │
  │   A place to store arbitrary attributes of intrest for a given run of a process or compone  │
  │   component                                                                                 │
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤
  │ REVISION HISTORY:                                                                           │
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤
  │   DATE       AUTHOR          CHANGE DESCRIPTION                                             │
  │   ────────── ─────────────── ───────────────────────────────────────────────────────────────┤
      2019.01.08 bwarner         Initial Draft
  └─────────────────────────────────────────────────────────────────────────────────────────────┘*/
USE Analytics_WS
GO

IF EXISTS (SELECT *
           FROM sys.objects
           WHERE object_id = OBJECT_ID(N'logging.RunAttribute')
                 AND type IN (N'U'))
    DROP TABLE 
      logging.RunAttribute
GO

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

IF NOT EXISTS (SELECT *
               FROM sys.objects
               WHERE object_id = OBJECT_ID(N'logging.RunAttribute')
                     AND type IN (N'U'))
  BEGIN
    CREATE TABLE
      logging.RunAttribute
        (
            RunLogID        BIGINT          NOT NULL
                            CONSTRAINT
                              FK_RunAttribute_RunLogID
                            FOREIGN KEY REFERENCES
                              logging.RunLog(RunLogID)
          , AttributeName   NVARCHAR(128)   NOT NULL
          , AttributeValue  NVARCHAR(MAX)   NULL
          , CONSTRAINT
              PK_logging_RunAttribute
            PRIMARY KEY CLUSTERED
              (
                  RunLogID DESC
                , AttributeName 
              )
        )
  END
GO

