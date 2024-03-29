/*┌─────────────────────────────────────────────────────────────────────────────────────────────┐*\
  │ TITLE: Stored Procedure DDL                                                                 │
  │   AdventureWorks_0006.dbo.usp_MailedReport_Salesforce_Acq_Refresh
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤
  │ DESCRIPTION:                                                                                │
      
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤
  │ REVISION HISTORY:                                                                           │
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤
  │   DATE       AUTHOR          CHANGE DESCRIPTION                                             │
  │   ────────── ─────────────── ────────────────────────────────────────────────────────────── │
      2018.12.27 bwarner         Initial Draft
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤
  │ UNIT TESTING SCRIPTS:                                                                       │


      EXEC dbo.usp_MailedReport_Salesforce_Acq_Refresh 

      EXEC dbo.usp_MailedReport_Salesforce_Acq_Refresh @RebuildAll = 1

  ├─────────────────────────────────────────────────────────────────────────────────────────────┤
  │ Run Component Configure                                                                     │
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤

    DECLARE @RunComponentID SMALLINT

    EXEC logging.usp_RunComponent_Add
        @RunComponentName     = 'usp_MailedReport_Salesforce_Acq_Refresh' 
      , @RunComponentDesc     = 'Updates the master MailSuppressionsByDUNS list that suppressies mail by DUNS'
      , @ParentRunComponentID = NULL
      , @SequentialPosition   = NULL
      , @RunComponentID       = @RunComponentID OUTPUT


\*└─────────────────────────────────────────────────────────────────────────────────────────────┘*/
USE AdventureWorks_0006
GO

IF EXISTS 
  (
    SELECT 
      * 
    FROM 
      sys.objects 
    WHERE 
          [object_id] = OBJECT_ID(N'dbo.usp_MailedReport_Salesforce_Acq_Refresh') 
      AND [type] IN(N'P', N'PC')
  )
	DROP PROCEDURE 
    dbo.usp_MailedReport_Salesforce_Acq_Refresh
GO

CREATE PROCEDURE 
  dbo.usp_MailedReport_Salesforce_Acq_Refresh
    (
        @RebuildAll   BIT = 0
    )
WITH RECOMPILE
AS
BEGIN

  SET NOCOUNT ON

  DECLARE
      @RunLogID     BIGINT
    , @RowsAffected BIGINT
    --, @MailWeekAsOf DATETIME 

  /* Sproc RunLog Start */
  EXEC logging.usp_RunLog_LogBegin 
      @ParentRunLogID   = NULL
    , @RunComponentName = 'usp_MailedReport_Salesforce_Acq_Refresh'
    , @RunLogID         = @RunLogID OUTPUT

  /*┌────────────────────────────────────────────────────────────────────┐*
      Rebuild Case: use achived campain members and one-off corrections
      for old campains; truncate and rebuild all rows
  \*└────────────────────────────────────────────────────────────────────┘*/
  IF @RebuildAll = 1
    BEGIN

      SELECT @RowsAffected = COUNT_BIG(*) FROM AdventureWorks_0006.dbo.MailedReport_Salesforce_House

      TRUNCATE TABLE
        AdventureWorks_0006.dbo.MailedReport_Salesforce_House

      EXEC logging.usp_RowsAffected_Log 
          @RunLogID       = @RunLogID
        , @OperationType  = 'delete'
        , @RowsAffected   = @RowsAffected
        , @ObjectName     = 'MailedReport_Salesforce_Acq'



      IF OBJECT_ID('tempdb.dbo.##CampaignTable_Acq', 'U') IS NOT NULL
        DROP TABLE ##CampaignTable_Acq

      SELECT 
          m.CampaignMemberId
        , m.leadid
        , m.FirstRespondedDate
        , m.Account_Number__c
        , campaignid          = c.Id
        , c.StartDate
        , c.License_Type__c
        , c.List_Reference__c
        , TimesMailed         = ROW_NUMBER() OVER(  PARTITION BY m.leadid
                                                    ORDER BY startdate      )
        , TimesCount          = COUNT(m.CampaignMemberId) OVER(PARTITION BY m.leadid)
        , MostRecentStartDate = MAX(c.StartDate) OVER(PARTITION BY m.leadid)
      INTO 
        ##CampaignTable_Acq
      FROM
        (
          SELECT 
              campaignmemberid = ID
            , leadid
            , CampaignId
            , FirstRespondedDate
            , Account_Number__c
          FROM 
            AdventureWorks_0022.dbo.CampaignMember

          UNION ALL

          SELECT 
              ID AS campaignmemberid
            , leadid
            , campaignid
            , FirstRespondedDate
            , Account_Number__c
          FROM 
            AdventureWorks_0001.dbo.CampaignMemberArchive2016

          UNION ALL

          SELECT 
              ID AS campaignmemberid
            , leadid
            , campaignid
            , FirstRespondedDate
            , Account_Number__c
          FROM 
              AdventureWorks_0001.dbo.CampaignMemberArchive2015

          UNION ALL

          SELECT 
              ID AS campaignmemberid
            , leadid
            , campaignid
            , FirstRespondedDate
            , Account_Number__c
          FROM 
              AdventureWorks_0001.dbo.CampaignMemberArchive2014

          UNION ALL

          SELECT 
              ID AS campaignmemberid
            , leadid
            , campaignid
            , FirstRespondedDate
            , Account_Number__c
          FROM 
            AdventureWorks_0001.dbo.CampaignMemberArchive2013
        ) m
        JOIN
        AdventureWorks_0022.dbo.Campaign c
          ON m.CampaignId = c.Id
          AND c.[TYPE] = 'direct mail'
          AND Prospect_Type__c = 'acquisition'
          AND StartDate >= '04-01-2013'

      CREATE UNIQUE CLUSTERED INDEX
        idx_c_CampaignMemberId
      ON 
        ##CampaignTable_Acq(CampaignMemberId)

      CREATE INDEX 
        idx_nc_leadid
      ON 
        ##CampaignTable_Acq(leadid)

      IF OBJECT_ID('tempdb.dbo.##CampaignTable_Current', 'U') IS NOT NULL
        DROP TABLE ##CampaignTable_Current;

      SELECT
          CampaignMemberId  = m.id
        , m.leadid
        , TimesMailedYear   = ROW_NUMBER()  OVER( PARTITION BY 
                                                    m.leadid
                                                  ORDER BY 
                                                    startdate   )
        , TimesCountYear    = COUNT(m.id)   OVER( PARTITION BY 
                                                    m.leadid    )
      INTO 
        ##CampaignTable_Current
      FROM 
        AdventureWorks_0022.dbo.CampaignMember m
        JOIN
        AdventureWorks_0022.dbo.Campaign c
          ON m.CampaignId = c.Id
          AND c.[TYPE] = 'direct mail'
          AND Prospect_Type__c = 'acquisition'
          AND DATEDIFF(month, c.StartDate, GETDATE()) <= 12

      CREATE UNIQUE CLUSTERED INDEX 
        idx_c_CampaignMemberId
      ON 
        ##CampaignTable_Current(CampaignMemberId)

      CREATE INDEX 
        idx_nc_leadid
      ON 
        ##CampaignTable_Current(leadid)


        --(11:40 TOTAL RUN TIME on 9/25 drop method)
        --(23:27 TOTAL RUN TIME on 9/25 truncate method)
        --(15:46 TOTAL RUN TIME on 10/28 drop method)
        --(46:38 TOTAL RUN TIME on 8/3 drop method)
        --(56:09 TOTAL RUN TIME on 8/18 drop method)


      IF OBJECT_ID('AdventureWorks_0001.dbo.Acq_Mail_Current', 'U') IS NOT NULL
        BEGIN
          DROP TABLE AdventureWorks_0001.dbo.Acq_Mail_Current;
      END

      SELECT DISTINCT --top 100
          cm.campaignid AS CampaignId
        , cm.CampaignMemberId AS CampaignMemberId
        , l.Id AS LeadId
        , l.ConvertedAccountId AS AccountId
        , cm.Account_Number__c
        , cm.FirstRespondedDate
        , cm.MostRecentStartDate
        , cm.TimesMailed
        , cm.TimesCount
        , cmc.TimesCountYear
        , cmc.TimesMailedYear
        , l.DUNS_Number__c
        , l.SICCODE__c
        , l.SICName__c
        , l.[State]
        , l.MSA_Code__c
        , l.Year_Started__c
        , l.NumberOfEmployees
        , l.Paydex_Score__c
        , l.Paydex_Band__c
        , l.UCC_Indicator__c
        , l.Sales_Volume__c
        , l.Response_Score__c
        , l.List_Reference__c AS Lead_List_Reference__c
        , l.Activation_Date__c
        , l.Initial_Lead_Source__c
        , l.Initial_Response_Channel__c
        , l.City
        , l.PostalCode
        , Fund_Score__c = CASE
                            WHEN Fund_Score__c <> 0
                              THEN Fund_Score__c
                            ELSE NULL
                          END
        , Week_Num = SUBSTRING(cm.Account_Number__c, 5, 1)


        --DATEADD(week, ISNULL(CAST(SUBSTRING(cm.Account_Number__c, 5, 1) AS INT), 1) - 1, c.StartDate)



        , CASE
              WHEN
            ISNUMERIC(Year_Started__c) <> 1
              THEN 'Unknown'
              WHEN Year_Started__c BETWEEN '0001' AND '1999'
              THEN '1999-'
              WHEN Year_Started__c BETWEEN '2000' AND '2007'
              THEN '2000-2007'
              WHEN
            Year_Started__c >= '2008'
              THEN '2008+'
              ELSE 'Unknown'
          END AS Year_Started_Segment


        , CASE
              WHEN
            ISNULL(NumberOfEmployees, 0) = 0
              THEN 'Unknown'
              WHEN ISNULL(NumberOfEmployees, 0) BETWEEN 1 AND 4
              THEN '1-4'
              WHEN ISNULL(NumberOfEmployees, 0) BETWEEN 5 AND 49
              THEN '5-49'
              WHEN ISNULL(NumberOfEmployees, 0) BETWEEN 50 AND 100
              THEN '50-100'
              WHEN
            ISNULL(NumberOfEmployees, 0) > 100
              THEN '101+'
              ELSE 'Other'
          END AS Empl_Segment

        , CASE
              WHEN
            ISNULL(NumberOfEmployees, 0) = 0
              THEN 'Unknown'
              WHEN
        ISNULL(NumberOfEmployees, 0) BETWEEN 1 AND 4
        AND ISNULL(Paydex_Band__c, 0) BETWEEN 1 AND 3
              THEN '1-4P'
              WHEN ISNULL(NumberOfEmployees, 0) BETWEEN 1 AND 4
              THEN '1-4NoP'
              WHEN ISNULL(NumberOfEmployees, 0) BETWEEN 5 AND 100
              THEN '5-100'
              ELSE 'Other'
          END AS Empl_Paydex_Segment




        , CASE
              WHEN ISNULL(Paydex_Band__c, 0) BETWEEN 1 AND 3
              THEN 1
              ELSE 0
          END AS Has_Paydex_Flag

        , CASE
              WHEN LEFT(ISNULL(UCC_Indicator__c, '00000000'), 4) IN('Yes')
              THEN 1
              WHEN LEFT(ISNULL(UCC_Indicator__c, '00000000'), 4) BETWEEN '2000' AND '2016'
              THEN 1
              ELSE 0
          END AS Has_UCC_Flag

        , CASE
              WHEN
            ISNULL(Sales_Volume__c, 0) = 0
              THEN '$0'
              WHEN
            Sales_Volume__c < 100000
              THEN '$1-99K'
              WHEN
            Sales_Volume__c < 150000
              THEN '$100-149K'
              WHEN
            Sales_Volume__c < 250000
              THEN '$150-249K'
              WHEN
            Sales_Volume__c >= 250000
              THEN '$250K+'
              ELSE 'Other'
          END AS Sales_Volume_Segment



      INTO 
        AdventureWorks_0001.dbo.Acq_Mail_Current
      FROM 
        ##CampaignTable_Acq AS cm
        INNER JOIN
        AdventureWorks_0022.dbo.Lead AS l
          ON cm.LeadId = l.Id
        LEFT JOIN
        ##CampaignTable_Current AS cmc
          ON cm.campaignmemberid = cmc.CampaignMemberId
      WHERE
            StartDate >= '01-01-2014'
      --and cm.Prospect_Type__c in ('Acquisition')
      --and cm.Type in ('Direct Mail')

      CREATE UNIQUE CLUSTERED INDEX idc_c_CampaignMemberId
      ON Acq_Mail_Current
        (CampaignMemberId ASC
        )
      --create unique index CMIndex on AdventureWorks_0001.dbo.Acq_Mail_Current (CampaignMemberId)

      CREATE INDEX idx_nc_CampaignMemberId
      ON AdventureWorks_0001.dbo.Acq_Mail_Current
        (CampaignMemberId
        )

      CREATE INDEX idx_nc_DUNS_Number__c
      ON AdventureWorks_0001.dbo.Acq_Mail_Current
        (DUNS_Number__c
        ) 

      CREATE INDEX idx_nc_CampaignId
      ON AdventureWorks_0001.dbo.Acq_Mail_Current
        (CampaignId
        ) 

      CREATE INDEX idx_nc_LeadId
      ON AdventureWorks_0001.dbo.Acq_Mail_Current
        (LeadId
        ) 

      CREATE INDEX idx_nc_AccountId
      ON AdventureWorks_0001.dbo.Acq_Mail_Current
        (AccountId
        )

      CREATE INDEX 
        idx_nc_MostRecentStartDate
      ON AdventureWorks_0001.dbo.Acq_Mail_Current
        (MostRecentStartDate)

      CREATE INDEX idx_nc_FirstRespondedDate
      ON AdventureWorks_0001.dbo.Acq_Mail_Current
        (FirstRespondedDate)
	           
      CREATE INDEX acq
      ON acq_mail_current
        (campaignId
        ) 
            INCLUDE
        (duns_number__c, timesMailed
        )





































      SET @RowsAffected = @@ROWCOUNT

      EXEC logging.usp_RowsAffected_Log 
          @RunLogID       = @RunLogID
        , @OperationType  = 'insert'
        , @RowsAffected   = @RowsAffected
        , @ObjectName     = 'MailedReport_Salesforce_House'

    END

  /*┌────────────────────────────────────────────────────────────────────┐*
      Standard Case: use simplified logic and only add new rows
  \*└────────────────────────────────────────────────────────────────────┘*/
  ELSE

    BEGIN

      SELECT
        @MailWeekAsOf = MAX(MailWeek)
      FROM
        AdventureWorks_0006.dbo.MailedReport_Salesforce_House

      INSERT
        AdventureWorks_0006.dbo.MailedReport_Salesforce_House
          (
              CampaignId
            , CampaignMemberId
            , LeadId 
            , ContactId
            , AccountId
            , AccountNo
            , MailWeek
          )
      SELECT 
          CampaignId        = c.Id
        , CampaignMemberId  = cm.Id
        , LeadId            = cm.LeadId
        , ContactId         = cm.ContactId
        , AccountId         = cnt.AccountId
        , AccountNo         = cm.Account_Number__c --Account_Number__c
        , MailWeek          = DATEADD(week, ISNULL(CAST(SUBSTRING(cm.Account_Number__c, 5, 1) AS INT), 1) - 1, c.StartDate)
      FROM 
        AdventureWorks_0022.dbo.Campaign c
        JOIN
        AdventureWorks_0022.dbo.CampaignMember cm
          ON c.Id = cm.CampaignId --To get AccountId from Contacts
        LEFT JOIN
        AdventureWorks_0022.dbo.Contact cnt
          ON cm.ContactId = cnt.Id
      WHERE
            c.[Type] = 'Direct Mail'
        AND c.Prospect_Type__c IN('House', 'Customer')
        AND DATEADD(week, ISNULL(CAST(SUBSTRING(cm.Account_Number__c, 5, 1) AS INT), 1) - 1, c.StartDate) > @MailWeekAsOf

      SET @RowsAffected = @@ROWCOUNT

      EXEC logging.usp_RowsAffected_Log 
          @RunLogID       = @RunLogID
        , @OperationType  = 'insert'
        , @RowsAffected   = @RowsAffected
        , @ObjectName     = 'MailedReport_Salesforce_House'

    END

  /* Sproc RunLog End */
  EXEC logging.usp_RunLog_LogEnd 
      @RunLogID   =  @RunLogID
    , @ReturnCode = NULL
    , @Suceeded   = 1

END
GO




