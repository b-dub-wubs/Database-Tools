/*┌─────────────────────────────────────────────────────────────────────────────────────────────┐*\
  │ TITLE: User Defined Function DDL                                                            │
  │   __DATABASE_NAME__.__SCHEMA_NAME__.__FUNCTION_NAME__
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤
  │ DESCRIPTION:                                                                                │
      
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤
  │ REVISION HISTORY:                                                                           │
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤
  │   DATE       AUTHOR          CHANGE DESCRIPTION                                             │
  │   ────────── ─────────────── ────────────────────────────────────────────────────────────── │
      YYYY.MM.DD __AUTHOR_______ Initial Draft
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤
  │ UNIT TESTING SCRIPTS:                                                                       │

      SELECT TestResult = __SCHEMA_NAME__.__FUNCTION_NAME__('Test_Param')

\*└─────────────────────────────────────────────────────────────────────────────────────────────┘*/
USE __DATABASE_NAME__
GO

IF  EXISTS (SELECT 1
            FROM  sys.objects 
            WHERE     [object_id] = OBJECT_ID(N'__SCHEMA_NAME__.__FUNCTION_NAME__')
                  AND [type_desc] LIKE 'SQL%FUNCTION')
  DROP FUNCTION 
    __SCHEMA_NAME__.__FUNCTION_NAME__
GO

CREATE FUNCTION 
  __SCHEMA_NAME__.__FUNCTION_NAME__
    (
        @Param01   VARCHAR(64)
    )
RETURNS
  VARCHAR(64)
AS
BEGIN
  RETURN 'Hello World' + @Param01
END
GO