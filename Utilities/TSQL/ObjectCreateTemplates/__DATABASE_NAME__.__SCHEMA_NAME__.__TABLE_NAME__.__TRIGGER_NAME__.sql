/*┌─────────────────────────────────────────────────────────────────────────────────────────────┐*\.
  │ TITLE: Index DDL __DATABASE_NAME__.__SCHEMA_NAME__.__TABLE_NAME__.__TRIGGER_NAME__
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤
  │ DESCRIPTION:                                                                                │
      
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤
  │ REVISION HISTORY:                                                                           │
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤
  │   DATE       AUTHOR          CHANGE DESCRIPTION                                             │
  │   ────────── ─────────────── ────────────────────────────────────────────────────────────── │
      YYYY.MM.DD __AUTHOR_______ Initial Draft
\*└─────────────────────────────────────────────────────────────────────────────────────────────┘*/
USE __DATABASE_NAME__
GO

IF EXISTS (SELECT 1
           FROM sys.triggers
           WHERE object_id = OBJECT_ID(N'__SCHEMA_NAME__.__TRIGGER_NAME__'))
  DROP TRIGGER 
    __SCHEMA_NAME__.__TRIGGER_NAME__
GO

SET ANSI_PADDING ON
GO

CREATE TRIGGER 
  __SCHEMA_NAME__.__TRIGGER_NAME__
ON 
  __SCHEMA_NAME__.__TABLE_NAME__

FOR -- INSTEAD OF
  UPDATE -- INSERT DELETE
AS
  UPDATE
    __SCHEMA_NAME__.__TABLE_NAME__ 
  SET
      ModifiedDate  = GETDATE()
    , ModifiedBy    = SUSER_SNAME()
  WHERE
    __TABLE_PK_COL__ IN (SELECT __TABLE_PK_COL__ FROM INSERTED)
