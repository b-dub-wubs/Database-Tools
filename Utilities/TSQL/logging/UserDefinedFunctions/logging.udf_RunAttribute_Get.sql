/*┌─────────────────────────────────────────────────────────────────────────────────────────────┐*\
  │ TITLE: User Defined Function DDL                                                            │
  │   Analytics_WS.logging.udf_RunAttribute_Get
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤
  │ DESCRIPTION:                                                                                │
      
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤
  │ REVISION HISTORY:                                                                           │
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤
  │   DATE       AUTHOR          CHANGE DESCRIPTION                                             │
  │   ────────── ─────────────── ────────────────────────────────────────────────────────────── │
      2019.01.08 bwarner         Initial Draft
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤
  │ UNIT TESTING SCRIPTS:                                                                       │

      SELECT TestResult = logging.udf_RunAttribute_Get('Test_Param')

\*└─────────────────────────────────────────────────────────────────────────────────────────────┘*/
USE Analytics_WS
GO

IF  EXISTS (SELECT 1
            FROM  sys.objects 
            WHERE     [object_id] = OBJECT_ID(N'logging.udf_RunAttribute_Get')
                  AND [type_desc] LIKE 'SQL%FUNCTION')
  DROP FUNCTION 
    logging.udf_RunAttribute_Get
GO

CREATE FUNCTION 
  logging.udf_RunAttribute_Get
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
