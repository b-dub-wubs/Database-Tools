/*┌─────────────────────────────────────────────────────────────────────────────────────────────┐*\
  │ TITLE: Table DDL                                                                            │
  │   AdventureWorks_0006.ref.ZipCode
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤
  │ DESCRIPTION:                                                                                │
  │                                                                                             │
  │                                                                                             │
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤
  │ REVISION HISTORY:                                                                           │
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤
  │   DATE       AUTHOR          CHANGE DESCRIPTION                                             │
  │   ────────── ─────────────── ───────────────────────────────────────────────────────────────┤
      2018.12.27 bwarner         Initial Draft
\*└─────────────────────────────────────────────────────────────────────────────────────────────┘*/
USE AdventureWorks_0006
GO

IF EXISTS (SELECT *
           FROM sys.objects
           WHERE object_id = OBJECT_ID(N'ref.ZipCode')
                 AND type IN (N'U'))
    DROP TABLE 
      ref.ZipCode
GO

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

IF NOT EXISTS (SELECT *
               FROM sys.objects
               WHERE object_id = OBJECT_ID(N'ref.ZipCode')
                     AND type IN (N'U'))
  BEGIN
    CREATE TABLE
      ref.ZipCode
        (
            ZipCodeID  BIGINT        NOT NULL
                              IDENTITY(1,1)
                              CONSTRAINT 
                                PK_ref_ZipCode
                              PRIMARY KEY CLUSTERED
          , ZipCodeName VARCHAR(128)   NOT NULL
          , ZipCodeDesc VARCHAR(512)   NULL
        )
  END
GO





