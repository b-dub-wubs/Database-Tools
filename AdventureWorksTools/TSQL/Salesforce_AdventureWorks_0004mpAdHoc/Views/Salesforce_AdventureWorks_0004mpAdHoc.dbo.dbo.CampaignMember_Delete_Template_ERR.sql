/*┌─────────────────────────────────────────────────────────────────────────────────────────────┐*\
  │ TITLE: View DDL                                                                             │
  │   Salesforce_AdventureWorks_0004mpAdHoc..dbo.CampaignMember_Delete_Template_ERR
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤
  │ DESCRIPTION:                                                                                │
     Errored Records for AdventureWorks_0004mp Bulk
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤
  │ REVISION HISTORY:                                                                           │
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤
  │   DATE       AUTHOR          CHANGE DESCRIPTION                                             │
  │   ────────── ─────────────── ───────────────────────────────────────────────────────────────┤
      2019.01.08 bwarner         Initial Draft
\*└─────────────────────────────────────────────────────────────────────────────────────────────┘*/
USE Salesforce_AdventureWorks_0004mpAdHoc
GO

IF EXISTS (SELECT *
           FROM sys.objects
           WHERE object_id = OBJECT_ID(N'.dbo.CampaignMember_Delete_Template_ERR')
                 AND type IN (N'V'))
    DROP VIEW 
      .dbo.CampaignMember_Delete_Template_ERR
GO

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW
  .dbo.CampaignMember_Delete_Template_ERR
AS
SELECT
  *
FROM
  .[dbo].[CampaignMember_Delete_Template]
WHERE
  Error NOT LIKE 'BulkAPI:%:Operation Successful.'

GO






