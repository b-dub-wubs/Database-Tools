
<#┌──────────────────────────────────────────────────────────────────────────────────────────────┐#˃
  │ Load Assemblies                                                                              │
˂#└──────────────────────────────────────────────────────────────────────────────────────────────┘#>
[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.Smo') | Out-Null
[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SmoExtended')  | Out-Null
[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic') | Out-Null

<#┌──────────────────────────────────────────────────────────────────────────────────────────────┐#˃
  │ Class prototypes scratch for advanced wizzard                                                │

class IndexSpec
{

    [ValidateNotNullOrEmpty()][bool]$IsUnique
    [IndexColSpec[]]$IndexCols
    [ValidateNotNullOrEmpty()][string]$Phone
}

class IndexColSpec
{

    [ValidateNotNullOrEmpty()][bool]$IsUnique
    [string]$IndexCols
    [ValidateNotNullOrEmpty()][string]$Phone
}



class ColumnSpec
{
    # Optionally, add attributes to prevent invalid values
    [ValidateNotNullOrEmpty()][bool]$IsInPK
    [string]$DefaultValExpression
    [ValidateNotNullOrEmpty()][IndexSpec]$IndexSpec
}
˂#└──────────────────────────────────────────────────────────────────────────────────────────────┘#>

function GetSqlDataTypeDefStr($SmoColDataType)
  { 
    $PlainDataTypes = @(
                          'datetime'
                        , 'date'
                        , 'time'
                        , 'text'
                        , 'ntext'
                        , 'xml'
                        , 'money'
                        , 'bigint'
                        , 'bit'
                        , 'int'
                        , 'smallint'
                        , 'tinyint'
                        , 'real'    
                    )  
    if($SmoColDataType.Name -in $PlainDataTypes)
      {
        return $SmoColDataType.Name.ToUpper()
      }
    else
      {
        if($SmoColDataType.IsStringType)
          {
            return ($SmoColDataType.Name.ToUpper() + "($($_.DataType.MaximumLength))")
          }
        else
          {
            if($SmoColDataType.IsNumericType)
              {
                if($SmoColDataType.Name -match 'float')
                  {
                    return ($SmoColDataType.Name.ToUpper() + "($($_.DataType.NumericPrecision))")
                  }
                else
                  {
                    return ($SmoColDataType.Name.ToUpper() + "($($_.DataType.NumericPrecision),$($_.DataType.NumericScale))")                      
                  }            
              }
            else
              {
                return "NVARCHAR(MAX) --? $($SmoColDataType.Name.ToUpper())"
              }
          }
      }
  }

function Write-TsqlScript
  {
    [CmdletBinding()]
    Param
      (
          [Parameter(Mandatory=$true)]
          [String]$SrcServerInstance
  
        , [Parameter(Mandatory=$true)]
          [String]$SrcDatabase

        , [Parameter(Mandatory=$true)]
          [String]$SrcSchema
          
        , [Parameter(Mandatory=$true)]
          [String]$SrcTable
          
        , [Parameter(Mandatory=$false)]
          [String]$DstDatabase

        , [Parameter(Mandatory=$false)]
          [String]$DstSchema
          
        , [Parameter(Mandatory=$false)]
          [String]$DstTable
      )
      
		$SmoServer = New-Object Microsoft.SqlServer.Management.Smo.Server $SrcServerInstance
		$SmoServer.ConnectionContext.Disconnect() | Out-Null
		$SmoServer.ConnectionContext.ApplicationName = 'PowerShell Script'
		$SmoServer.ConnectionContext.LoginSecure = $true
		$SmoServer.ConnectionContext.Connect()
    $SmoTable = $SmoServer.Databases[$SrcDatabase].Tables | where {$_.Schema -eq $SrcSchema -and $_.Name -eq $SrcTable}
  
    #$SmoTable | oh

    $SrcTableFullyQualified = "[$($SrcDatabase)].[$($SrcSchema)].[$($SrcTable)]"
    if(!$DstDatabase)
      {
        $DstDatabase  = [Microsoft.VisualBasic.Interaction]::InputBox("Change target database $($SrcDatabase)?", "New Database:", $SrcDatabase)
      }
    if(!$DstSchema)
      {
        $DstSchema    = [Microsoft.VisualBasic.Interaction]::InputBox("Change target Schema $($SrcSchema)?", "New Schema:", $SrcSchema)    
      }
    if(!$DstTable)
      {
        $DstTable     = [Microsoft.VisualBasic.Interaction]::InputBox("Rename table table $($SrcTable)?", "New Table Name:", $SrcTable)
      }
    
    $DstTableSchemaQualified = "$($DstSchema).$($DstTable)"
    $DstTableFullyQualified = "$($DstDatabase).$($DstSchema).$($DstTable)"
    
    [String]$DstTableCreateSQL = @"
/*┌─────────────────────────────────────────────────────────────────────────────────────────────┐*\
  │ TITLE: Table DDL                                                                            │
  │   $DstTableFullyQualified
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤
  │ DESCRIPTION:                                                                                │
  │                                                                                             │
  │                                                                                             │
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤
  │ REVISION HISTORY:                                                                           │
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤
  │   DATE       AUTHOR          CHANGE DESCRIPTION                                             │
  │   ────────── ─────────────── ───────────────────────────────────────────────────────────────┤
      $((Get-Date).ToString('yyyy.MM.dd')) $(($env:USERNAME).PadRight(17))Initial Draft
\*└─────────────────────────────────────────────────────────────────────────────────────────────┘*/
USE $DstDatabase
GO

IF EXISTS (SELECT *
           FR__SRC_SCHEMA_NAME__ sys.objects
           WHERE object_id = OBJECT_ID(N'$DstTableSchemaQualified')
                 AND type IN (N'U'))
    DROP TABLE 
      $DstTableSchemaQualified
GO

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

IF NOT EXISTS (SELECT *
               FR__SRC_SCHEMA_NAME__ sys.objects
               WHERE object_id = OBJECT_ID(N'$DstTableSchemaQualified')
                     AND type IN (N'U'))
  BEGIN
    CREATE TABLE
      $DstTableSchemaQualified
        (

"@

    [int]$SrcColNameMaxLen = 0
    [int]$DstColNameMaxLen = 0
    
    [int]$ColDataTypeMaxLen = 0
    $ColMap = @{}
    $SmoTable.Columns | where {!$_.IsSystemObject} | 
    % {
        $DstColName = [Microsoft.VisualBasic.Interaction]::InputBox("Rename $($_.Name)?", "New Column Name:", $_.Name)
        $ColMap.Add($_.Name,$DstColName)
        if($_.Name.ToString().Length -gt $SrcColNameMaxLen)
          {
            $SrcColNameMaxLen = $_.Name.ToString().Length
          }
        if($DstColName.Length -gt $DstColNameMaxLen)
          {
            $DstColNameMaxLen = $DstColName.Length
          }
        if((GetSqlDataTypeDefStr($_.DataType)).Length -gt $ColDataTypeMaxLen)
          {
            $ColDataTypeMaxLen = (GetSqlDataTypeDefStr($_.DataType)).Length
          }
      }
      
  if($SrcColNameMaxLen % 2 -gt 0)
    {
      $SrcColNameMaxLen++
    }
    
  if($ColDataTypeMaxLen % 2 -gt 0)
    {
      $ColDataTypeMaxLen++
    }
    
  [bool]$IsFirstCol = $true  
  $SmoTable.Columns | where {!$_.IsSystemObject} | 
    % {
        if($_.Nullable)
          {
            $NullableStr = 'NULL'
          }
        else
          {
            $NullableStr = 'NOT NULL'
          }
        if($IsFirstCol)
          {
            $DstTableCreateSQL += @"
            $($ColMap[$_.Name].PadRight($DstColNameMaxLen)) $((GetSqlDataTypeDefStr($_.DataType)).PadRight($ColDataTypeMaxLen)) $NullableStr
"@
          }
        else
          {
            $DstTableCreateSQL += @"
          , $($ColMap[$_.Name].PadRight($DstColNameMaxLen)) $((GetSqlDataTypeDefStr($_.DataType)).PadRight($ColDataTypeMaxLen)) $NullableStr

"@          
          }
        $IsFirstCol = $false
      }
      
    [String]$DstTableCreateSQL += @"
        )

GO

"@   
    [String]$DstTableCreateSQL += @"
/*┌─────────────────────────────────────────────────────────────────────────────────────────────┐*\
  │ Populate Fr__SRC_SCHEMA_NAME__ Old Table                                                                     │
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤

    INSERT
      $DstTableSchemaQualified
        (

"@

  [bool]$IsFirstCol = $true  
  $SmoTable.Columns | where {!$_.IsSystemObject} | 
    % {
        if($_.Nullable)
          {
            $NullableStr = 'NULL'
          }
        else
          {
            $NullableStr = 'NOT NULL'
          }
        if($IsFirstCol)
          {
            $DstTableCreateSQL += @"
            $($ColMap[$_.Name])

"@
          }
        else
          {
            $DstTableCreateSQL += @"
          , $($ColMap[$_.Name])

"@          
          }
        $IsFirstCol = $false
      }
      
    [String]$DstTableCreateSQL += @"
        
        )
    SELECT

"@

  [bool]$IsFirstCol = $true  
  $SmoTable.Columns | where {!$_.IsSystemObject} | 
    % {
        if($_.Nullable)
          {
            $NullableStr = 'NULL'
          }
        else
          {
            $NullableStr = 'NOT NULL'
          }
        if($IsFirstCol)
          {
            $DstTableCreateSQL += @"
        [$($_.Name)]

"@
          }
        else
          {
            $DstTableCreateSQL += @"
      , [$($_.Name)]

"@          
          }
        $IsFirstCol = $false
      }

    [String]$DstTableCreateSQL += @"
    FR__SRC_SCHEMA_NAME__
      $SrcTableFullyQualified

\*└─────────────────────────────────────────────────────────────────────────────────────────────┘*/

"@

    $DstTableCreateSQL | Out-Host
    $DstTableCreateSQL | Out-File -FilePath "$env:USERPROFILE" -Encoding utf8 -Confirm
    
  }

$SrcTableManifest = @(
, @( '__SRC_DB_NAME__', '__SRC_SCHEMA_NAME__', '__SRC_TBL_NAME__', '__DST_DB_NAME__', '__DST_SCHEMA_NAME__', '__DST_TBL_NAME__')
, @( '__SRC_DB_NAME__', '__SRC_SCHEMA_NAME__', '__SRC_TBL_NAME__', '__DST_DB_NAME__', '__DST_SCHEMA_NAME__', '__DST_TBL_NAME__')
, @( '__SRC_DB_NAME__', '__SRC_SCHEMA_NAME__', '__SRC_TBL_NAME__', '__DST_DB_NAME__', '__DST_SCHEMA_NAME__', '__DST_TBL_NAME__')
, @( '__SRC_DB_NAME__', '__SRC_SCHEMA_NAME__', '__SRC_TBL_NAME__', '__DST_DB_NAME__', '__DST_SCHEMA_NAME__', '__DST_TBL_NAME__')
)
$myServerInstance = 'dum'
$SrcTableManifest | % {
  Write-TsqlScript -SrcServerInstance $myServerInstance -SrcDatabase $_[0] -SrcSchema $_[1] -SrcTable $_[2] -DstDatabase $_[3] -DstSchema $_[4] -DstTable $_[5]

}

<#

            , DataTypeStrNative = CASE
                                    WHEN [DATA_TYPE] IN(
                                                            'datetime'
                                                          , 'date'
                                                          , 'time'
                                                          , 'text'
                                                          , 'ntext'
                                                          , 'xml'
                                                          , 'money'
                                                          , 'bigint'
                                                          , 'bit'
                                                          , 'int'
                                                          , 'smallint'
                                                          , 'tinyint'
                                                          , 'real'
                                                        )
                                      THEN [DATA_TYPE]            

                                    WHEN [DATA_TYPE] LIKE '%char' OR [DATA_TYPE] LIKE '%binary'  
                                      THEN [DATA_TYPE] + '(' + REPLACE(LTRIM(RTRIM(STR([CHARACTER_MAXIMUM_LENGTH]))),'-1','MAX') + ')'

                                    WHEN [DATA_TYPE] = 'datetime2' 
                                      THEN [DATA_TYPE] + '(' + LTRIM(RTRIM(STR([DATETIME_PRECISION]))) + ')'

                                    WHEN [DATA_TYPE] = 'float' 
                                      THEN [DATA_TYPE] + '(' + LTRIM(RTRIM(STR([NUMERIC_PRECISION]))) + ')'              

                                    WHEN [DATA_TYPE] IN('decimal', 'numeric')
                                      THEN [DATA_TYPE] + '(' + LTRIM(RTRIM(STR([NUMERIC_PRECISION]))) + ',' + LTRIM(RTRIM(STR([NUMERIC_SCALE])))  + ')'     

                                  END 
                                + CASE 
                                    WHEN IS_NULLABLE = '1' 
                                      THEN ' NULL' 
                                    ELSE ' NOT NULL' 
                                  END
                                  
#>

