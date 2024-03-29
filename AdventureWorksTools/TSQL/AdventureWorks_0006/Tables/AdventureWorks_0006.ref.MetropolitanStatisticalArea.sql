/*┌─────────────────────────────────────────────────────────────────────────────────────────────┐*\
  │ TITLE: Table DDL                                                                            │
  │   AdventureWorks_0006.ref.MetropolitanStatisticalArea
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
           WHERE object_id = OBJECT_ID(N'ref.MetropolitanStatisticalArea')
                 AND type IN (N'U'))
    DROP TABLE 
      ref.MetropolitanStatisticalArea
GO

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

IF NOT EXISTS (SELECT *
               FROM sys.objects
               WHERE object_id = OBJECT_ID(N'ref.MetropolitanStatisticalArea')
                     AND type IN (N'U'))
  BEGIN
    CREATE TABLE
      ref.MetropolitanStatisticalArea
        (
            MSA       INT        NOT NULL
                      CONSTRAINT 
                        PK_ref_MetropolitanStatisticalArea
                      PRIMARY KEY CLUSTERED
          , MSA_Name  VARCHAR(128)   NOT NULL
        )
  END
GO


/*┌─────────────────────────────────────────────────────────────────────────────────────────────┐*\
  │ Load from manual import temp table I set up                                                 │
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤

    INSERT
      ref.MetropolitanStatisticalArea
        (
            MSA
          , MSA_Name
        )
    SELECT DISTINCT 
        MSA = CAST(MSA AS INT)
      , MSA_NAME 
    FROM 
      [ref].[fs11_gpci_by_msa_ZIP] 
    WHERE
      MSA IS NOT NULL
      AND CAST(MSA AS INT) <> 0


    SELECT DISTINCT 
        MSA = CAST(MSA AS INT)
      , MSA_NAME 
    FROM 
      [ref].[fs11_gpci_by_msa_ZIP] 
    WHERE
      MSA IS NOT NULL
      AND CAST(MSA AS INT) = 0

  ├─────────────────────────────────────────────────────────────────────────────────────────────┤
  │ Load special values                                                                         │
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤



    SELECT DISTINCT 
        MSA = CAST(MSA AS INT)
      , MSA_NAME 
    FROM 
      [ref].[fs11_gpci_by_msa_ZIP] 
    WHERE
      MSA IS NOT NULL
      AND CAST(MSA AS INT) = 0

    INSERT
      ref.MetropolitanStatisticalArea
        (
            MSA
          , MSA_Name
        )
    VALUES
        (0, 'ALL')
      , (-1, 'UNKNOWN')
      , (-2, 'OTHER')
      , (-3, 'NONE')
      , (-4, 'All other territories and foreign countries')
      , (-5, 'ARMED FORCES')

\*└─────────────────────────────────────────────────────────────────────────────────────────────┘*/






