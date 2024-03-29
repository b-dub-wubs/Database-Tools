/*┌─────────────────────────────────────────────────────────────────────────────────────────────┐*\
  │ TITLE: Table DDL                                                                            │
  │   Salesforce_AdventureWorks_0004mpAdHoc.dbo.CampaignMember_Batch_Insert
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤
  │ DESCRIPTION:                                                                                │
  │                                                                                             │
  │                                                                                             │
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤
  │ REVISION HISTORY:                                                                           │
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤
  │   DATE       AUTHOR          CHANGE DESCRIPTION                                             │
  │   ────────── ─────────────── ───────────────────────────────────────────────────────────────┤
      2019.01.08 bwarner         Initial Draft
  └─────────────────────────────────────────────────────────────────────────────────────────────┘*/
USE Salesforce_AdventureWorks_0004mpAdHoc
GO

IF EXISTS (SELECT *
           FROM sys.objects
           WHERE object_id = OBJECT_ID(N'dbo.CampaignMember_Batch_Insert')
                 AND type IN (N'U'))
    DROP TABLE 
      dbo.CampaignMember_Batch_Insert
GO

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

IF NOT EXISTS (SELECT *
               FROM sys.objects
               WHERE object_id = OBJECT_ID(N'dbo.CampaignMember_Batch_Insert')
                     AND type IN (N'U'))
  CREATE TABLE 
    dbo.CampaignMember_Batch_Insert
      (
          Account_Number__c       NVARCHAR(16) NULL
        , CampaignId              NCHAR(18) NULL
        , ContactId               NCHAR(18) NULL
        , Id                      NCHAR(18) NULL
        , Error                   NVARCHAR(255) NULL
        , Short_Account_Number__c NVARCHAR(9) NULL
        , Leadid                  NCHAR(18) NULL
        , stagingId               INT NOT NULL
        , stagingType             NVARCHAR(255) NULL
      )



