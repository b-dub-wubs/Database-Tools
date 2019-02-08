



/*┌─────────────────────────────────────────────────────────────────────────────────────────────┐*\
  │ TITLE: Salesforce_DBAmpAdHoc                                                                │
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤
  │ DESCRIPTION:                                                                                │
      Replicating Large Tables
\*└─────────────────────────────────────────────────────────────────────────────────────────────┘*/







USE Salesforce_DBAmpAdHoc
GO

--EXEC Salesforce_DBAmpAdHoc.dbo.SF_ReplicateLarge
--    @table_server = 'SALESFORCE'
--  , @table_name   = 'CampaignMember'
--  , @batchsize    = 100000 

/*┌────────────────────────────────────────────────────────────────────┐*\.
    PKChunk => Works for Replicating Larger Tables Like Campaign Member
\*└────────────────────────────────────────────────────────────────────┘*/

EXEC Salesforce_DBAmpAdHoc.dbo.SF_Replicate
    @table_server = 'SALESFORCE'
  , @table_name   = 'CampaignMember'
  , @options      = 'PKChunk' 





EXEC SF_Replicate 'SALESFORCE','CampaignMember','pkchunk,batchsize(100000)'





/*┌────────────────────────────────────────────────────────────────────┐*\.
    PKChunk w/ Batching  => If Default Batch Size Still Causes
    timeouts with PKCHunk, try setting it to a lower batch size
    the default is 
\*└────────────────────────────────────────────────────────────────────┘*/

EXEC Salesforce_DBAmpAdHoc.dbo.SF_Replicate
    @table_server = 'SALESFORCE'
  , @table_name   = 'CampaignMember'
  , @options      = 'PKChunk' 


/*┌─────────────────────────────────────────────────────────────────────────────────────────────┐*\
  │ TITLE: Salesforce_DBAmpAdHoc                                                                │
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤
  │ DESCRIPTION:                                                                                │

\*└─────────────────────────────────────────────────────────────────────────────────────────────┘*/

USE Salesforce_Repl
GO

EXEC Salesforce_Repl.dbo.SF_Replicate
    @table_server = 'SALESFORCE'
  , @table_name   = 'CampaignMember'
  , @options      = 'PKChunk' 


  USE Salesforce_Repl
GO





EXEC Salesforce_DBAmpAdHoc.dbo.SF_Replicate
    @table_server = 'SALESFORCE'
  , @table_name   = 'CampaignMember'
  , @options      = 'PKChunk' 
