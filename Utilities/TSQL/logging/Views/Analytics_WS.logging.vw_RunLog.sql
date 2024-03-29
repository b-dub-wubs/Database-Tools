/*┌─────────────────────────────────────────────────────────────────────────────────────────────┐*\
  │ TITLE: View DDL                                                                             │
  │   Analytics_WS.logging.vw_RunLog
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤
  │ DESCRIPTION:                                                                                │
      SELECT * FROM  logging.vw_RunLog

      SELECT * FROM logging.RunAttribute

  ├─────────────────────────────────────────────────────────────────────────────────────────────┤
  │ REVISION HISTORY:                                                                           │
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤
  │   DATE       AUTHOR          CHANGE DESCRIPTION                                             │
  │   ────────── ─────────────── ───────────────────────────────────────────────────────────────┤
      2019.01.08 bwarner         Initial Draft
\*└─────────────────────────────────────────────────────────────────────────────────────────────┘*/
USE Analytics_WS
GO

IF EXISTS (SELECT *
           FROM sys.objects
           WHERE object_id = OBJECT_ID(N'logging.vw_RunLog')
                 AND type IN (N'V'))
    DROP VIEW 
      logging.vw_RunLog
GO

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW
  logging.vw_RunLog
AS

WITH 
  RunLogHierarchy 
    (
        RunLogID
      , RunComponentID
      , Executed
      , Completed
      , ReturnCode
      , DidSucceed
      , IndentPad
      , Lineage
      , NestingLevel
    )
AS 
  (
    SELECT
        RunLogID        = rl.RunLogID
      , RunComponentID  = rl.RunComponentID
      , Executed        = rl.Executed
      , Completed       = rl.Completed
      , ReturnCode      = rl.ReturnCode
      , DidSucceed        = rl.DidSucceed
      , IndentPad       = (CAST('' AS VARCHAR(128)))
      , Lineage         = (CAST('[' + LTRIM(STR(RunLogID)) + ']' AS VARCHAR(512)))
      , NestingLevel      = 0
    FROM
      logging.RunLog rl
    WHERE 
      ParentRunLogID IS NULL

    UNION ALL 

    SELECT
        RunLogID        = rl_2bd.RunLogID
      , RunComponentID  = rl_2bd.RunComponentID
      , Executed        = rl_2bd.Executed
      , Completed       = rl_2bd.Completed
      , ReturnCode      = rl_2bd.ReturnCode
      , DidSucceed        = rl_2bd.DidSucceed
      , IndentPad       = CAST(rlh.IndentPad + '    ' AS VARCHAR(128)) 
      , Lineage         = (CAST(rlh.Lineage + '\' + LTRIM(STR(rl_2bd.RunLogID)) AS VARCHAR(512)))
      , NestingLevel      = rlh.NestingLevel + 1
    FROM
      logging.RunLog rl_2bd
      JOIN 
      RunLogHierarchy rlh
        ON rl_2bd.ParentRunLogID = rlh.RunLogID
)

SELECT 
    rlh.Lineage
  , ComponentDesc  = rlh.IndentPad + rc.RunComponentName
  , rlh.Executed
  , rlh.Completed

  , Durration      = CASE 
                        WHEN rlh.Completed IS NOT NULL 
                          THEN logging.udf_DurrationStr(rlh.Executed,rlh.Completed) 
                        ELSE logging.udf_DurrationStr(rlh.Executed,GETDATE()) + ' <running>' 
                      END
  , ra.AttributeName
  , ra.AttributeValue
  , rlh.RunLogID
  , rc.RunComponentID

  , ReturnCode
  , DidSucceed

  , NestingLevel

FROM 
  RunLogHierarchy rlh
  JOIN
  logging.RunComponent rc
    ON rlh.RunComponentID = rc.RunComponentID
  LEFT JOIN
  logging.RunAttribute ra
    ON ra.RunLogID = rlh.RunLogID

GO

