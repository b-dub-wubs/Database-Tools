<#
.SYNOPSIS


.DESCRIPTION


.NOTES
┌─────────────────────────────────────────────────────────────────────────────────────────────┐
│ ORIGIN STORY                                                                                │
├─────────────────────────────────────────────────────────────────────────────────────────────┤
│   DATE        : yyyy.mm.dd
│   AUTHOR      : __AUTHOR_NAME__
│   DESCRIPTION : Initial Draft
└─────────────────────────────────────────────────────────────────────────────────────────────┘

.PARAMETER Param01
__DESC_PARAM01__

.PARAMETER Param02
__DESC_PARAM02__

.EXAMPLE

foo `
  -Param01 'Hello' `
  -Param02 'World' | oh

#>

function Write-ModTrackingFieldsScript
  {
    [OutputType([String])]    
    [CmdletBinding()]
    Param
      (
          [Parameter(Mandatory = $true)]
          $TableManifest

        , [Parameter(Mandatory = $true)]
          [String]$ScriptWriteDir



      )

    $SQL_Alter = ''

    $TableManifest | 
      % {
          $Database = $_[0]
          $Schema = $_[1]
          $Table = $_[2]
          $PK_Col = $_[3]      
          $SQL_Alter += @"

USE $Database
GO

ALTER TABLE
  $Schema.$Table

ADD

            CreatedDate       DATETIME        NOT NULL
                              CONSTRAINT
                                DF_$($Schema)_$($Table)_CreatedDate
                              DEFAULT 
                                GETDATE()
          , CreatedBy         SYSNAME         NOT NULL
                              CONSTRAINT
                                DF_$($Schema)_$($Table)_CreatedBy
                              DEFAULT 
                                SUSER_NAME()
          , ModifiedDate      DATETIME        NOT NULL
                              CONSTRAINT
                                DF_$($Schema)_$($Table)_ModifiedDate
                              DEFAULT 
                                GETDATE()
          , ModifiedBy        SYSNAME         NOT NULL
                              CONSTRAINT
                                DF_$($Schema)_$($Table)_ModifiedBy
                              DEFAULT 
                                SUSER_NAME()

"@
          $TriggerFileName = "$Database.$Schema.$Table.tr_$($Schema)_$($Table)_Modified.sql"
          $TriggerDML_SQL = @"

/*┌─────────────────────────────────────────────────────────────────────────────────────────────┐*\.
  │ TITLE: Index DDL $Database.$Schema.$Table.tr_$($Schema)_$($Table)_Modified
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤
  │ DESCRIPTION:                                                                                │
      
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤
  │ REVISION HISTORY:                                                                           │
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤
  │   DATE       AUTHOR          CHANGE DESCRIPTION                                             │
  │   ────────── ─────────────── ────────────────────────────────────────────────────────────── │
      $((Get-Date).ToString('yyyy.MM.dd')) bwarner         Initial Draft
\*└─────────────────────────────────────────────────────────────────────────────────────────────┘*/
USE $Database
GO

IF EXISTS (SELECT 1
           FROM sys.triggers
           WHERE object_id = OBJECT_ID(N'dbo.tr_$($Schema)_$($Table)_Modified'))
  DROP TRIGGER 
    dbo.tr_$($Schema)_$($Table)_Modified
GO

SET ANSI_PADDING ON
GO

CREATE TRIGGER 
  dbo.tr_$($Schema)_$($Table)_Modified
ON 
  $Schema.$Table
 
FOR -- INSTEAD OF
  UPDATE -- INSERT DELETE
AS

UPDATE
  $Schema.$Table 
SET
    ModifiedDate  = GETDATE()
  , ModifiedBy    = SUSER_SNAME()
WHERE
  $PK_Col IN (SELECT $PK_Col FROM INSERTED)

"@
        $DestPath = "$ScriptWriteDir\$TriggerFileName"
        $DestPath | oh
      $TriggerDML_SQL | Out-File -FilePath "$ScriptWriteDir\$TriggerFileName" -Force

    }


   $SQL_Alter | oh

  }

$TableManifest = @(
, @(
      , 'DirectMail'
      , 'config'
      , 'BusinessAgeSegment'
      , 'BusinessAgeSegmentID'
  )
, @(
      , 'DirectMail'
      , 'config'
      , 'EmployeeSizeSegment'
      , 'EmployeeSizeSegmentID'
  )
, @(
      , 'DirectMail'
      , 'config'
      , 'MailSegment'
      , 'MailSegmentID'
  )
, @(
      , 'DirectMail'
      , 'dbo'
      , 'DataProvider'
      , 'DataProviderID'
  )

, @(
      , 'DirectMail'
      , 'dbo'
      , 'DataFeed'
      , 'DataFeedID'
  )
)    

#C:\Users\bwarner\Documents\CodeGen

Write-ModTrackingFieldsScript -TableManifest $TableManifest -ScriptWriteDir 'E:\LocalGitRepos\bwarner\Analytics-Data-Infrastructure\Projects\Direct Mail\vNext\TSQL\DirectMail\Tables\CODE_GEN'
