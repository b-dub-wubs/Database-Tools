Import-Module SqlServer

function Install-DbAmpBulkloadErrViews
  {
    [CmdletBinding()]
    Param
      (
          [Parameter(Mandatory=$true)]
          [String]$ServerInstance
  
        , [Parameter(Mandatory=$true)]
          [String]$Database
         
        , [Parameter(Mandatory=$false)]
          [String]$ScriptDestDir = "$env:USERPROFILE\Documents"          
      )
      
		$SmoServer = New-Object Microsoft.SqlServer.Management.Smo.Server $ServerInstance
		$SmoServer.ConnectionContext.Disconnect() | Out-Null
		$SmoServer.ConnectionContext.ApplicationName = 'PowerShell Script'
		$SmoServer.ConnectionContext.LoginSecure = $true
		$SmoServer.ConnectionContext.Connect()
    $SmoServer.Databases[$Database].Tables | where {!$_.IsSystemObject -and $_.Name -match '_(insert|update|delete)_' -and $_.Columns.Contains('Error') -and $_.Name -notmatch 'Template'} | % {
    $DDL=''
    $thisViewName = "$($_)_ERR".Replace('[','').Replace(']','')
    $DDL = @"
/*┌─────────────────────────────────────────────────────────────────────────────────────────────┐*\
  │ TITLE: View DDL                                                                             │
  │   $($Database).$($_.Schema.Name).$($thisViewName)
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤
  │ DESCRIPTION:                                                                                │
     Errored Records for DBAmp Bulk
\*└─────────────────────────────────────────────────────────────────────────────────────────────┘*/
USE $($Database)
GO

IF EXISTS (SELECT *
           FROM sys.objects
           WHERE object_id = OBJECT_ID(N'$($_.Schema.Name).$($thisViewName)')
                 AND type IN (N'V'))
    DROP VIEW 
      $($_.Schema.Name).$($thisViewName)
GO

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW
  $($_.Schema.Name).$($thisViewName)
AS
SELECT
  *
FROM
  $($_.Schema.Name).$($_)
WHERE
  Error NOT LIKE 'BulkAPI:%:Operation Successful.'
GO

"@
Invoke-Sqlcmd -ServerInstance s26 -Database Salesforce_DBAmpAdHoc -Query $DDL
$DDL|Out-File -LiteralPath "$ScriptDestDir\Salesforce_DBAmpAdHoc.dbo.$thisViewName.sql" -Force
$DDL|oh
}
}
Install-DbAmpBulkloadErrViews -ServerInstance s26 -Database 'Salesforce_DBAmpAdHoc'