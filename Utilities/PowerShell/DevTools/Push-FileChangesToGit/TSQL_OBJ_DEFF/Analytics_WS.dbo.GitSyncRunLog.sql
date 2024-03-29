/*┌─────────────────────────────────────────────────────────────────────────────────────────────┐*\
  │ TITLE: Table DDL                                                                            │
  │   Analytics_WS.dbo.GitSyncRunLog
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤
  │ DESCRIPTION:                                                                                │
  │                                                                                             │
  │                                                                                             │
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤
  │ REVISION HISTORY:                                                                           │
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤
  │   DATE       AUTHOR          CHANGE DESCRIPTION                                             │
  │   ────────── ─────────────── ───────────────────────────────────────────────────────────────┤
      2018.10.31 bwarner         Initial Draft

  ├─────────────────────────────────────────────────────────────────────────────────────────────┤
  │ REVISION HISTORY:                                                                           │
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤

    INSERT
      dbo.GitSyncRunLog
        (
            SyncSetKey
          , SyncFrom
          , SyncTo
        )
    VALUES
      (
          'DEPTS_BI_SQL_Library_Obay_Analytics'
        , '10/15/2018 08:45:00'
        , '10/30/2018 20:07:46'
      )


    INSERT
      dbo.GitSyncRunLog
        (
            SyncSetKey
          , SyncFrom
          , SyncTo
          , DidComplete
        )
    VALUES
      (
          'DEPTS_BI_SQL_Library_Obay_Analytics'
        , '10/15/2018 08:45:00'
        , '10/30/2018 20:07:46'
        , 1
      )


\*└─────────────────────────────────────────────────────────────────────────────────────────────┘*/
USE Analytics_WS
GO

IF EXISTS (SELECT *
           FROM sys.objects
           WHERE object_id = OBJECT_ID(N'dbo.GitSyncRunLog')
                 AND type IN (N'U'))
    DROP TABLE 
      dbo.GitSyncRunLog
GO

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

IF NOT EXISTS (SELECT *
               FROM sys.objects
               WHERE object_id = OBJECT_ID(N'dbo.GitSyncRunLog')
                     AND type IN (N'U'))
  BEGIN
    CREATE TABLE
      dbo.GitSyncRunLog
        (
            GitSyncRunLogID   INT        NOT NULL
                              IDENTITY(1,1)
                              CONSTRAINT 
                                PK_dbo_GitSyncRunLog
                              PRIMARY KEY CLUSTERED
          , SyncSetKey        VARCHAR(128)   NOT NULL
          , SyncFrom          DATETIME NOT NULL
          , SyncTo            DATETIME NOT NULL
          , FileCount         INT NULL
          , DidComplete       BIT NOT NULL
                              CONSTRAINT
                                DF_GitSyncRunLog_WasSuccessful
                              DEFAULT (CAST(0 AS BIT))
        )
  END
GO

