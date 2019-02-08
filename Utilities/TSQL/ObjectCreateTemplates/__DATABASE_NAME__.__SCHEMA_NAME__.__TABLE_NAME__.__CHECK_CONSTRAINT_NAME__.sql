/*┌─────────────────────────────────────────────────────────────────────────────────────────────┐*\
  │ TITLE: Check Constraint DDL                                                                 │
  │   __DATABASE_NAME__.__SCHEMA_NAME__.__TABLE_NAME__.__CHECK_CONSTRAINT_NAME__
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤
  │ DESCRIPTION:                                                                                │
      
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤
  │ REVISION HISTORY:                                                                           │
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤
  │   DATE       AUTHOR          CHANGE DESCRIPTION                                             │
  │   ────────── ─────────────── ────────────────────────────────────────────────────────────── │
      YYYY.MM.DD __AUTHOR_______ Initial Draft
\*└─────────────────────────────────────────────────────────────────────────────────────────────┘*/
USE
__DATABASE_NAME__
GO

IF EXISTS 
  (
    SELECT 1
    FROM sys.check_constraints 
    WHERE 
          [object_id]       = OBJECT_ID(N'__SCHEMA_NAME__.__CHECK_CONSTRAINT_NAME__')
      AND parent_object_id  = OBJECT_ID(N'__SCHEMA_NAME__.__TABLE_NAME__')
  )
  ALTER TABLE 
    __SCHEMA_NAME__.__TABLE_NAME__ 
  DROP CONSTRAINT 
    __CHECK_CONSTRAINT_NAME__
GO

ALTER TABLE
  __SCHEMA_NAME__.__TABLE_NAME__
ADD CONSTRAINT 
  __CHECK_CONSTRAINT_NAME__
CHECK 
  (
    -- TODO: Add your boolean valued validation expression here
     1 = 1
  )

