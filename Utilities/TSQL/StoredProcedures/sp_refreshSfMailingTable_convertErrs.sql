
IF @@SERVERNAME != 'S28'
BEGIN
    RAISERROR('Run on S28',16,1)
    RETURN 
END

USE [Analytics_WS]

IF OBJECT_ID('sp_refreshSfMailingTable_convertErrs','P') IS NOT NULL
    DROP PROCEDURE [sp_refreshSfMailingTable_convertErrs]
GO

CREATE PROCEDURE [sp_refreshSfMailingTable_convertErrs]
(
     @mailTableName VARCHAR(MAX)
    ,@hasAcctNum bit = 0
    ,@hasLeadId bit = 0
)
AS
    BEGIN
       
        DECLARE  @acctStr VARCHAR(4000) = ''
                ,@createAcctStr VARCHAR(4000) = ''
                ,@leadIdStr VARCHAR(4000) = 'NULL'

        IF @hasAcctNum = 1 
        BEGIN
            SET @acctStr = '
                    ,[cm].[Account_Number__c]
                    ,[cm].[Short_Account_Number__c]
                 '
            SET @createAcctStr = '
	           ,[Account_Number__c] [nvarchar](16) NULL
	           ,[Short_Account_Number__c] [nvarchar](9) NULL
            '
        END

        IF @hasLeadId = 1
        BEGIN
            SET @leadIdStr = '[cm].[LeadId]'
        END

        IF OBJECT_ID('salesforce_repl.dbo.[CampaignMember_SfMailingTable_convertErrs]','U') IS NOT NULL
            DROP TABLE [salesforce_repl].[dbo].[CampaignMember_SfMailingTable_convertErrs]

        DECLARE @sql VARCHAR(MAX) = '
            CREATE TABLE [salesforce_repl].[dbo].[CampaignMember_SfMailingTable_convertErrs]
            (
                [Id]         NCHAR(18) NULL
               ,[Error]      NVARCHAR(255) NULL
               ,[contactid]  NCHAR(18) NULL
               ,[leadid]     NCHAR(18) NULL
               ,[campaignid] VARCHAR(18) NULL
               '+@createAcctStr+'
            )
        '
         EXEC(@sql)

        SET @sql = '
			INSERT INTO [salesforce_repl].[dbo].[CampaignMember_SfMailingTable_convertErrs]
			SELECT
			    NULL AS [id]
			   ,NULL AS [error]
			   ,[l].[ConvertedContactId]
			   ,'+@leadIdStr+'
			   ,[cm].[campaignId]
                  '+@acctStr+'
               FROM
				'+@mailTableName+' AS [CM]
				JOIN [s28].[Salesforce_Repl].[dbo].[Lead] AS [l]
					ON [l].[Id] = [cm].[leadId]
			WHERE 
                   [error] LIKE ''%convert%''
		'
        --select @sql
        EXEC (@sql)

        IF EXISTS(select 1)--SELECT TOP 1 1 FROM [salesforce_repl].[dbo].[CampaignMember_SfMailingTable_convertErrs])
        BEGIN
            BEGIN TRY
                EXEC [salesforce_repl].[dbo].[SF_BulkOps]
                    'insert:bulkapi',
                    'salesforce',
                    'CampaignMember_SfMailingTable_convertErrs'
            END TRY
            BEGIN CATCH
                PRINT('Some rows had errors')
            END CATCH

            /* Log the campaign member insert */
            SET @sql = '
                INSERT INTO [S26].[Analytics_WS].[dbo].[CampaignMember_Master_Insert]
                (
                     [Id]
                    ,[Error]
                    ,[contactid]
                    ,[leadid]
                    ,[campaignid]
                    '+REPLACE(@acctStr, '[cm].', '')+'
                    ,StagingId
                    ,insertDate
                )
                SELECT
                     [Id]        
                    ,[Error]     
                    ,[contactid] 
                    ,[leadid]    
                    ,[campaignid]
                    '+REPLACE(@acctStr, '[cm].', '')+'
                    ,-1 AS StagingId
                    ,GETDATE() AS insertDate
                FROM
                    [Salesforce_Repl].[dbo].CampaignMember_SfMailingTable_convertErrs
            '
            --select @sql
            EXEC(@sql)

            --/* Refresh Salesforce_Repl (may be separate job always running) */
            --EXEC [Salesforce_Repl]..SF_REFRESH 'SALESFORCE','CampaignMember'
        
        END

    END