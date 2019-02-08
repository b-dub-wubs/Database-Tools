<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2019 v5.6.156
	 Created on:   	1/14/2019 2:29 PM
	 Created by:   	bwarner
	 Organization: 	
	 Filename:     	
	===========================================================================
	.DESCRIPTION
		A description of the file.
#>

$ComponentSQL = "

  DECLARE 
      @TimestampStr     VARCHAR(15)   = CONVERT(VARCHAR(15),GETDATE(),12) + 'T' + REPLACE(CONVERT(VARCHAR(15),GETDATE(),8),':','')
    , @ArchiveTableName SYSNAME
    , @sql              NVARCHAR(MAX)


"
$RunConfigSQL = ''
$i = 1

@(
, 'dbo.Lead_Staging_Insert'
, 'dbo.Lead_Staging_Update'
, 'dbo.CampaignMember_Staging_Insert'
, 'Salesforce_DBAmpAdHoc.dbo.Lead_Batch_Insert'
, 'Salesforce_DBAmpAdHoc.dbo.Lead_Batch_Update'
, 'Salesforce_DBAmpAdHoc.dbo.CampaignMember_Batch_Insert'
) | %{


  $ComponentName = "Clear SF Load Queue => $_"



$ComponentSQL+=@"



    /*┌────────────────────────────────────────────────────────────────────┐*\.
      │ BEGIN: $($ComponentName)
    \*└────────────────────────────────────────────────────────────────────┘*/
    SET @RunLogID_step = NULL
    EXEC logging.usp_RunLog_LogBegin 
        @ParentRunLogID   = @RunLogID_sproc
      , @RunComponentName = '$($ComponentName)'
      , @RunLogID         = @RunLogID_step OUTPUT

    SET @ArchiveTableName = '$($_)_ARCH_' + @TimestampStr
  
    SET @sql = '
SELECT *
INTO '+@ArchiveTableName+'
FROM $($_)
'
    IF @BackupExisting = 1
      BEGIN
        EXEC logging.usp_EventMessage_Log @EventMessage=@sql, @ProcName=@ProcName
        EXEC logging.usp_RunAttribute_Set 
            @RunLogID       = @RunLogID_sproc
          , @AttributeName  = 'DSQL:Archive-$($_)'
          , @AttributeValue = @sql
        EXEC(@sql)        
      END

    TRUNCATE TABLE $($_)
    
    EXEC logging.usp_RunAttribute_Set 
        @RunLogID       = @RunLogID_step
      , @AttributeName  = 'ArchivedTableName'
      , @AttributeValue = @ArchiveTableName

    SET @RowsAffected = @@ROWCOUNT
    EXEC logging.usp_RowsAffected_Log 
        @RunLogID       = @RunLogID_step
      , @OperationType  = 'archive'
      , @RowsAffected   = @RowsAffected
      , @ObjectName     = '$($_)'
      
    EXEC logging.usp_RunLog_LogEnd 
        @RunLogID   =  @RunLogID_step
      , @ReturnCode = NULL
      , @DidSucceed = 1
      
      
      
"@


$RunConfigSQL+=@"


EXEC logging.usp_RunComponent_Add
    @RunComponentName     = '$($ComponentName)' 
  , @RunComponentDesc     = 'Clears the SF Data Upload Queue Table $_'
  , @ParentRunComponentID = @RunComponentID_parent
  , @SequentialPosition   = $i
  , @RunComponentID       = @RunComponentID_child OUTPUT    


"@

$i++
} 



@"


/*┌─────────────────────────────────────────────────────────────────────────────────────────────┐*\
    COMPONENT SQL
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤

$ComponentSQL

  ├─────────────────────────────────────────────────────────────────────────────────────────────┤
  │ RUN COMPONENT REGISTRATION                                                                  │
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤

    DECLARE 
        @RunComponentID_parent  SMALLINT 
      , @RunComponentID_child   SMALLINT 

    EXEC logging.usp_RunComponent_Add
        @RunComponentName     = 'sp_uploadSfBatches_vNext' 
      , @RunComponentDesc     = 'Uploads a batch of lead inserts or updates into salesforce and cleans up atfter itself'
      , @ParentRunComponentID = NULL
      , @SequentialPosition   = NULL
      , @RunComponentID       = @RunComponentID_parent OUTPUT

$RunConfigSQL

    SELECT * FROM logging.RunComponent

\*└─────────────────────────────────────────────────────────────────────────────────────────────┘*/




"@ | oh