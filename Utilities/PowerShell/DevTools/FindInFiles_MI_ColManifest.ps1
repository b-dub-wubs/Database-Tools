

$dt = New-Object System.Data.Datatable
[void]$dt.Columns.Add("MI_Reference")
[void]$dt.Columns.Add("File")
[void]$dt.Columns.Add("MatchCount")
 $dt.Columns["MatchCount"].DataType = [int]
 

 
$dt_nomatch = New-Object System.Data.Datatable
[void]$dt_nomatch.Columns.Add("MI_Reference")

  
$SearchDir = 'E:\SearchBucket'
#$SearchDir = 'E:\LocalGitRepos\bwarner\Analytics-Data-Infrastructure\Projects\Direct Mail\DnB_MI_ExtractDefs'
 
 
# Add a row manually

 
# Or add an array
$me = "computername","userdomain","username"
$array = (Get-Childitem env: | Where-Object { $me -contains $_.Name }).Value
[void]$dt.Rows.Add($array)

@(

  , 'Control'
  , 'fiUSMode'
  , 'fiUSPros'
  , 'si215Sc'
  , 'siCH16f4'
  , 'siCH16JQ'
  , 'siCH16MZ'
  , 'siCH16QR'
  , 'siCH16UA'
  , 'siCH17OD'
  , 'siClas27'
  , 'siClas39'
  , 'siClas46'
  , 'siClas47'
  , 'siClas65'
  , 'siClas79'
  , 'siCoun80'
  , 'siCountU'
  , 'siEmpSeg'
  , 'silUSARe'
  , 'siLastof'
  , 'siLastUC'
  , 'siRece10'
  , 'siRecenc'
  , 'siVX6SYM'
  , 'siVX6T3W'
  , 'siVX6T9T'
  , 'siVX6TTD'
  , 'siVX6U38'
  , 'siVX6U80'
  , 'siVX6UHG'
  , 'siVX6UNG'
  ) | % { 
  
  $MatchFound = $false
  $thisMI_Reference = $_
  
  gci -Path $SearchDir -Recurse -Include *.xml | 
    % {
        "Searching for $thisMI_Reference in $($_.FullName)" | oh
        
        $thisFileName = $_.Name
        $thisFilePath = $_.FullName
        $thisFileConent = $null
        $thisFileConent = Get-Content -LiteralPath $thisFilePath -Raw -Force
        if(!$thisFileConent)
          { 
            "Could not read conents of $thisFilePath" | Write-Warning
          }
        else
          {
            [int]$thisMatchCount = [regex]::matches($thisFileConent,$thisMI_Reference).count
            if($thisMatchCount -gt 0)
              {
                $MatchFound = $true
                [void]$dt.Rows.Add($thisMI_Reference,$thisFileName,$thisMatchCount)
              }
          }

        
        
        }
        
        if(!$MatchFound){[void]$dt_nomatch.Rows.Add($thisMI_Reference)}
        
      }
      

  
  

$dt | ogv -Wait -Title 'Match Report'

$dt_nomatch | ogv -Wait -Title 'Match Report'