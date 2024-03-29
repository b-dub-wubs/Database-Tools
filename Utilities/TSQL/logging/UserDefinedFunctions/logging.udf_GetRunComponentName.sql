/*┌─────────────────────────────────────────────────────────────────────────────────────────────┐*\
  │ TITLE: User Defined Function DDL                                                            │
  │   Analytics_WS.dbo.udf_GetRunComponentName
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤
  │ DESCRIPTION:                                                                                │
      
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤
  │ REVISION HISTORY:                                                                           │
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤
  │   DATE       AUTHOR          CHANGE DESCRIPTION                                             │
  │   ────────── ─────────────── ────────────────────────────────────────────────────────────── │
      2019.01.15 bwarner         Initial Draft
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤
  │ UNIT TESTING SCRIPTS:                                                                       │

      SELECT TestResult = dbo.udf_GetRunComponentName('Test_Param')

\*└─────────────────────────────────────────────────────────────────────────────────────────────┘*/
--USE Adventureworks
--GO

IF  EXISTS (SELECT 1
            FROM  sys.objects 
            WHERE     [object_id] = OBJECT_ID(N'dbo.udf_GetRunComponentName')
                  AND [type_desc] LIKE 'SQL%FUNCTION')
  DROP FUNCTION 
    dbo.udf_GetRunComponentName
GO

CREATE FUNCTION 
  dbo.udf_GetRunComponentName
    (
        @RunComponentID   SMALLINT
    )
RETURNS
  SYSNAME
AS
BEGIN
  RETURN (  SELECT TOP 1 RunComponentName 
            FROM loggging.RunComponent 
            WHERE RunComponentID = @RunComponentID  )
END
GO

CREATE SYNONYM dbo.rcn FOR dbo.udf_GetRunComponentName  