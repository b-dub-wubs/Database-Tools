USE [Analytics_DWH]
GO

IF OBJECT_ID('[dbo].[Opportunity_Renewal_Links_VW]','V') IS NOT NULL
    DROP VIEW [dbo].[Opportunity_Renewal_Links_VW]
GO
 
CREATE VIEW [dbo].[Opportunity_Renewal_Links_VW]
AS

    SELECT
        [a].*
       ,CASE WHEN [a].[Fund_Date__c] < [a].[Last_Renewal_Fund_Date] THEN 1
             ELSE 0
        END AS [Renewed_Flag]
       ,CASE WHEN [a].[Fund_Date__c] < [a].[Last_NF_Renewal_Fund_Date] THEN 1
             ELSE 0
        END AS [NF_Renewed_Flag]
	    --, b.Id as Previous_OppId
	    --, b.Fund_Date__c as Previous_Fund_Date__c
	    --, case when b.Type = 'CONCURRENT' then 1 else 0 end as Previous_Concurrent_Flag
	    --, b.Actual_Amt_Offered__c 
	    --	+ case when b.Type = 'CONCURRENT' then isnull(b1.Actual_Amt_Offered__c,0) else 0 end
	    --	as Previous_Actual_Amt_Offered__c
	    --, b.Actual_Amt_Collected__c
	    --	+ case when b.Type = 'CONCURRENT' then isnull(b1.Actual_Amt_Collected__c,0) else 0 end
	    --	as Previous_Actual_Amt_Collected__c
	    --, b.Actual_MCA_Term__c as Previous_Actual_MCA_Term__c
	    --, b.Balance_Paid_60_Percent_Date__c as Previous_Balance_Paid_60_Percent_Date__c
	    /*HARD CODE START 5 Payoff New only + 1 Hard Code (2 CONCURRENTS)*/
       ,CASE WHEN [a].[OppId] IN ( '0068000000wFbK9AAK' ) THEN '0068000000sdVaGAAU'
             WHEN [a].[OppId] IN ( '0068000000uPv6rAAC', '0068000000uPhfnAAC', '0068000000wEdLnAAK', '0068000000wG0yyAAC',
                  '00634000010RxLHAA0' ) THEN [b1].[Id]
             ELSE [b].[Id]
        END AS [Previous_OppId]
       ,CASE WHEN [a].[OppId] IN ( '0068000000wFbK9AAK' ) THEN CAST('2014-12-11 15:28:03.000' AS DATETIME)
             WHEN [a].[OppId] IN ( '0068000000uPv6rAAC', '0068000000uPhfnAAC', '0068000000wEdLnAAK', '0068000000wG0yyAAC',
                  '00634000010RxLHAA0' ) THEN [b1].[Fund_Date__c]
             ELSE [b].[Fund_Date__c]
        END AS [Previous_Fund_Date__c]
       ,CASE WHEN [b].[Type] LIKE '%CONCURRENT' THEN 1
             ELSE 0
        END AS [Previous_Concurrent_Flag]
       ,CASE WHEN [a].[OppId] IN ( '0068000000wFbK9AAK' ) THEN 60000
             WHEN [a].[OppId] IN ( '0068000000uPv6rAAC', '0068000000uPhfnAAC', '0068000000wEdLnAAK', '0068000000wG0yyAAC',
                  '00634000010RxLHAA0' ) THEN 0
             ELSE [b].[ACTUAL_AMT_OFFERED__c]
        END + CASE WHEN [b].[Type] LIKE '%CONCURRENT' THEN ISNULL([b1].[ACTUAL_AMT_OFFERED__c], 0)
                   ELSE 0
              END AS [Previous_Actual_Amt_Offered__c]
       ,CASE WHEN [a].[OppId] IN ( '0068000000wFbK9AAK' ) THEN 71999.40
             WHEN [a].[OppId] IN ( '0068000000uPv6rAAC', '0068000000uPhfnAAC', '0068000000wEdLnAAK', '0068000000wG0yyAAC',
                  '00634000010RxLHAA0' ) THEN 0
             ELSE [b].[ACTUAL_AMT_COLLECTED__c]
        END + CASE WHEN [b].[Type] LIKE '%CONCURRENT' THEN ISNULL([b1].[ACTUAL_AMT_COLLECTED__c], 0)
                   ELSE 0
              END AS [Previous_Actual_Amt_Collected__c]

       ,CASE WHEN [a].[OppId] IN ( '0068000000wFbK9AAK' ) THEN 3000
             WHEN [a].[OppId] IN ( '0068000000uPv6rAAC', '0068000000uPhfnAAC', '0068000000wEdLnAAK', '0068000000wG0yyAAC',
                  '00634000010RxLHAA0' ) THEN 0
             ELSE [b].[Actual_FPC_Margin__c]
        END + CASE WHEN [b].[Type] LIKE '%CONCURRENT' THEN ISNULL([b1].[Actual_FPC_Margin__c], 0)
                   ELSE 0
              END AS [Previous_Actual_FPC_Margin__c]

       ,CASE WHEN [a].[OppId] IN ( '0068000000wFbK9AAK' ) THEN 3000
             WHEN [a].[OppId] IN ( '0068000000uPv6rAAC', '0068000000uPhfnAAC', '0068000000wEdLnAAK', '0068000000wG0yyAAC',
                  '00634000010RxLHAA0' ) THEN 0
             ELSE [b].[Actual_FPC_Margin_w_o_Doc_Fee__c]
        END + CASE WHEN [b].[Type] LIKE '%CONCURRENT' THEN ISNULL([b1].[Actual_FPC_Margin_w_o_Doc_Fee__c], 0)
                   ELSE 0
              END AS [Previous_Actual_FPC_Margin_w_o_Doc_Fee__c]

       ,CASE WHEN [a].[OppId] IN ( '0068000000uPv6rAAC', '0068000000uPhfnAAC', '0068000000wEdLnAAK', '0068000000wG0yyAAC',
                  '00634000010RxLHAA0' ) THEN [b1].[ACTUAL_MCA_TERM__c]
             ELSE [b].[ACTUAL_MCA_TERM__c]
        END AS [Previous_Actual_MCA_Term__c]
       ,CASE WHEN [a].[OppId] IN ( '0068000000uPv6rAAC', '0068000000uPhfnAAC', '0068000000wEdLnAAK', '0068000000wG0yyAAC',
                  '00634000010RxLHAA0' ) THEN [b1].[Actual_Daily_Payment__c]
             ELSE [b].[Actual_Daily_Payment__c]
        END AS [Previous_Actual_Daily_Payment__c]
       ,CASE WHEN [a].[OppId] IN ( '0068000000wFbK9AAK' ) THEN CAST('2015-04-22' AS DATETIME)
             WHEN [a].[OppId] IN ( '0068000000uPv6rAAC', '0068000000uPhfnAAC', '0068000000wEdLnAAK', '0068000000wG0yyAAC',
                  '00634000010RxLHAA0' ) THEN [b1].[Balance_Paid_60_Percent_Date__c]
             ELSE [b].[Balance_Paid_60_Percent_Date__c]
        END AS [Previous_Balance_Paid_60_Percent_Date__c]
       ,CASE WHEN [a].[OppId] IN ( '0068000000wFbK9AAK' ) THEN CAST('2015-05-01' AS DATETIME)
             WHEN [a].[OppId] IN ( '0068000000uPv6rAAC', '0068000000uPhfnAAC', '0068000000wEdLnAAK', '0068000000wG0yyAAC',
                  '00634000010RxLHAA0' ) THEN [b1].[Balance_Paid_100_Percent_Date__c]
             ELSE [b].[Balance_Paid_100_Percent_Date__c]
        END AS [Previous_Balance_Paid_100_Percent_Date__c]
	    /*HARD CODE END 5 Payoff New only + 1 Hard Code (2 CONCURRENTS)*/
       ,[b2].[Id] AS [First_OppId]
       ,[b2].[Fund_Date__c] AS [First_Fund_Date__c]
       ,ISNULL([c].[renewal_row_asc], 0) AS [Renewal_Num]
    FROM
        --All Funded Working Capital Deals
        (
          SELECT
            [o].[Id] AS [OppId]
           ,[o].[AccountId]
           ,[la].[Name] AS [Lender_Account_Name]
           ,[o].[Fund_Date__c]
           ,[o].[ACTUAL_AMT_OFFERED__c]
           ,[o].[ACTUAL_AMT_COLLECTED__c]
           ,[o].[ACTUAL_MCA_TERM__c]
           ,[o].[Actual_Daily_Payment__c]
           ,[o].[Net_to_Customer__c]
           ,[o].[BofI_Deal__c]
           ,ROW_NUMBER() OVER ( PARTITION BY [o].[AccountId] ORDER BY [o].[Fund_Date__c] ) AS [row_asc]
           ,ROW_NUMBER() OVER ( PARTITION BY [o].[AccountId] ORDER BY [o].[Fund_Date__c] DESC ) AS [row_desc]
	
	    --, count(*) over (partition by o.AccountId) as Total_Deal_ct
	    --, min(o.Fund_Date__c) over (partition by o.AccountId) as First_Deal_Fund_Date
	    --, max(o.Fund_Date__c) over (partition by o.AccountId) as Last_Deal_Fund_Date
           ,SUM(CASE WHEN [o].[Type] LIKE 'RENEWAL%' THEN 1
                     ELSE 0
                END) OVER ( PARTITION BY [o].[AccountId] ) AS [Total_Renewal_ct]
	    --, min(case when o.Type like 'RENEWAL%' then o.Fund_Date__c else NULL end) 
	    --	over (partition by o.AccountId) as First_Renewal_Fund_Date
           ,MAX(CASE WHEN [o].[Type] LIKE 'RENEWAL%' THEN [o].[Fund_Date__c]
                     ELSE NULL
                END) OVER ( PARTITION BY [o].[AccountId] ) AS [Last_Renewal_Fund_Date]
		
	    --, sum(case when la.Name like 'National Funding%' then 1 else 0 end) 
	    --	over (partition by o.AccountId) as NF_Deal_ct
	    --, min(case when la.Name like 'National Funding%' then o.Fund_Date__c else NULL end) 
	    --	over (partition by o.AccountId) as First_NF_Deal_Fund_Date
	    --, max(case when la.Name like 'National Funding%' then o.Fund_Date__c else NULL end) 
	    --	over (partition by o.AccountId) as Last_NF_Deal_Fund_Date
		
	    --, sum(case when o.Type like 'RENEWAL%' and la.Name like 'National Funding%' then 1 else 0 end) 
	    --	over (partition by o.AccountId) as NF_Renewal_ct
	    --, min(case when o.Type like 'RENEWAL%' and la.Name like 'National Funding%' then o.Fund_Date__c else NULL end) 
	    --	over (partition by o.AccountId) as First_NF_Renewal_Fund_Date
           ,MAX(CASE WHEN [o].[Type] LIKE 'RENEWAL%' AND [la].[Name] LIKE 'National Funding%' THEN [o].[Fund_Date__c]
                     ELSE NULL
                END) OVER ( PARTITION BY [o].[AccountId] ) AS [Last_NF_RenewalAll_Fund_Date]
           ,MAX(CASE WHEN [o].[Type] = 'RENEWAL' AND [la].[Name] LIKE 'National Funding%' THEN [o].[Fund_Date__c]
                     ELSE NULL
                END) OVER ( PARTITION BY [o].[AccountId] ) AS [Last_NF_Renewal_Fund_Date]
          FROM
            [Salesforce_Repl].[dbo].[Opportunity] AS [o]
            INNER JOIN [Salesforce_Repl].[dbo].[Recordtype] AS [r]
                ON [o].[RecordTypeId] = [r].[Id]
            LEFT JOIN [Salesforce_Repl].[dbo].[Account] AS [la]
                ON [o].[Lender_Account__c] = [la].[Id]
          WHERE
            [o].[StageName] = 'Funded' 
            AND [r].[Name] IN ( 'Working Capital Oppty', 'Broker WC Oppty' )
        ) AS [a]
        LEFT JOIN --To get the Previous Deal
            (
              SELECT
                [o].[Id]
               ,[o].[AccountId]
               ,[o].[Fund_Date__c]
               ,[o].[Type]
               ,ROW_NUMBER() OVER ( PARTITION BY [o].[AccountId] ORDER BY [o].[Fund_Date__c] ) AS [row_asc]
               ,ROW_NUMBER() OVER ( PARTITION BY [o].[AccountId] ORDER BY [o].[Fund_Date__c] DESC ) AS [row_desc]
               ,[o].[ACTUAL_AMT_OFFERED__c]
               ,[o].[ACTUAL_AMT_COLLECTED__c]
               ,CASE WHEN [r].[Name] = 'Broker WC Oppty' AND [o].[Type] IN ( 'NEW', 'CONCURRENT' ) THEN [o].[Broker_Commission__c]
                     ELSE [o].[Actual_FPC_Margin__c]
                END AS [Actual_FPC_Margin__c]
               ,CASE WHEN [r].[Name] = 'Broker WC Oppty' AND [o].[Type] IN ( 'NEW', 'CONCURRENT' ) THEN [o].[Broker_Commission__c]
                     ELSE [o].[Actual_FPC_Margin_w_o_Doc_Fee__c]
                END AS [Actual_FPC_Margin_w_o_Doc_Fee__c]
               ,[o].[ACTUAL_MCA_TERM__c]
               ,[o].[Actual_Daily_Payment__c]
               ,[o].[Balance_Paid_60_Percent_Date__c]
               ,[o].[Balance_Paid_100_Percent_Date__c]
              FROM
                [Salesforce_Repl].[dbo].[Opportunity] AS [o]
                INNER JOIN [Salesforce_Repl].[dbo].[Recordtype] AS [r]
                    ON [o].[RecordTypeId] = [r].[Id]
              WHERE
                [o].[StageName] = 'Funded' AND [r].[Name] IN ( 'Working Capital Oppty', 'Broker WC Oppty' )
            ) AS [b]
            ON [a].[AccountId] = [b].[AccountId] 
            AND ( [a].[row_asc] - 1 ) = [b].[row_asc]
        LEFT JOIN --To get the 2nd Previous Deal (For Concurrent - Hard Code Deals for now)
            (
              SELECT
                [o].[Id]
               ,[o].[AccountId]
               ,[o].[Fund_Date__c]
               ,[o].[Type]
               ,ROW_NUMBER() OVER ( PARTITION BY [o].[AccountId] ORDER BY [o].[Fund_Date__c] ) AS [row_asc]
               ,ROW_NUMBER() OVER ( PARTITION BY [o].[AccountId] ORDER BY [o].[Fund_Date__c] DESC ) AS [row_desc]
               ,[o].[ACTUAL_AMT_OFFERED__c]
               ,[o].[ACTUAL_AMT_COLLECTED__c]
               ,CASE WHEN [r].[Name] = 'Broker WC Oppty' AND [o].[Type] IN ( 'NEW', 'CONCURRENT' ) THEN [o].[Broker_Commission__c]
                     ELSE [o].[Actual_FPC_Margin__c]
                END AS [Actual_FPC_Margin__c]
               ,CASE WHEN [r].[Name] = 'Broker WC Oppty' AND [o].[Type] IN ( 'NEW', 'CONCURRENT' ) THEN [o].[Broker_Commission__c]
                     ELSE [o].[Actual_FPC_Margin_w_o_Doc_Fee__c]
                END AS [Actual_FPC_Margin_w_o_Doc_Fee__c]
               ,[o].[ACTUAL_MCA_TERM__c]
               ,[o].[Actual_Daily_Payment__c]
               ,[o].[Balance_Paid_60_Percent_Date__c]
               ,[o].[Balance_Paid_100_Percent_Date__c]
              FROM
                [Salesforce_Repl].[dbo].[Opportunity] AS [o]
                INNER JOIN [Salesforce_Repl].[dbo].[Recordtype] AS [r]
                    ON [o].[RecordTypeId] = [r].[Id]
              WHERE
                [o].[StageName] = 'Funded' AND [r].[Name] IN ( 'Working Capital Oppty', 'Broker WC Oppty' ) AND [o].[AccountId] IN (
                '0018000001AfBMnAAN', '0018000000whWZhAAM', '0018000001AezwJAAR', '0018000001DJXPTAA5', '0018000001DLf9bAAD',
                '0018000001FUbapAAD', '0018000000nfRAFAA2', '0018000001DKh1RAAT', '0018000000nWQrEAAW', '0018000001C8AJ0AAN',
                '0018000001FXRNnAAP', '0018000001HXqSRAA1', '0018000001FWCRjAAP', '0013400001K6zFUAAZ', '0018000000newqoAAA',
                '0013400001JXVwxAAH', '0013400001JXz3aAAD' ) /*HARD CODE: 10 Payoff New & Concurrent + 7 Payoff New only*/
            ) AS [b1]
            ON [a].[AccountId] = [b1].[AccountId] 
            AND ( [a].[row_asc] - 2 ) = [b1].[row_asc]
        LEFT JOIN --To get the First Deal
            (
              SELECT
                [o].[Id]
               ,[o].[AccountId]
               ,[o].[Fund_Date__c]
               ,ROW_NUMBER() OVER ( PARTITION BY [o].[AccountId] ORDER BY [o].[Fund_Date__c] ) AS [row_asc]
               ,ROW_NUMBER() OVER ( PARTITION BY [o].[AccountId] ORDER BY [o].[Fund_Date__c] DESC ) AS [row_desc]
              FROM
                [Salesforce_Repl].[dbo].[Opportunity] AS [o]
                INNER JOIN [Salesforce_Repl].[dbo].[Recordtype] AS [r]
                    ON [o].[RecordTypeId] = [r].[Id]
              WHERE
                [o].[StageName] = 'Funded' 
                AND [r].[Name] IN ( 'Working Capital Oppty', 'Broker WC Oppty' )
            ) AS [b2]
            ON [a].[AccountId] = [b2].[AccountId] 
            AND [b2].[row_asc] = 1
        LEFT JOIN --To get the N Renewal
            (
              SELECT
                [o].[Id]
               ,[o].[AccountId]
               ,ROW_NUMBER() OVER ( PARTITION BY [o].[AccountId] ORDER BY [o].[Fund_Date__c] ) AS [renewal_row_asc]
              FROM
                [Salesforce_Repl].[dbo].[Opportunity] AS [o]
                INNER JOIN [Salesforce_Repl].[dbo].[Recordtype] AS [r]
                    ON [o].[RecordTypeId] = [r].[Id]
              WHERE
                [o].[StageName] = 'Funded' 
                AND [r].[Name] IN ( 'Working Capital Oppty', 'Broker WC Oppty' ) 
                AND [o].[Type] LIKE 'RENEWAL%'
            ) AS [c]
            ON [a].[OppId] = [c].[Id]

