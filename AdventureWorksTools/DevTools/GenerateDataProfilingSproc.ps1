<#┌──────────────────────────────────────────────────────────────────────────────────────────────┐#˃
  │ Load Assemblies                                                                              │
˂#└──────────────────────────────────────────────────────────────────────────────────────────────┘#>
[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.Smo')          | Out-Null
[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SmoExtended')  | Out-Null

<#
.SYNOPSIS
Takes a text string and word-wraps it to a specific length. 

.DESCRIPTION
This function takes a string of text and word-wraps it to a specific target line width. In addition 
to word-wrapping the applies optionally prefix and suffix to each line, and also an optional 
indent based on tab with and indent level.

.NOTES
┌──────────────────────────────────────────────────────────────────────────────────────────────────┐
│ ORIGIN STORY                                                                                     │
├──────────────────────────────────────────────────────────────────────────────────────────────────┤
│   DATE        : 2016-06-23
│   AUTHOR      : Brandon Warner
│   DESCRIPTION : Initial Draft
├──────────────────────────────────────────────────────────────────────────────────────────────────┤
│   DATE        : 2016-06-27
│   AUTHOR      : Brandon Warner
│   DESCRIPTION : Fixed bug with line wrapping for lines less than the wrap-width
                  Also removed line endings from the last line of the returned wrapped text
└──────────────────────────────────────────────────────────────────────────────────────────────────┘

.PARAMETER Text
The source text that we want to word-wrap.

.PARAMETER WrapWidth
The target width of one line in the wrapped text.

.PARAMETER Prefix
A text prefix that should be appended to the beginning of each line in resulting wrapped text
(useful for box drawing)

.PARAMETER Suffix
A text suffix that should be appended to the end of each line in resulting wrapped text
(useful for box drawing)

.PARAMETER TabWidth
Defines the character length of each indent level, if a non-zero indent level is supplied.

.PARAMETER IndentLevel
Indicates the number of levels to indent the resulting wrapped text.

.EXAMPLE

$ThisText  = 'Hello this is a really, really, really, really long sentence that I want to be word-wrapped'
$ThisText += ' so that it displays nicely in a document (either printed or on screen) so that I avoid having to scroll'
$ThisText += ' back and forth, back and forth, wasting both time and effort, that will not have to be spent,'
$ThisText += ' when the text is properly formatted.'

Get-WordWrappedText `
  -Text $ThisText `
  -WrapWidth 50 `
  -Prefix '>' `
  -IndentLevel 2 | oh

#>
function Get-WordWrappedText 
  {
    [CmdletBinding()]
    Param
      (
          [Parameter(Mandatory = $true)]
          [string]$Text  

        , [Parameter(Mandatory = $false)]
          [ValidateRange(25,150)]
          [Int]$WrapWidth = 100

        , [Parameter(Mandatory = $false)]
          [ValidateLength(1,25)]  
          [String]$Prefix = ''
  
        , [Parameter(Mandatory = $false)]
          [ValidateLength(1,25)]
          [String]$Suffix = ''  
  
        , [Parameter(Mandatory = $false)]
          [ValidateRange(1,8)]
          [Int]$TabWidth = 2
  
        , [Parameter(Mandatory = $false)]
          [ValidateRange(0,75)]
          [Int]$IndentLevel = 0    
      )
  
    if(($WrapWidth - "$Prefix$Suffix".Length) -lt 10)
      { 
        Write-Error `
          -Message "The wrap width (minus prefix and suffix length) is too short. There should be at least 10 characters width of text space left over after the prefix and suffix." 
      }
  
    [String]$Result       = ''
    [String]$ThisLine     = ''
    [String]$IndentSpace  = ''.PadLeft($TabWidth*$IndentLevel)
    [Int]$WorkingWidth    = $WrapWidth - $Prefix.Length - $Suffix.Length - 2 #Allow for prefix suffix and two spaces
   
    <#┌────────────────────────────────────────────────────────────────────┐#\
      │ See if the whole thing fits on one line                            │
    \#└────────────────────────────────────────────────────────────────────┘#>
    [Int]$LineWidth     = "$Prefix $Text $Suffix".Length
    
    if($LineWidth -le $WrapWidth)
      {
        return "$IndentSpace$Prefix $Text$("$Suffix".PadLeft($WrapWidth - $Text.Length - $Prefix.Length))"
      }
  
    <#┌────────────────────────────────────────────────────────────────────┐#\
      │ Proceed with word-wrapping the text                                │
    \#└────────────────────────────────────────────────────────────────────┘#>  
    else
      {
        [Bool]$Done         = $false
        [Int]$Position      = 0
        [Int]$PositionPrev  = 0

        while(!$Done)
          {
            $PositionPrev = $Position 
            $Position += $WorkingWidth
   
            if($Position -lt $Text.Length)
              {        
                <#┌───────────────────────────────────────────┐#\
                  │ Inch back till you hit a space            │
                \#└───────────────────────────────────────────┘#>  
                while(!($Text.Substring($Position,1) -match '\s') -and ($Position -gt $PositionPrev))
                  { 
                    $Position-- 
                  }
              }
            else
              {
                <#┌────────────────────────────────────────────────────────────────────┐#\
                  │ If we over-shot, inch back to the end of the text                  │
                \#└────────────────────────────────────────────────────────────────────┘#>
                while($Position -ge $Text.Length)
                  { 
                    $Position-- 
                  }              
                $Done = $true
              }
      
            <#┌──────────────────────────────────────────────────────────────────────────────┐#\
              │ If there entire line width was unbroken by white space, break the word       │
            \#└──────────────────────────────────────────────────────────────────────────────┘#>
            if($Position -eq $PositionPrev)
              {
                $Position += $WorkingWidth 
              }
      
            $LineWidth = $Position - $PositionPrev 

            $Result += "$IndentSpace$Prefix $($Text.Substring($PositionPrev,$LineWidth))$(" $Suffix".PadLeft($WrapWidth-$LineWidth-$Prefix.Length))"
            if(!$Done)
              {
                $Result += "`r`n"
              }
      
            <#┌────────────────────────────────────────────────────────────────────┐#\
              │ Inch past white space to the next word                             │
            \#└────────────────────────────────────────────────────────────────────┘#>      
            while(($Text.Substring($Position,1) -match '\s') -and ($Position -lt $Text.Length))
              { 
                $Position++ 
              }
          }   
      }
    return $Result
  }

<#
.SYNOPSIS
Returns comment block of word-wrapped text inside a character based box drawing.

.DESCRIPTION
Given a string of body text which you want to appear in a comment block surrounded in box
drawing characters, produces said comment block, word-wrapped to a given width and indented
to a given level as per the indent level and tab width.

.NOTES
┌──────────────────────────────────────────────────────────────────────────────────────────────────┐
│ ORIGIN STORY                                                                                     │
├──────────────────────────────────────────────────────────────────────────────────────────────────┤
│   DATE        : 2016-06-23
│   AUTHOR      : Brandon Warner
│   DESCRIPTION : Initial Draft
├──────────────────────────────────────────────────────────────────────────────────────────────────┤
│   DATE        : 2016-06-27
│   AUTHOR      : Brandon Warner
│   DESCRIPTION : Adjusted final return string to account for change in line endings of last line
                  returned in Get-WordWrappedText
└──────────────────────────────────────────────────────────────────────────────────────────────────┘

.PARAMETER CommentText
The text that we want to appear in the comment block.

.PARAMETER SectionWidth
The target width of the comment block

.PARAMETER TabWidth
The number of characters which the comment block will be indented for each indentation level.

.PARAMETER IndentLevel
The number of indentation levels which we want to indent the text by.

.PARAMETER Encoding
'Unicode' for special Unicode box-drawing characters to be used. 'OEM' for approximate ANSI characters to appear instead.

.PARAMETER CommentStyle
Specifies the comment style for the programming language we are providing the comment block for.

.EXAMPLE

Get-BoxedComment `
  -CommentText 'Line breaking, also known as word wrapping, is the process of breaking a section of text into lines such that it will fit in the available width of a page, window or other display area. In text display, line wrap is the feature of continuing on a new line when a line is full, such that each line fits in the viewable window, allowing text to be read from top to bottom without any horizontal scrolling. Word wrap is the additional feature of most text editors, word processors, and web browsers, of breaking lines between words rather than within words, when possible. Word wrap makes it unnecessary to hard-code newline delimiters within paragraphs, and allows the display of text to adapt flexibly and dynamically to displays of varying sizes.' `
  -IndentLevel 2 `
  -CommentStyle PowerShell | Out-File -FilePath "$env:USERPROFILE\CommentBlockSample.ps1" -Force

#>

function Get-BoxedComment
  {
    [OutputType([String])]    
    [CmdletBinding()]
    Param
      (
          [Parameter(Mandatory = $true)]
          [string]$CommentText  

        , [Parameter(Mandatory = $false)]
          [ValidateRange(25,150)]
          [Int]$SectionWidth = 100

        , [Parameter(Mandatory = $false)]
          [ValidateRange(1,8)]
          [Int]$TabWidth = 2
  
        , [Parameter(Mandatory = $false)]
          [ValidateRange(0,50)]
          [Int]$IndentLevel = 0  

        , [Parameter(Mandatory = $false)]
          [ValidateSet('Unicode','OEM')]
          [String]$Encoding = 'Unicode'  

        , [Parameter(Mandatory = $false)]
          [ValidateSet('SQL','PowerShell')]
          [String]$CommentStyle = 'SQL'  
      )

    <#┌────────────────────────────────────────────────────────────────────┐#\
      │ Define the box drawing characters                                  │
    \#└────────────────────────────────────────────────────────────────────┘#>  
    switch($Encoding)
      {
        'Unicode' 
          {
            $BoxHorizontalLineChar     = '─'
            $BoxVerticalLineChar       = '│'
            $BoxUpperLeftCornerChar    = '┌'
            $BoxUpperRightCornerChar   = '┐'
            $BoxLowerLeftCornerChar    = '└'
            $BoxLowerRightCornerChar   = '┘'
          }
        'OEM'
          {
            $BoxHorizontalLineChar     = '-'
            $BoxVerticalLineChar       = '|'
            $BoxUpperLeftCornerChar    = '+'
            $BoxUpperRightCornerChar   = '+'
            $BoxLowerLeftCornerChar    = '+'
            $BoxLowerRightCornerChar   = '+'
          }
      }
  
    <#┌────────────────────────────────────────────────────────────────────┐#\
      │ Define the multi-line commenting delimiters & corresponding        │
      │ symmetry embellishments as per the given comment style             │  
    \#└────────────────────────────────────────────────────────────────────┘#>
    switch($CommentStyle)
      {
        'SQL' 
          {
            $MultilineCommentOpen   = '/*'
            $UpperRightEmbelishment = '*\'
            $LowerLeftEmbelishment  = '\*'
            $MultilineCommentClose  = '*/'
          }
        'PowerShell'
          {
            $MultilineCommentOpen   = '<#'
            $UpperRightEmbelishment = '# '
            $LowerLeftEmbelishment  = ' #'
            $MultilineCommentClose  = '#>' 
          }
      }  

    [String]$BoxHorizontalLine  = $BoxHorizontalLineChar.PadRight($SectionWidth-6).Replace(' ',$BoxHorizontalLineChar)
    [String]$IndentSpace        = ''.PadLeft($TabWidth*$IndentLevel)
    [String]$Body               = Get-WordWrappedText `
                                    -Text $CommentText `
                                    -Prefix "$("$BoxVerticalLineChar".PadLeft($MultilineCommentOpen.Length + 1))" `
                                    -Suffix "$BoxVerticalLineChar" `
                                    -WrapWidth ($SectionWidth - $MultilineCommentOpen.Length -1 ) `
                                    -TabWidth $TabWidth `
                                    -IndentLevel $IndentLevel
  
    return @"
$($IndentSpace)$($MultilineCommentOpen)$($BoxUpperLeftCornerChar)$($BoxHorizontalLine)$($BoxUpperRightCornerChar)$($UpperRightEmbelishment)
$($Body)
$($IndentSpace)$($LowerLeftEmbelishment)$($BoxLowerLeftCornerChar)$($BoxHorizontalLine)$($BoxLowerRightCornerChar)$($MultilineCommentClose)
  
"@
  }

<#
.SYNOPSIS
Example for Automatic Programming of Transact-SQL code using SQL Server Management Objects (SMO)

.DESCRIPTION
This function is simple example of using SMO to iterate through some database objects, tables 
and table rows, in this case, in order to generate a T-SQL script. In this example, I have 
created a script that creates a view for each table that selects the top 100 rows of table. 
Though I doubt this would be very useful, this is simply to exemplify the technique of 
looping through the SMO API to generate code. This can be extremely powerful in generating 
a variety of scripts based on property values available in this API.

.NOTES
┌──────────────────────────────────────────────────────────────────────────────────────────────┐
│ REVISION HISTORY                                                                             │
├──────────────────────────────────────────────────────────────────────────────────────────────┤
│   DATE        : 2016.06.23
│   AUTHOR      : Brandon Warner
│   DESCRIPTION : Initial Draft
└──────────────────────────────────────────────────────────────────────────────────────────────┘

.PARAMETER ServerInstance
Target SQL Server\Instance

.PARAMETER Database
Target Database

.PARAMETER Table
Target Table

.PARAMETER DestinationScriptPath
Destination File Path for the script we want to write

.EXAMPLE 

Write-DataProfileScript `
  -ServerInstance 'MyServer\MyInstance,MyListenerPort' `
  -Database 'MyDatabase' `
  -DestinationScriptPath "$env:USERPROFILE\AutomaticProgrammingTSQL_SMO_Example.sql"

#>
function Write-DataProfileScript
  {
    [CmdletBinding()]
    Param
      (
          [Parameter(Mandatory=$true)]
          [String]$ServerInstance
  
        , [Parameter(Mandatory=$true)]
          [String]$Database


        , [Parameter(Mandatory=$true)]
          [String]$Schema
          
        , [Parameter(Mandatory=$true)]
          [String]$Table
          
        , [Parameter(Mandatory=$false)]
          [String]$DestinationScriptPath  
      )

    <#┌────────────────────────────────────────────────────────────────────┐#˃
      │ Connect to SQL Server via SMO                                      │
    ˂#└────────────────────────────────────────────────────────────────────┘#>
		$SmoServer = New-Object Microsoft.SqlServer.Management.Smo.Server $ServerInstance
		$SmoServer.ConnectionContext.Disconnect() | Out-Null
		$SmoServer.ConnectionContext.ApplicationName = 'PowerShell Script'
		$SmoServer.ConnectionContext.LoginSecure = $true
		$SmoServer.ConnectionContext.Connect()

    [String]$SprocName = "dbo.usp_$($Table)_ProfileData"
    [String]$TSQL     = @"
/*┌─────────────────────────────────────────────────────────────────────────────────────────────┐*\
  │ TITLE: $("Creates a data profiling sproc for $Database.$Schema.$Table".PadRight(85))│
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤
  │ DESCRIPTION:                                                                                │
  │                                                                                             │
  │   Initially Auto-Generated by PowerShell Script:                                            │
$(Get-WordWrappedText `
  -Text ($MyInvocation.ScriptName) `
  -WrapWidth 94 `
  -Prefix '│    ' `
  -Suffix '│' `
  -IndentLevel 1)
  │   Function:                                                                                 │
$(Get-WordWrappedText `
  -Text ($MyInvocation.MyCommand.Name) `
  -WrapWidth 94 `
  -Prefix '│    ' `
  -Suffix '│' `
  -IndentLevel 1)  
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤
  │ REVISION HISTORY:                                                                           │
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤
  │   DATE       AUTHOR          CHANGE DESCRIPTION                                             │
  │   ────────── ─────────────── ───────────────────────────────────────────────────────────────┤
  │   $((Get-Date).ToString('yyyy.MM.dd')) $($env:USERNAME.PadRight(15)) Initial Draft$("".PadLeft(50))│
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤
  │ UNIT TESTING SCRIPTS:                                                                       │
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤
     EXEC $SprocName
  
\*└─────────────────────────────────────────────────────────────────────────────────────────────┘*/

USE $Database
GO

"@
  
    <#┌──────────────────────────────────────────────────────────────────────────────────────────────┐#˃
      │ Loop through all the non-system tables in the given database                                 │
    ˂#└──────────────────────────────────────────────────────────────────────────────────────────────┘#>
    $TargetTable = $SmoServer.Databases[$Database].Tables | where {!$_.IsSystemObject -and $_.Schema -eq $Schema -and $_.Name -eq $Table} 

    $TableName = $TargetTable.Name
    
    $RowCount = $TargetTable.RowCount
  
    $FullyQualifiedTableStr = "[$Database].[$Schema].[$TableName]"

    <#┌──────────────────────────────────────────────────────────────────────────────────────────────┐#˃
      │ Create comment header-block for this script & other setup before looping through columns     │
    ˂#└──────────────────────────────────────────────────────────────────────────────────────────────┘#>
    [String]$SprocName = "dbo.vw_$($TableName)_DataProfile"
    $TSQL += @"

$(Get-BoxedComment `
  -CommentText "Create View: $SprocName" `
  -IndentLevel 1 `
  -SectionWidth 75 `
  -CommentStyle SQL)
IF OBJECT_ID('$SprocName','procedure') IS NOT NULL
 DROP PROCEDURE $SprocName
GO

CREATE PROCEDURE
  $SprocName
AS
 BEGIN

"@
    [Bool]$IsFirst    = $true
    [Int]$PadLength   = 0
  

        
    <#┌──────────────────────────────────────────────────────────────────────────────────────────────┐#˃
      │ Loop through the columns in the table, adding each to the select statement                   │
    ˂#└──────────────────────────────────────────────────────────────────────────────────────────────┘#>  
    [bool]$FirstCol = $true
		$TargetTable.Columns | where {!$_.IsSystemObject} | 
      % {
      
          $_ | oh
          $_ | gm
          
          $_.DataType | oh
          $_.DataType| gm          
          exit
          
          $ThisColDataType = $_.DataType
          $ThisColDataType.IsStringType
          $ThisColDataType.Computed
          $ThisColDataType.Nullable
          
          
          
          $TSQL += @"

                SELECT
                    ColName = '$($_.Name.Replace("'","''"))'
                  , Metric  = 'BlankOrNullCount'
                  , Value   = CAST(SUM
                                (
                                  CASE 
                                    WHEN ISNULL(LTRIM(RTRIM([$($_.Name)])),'') = '' 
                                      THEN 1 
                                    ELSE 0 
                                  END
                                ) AS VARCHAR(MAX))
                FROM
                  $FullyQualifiedTableStr

                UNION ALL          
          
                SELECT
                    ColName = '$($_.Name.Replace("'","''"))'
                  , Metric  = 'MaxVal'
                  , Value   = CAST(MAX([$($_.Name)]) AS VARCHAR(MAX))
                FROM
                  $FullyQualifiedTableStr

                UNION ALL
                
                SELECT
                    ColName = '$($_.Name.Replace("'","''"))'
                  , Metric  = 'MinVal'
                  , Value   = CAST(MIN([$($_.Name)]) AS VARCHAR(MAX))
                FROM
                  $FullyQualifiedTableStr
                  
                UNION ALL          
          
                SELECT
                    ColName = '$($_.Name.Replace("'","''"))'
                  , Metric  = 'DistinctValCnt'
                  , Value   = CAST(COUNT(DISTINCT [$($_.Name)]) AS VARCHAR(MAX))
                FROM
                  $FullyQualifiedTableStr

"@          
          
          if($ThisColDataType.IsStringType)
            {
              if($ThisColDataType.SqlDataType.ToString().StartsWith('N'))
                {
                  $TSQL += @"
          
                UNION ALL          
          
                SELECT
                    ColName = '$($_.Name.Replace("'","''"))'
                  , Metric  = 'UnicodeCnt'
                  , Value   = CAST
                                (
                                  CASE 
                                    WHEN [$($_.Name)] <> CONVERT(VARCHAR(MAX), [$($_.Name)])
                                      THEN 1 
                                    ELSE 0 
                                  END                                
                                  AS VARCHAR(MAX)
                                )
                FROM
                  $FullyQualifiedTableStr                

"@
                }
              else
                {
                  $TSQL += @"
          
                UNION ALL          
          
                SELECT
                    ColName = '$($_.Name.Replace("'","''"))'
                  , Metric  = 'UnicodeCnt'
                  , Value   = '0'
                FROM
                  $FullyQualifiedTableStr
              

"@
                }
                
              $TSQL += @"
          
                UNION ALL
                
                SELECT
                    ColName = '$($_.Name.Replace("'","''"))'
                  , Metric  = 'MaxLen'
                  , Value   = CAST(MAX(LEN([$($_.Name)])) AS VARCHAR(MAX))
                FROM
                  $FullyQualifiedTableStr
               
                UNION ALL
                
                SELECT
                    ColName = '$($_.Name.Replace("'","''"))'
                  , Metric  = 'MinLen'
                  , Value   = CAST(MIN(LEN([$($_.Name)])) AS VARCHAR(MAX))
                FROM
                  $FullyQualifiedTableStr
               
                UNION ALL
                
                SELECT
                    ColName = '$($_.Name.Replace("'","''"))'
                  , Metric  = 'IsNumeric'
                  , Value   = CAST(CASE 
                                WHEN NumericRowCnt = rc.RowCnt - NullRowCnt
                                  THEN '1' 
                                ELSE '0' 
                              END AS VARCHAR(MAX))
                FROM
                  (
                    SELECT 
                        NumericRowCnt = SUM(ISNUMERIC(CAST([$($_.Name)] AS NVARCHAR(MAX))))
                      , NullRowCnt = SUM(CASE WHEN [$($_.Name)] IS NULL THEN 1 ELSE 0 END)
                    FROM
                      $FullyQualifiedTableStr
                  ) x
                  CROSS JOIN
                  RowCnt rc
                  
                UNION ALL

                SELECT
                    ColName = '$($_.Name.Replace("'","''"))'
                  , Metric  = 'NumericRowCnt'
                  , Value   = CAST(SUM(ISNUMERIC(CAST([$($_.Name)] AS NVARCHAR(MAX)))) AS VARCHAR(MAX))
                FROM
                  $FullyQualifiedTableStr

                UNION ALL

                SELECT
                    ColName = '$($_.Name.Replace("'","''"))'
                  , Metric  = 'IsInteger'
                  , Value   = CAST(CASE 
                                WHEN IntegerRowCnt = rc.RowCnt 
                                  THEN '1' 
                                ELSE '0' 
                              END AS VARCHAR(MAX))
                FROM
                  (
                    SELECT 
                     IntegerRowCnt = SUM(ISNUMERIC(CAST([$($_.Name)] AS NVARCHAR(MAX)) + '.0e0'))
                    FROM
                      $FullyQualifiedTableStr
                  ) x
                  CROSS JOIN
                  RowCnt rc
                  
                UNION ALL

                SELECT
                    ColName = '$($_.Name.Replace("'","''"))'
                  , Metric  = 'IntegerRowCnt'
                  , Value   = CAST(SUM(ISNUMERIC(CAST([$($_.Name)] AS NVARCHAR(MAX)) + '.0e0')) AS VARCHAR(MAX))
                FROM
                  $FullyQualifiedTableStr               

"@
            }
          else
            {
              $TSQL += @"
          
                UNION ALL          
          
                SELECT
                    ColName = '$($_.Name.Replace("'","''"))'
                  , Metric  = 'UnicodeCnt'
                  , Value   = '0'


                UNION ALL

                SELECT
                    ColName = '$($_.Name.Replace("'","''"))'
                  , Metric  = 'UnicodePct'
                  , Value   = '0.0'

                UNION ALL
                
                SELECT
                    ColName = '$($_.Name.Replace("'","''"))'
                  , Metric  = 'IsNumeric'
                  , Value   = '0' 
                  
                UNION ALL

                SELECT
                    ColName = '$($_.Name.Replace("'","''"))'
                  , Metric  = 'NumericRowCnt'
                  , Value   = '0'

                UNION ALL

                SELECT
                    ColName = '$($_.Name.Replace("'","''"))'
                  , Metric  = 'IsInteger'
                  , Value   = '0' 
                  
                UNION ALL

                SELECT
                    ColName = '$($_.Name.Replace("'","''"))'
                  , Metric  = 'IntegerRowCnt'
                  , Value   = '0'

"@
            }            
            
          
          $FirstCol = $false
        }

    <#┌────────────────────────────────────────────────────────────────────┐#˃
      │ Finalize the create view statement for this table                  │
    ˂#└────────────────────────────────────────────────────────────────────┘#>
    $TSQL += @"
            ) x
        )

    , ByColPivot AS
        (
          SELECT
              ColName
            , MaxLen
            , MinLen
            , MaxVal
            , MinVal
            , DistinctValCnt
            , [IsNumeric]
            , IsInteger
            , IntegerRowCnt
            , NumericRowCnt
            , BlankOrNullCount
            , BlankOrNullPct
            , UnicodeCnt
            , UnicodePct
          FROM
            ColumnByMetic
          PIVOT 
            (
              MAX([Value])
              FOR Metric IN
                (
                    [MaxLen]
                  , [MinLen]
                  , [MaxVal]
                  , [MinVal]
                  , [DistinctValCnt]
                  , [IsNumeric]
                  , [IsInteger]
                  , [IntegerRowCnt]
                  , [NumericRowCnt]
                  , [BlankOrNullCount]
                  , [BlankOrNullPct]
                  , [UnicodeCnt]
                  , [UnicodePct]
                )
            ) x        
        )
 
    , SmallestSquareLen_OrdPos_Calc AS
        (
          SELECT
              OrdinalPos                    = isc.ORDINAL_POSITION
            , SmallestSquareLen             = CASE 
                                                WHEN MaxLen < 16
                                                  THEN LTRIM(RTRIM(STR(MaxLen)))
                                                WHEN MaxLen < 24
                                                  THEN '32'
                                                WHEN MaxLen < 48
                                                  THEN '64'
                                                WHEN MaxLen < 96
                                                  THEN '128'
                                                WHEN MaxLen < 192
                                                  THEN '256'
                                                WHEN MaxLen < 384
                                                  THEN '512'
                                                WHEN MaxLen < 768
                                                  THEN '1024'
                                                WHEN MaxLen < 1536
                                                  THEN '2048'
                                                WHEN MaxLen < 1536
                                                  THEN '2048'
                                                WHEN MaxLen < 3072
                                                  THEN '4096'
                                                WHEN MaxLen < 6144
                                                  THEN '8192'
                                                ELSE 'MAX'
                                              END
            , [DATA_TYPE]                   = UPPER(isc.[DATA_TYPE])
            , isc.[CHARACTER_MAXIMUM_LENGTH]
            , isc.[IS_NULLABLE]
            , isc.[NUMERIC_PRECISION]
            , isc.[NUMERIC_SCALE]
            , isc.[DATETIME_PRECISION]
            , piv.*            
          FROM
            ByColPivot piv            
            LEFT JOIN [$Database].INFORMATION_SCHEMA.COLUMNS isc            
              ON piv.ColName = isc.COLUMN_NAME
              AND isc.TABLE_SCHEMA  = '$Schema'
              AND isc.TABLE_NAME    = '$Table'     
        )
    , CharTypeDefStr_Calc AS
        (
          SELECT
              calc.*
            , CharTypeDefStr  = CASE 
                                  WHEN CAST(UnicodePct AS FLOAT) = 0.0 
                                    THEN 'VARCHAR(' + SmallestSquareLen + ')'
                                  ELSE
                                    'NVARCHAR(' + SmallestSquareLen + ')'
                                END   
          FROM
            SmallestSquareLen_OrdPos_Calc calc  
        )     

    , Nullability_Calc AS
        (
          SELECT
              calc.*
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
            , Nullability       = CASE 
                                    WHEN CAST(BlankOrNullPct AS FLOAT) = 100.0 
                                      THEN ' NULL'
                                    ELSE ' NOT NULL'
                                  END
          FROM
            CharTypeDefStr_Calc calc
        )             
  SELECT
      OrdinalPos       = CAST(calc.OrdinalPos AS INT)
    , ColName          = CAST(calc.ColName AS SYSNAME)

    , MaxVal           = CAST(calc.MaxVal AS NVARCHAR(MAX))
    , MinVal           = CAST(calc.MinVal AS NVARCHAR(MAX))

    , IsNumeric        = CAST(calc.IsNumeric AS BIT)
    , IsInteger        = CAST(calc.IsInteger AS BIT)
    
    , MaxLen           = CAST(calc.MaxLen AS BIGINT)
    , MinLen           = CAST(calc.MinLen AS BIGINT)
    
    , DistinctValCnt   = CAST(calc.DistinctValCnt AS BIGINT)    
    , IntegerRowCnt    = CAST(calc.IntegerRowCnt AS BIGINT)
    , NumericRowCnt    = CAST(calc.NumericRowCnt AS BIGINT)
    
    , BlankOrNullCount = CAST(calc.BlankOrNullCount AS BIGINT)
    , BlankOrNullPct   = CAST(calc.BlankOrNullPct AS FLOAT)
    , UnicodeCnt       = CAST(calc.UnicodeCnt AS BIGINT)
    , TypeDef          = CAST(', [' + ColName + '] ' + CharTypeDefStr + Nullability AS VARCHAR(256))
    , TypeDefNative    = CAST(', [' + ColName + '] ' + DataTypeStrNative AS VARCHAR(256))
  FROM
    Nullability_Calc calc
   
GO

INSERT
  data_prof.DataProfileRpt_00
    (
        TableName
      , OrdinalPos    
      , ColName        
      , MaxLen          
      , MinLen          
      , MaxVal         
      , MinVal        
      , DistinctValCnt 
      , [IsNumeric]     
      , IsInteger    
      , IntegerRowCnt 
      , NumericRowCnt   
      , BlankOrNullCount
      , BlankOrNullPct   
      , UnicodeCnt    
      , UnicodePct       
      , TypeDef         
      , TypeDefNative        
    )
SELECT 
    TableName = '$Table'
  , OrdinalPos    
  , ColName        
  , MaxLen          
  , MinLen          
  , MaxVal         
  , MinVal        
  , DistinctValCnt 
  , [IsNumeric]     
  , IsInteger    
  , IntegerRowCnt 
  , NumericRowCnt   
  , BlankOrNullCount
  , BlankOrNullPct   
  , UnicodeCnt    
  , UnicodePct       
  , TypeDef         
  , TypeDefNative
FROM 
  $SprocName

"@

    <#┌──────────────────────────────────────────────────────────────────────────────────────────────┐#˃
      │ Display the final script to the host terminal and write out the file if a destination file   │
      │ path was given                                                                               │
    ˂#└──────────────────────────────────────────────────────────────────────────────────────────────┘#> 
    $TSQL | Out-Host

    Invoke-SqlCmd -ServerInstance $ServerInstance -Database $Database -Query $TSQL -QueryTimeout 0 -Verbose | oh
    if($DestinationScriptPath)
      {
        $TSQL | Out-File -FilePath $DestinationScriptPath -Force
      }
  }

@(
#  , @('dbo', 'DnbHotList_Archive')
#  , @('dbo', 'DnbNLNames_Archive')
#  , @('dbo', 'DnbNoNames_Archive')
#  , @('dbo', 'ExperianBCS_Archive')
#  , @('dbo', 'InfoUsaMatched_Archive')
#  , @('dbo', 'InfoUsaRegularBusiness_Archive')
#  , @('dbo', 'InfoUsaTopEighty_Archive')
#  , @('dbo', 'InfoUsaTopThirty_Archive')
  , @('dbo', 'InfoUsaUnmatched_Archive')
#  , @('dbo', 'LicensedDnbBusinesses_Archive')
#  , @('dbo', 'OverallDnbBusinesses_Archive')
) | 
% {
    $ServerInstance = '__SERVER_INSTANCE_NAME__'
    $Database       = 'AdventureWorks_0007'
    $Schema         = $_[0]
    $TableName      = $_[1]
    $DestScript     = "C:\Users\bwarner\Documents\SQL Server Management Studio\$Database.$Schema.vw_$($TableName)_DataProfile.sql"

    Write-DataProfileScript `
      -ServerInstance $ServerInstance `
      -Database $Database `
      -Schema $Schema `
      -Table $TableName `
      -DestinationScriptPath $DestScript
  }





