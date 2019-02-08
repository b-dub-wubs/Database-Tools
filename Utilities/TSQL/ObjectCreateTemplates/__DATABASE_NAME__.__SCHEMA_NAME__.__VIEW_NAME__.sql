/*┌─────────────────────────────────────────────────────────────────────────────────────────────┐*\
  │ TITLE: View DDL                                                                             │
  │   __DATABASE_NAME__.__SCHEMA_NAME__.__VIEW_NAME__
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤
  │ DESCRIPTION:                                                                                │
      
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤
  │ REVISION HISTORY:                                                                           │
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤
  │   DATE       AUTHOR          CHANGE DESCRIPTION                                             │
  │   ────────── ─────────────── ───────────────────────────────────────────────────────────────┤
      YYYY.MM.DD __AUTHOR_______ Initial Draft
\*└─────────────────────────────────────────────────────────────────────────────────────────────┘*/
USE __DATABASE_NAME__
GO

IF EXISTS (SELECT *
           FROM sys.objects
           WHERE object_id = OBJECT_ID(N'__SCHEMA_NAME__.__VIEW_NAME__')
                 AND type IN (N'V'))
    DROP VIEW 
      __SCHEMA_NAME__.__VIEW_NAME__
GO

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW
  __SCHEMA_NAME__.__VIEW_NAME__
AS
   WITH 
      __CTE_00__ AS
        (
          SELECT
              TABLE_CATALOG
            , TABLE_SCHEMA
            , TABLE_NAME
            , CREATED       = NULL
            , LAST_ALTERED  = NULL
          FROM
            INFORMATION_SCHEMA.TABLES 
        )
    , __CTE_01__ AS
        (
          SELECT
              TABLE_CATALOG
            , TABLE_SCHEMA
            , TABLE_NAME
            , COLUMN_NAME
            , CREATED       = NULL
            , LAST_ALTERED  = NULL
          FROM
            INFORMATION_SCHEMA.COLUMNS
        )
    , __CTE_02__ AS
        (
          SELECT 
              ROUTINE_CATALOG
            , ROUTINE_SCHEMA
            , ROUTINE_NAME
            , CREATED
            , LAST_ALTERED
          FROM
            INFORMATION_SCHEMA.ROUTINES
        )

  SELECT
      OBJECT_TYPE         = 'TABLE'
    , [DATABASE_NAME]     = TABLE_CATALOG
    , [SCHEMA]            = TABLE_SCHEMA
    , [OBJ_NAME]          = TABLE_NAME
    , [PARENT_NAME]       = NULL
    , [OBJ_CREATED]       = CREATED
    , [OBJ_LAST_ALTERED]  = LAST_ALTERED
  FROM
    __CTE_00__
   
  UNION ALL

  SELECT
      OBJECT_TYPE         = 'COLUMN'
    , [DATABASE_NAME]     = TABLE_CATALOG
    , [SCHEMA]            = TABLE_SCHEMA
    , [OBJ_NAME]          = COLUMN_NAME
    , [PARENT_NAME]       = TABLE_NAME
    , [OBJ_CREATED]       = CREATED
    , [OBJ_LAST_ALTERED]  = LAST_ALTERED
  FROM
    __CTE_01__
   
  UNION ALL

  SELECT
      OBJECT_TYPE         = 'ROUTINE'
    , [DATABASE_NAME]     = ROUTINE_CATALOG
    , [SCHEMA]            = ROUTINE_SCHEMA
    , [OBJ_NAME]          = ROUTINE_NAME
    , [PARENT_NAME]       = NULL
    , [OBJ_CREATED]       = CREATED
    , [OBJ_LAST_ALTERED]  = LAST_ALTERED
  FROM
    __CTE_02__

GO
