/*┌─────────────────────────────────────────────────────────────────────────────────────────────┐*\
  │ TITLE: View DDL                                                                             │
  │   AdventureWorks_0006.ref.vw_SIC_Hierarchy_Full
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤
  │ DESCRIPTION:                                                                                │
      Joins all of the SIC hierarchy tables to give the full picture of how the SIC hierarchy 
      breaks down


    SELECT * FROM ref.vw_SIC_Hierarchy_Full

\*└─────────────────────────────────────────────────────────────────────────────────────────────┘*/
USE AdventureWorks_0006
GO

IF EXISTS (SELECT *
           FROM sys.objects
           WHERE object_id = OBJECT_ID(N'ref.vw_SIC_Hierarchy_Full')
                 AND type IN (N'V'))
    DROP VIEW 
      ref.vw_SIC_Hierarchy_Full
GO

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW
  ref.vw_SIC_Hierarchy_Full
AS
SELECT
    d.Division
  , d.DivisionDesc
  , mg.MajorGroup
  , mg.MajorGroupDesc
  , ig.IndustryGroup
  , ig.IndustryGroupDesc
  , sic.SIC
  , sic.SIC_Desc
FROM
  ref.SIC_Code sic
  JOIN
  ref.SIC_IndustryGroup ig
    ON sic.IndustryGroup = ig.IndustryGroup
  JOIN
  ref.SIC_MajorGroup mg
    ON sic.MajorGroup = mg.MajorGroup
  JOIN
  ref.SIC_Division d
    ON sic.Division = d.Division

GO





