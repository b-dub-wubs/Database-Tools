/*┌─────────────────────────────────────────────────────────────────────────────────────────────┐*\
  │ TITLE: View DDL                                                                             │
  │   AdventureWorks_0006.dbo.vw_DataFeed
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤
  │ DESCRIPTION:                                                                                │
      
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤
  │ REVISION HISTORY:                                                                           │
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤
  │   DATE       AUTHOR          CHANGE DESCRIPTION                                             │
  │   ────────── ─────────────── ───────────────────────────────────────────────────────────────┤
      2019.01.04 bwarner         Initial Draft
\*└─────────────────────────────────────────────────────────────────────────────────────────────┘*/
USE AdventureWorks_0006
GO

IF EXISTS (SELECT *
           FROM sys.objects
           WHERE object_id = OBJECT_ID(N'dbo.vw_DataFeed')
                 AND type IN (N'V'))
    DROP VIEW 
      dbo.vw_DataFeed
GO

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW
  dbo.vw_DataFeed
AS
    SELECT 
        mo.MailingOrgName
      , dp.DataProviderCode
      , dp.DataProviderName
      , df.DataFeedName
      , df.DataFeedDesc
      , df.DeliveryMechanism
      , df.DeliverySchedule
      , df.IsInbound
      , df.FileNameingConv

      , df.FormatDesc
      , df.ModifiedBy
      , df.ModifiedDate
      , df.CreatedBy
      , df.CreatedDate





      , df.IsCurrent
      , df.ValidFrom
      , df.ValidTo

    FROM 
      dbo.DataFeed df
      JOIN
      dbo.DataProvider dp
        ON df.DataProviderID = dp.DataProviderID
      JOIN
      dbo.MailingOrg mo
        ON mo.MailingOrgID = df.MailingOrgID
GO





