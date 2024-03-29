[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic') | Out-Null

$BaseDestDir = 'C:\Users\bwarner\Documents\Git\Analytics\Direct Mail\vNext\TSQL'

[RegEx]$ElementNameExtract = '__(\S+)_NAME__'
[RegEx]$ReplacerElementPatt = '__[A-Z]+_NAME__'

$Choices = @()


gci -Path "C:\Users\bwarner\Documents\SQL Server Management Studio\Templates\ItemTemplates\*" -Hidden | 
  % {
      $_.BaseName -match '__DATABASE_NAME__.__SCHEMA_NAME__.(?:__\S+__\.)?__(\S+)_NAME__' | Out-Null
      $Choices += New-Object System.Management.Automation.Host.ChoiceDescription("&$($Matches[1])", $_.FullName)
    }
$Choices = [System.Management.Automation.Host.ChoiceDescription[]]($Choices) # Strongly typed array

$PickIdx = $host.ui.PromptForChoice($Caption,$Message,$Choices,0)
$ChosenTemplatePath = $Choices[$PickIdx].HelpMessage
$ChosenTemplateName = "$($Choices[$PickIdx].Label.Replace('&',''))S"

$DestDir = "$BaseDestDir\$($ChosenTemplateName)"
if(!(Test-Path -Path $DestDir  -PathType Container)){ni -Path $DestDir -ItemType Directory}
$ObjName = ''
[System.String]$ThisTemplateText = gc -Path ($Choices[$PickIdx].HelpMessage) -Raw 
$DatabaseName = ''
$SchemaName = ''
$TableName = ''

$ReplacerElementPatt.Matches($ThisTemplateText) | where {$_.Success} | select -Property Value -Unique |
  % { 
      $ThisElement = $_.Value
      $ThisElementName = $ElementNameExtract.Matches($_.Value).Groups[1].Value
      
      switch($ThisElementName)
        {
          'DATABASE' 
            { $DefaultVal = 'AdventureWorks_0006'}
            
          'SCHEMA' 
            { $DefaultVal = 'imp' }
            
          'SPROC' 
            { $DefaultVal = 'usp_' }
            
          'FUNCTION' 
            { $DefaultVal = 'udf_' }
            
          'VIEW' 
            { $DefaultVal = 'vw_' }
            
          'INDEX' 
            { $DefaultVal = "idx_$($SchemaName)_$($TableName)_" }

          default 
            { $DefaultVal = ''}        
        }

      $RepWithVal = [Microsoft.VisualBasic.Interaction]::InputBox("Enter $ThisElementName Name?", "$ThisElementName", $DefaultVal)
      $ThisTemplateText = $ThisTemplateText.Replace($ThisElement,$RepWithVal)

      switch($ThisElementName)
        {
          'DATABASE' 
            { $DatabaseName = $RepWithVal }
            
          'SCHEMA' 
            { $SchemaName = $RepWithVal }
            
          'TABLE' 
            { $TableName = $RepWithVal }         
        }
              
      switch($ThisElementName)
        {
          'DATABASE' 
            { $ObjName += $RepWithVal }

          default 
            { $ObjName += ".$RepWithVal" }        
        }

    }

$ThisTemplateText = $ThisTemplateText.Replace('YYYY.MM.DD',(Get-Date).ToString('yyyy.MM.dd'))
$ThisTemplateText = $ThisTemplateText.Replace('__AUTHOR_______',"$(($env:USERNAME).PadRight(15))")

$ThisTemplateText | oh
$ThisTemplateText | Out-File -FilePath "$DestDir\$ObjName.sql"

Set-Clipboard -Value $ThisTemplateText




