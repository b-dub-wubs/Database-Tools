<#
.SYNOPSIS
One-way push that syncs new and updated files to a remote Git repository

.DESCRIPTION
This script examines a file directory for files and folders with a change date that is 
greater than a given date so that they can be pushed to a remote git repository. In order
to do this a local staging repository must be present that has a remote reference to
the remote repository that you want to sync to. This local staging repository will 
must pull the remotes changes, and is set to automatically use the remote repository's version
so the staging repository SHOULD NOT BE USED as anyone's local workspace, as the changes 
may get overwriten with the current remote version. 

Once the local staging repository has the latest commit from the remote, the changed files
and directorys from the sync source directory will be copied to the local staging repository
in the same relative folder structure as they are in the sync source directory. As they are 
copied, one by one, they will be staged, commited to the staging repository with a commit message
that specifies the current file system "owner" account, and the last modified date as they appear
in the sync source directory, and pushed to the remote repository. 


.NOTES
┌─────────────────────────────────────────────────────────────────────────────────────────────┐
│ ORIGIN STORY                                                                                │
├─────────────────────────────────────────────────────────────────────────────────────────────┤
│   DATE        : 2018.11.01
│   AUTHOR      : bwarner
│   DESCRIPTION : Initial Draft
├─────────────────────────────────────────────────────────────────────────────────────────────┤
│ Sync Run Log Table DDL                                                                      │
├─────────────────────────────────────────────────────────────────────────────────────────────┤

CREATE TABLE
  dbo.GitSyncRunLog
    (
        GitSyncRunLogID   INT        NOT NULL
                          IDENTITY(1,1)
                          CONSTRAINT 
                            PK_dbo_GitSyncRunLog
                          PRIMARY KEY CLUSTERED
      , SyncSetKey        VARCHAR(128)   NOT NULL
      , SyncFrom          DATETIME NOT NULL
      , SyncTo            DATETIME NOT NULL
      , FileCount         INT NULL
      , DidComplete       BIT NOT NULL
                          CONSTRAINT
                            DF_GitSyncRunLog_WasSuccessful
                          DEFAULT (CAST(0 AS BIT))
├─────────────────────────────────────────────────────────────────────────────────────────────┤
│ Sync Run Log Table Initialization Sample                                                    │
├─────────────────────────────────────────────────────────────────────────────────────────────┤

    INSERT
      dbo.GitSyncRunLog
        (
            SyncSetKey
          , SyncFrom
          , SyncTo
          , DidComplete
        )
    VALUES
      (
          '__MY_SYNC_SET_KEY__'  -- put your unique sync set key here
        , '10/15/2018 08:45:00'  -- does not matter for initiation record
        , '10/30/2018 20:07:46'  -- set to the first date that you want to sync changes as-of 
        , 1
      )

└─────────────────────────────────────────────────────────────────────────────────────────────┘

.PARAMETER ChangesAsOf
Optional, if you want to over-ride the Git sync run log lookup that gets the changes
as-of date from the last successful sync run that occured, set this parameter to 
the earliest date that you want to capture changes relativ to

.PARAMETER GitExePath
Optional, if you have git installed in a different location then your local enviornment
program files, under \Git\bin\git.exe, specify the path of the git.exe that you want to 
use

.PARAMETER RunLogServerInstance
Specifys the SQL Server instance that contains your sync run log table

.PARAMETER RunLogDatabase
Specifys the SQL Server database that contains your sync run log table

.PARAMETER RunLogTable
Specifys the your sync run log table name, defaults to 'dbo.GitSyncRunLog'

.PARAMETER SyncSetKey
Easch sync job configuration should have a unique sync set key that identifies the ongoing
syncronization run that occur for a particular job. This is used if multiple sync jobs
want to use the same run log table and we need to differentiat

.PARAMETER SyncSourceDir
This is the file path to the directory that you want to sync changes from 

.PARAMETER LocalSyncRepositoryDir
This is the local working directory of the sync staging repository. This repository should be dedicated
to the git sync process only, and not used by other users or processes

.PARAMETER Excludes
This is a string array of file patters that you want excluded from the changed file set to sync
(see "Get-Help Get-ChildItem -Parameter Exclude" parameter for syntax details) 

.PARAMETER MaxFileSizeMB
Sets a limit on the maximum file size to consider for the sync



.EXAMPLE

Push-FileChangesToGit `
  -RunLogServerInstance 's26' `
  -RunLogDatabase 'Analytics_WS' `
  -SyncSetKey 'DEPTS_BI_SQL_Library_Obay_Analytics' `
  -SyncSourceDir '\\corp\nffs\Departments\BusinessIntelligence\SQL Library\Obay\Analytics' `
  -LocalSyncRepositoryDir '\\corp\nffs\Departments\BusinessIntelligence\SQL Library\GitAutoPushStaging_DO_NOT_USE'

#>

Import-Module -Name SqlServer

function Push-FileChangesToGit
  {
    [OutputType([String])]    
    [CmdletBinding()]
    Param
      (
          [Parameter(Mandatory = $false)]
          [System.DateTime]$ChangesAsOf
           
        , [Parameter(Mandatory = $true)]
          [string]$RunLogServerInstance
       
        , [Parameter(Mandatory = $true)]
          [string]$RunLogDatabase

        , [Parameter(Mandatory = $true)]
          [String]$SyncSetKey
       
        , [Parameter(Mandatory = $false)]
          [string]$RunLogTable            = 'dbo.GitSyncRunLog'          
          
        , [Parameter(Mandatory = $true)]
          [String]$SyncSourceDir
          
        , [Parameter(Mandatory = $true)]
          [String]$LocalSyncRepositoryDir
                 
        , [Parameter(Mandatory = $false)]
          [string[]]$Excludes             = @('*Thumbs.db') #@('*Thumbs.db','*secrets.json','*client_secrets.json')
          
        , [Parameter(Mandatory = $false)]
          [int16]$MaxFileSizeMB           = 100          

        , [Parameter(Mandatory = $false)]
          [string]$GitExePath             = "$env:ProgramFiles\Git\bin\git.exe"
      )
    
    [System.DateTime]$ScriptStart = Get-Date
    
    if(!$ChangesAsOf)
      {
        $GetLastSyncDateSQL = @"
          SELECT 
            LastSyncTo = MAX(SyncTo)
          FROM
            dbo.GitSyncRunLog
          WHERE
                SyncSetKey    = '$SyncSetKey'
            AND DidComplete   = 1
"@         
        $SQL_RetVal = (Invoke-Sqlcmd -ServerInstance $RunLogServerInstance -Database $RunLogDatabase -Query $GetLastSyncDateSQL -Verbose).LastSyncTo
        if($SQL_RetVal.GetType().Name -eq 'DBNull')
          {
            Write-Error -Message "Unable to find the last sync date in [$RunLogServerInstance].[$RunLogDatabase].[$RunLogTable] for sync set key '$SyncSetKey'" -Category InvalidResult
          }
        $ChangesAsOf = [datetime]$SQL_RetVal
        "Last Sync Date Lookup Resolved to: $ChangesAsOf" | oh 
      }

    $InsertRunLogSQL = @"
      INSERT
        $RunLogTable
          (
              SyncSetKey
            , SyncFrom
            , SyncTo
          )
      OUTPUT
        INSERTED.GitSyncRunLogID    
      VALUES
        (
            '$SyncSetKey'
          , '$ChangesAsOf'
          , '$ScriptStart'
        )
"@
    
    $SQL_RetVal = $null
    $SQL_RetVal = (Invoke-Sqlcmd -ServerInstance $RunLogServerInstance -Database $RunLogDatabase -Query $InsertRunLogSQL -Verbose).GitSyncRunLogID
    if($SQL_RetVal.GetType().Name -eq 'DBNull')
      {
        Write-Error -Message "Unable to insert record into [$RunLogServerInstance].[$RunLogDatabase].[$RunLogTable] for sync set key '$SyncSetKey'" -Category InvalidResult
      }
    $ThisGitSyncRunLogID = [int]$SQL_RetVal

    "GitPath: $GitExePath" | Write-Debug
    if(!(Test-Path -Path $GitExePath))
      {
        Write-Error -Message 'Git Executable was not found. Please install Git and specify the GitExePath if installed in a non-standard location.' -Category NotInstalled
        exit
      }    
    New-Alias -Name git -Value $GitExePath

    "Pulling Git remote host origin into sync repository $LocalSyncRepositoryDir" | oh
    git --git-dir=$LocalSyncRepositoryDir/.git --work-tree=$LocalSyncRepositoryDir pull -X theirs origin master  

     "Analyzing file changes Between $ChangesAsOf and $ScriptStart" | Write-Host -ForegroundColor Green -BackgroundColor DarkBlue

    #git --git-dir=$LocalSyncRepositoryDir/.git --work-tree=$LocalSyncRepositoryDir fetch
    #git --git-dir=$LocalSyncRepositoryDir/.git --work-tree=$LocalSyncRepositoryDir status #pull -X theirs origin master
  
    $FilesAndFoldersChanged = gci -Path $SyncSourceDir -Recurse -Exclude $Excludes -Force | 
      where {
                    ($_.LastWriteTime -gt $ChangesAsOf -or $_.CreationTime -gt $ChangesAsOf) `
              -and  ($_.LastWriteTime -lt $ScriptStart) `
              -and  ($_.FullName -notmatch '.+\\\.git\\.+' ) `
              -and  ($_.FullName -notmatch "^$([RegEx]::Escape($SyncSourceDir))\\Archive\\.+" ) `
              -and $_.Length/1MB -le $MaxFileSizeMB
            }

    $FilesOnly = $FilesAndFoldersChanged | where {!$_.PSIsContainer}
    $FileCount =$FilesOnly.Count
    "Number of new/updated files found: $FileCount" | Write-Host -ForegroundColor White -BackgroundColor DarkBlue    
        
    [int]$i = 0

    $FilesAndFoldersChanged |
    % {
        $LocalSyncRepositoryRelativePath = $_.FullName.Replace($SyncSourceDir,$LocalSyncRepositoryDir)
        
        $_ | Copy-Item -Destination $LocalSyncRepositoryRelativePath -Force

        if(!$_.PSIsContainer)
          {
            $i++
            $OwnerStr = ($_.GetAccessControl().GetOwner([System.Security.Principal.SecurityIdentifier])).Translate([System.Security.Principal.NTAccount]).ToString()
            @"
        
  Processing File: $($i.ToString('00000'))/$($FileCount.ToString('00000')) ($OwnerStr)
    $($_.FullName)
  to
    $LocalSyncRepositoryRelativePath
      
"@ | Write-Host -ForegroundColor Green -BackgroundColor DarkBlue          
            $GitCommitMessage = "Push-FileChangesToGit automatic commit - FILE_OWNER: $OwnerStr LAST_WRITE_TIME: $($_.LastWriteTime)" 
            "Git Commit Message: $GitCommitMessage" | oh
            git --git-dir=$LocalSyncRepositoryDir/.git --work-tree=$LocalSyncRepositoryDir commit -a -m $GitCommitMessage
            git --git-dir=$LocalSyncRepositoryDir/.git --work-tree=$LocalSyncRepositoryDir push origin master
          }

        Write-Progress -Activity 'Commiting file changes' -Status $LocalSyncRepositoryRelativePath -PercentComplete ($i*100/$FileCount)
      }
      
    $UpdateRunLogSQL = @"
      UPDATE
        $RunLogTable
      SET
          DidComplete = 1
        , FileCount = $FileCount
      WHERE
        GitSyncRunLogID = $ThisGitSyncRunLogID
"@
    
    Invoke-Sqlcmd -ServerInstance $RunLogServerInstance -Database $RunLogDatabase -Query $UpdateRunLogSQL -Verbose
    "Push to git completed succesfully. $FileCount files were pushed to the remote repository" | oh
  }


Push-FileChangesToGit `
  -RunLogServerInstance 's26' `
  -RunLogDatabase 'Analytics_WS' `
  -SyncSetKey 'DEPTS_BI_SQL_Library_Obay_Analytics' `
  -SyncSourceDir '\\corp\nffs\Departments\BusinessIntelligence\SQL Library\Obay\Analytics' `
  -LocalSyncRepositoryDir '\\corp\nffs\Departments\BusinessIntelligence\SQL Library\GitAutoPushStaging_DO_NOT_USE'
  