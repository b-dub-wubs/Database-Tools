<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2019 v5.6.156
	 Created on:   	1/10/2019 1:32 PM
	 Created by:   	bwarner
	 Organization: 	
	 Filename:     	
	===========================================================================
	.DESCRIPTION
		A description of the file.
#>

$CodeBone = @"




/*┌────────────────────────────────────────────────────────────────────┐*\.
  │  BEGIN: __RUN_COMPONENT_NAME__
\*└────────────────────────────────────────────────────────────────────┘*/
  SET @RunLogID_step = NULL
  EXEC logging.usp_RunLog_LogBegin 
      @ParentRunLogID   = @RunLogID_sproc
    , @RunComponentName = '__RUN_COMPONENT_NAME__'
    , @RunLogID         = @RunLogID_step OUTPUT

  /* Log and arbitrary attribute value
  EXEC logging.usp_RunAttribute_Set 
      @RunLogID       = RunLogID_step
    , @AttributeName  = '__RUN_ATTRIB___'
    , @AttributeValue = '__RUN_ATTRIB_VALUE__' */




  SET @RowsAffected = @@ROWCOUNT
  EXEC logging.usp_RowsAffected_Log 
      @RunLogID       = @RunLogID_step
    , @OperationType  = 'insert'
    , @RowsAffected   = @RowsAffected
    , @ObjectName     = 'Lead_Staging_Update'
    
  EXEC logging.usp_RunLog_LogEnd 
      @RunLogID   =  @RunLogID_step
    , @ReturnCode = NULL
    , @DidSucceed = 1
/*┌────────────────────────────────────────────────────────────────────┐*\.
  │ END:  __RUN_COMPONENT_NAME__
\*└────────────────────────────────────────────────────────────────────┘*/    





"@

$ConfigWidgetlet = @"

DECLARE 
    @RunComponentID_parent  SMALLINT = (SELECT RunComponentD FROM logging.RunComponent WHERE RunComponentName = 'usp_DirectMail_CampaignMember_TargetErrors_SF_Load')
  , @RunComponentID_child   SMALLINT  

  EXEC logging.usp_RunComponent_Add
    @RunComponentName     = '__RUN_COMPONENT_NAME__'
  , @RunComponentDesc     = '__RUN_COMPONENT_NAME__'
  , @ParentRunComponentID = @RunComponentID_parent
  , @SequentialPosition   = 1
  , @RunComponentID       = @RunComponentID_child OUTPUT
  
"@

$CodeBones    = ''
$ConfigWidget  = ''

@(
, 'Clear the Retry Holding Tables; Snapshot Rows if they exist'
, 'Salesforce_DBAmpAdHoc.dbo.SF_BulkOps'
, 'Clear the Retry Holding Tables; Snapshot Rows if they exist'
, 'Load the Campaign Member Batch Insert Retry Table'
, 'Load Campaign Member Batch Insert Tetry Table '
, 'Archive Results to Master Campaign Member Insert Table'
)|%{
  $CodeBones+=$CodeBone.Replace('__RUN_COMPONENT_NAME__',$_)
  $ConfigWidget+=$ConfigWidgetlet.Replace('__RUN_COMPONENT_NAME__',$_)
}

$PreBuildBundle = @"

/*┌─────────────────────────────────────────────────────────────────────────────────────────────┐*\
  │ CONFIG. WIDGET                                                                              │
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤

$CodeBones


  ├─────────────────────────────────────────────────────────────────────────────────────────────┤
  │ CODE BONES                                                                                  │
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤

$ConfigWidget

\*└─────────────────────────────────────────────────────────────────────────────────────────────┘*/


"@

$PreBuildBundle|oh