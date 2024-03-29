/*┌─────────────────────────────────────────────────────────────────────────────────────────────┐*\
  │ TITLE: Table DDL                                                                            │
  │   AdventureWorks_0006.dbo.ResponderMatchFile2
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤
  │ DESCRIPTION:                                                                                │
  │                                                                                             │
  │                                                                                             │
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤
  │ REVISION HISTORY:                                                                           │
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤
  │   DATE       AUTHOR          CHANGE DESCRIPTION                                             │
  │   ────────── ─────────────── ───────────────────────────────────────────────────────────────┤
      2018.12.18 bwarner         Initial Draft
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤
  │ DATA MIGRATION SCRIPT                                                                       │
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤

    INSERT
      dbo.ResponderMatchFile2
        (
            DUNS
        )
    SELECT DISTINCT
        DUNS
    FROM 
      AdventureWorks_0007.dbo.NF_Matching_DUNS_2


\*└─────────────────────────────────────────────────────────────────────────────────────────────┘*/

USE AdventureWorks_0006
GO

IF EXISTS (SELECT *
           FROM sys.objects
           WHERE object_id = OBJECT_ID(N'dbo.ResponderMatchFile2')
                 AND type IN (N'U'))
    DROP TABLE 
      dbo.ResponderMatchFile2
GO

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

IF NOT EXISTS (SELECT *
               FROM sys.objects
               WHERE object_id = OBJECT_ID(N'dbo.ResponderMatchFile2')
                     AND type IN (N'U'))
  BEGIN
    CREATE TABLE
      dbo.ResponderMatchFile2
        (
            DUNS                      INT       NOT NULL
                                      CONSTRAINT
                                        PK_ResponderMatchFile2
                                      PRIMARY KEY CLUSTERED
        )
  END
GO






