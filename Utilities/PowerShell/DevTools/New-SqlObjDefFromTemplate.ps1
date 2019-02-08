[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic') | Out-Null

<#
.SYNOPSIS
Starts a brief wizzard to create a database object definition script for 

.DESCRIPTION
Uses a set of specially formatted TSQL templates to generate a database object creation
script with drop/recreated logic for script idempotence and a base template format

.NOTES
┌─────────────────────────────────────────────────────────────────────────────────────────────┐
│ ORIGIN STORY                                                                                │
├─────────────────────────────────────────────────────────────────────────────────────────────┤
│   DATE        : 2018.10.31
│   AUTHOR      : bwarner        
│   DESCRIPTION : Initial Draft
└─────────────────────────────────────────────────────────────────────────────────────────────┘

.PARAMETER SaveToDefaultDir
Sets the default directory to save scripts to

.PARAMETER DefaultDatabase
Optional, specifies the default database that you want to create the database object on

.PARAMETER DefaultSchema
Optional, specifies a default schema that you want to creat objects for. If not provided dbo is used

.PARAMETER TemplateSourceDir
This is the directory that contains the T-SQL templates

.PARAMETER CopyScriptToClipboard
Switch to copy the object creation script to the clipboard

.EXAMPLE

New-SqlObjDefFromTemplate `
  -TargetServerInstance 's26' `
  -DefaultDatabase      'Analytics_WS' `
  -SaveToDefaultDir     '\\corp\nffs\Departments\BusinessIntelligence\SQL Library' 

#>
  
function New-SqlObjDefFromTemplate
  {
    [OutputType([String])]    
    [CmdletBinding()]
    Param
      (
          [Parameter(Mandatory = $false)]
          [string]$SaveToDefaultDir         = "$env:USERPROFILE\Documents\SQL Server Management Studio\"       

        , [Parameter(Mandatory = $false)]
          [string]$DefaultDatabase          = ''

        , [Parameter(Mandatory = $false)]
          [string]$DefaultSchema            = 'dbo'
          
        , [Parameter(Mandatory = $false)]
          [string]$TemplateSourceDir        = "E:\LocalGitRepos\$env:USERNAME\Analytics-Data-Infrastructure\Utilities\TSQL\ObjectCreateTemplates\*.sql"
          
        , [Switch]$CopyScriptToClipboard
      )

    [RegEx]$ElementNameExtract = '__(\S+)_NAME__'
    [RegEx]$ReplacerElementPatt = '__[A-Z]+?_NAME__'

    $Choices = @()

    gci -Path $TemplateSourceDir | 
      % {
          $_.BaseName | oh
          $_.BaseName -match '__DATABASE_NAME__.__SCHEMA_NAME__.(?:__\S+__\.)?__(\S+)_NAME__' | Out-Null
          $Choices += New-Object System.Management.Automation.Host.ChoiceDescription("&$($Matches[1])", $_.FullName)
        }
    if($Choices.Count -lt 1)
      {
        Write-Error -Message "Could not find any T-SQL templates in $TemplateSourceDir" -Category ObjectNotFound
        exit
      }
      
    $Choices = [System.Management.Automation.Host.ChoiceDescription[]]($Choices) # Strongly typed array

    $PickIdx = $host.ui.PromptForChoice($Caption,$Message,$Choices,0)
    $ChosenTemplatePath = $Choices[$PickIdx].HelpMessage
    $ChosenTemplateName = "$($Choices[$PickIdx].Label.Replace('&',''))S"

    $ObjName    = ''

    [System.String]$ThisScriptText = gc -Path ($Choices[$PickIdx].HelpMessage) -Raw 

    $DatabaseName = ''
    $SchemaName   = ''
    $TableName    = ''

    $ReplacerElementPatt.Matches($ThisScriptText) | where {$_.Success} | select -Property Value -Unique |
      % { 
          $ThisElement = $_.Value
          $ThisElementName = $ElementNameExtract.Matches($_.Value).Groups[1].Value
          "`$ThisElementName $ThisElementName" | oh
          switch($ThisElementName)
            {
              'DATABASE' 
                { $DefaultVal = $DefaultDatabase}
                
              'SCHEMA' 
                { $DefaultVal = $DefaultSchema }
                
              'SPROC' 
                { $DefaultVal = 'usp_' }
                
              'FUNCTION' 
                { $DefaultVal = 'udf_' }
                
              'VIEW' 
                { $DefaultVal = 'vw_' }
                
              'INDEX' 
                { $DefaultVal = "IDX_$($SchemaName)_$($TableName)_" }

              'TRIGGER' 
                { $DefaultVal = "tr_$($SchemaName)_$($TableName)_" }

              'FOREIGN_KEY' 
                { $DefaultVal = "FK_$($SchemaName)_$($TableName)_" }
                

              'CHECK_CONSTRAINT' 
                { $DefaultVal = "CHK_$($SchemaName)_$($TableName)_" }                
                
              default 
                { $DefaultVal = ''}        
            }
          
          $RepWithVal = [Microsoft.VisualBasic.Interaction]::InputBox("Enter $ThisElementName Name?", "$ThisElementName", $DefaultVal)
          $ThisScriptText = $ThisScriptText.Replace($ThisElement,$RepWithVal)

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
    
    $ThisScriptText = $ThisScriptText.Replace('YYYY.MM.DD',(Get-Date).ToString('yyyy.MM.dd'))
    $ThisScriptText = $ThisScriptText.Replace('__AUTHOR_______',"$(($env:USERNAME).PadRight(15))")
    if($CopyScriptToClipboard)
      {
        Set-Clipboard -Value $ThisScriptText
      }
    $ThisScriptText | oh
    
    $SaveChooser = New-Object -Typename System.Windows.Forms.SaveFileDialog
    $SaveChooser.DefaultExt       = 'sql'
    $SaveChooser.FileName         = "$ObjName.sql"
    $SaveChooser.CheckFileExists  = $false
    $SaveChooser.CheckPathExists  = $true
    $SaveChooser.InitialDirectory = $SaveToDefaultDir
    $SaveChooser.ShowDialog()
    "Saving file to $($SaveChooser.FileName)" | oh
    $ThisScriptText | Out-File -FilePath $SaveChooser.FileName -Force
    
    #Start-Process -FilePath ($SaveChooser.FileName)

    return $ThisScriptText
  }

### AdventureWorks #####  
New-SqlObjDefFromTemplate `
  -DefaultDatabase      'Analytics_WS' `
  -DefaultSchema        'dbo' `
  -SaveToDefaultDir     'E:\LocalGitRepos\bwarner\Analytics-Data-Infrastructure\Projects\Direct Mail\Salesforce Data Transfer\vNext\TSQL\BI-253\BI-253' 
 