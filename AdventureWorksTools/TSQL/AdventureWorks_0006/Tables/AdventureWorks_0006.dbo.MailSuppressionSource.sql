/*┌─────────────────────────────────────────────────────────────────────────────────────────────┐*\
  │ TITLE: Table DDL                                                                            │
  │   AdventureWorks_0006.dbo.MailSuppressionSource
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤
  │ DESCRIPTION:                                                                                │
  │                                                                                             │
  │                                                                                             │
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤
  │ REVISION HISTORY:                                                                           │
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤
  │   DATE       AUTHOR          CHANGE DESCRIPTION                                             │
  │   ────────── ─────────────── ───────────────────────────────────────────────────────────────┤
      2018.11.12 bwarner         Initial Draft

  ├─────────────────────────────────────────────────────────────────────────────────────────────┤
  │ Initial Populate table script                                                               │
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤

  SELECT * FROM dbo.MailSuppressionSource

\*└─────────────────────────────────────────────────────────────────────────────────────────────┘*/
USE AdventureWorks_0006
GO

IF EXISTS (SELECT *
           FROM sys.objects
           WHERE object_id = OBJECT_ID(N'dbo.MailSuppressionSource')
                 AND type IN (N'U'))
    DROP TABLE 
      dbo.MailSuppressionSource
GO

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

IF NOT EXISTS (SELECT *
               FROM sys.objects
               WHERE object_id = OBJECT_ID(N'dbo.MailSuppressionSource')
                     AND type IN (N'U'))
  BEGIN
    CREATE TABLE
      dbo.MailSuppressionSource
        (
            MailSuppressionSourceID   TINYINT         NOT NULL
                                      IDENTITY(1,1)
                                      CONSTRAINT 
                                        PK_dbo_MailSuppressionSource
                                      PRIMARY KEY CLUSTERED
          , MailSuppressionSourceName VARCHAR(128)    NOT NULL
          , MailSuppressionSourceDesc VARCHAR(512)    NULL
          , CreatedDate               DATETIME        NOT NULL
                                      CONSTRAINT
                                        DF_MailSuppressionSource_CreatedDate
                                      DEFAULT 
                                        GETDATE()
          , CreatedBy                 SYSNAME         NOT NULL
                                      CONSTRAINT
                                        DF_MailSuppressionSource_CreatedBy
                                      DEFAULT 
                                        SUSER_NAME()
          , ModifiedDate              DATETIME        NOT NULL
                                      CONSTRAINT
                                        DF_MailSuppressionSource_ModifiedDate
                                      DEFAULT 
                                        GETDATE()
          , ModifiedBy                SYSNAME         NOT NULL
                                      CONSTRAINT
                                        DF_MailSuppressionSource_ModifiedBy
                                      DEFAULT 
                                        SUSER_NAME()
        )
  END
GO






