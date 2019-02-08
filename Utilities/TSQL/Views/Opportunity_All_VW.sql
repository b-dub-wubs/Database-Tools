

SELECT 
	o.id AS OppId
	, o.Fund_Date__c
    
	, r.name AS RecordTypeName -- 2 sec
	, la.Name AS Lender_Account_Name --4 sec

	, o.WC_Credit_Decision_Record__c-- 8 sec
	, o.Years_in_Business__c
	
	, crl.Id AS CreditReviewId -- 9 sec
	, COALESCE(cd.Credit_Review__c,crl.Id) AS Best_CreditReviewId
    
	, cr.Decline_Reasons__c
	, cr.Decline_Other_Reason__c
	, cr.Broker_Decline_Reasons__c
	, cr.Broker_Decline_Other_Reason__c
	, cr.PG_1_EQF_Score__c
	, cr.PG_1_EXP_Score__c
	, cr.Second_Review_Date__c
	, cr.Second_Review_By__c
	, cr.Max_Approval_Amount__c
	, cr.Max_Term__c -- 9 sec
    
	, COALESCE(cr.SIC_Code__c, lcr.SIC_Code__c) AS SIC_Code__c
	, COALESCE(cr.SIC_Name__c, lcr.SIC_Name__c) AS SIC_Name__c--9 sec
	, COALESCE(cr.SIC_Code__c, lcr.SIC_Code__c, a.SIC) AS SIC_Code
	, COALESCE(cr.SIC_Name__c, lcr.SIC_Name__c, a.SIC_Name__c) AS SIC_Name --13 sec

    
	, ca.Full_Name__c AS Credit_Analyst_FullName
	, ca.Operations_Roles__c AS Credit_Analyst_OpsRole
	, ica.Full_Name__c AS Internal_Credit_Analyst_FullName
	, ica.Operations_Roles__c AS Internal_Credit_Analyst_OpsRole
	, cca.Full_Name__c AS Commercial_Analyst_FullName
	, cca.Operations_Roles__c AS Commercial_Analyst_OpsRole
	, f.Full_Name__c AS Funder_FullName
	, sr.Full_Name__c AS Sales_Rep_FullName
	, srm.Full_Name__c AS Sales_Rep_Manager_FullName
	, sr.Title AS Sales_Rep_Title
	, sr.Division AS Sales_Rep_Division
	, CASE
		WHEN sr.Name IN ('Eric Fong','Roman Bogomolny','Steve De Simone','Tim Lewis') THEN '2012-Prior'
		WHEN sr.Name IN ('John Janiga') THEN '2015Q4'
		ELSE SUBSTRING(sr.Sales_Class__c,CHARINDEX(' ',sr.Sales_Class__c)+1,4)
			+ CASE
				WHEN SUBSTRING(sr.Sales_Class__c,1,CHARINDEX(' ',sr.Sales_Class__c)) = 'January' THEN 'Q1'
				WHEN SUBSTRING(sr.Sales_Class__c,1,CHARINDEX(' ',sr.Sales_Class__c)) = 'April' THEN 'Q2'
				WHEN SUBSTRING(sr.Sales_Class__c,1,CHARINDEX(' ',sr.Sales_Class__c)) = 'May' THEN 'Q2'
				WHEN SUBSTRING(sr.Sales_Class__c,1,CHARINDEX(' ',sr.Sales_Class__c)) = 'June' THEN 'Q3'
				WHEN SUBSTRING(sr.Sales_Class__c,1,CHARINDEX(' ',sr.Sales_Class__c)) = 'July' THEN 'Q3'
				WHEN SUBSTRING(sr.Sales_Class__c,1,CHARINDEX(' ',sr.Sales_Class__c)) = 'September' THEN 'Q4'
				ELSE SUBSTRING(sr.Sales_Class__c,1,CHARINDEX(' ',sr.Sales_Class__c))
			END
		END AS Sales_Rep_Class--27sec

FROM
    [Salesforce_Repl].[dbo].[Opportunity] [o] --215K rows, many indexes
    INNER JOIN [Salesforce_Repl].[dbo].[Recordtype] [r] --66 rows, pk
        ON [o].[RecordTypeId] = [r].[Id]
    LEFT JOIN [Salesforce_Repl].[dbo].[Account] [la] --697K rows, pk + nc
        ON [o].[Lender_Account__c] = [la].[Id]
    LEFT JOIN [Analytics_DWH].[dbo].[Opportunity_Last_Credit_Review_Link_VW] [crl] --logic built in -return
        ON [o].[Id] = [crl].[Opportunity__c]
    LEFT JOIN [Salesforce_Repl].[dbo].[WC_Credit_Decision__c] [cd] --157K, pk
        ON [o].[WC_Credit_Decision_Record__c] = [cd].[Id]
    LEFT JOIN [Salesforce_Repl].[dbo].[Credit_Review__c] [cr] --100K, pk + nc
        ON [crl].[Id] = [cr].[Id]
    LEFT JOIN [Salesforce_Repl].[dbo].[Lease_Credit_Review__c] [lcr] --10K pk
        ON [crl].[Id] = [lcr].[Id]
    LEFT JOIN [Salesforce_Repl].[dbo].[User] [ca] --1000 pk
        ON [o].[Credit_Analyst__c] = [ca].[Id]
    LEFT JOIN [Salesforce_Repl].[dbo].[User] [ica] -- same as above
        ON [o].[Internal_Credit_Analyst__c] = [ica].[Id]
    LEFT JOIN [Salesforce_Repl].[dbo].[User] [cca] -- same as above
        ON [o].[Commercial_Analyst__c] = [cca].[Id]
    LEFT JOIN [Salesforce_Repl].[dbo].[User] [f] -- same as above
        ON [o].[Funder__c] = [f].[Id]
    LEFT JOIN [Salesforce_Repl].[dbo].[User] [sr] -- same as above
        ON [o].[OwnerId] = [sr].[Id]
    LEFT JOIN [Salesforce_Repl].[dbo].[User] [srm] -- same as above
        ON [sr].[ManagerId] = [srm].[Id]
    --LEFT JOIN [Salesforce_Repl].[dbo].[User] [d] -- same as above
    --    ON [o].[Documentator__c] = [d].[Id] 
    --LEFT JOIN [Salesforce_Repl].[dbo].[User] [cp] -- same as above
    --    ON [o].[Credit_Processor__c] = [cp].[Id]
    LEFT JOIN [Salesforce_Repl].[dbo].[Account] [a] -- same as above
        ON [o].[AccountId] = [a].[Id]
    --LEFT JOIN [Salesforce_Repl].[dbo].[Account] [ba] -- same as above
    --    ON [o].[Broker_Account__c] = [ba].[Id]
    --LEFT JOIN [Salesforce_Repl].[dbo].[User] [rbd] -- same as above
    --    ON [ba].[Regional_Business_Developer__c] = [rbd].[Id]
    --LEFT JOIN [Salesforce_Repl].[dbo].[User] [bas] -- same as above
    --    ON [ba].[OwnerId] = [bas].[Id]
    --LEFT JOIN [Salesforce_Repl].[dbo].[FPC_Funding_Del__c] [ft] --200K pk + nc
    --    ON [o].[Id] = [ft].[Opportunity__c]
    --       AND [ft].[Status__c] = 'Approved'
    --       AND YEAR([ft].[CreatedDate]) >= 2012
WHERE
    [o].[Id] NOT IN ( '0068000000ZpQF8AAN' , '0068000000qtm7AAAQ' , '0068000000qwLghAAE' , '0068000000lz2ugAAA' , '0068000000sbNtcAAE' , '0068000000qwyGsAAI' ,
                  '0068000000qvedNAAQ' , '0068000000sa5S0AAI' , '0068000000sc9MtAAI' , '0068000000sbNK1AAM' , '0068000000sbNOqAAM' , '0068000000sbeWsAAI' ,
                  '0068000000uR62NAAS' , '0068000000uSUilAAG' , '0063400000wGageAAC' , '0063400000y2no1AAA' , '0068000000lz2gPAAQ' , '0068000000uPmDDAA0' ,
                  '0063400000xdxylAAA' , '0063400000yfUMRAA2' , '0068000000uSHL3AAO' , '0068000000uSRnuAAG' , '0068000000uSHKAAA4' , '0068000000uSSD7AAO' ,
                  '0068000000uSRhWAAW' , '0068000000uSHMzAAO' , '0068000000h1OenAAE' , '0068000000bc5UUAAY' , '0068000000sdBmoAAE' , '0068000000sdBmtAAE' ,
                  '0068000000uQvbaAAC' , '0068000000ZmNY5AAN' , '0063400000yfdbPAAQ' , '0063400000zdhAwAAI' , '00634000010jCcRAAU' ) --Test Oppty
    AND [o].[AccountId] NOT IN ( '0018000000ni9agAAA' ) --Test Account

