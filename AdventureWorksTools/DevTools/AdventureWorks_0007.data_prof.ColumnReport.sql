/*┌─────────────────────────────────────────────────────────────────────────────────────────────┐*\
  │ TITLE: Table DDL                                                                            │
  │   AdventureWorks_0007.data_prof.ColumnReport
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤
  │ DESCRIPTION:                                                                                │
  │                                                                                             │
  │                                                                                             │
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤
  │ REVISION HISTORY:                                                                           │
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤
  │   DATE       AUTHOR          CHANGE DESCRIPTION                                             │
  │   ────────── ─────────────── ───────────────────────────────────────────────────────────────┤
      2018.10.16 bwarner         Initial Draft



\*└─────────────────────────────────────────────────────────────────────────────────────────────┘*/
USE AdventureWorks_0007
GO

IF EXISTS (SELECT *
           FROM sys.objects
           WHERE object_id = OBJECT_ID(N'data_prof.ColumnReport')
                 AND type IN (N'U'))
    DROP TABLE 
      data_prof.ColumnReport
GO

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

IF NOT EXISTS (SELECT *
               FROM sys.objects
               WHERE object_id = OBJECT_ID(N'data_prof.ColumnReport')
                     AND type IN (N'U'))
  BEGIN
CREATE TABLE 
  data_prof.ColumnReport
    (
        
        TableSchema     SYSNAME       NOT NULL
      , TableName       SYSNAME       NOT NULL
      , ColName         SYSNAME       NOT NULL
      , OrdinalPos      INT           NOT NULL
      , MaxLen          BIGINT        NULL
      , MinLen          BIGINT        NULL
      , MaxVal          NVARCHAR(MAX) NULL
      , MinVal          NVARCHAR(MAX) NULL
      , TotlRowCnt      BIGINT        NOT NULL
      , BlankOrNullCnt  BIGINT        NULL
      , BlankOrNullPct  AS CAST(BlankOrNullCnt AS FLOAT)/CAST(TotlRowCnt AS FLOAT) PERSISTED
      , DistinctValCnt  BIGINT        NULL
      , DistinctValPct  AS CAST(DistinctValCnt AS FLOAT)/CAST(TotlRowCnt AS FLOAT) PERSISTED
      , IntegerRowCnt   BIGINT        NULL
      , IntegerRowPct   AS CAST(IntegerRowCnt AS FLOAT)/CAST(TotlRowCnt AS FLOAT) PERSISTED
      , NumericRowCnt   BIGINT        NULL
      , NumericRowPct   AS CAST(NumericRowCnt AS FLOAT)/CAST(TotlRowCnt AS FLOAT) PERSISTED
      , UnicodeCnt      BIGINT        NULL
      , UnicodePct      AS CAST(UnicodeCnt AS FLOAT)/CAST(TotlRowCnt AS FLOAT) PERSISTED
      , InfTypeClassID  TINYINT       NULL
      , TypeDef         VARCHAR(256)   NULL
      , TypeDefNative   VARCHAR(256)   NULL
      , CONSTRAINT
          PK_ColumnReport
        PRIMARY KEY CLUSTERED(TableName,OrdinalPos)
    )
  END
GO





