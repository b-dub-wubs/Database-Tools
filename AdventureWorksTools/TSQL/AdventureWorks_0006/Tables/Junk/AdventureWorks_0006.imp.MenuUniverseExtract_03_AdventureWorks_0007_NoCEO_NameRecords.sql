/*┌─────────────────────────────────────────────────────────────────────────────────────────────┐*\
  │ TITLE: Table DDL                                                                            │
  │   AdventureWorks_0006.imp.MenuUniverseExtract_03_AdventureWorks_0007_NoCEO_NameRecords
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤
  │ DESCRIPTION:                                                                                │
  │                                                                                             │
  │                                                                                             │
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤
  │ REVISION HISTORY:                                                                           │
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤
  │   DATE       AUTHOR          CHANGE DESCRIPTION                                             │
  │   ────────── ─────────────── ───────────────────────────────────────────────────────────────┤
      2018.10.06 bwarner         Initial Draft
\*└─────────────────────────────────────────────────────────────────────────────────────────────┘*/
USE AdventureWorks_0006
GO

IF EXISTS (SELECT *
           FROM sys.objects
           WHERE object_id = OBJECT_ID(N'imp.MenuUniverseExtract_03_AdventureWorks_0007_NoCEO_NameRecords')
                 AND type IN (N'U'))
    DROP TABLE 
      imp.MenuUniverseExtract_03_AdventureWorks_0007_NoCEO_NameRecords
GO

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

IF NOT EXISTS (SELECT *
               FROM sys.objects
               WHERE object_id = OBJECT_ID(N'imp.MenuUniverseExtract_03_AdventureWorks_0007_NoCEO_NameRecords')
                     AND type IN (N'U'))
  BEGIN
    CREATE TABLE
      imp.MenuUniverseExtract_03_AdventureWorks_0007_NoCEO_NameRecords
        (
            DUNS  INT NOT NULL
                  CONSTRAINT 
                    PK_imp_MenuUniverseExtract_03_AdventureWorks_0007_NoCEO_NameRecords
                  PRIMARY KEY CLUSTERED
        )
  END
GO






