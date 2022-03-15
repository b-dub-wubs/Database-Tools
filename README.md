# Database-Tools
Database Development &amp; DBA Tools

// C# code
// Fill SSIS variables with file properties
using System;
using System.Data;
using System.IO;                        // Added to get file properties
using System.Security.Principal;        // Added to get file owner
using System.Security.AccessControl;    // Added to get file owner
using Microsoft.SqlServer.Dts.Runtime;
using System.Windows.Forms;

namespace ST_9ef66c631df646e08e4184e34887da16.csproj
{
    [System.AddIn.AddIn("ScriptMain", Version = "1.0", Publisher = "", Description = "")]
    public partial class ScriptMain : Microsoft.SqlServer.Dts.Tasks.ScriptTask.VSTARTScriptObjectModelBase
    {

        #region VSTA generated code
        enum ScriptResults
        {
            Success = Microsoft.SqlServer.Dts.Runtime.DTSExecResult.Success,
            Failure = Microsoft.SqlServer.Dts.Runtime.DTSExecResult.Failure
        };
        #endregion

        public void Main()
        {
            // Variable for file information
            FileInfo fileInfo;

            // Fill fileInfo variable with file information
            fileInfo = new FileInfo(Dts.Variables["User::FilePath"].Value.ToString());

            // Check if file exists
            Dts.Variables["User::FileExists"].Value = fileInfo.Exists;

            // Get the rest of the file properties if the file exists
            if (fileInfo.Exists)
            {
                // Get file creation date
                Dts.Variables["User::FileCreationDate"].Value = fileInfo.CreationTime;
                
                // Get last modified date
                Dts.Variables["User::FileLastModifiedDate"].Value = fileInfo.LastWriteTime;

                // Get last accessed date
                //Dts.Variables["User::FileLastAccessedDate"].Value = fileInfo.LastAccessTime;

                // Get size of the file in bytes
                Dts.Variables["User::FileSize"].Value = fileInfo.Length;

                // Get file attributes
                Dts.Variables["User::FileAttributes"].Value = fileInfo.Attributes.ToString();
                Dts.Variables["User::FileIsReadOnly"].Value = fileInfo.IsReadOnly;
                
                //////////////////////////////////////////////////////
                // Check if the file isn't locked by an other process
                try
                {
                    // Try to open the file. If it succeeds, set variable to false and close stream
                    FileStream fs = new FileStream(Dts.Variables["User::FilePath"].Value.ToString(), FileMode.Open);
                    Dts.Variables["User::FileInUse"].Value = false;
                    fs.Close();
                }
                catch (Exception ex)
                {
                    // If opening fails, it's probably locked by an other process
                    Dts.Variables["User::FileInUse"].Value = true;

                    // Log actual error to SSIS to be sure 
                    Dts.Events.FireWarning(0, "Get File Properties", ex.Message, string.Empty, 0);
                }

                //////////////////////////////////////////////////////
                // Get the Windows domain user name of the file owner
                FileSecurity fileSecurity = fileInfo.GetAccessControl();
                IdentityReference identityReference = fileSecurity.GetOwner(typeof(NTAccount));
                Dts.Variables["User::FileOwner"].Value = identityReference.Value;
            }

            Dts.TaskResult = (int)ScriptResults.Success;
        }
    }
}

###########################################################################################################################################################################################
###########################################################################################################################################################################################
###########################################################################################################################################################################################
###########################################################################################################################################################################################
###########################################################################################################################################################################################

// C# code
// Fill SSIS variables with file properties
using System;
using System.Data;
using System.IO;                        // Added to get file properties
using System.Security.Principal;        // Added to get file owner
using System.Security.AccessControl;    // Added to get file owner
using Microsoft.SqlServer.Dts.Runtime;
using System.Windows.Forms;

namespace ST_9ef66c631df646e08e4184e34887da16.csproj
{
    [System.AddIn.AddIn("ScriptMain", Version = "1.0", Publisher = "", Description = "")]
    public partial class ScriptMain : Microsoft.SqlServer.Dts.Tasks.ScriptTask.VSTARTScriptObjectModelBase
    {

        #region VSTA generated code
        enum ScriptResults
        {
            Success = Microsoft.SqlServer.Dts.Runtime.DTSExecResult.Success,
            Failure = Microsoft.SqlServer.Dts.Runtime.DTSExecResult.Failure
        };
        #endregion

        public void Main()
        {
            // Variable for file information
            FileInfo fileInfo;

            // Fill fileInfo variable with file information
            fileInfo = new FileInfo(Dts.Variables["User::FilePath"].Value.ToString());

            // Check if file exists
            Dts.Variables["User::FileExists"].Value = fileInfo.Exists;

            // Get the rest of the file properties if the file exists
            if (fileInfo.Exists)
            {
                // Get file creation date
                Dts.Variables["User::FileCreationDate"].Value = fileInfo.CreationTime;
                
                // Get last modified date
                Dts.Variables["User::FileLastModifiedDate"].Value = fileInfo.LastWriteTime;

                // Get last accessed date
                Dts.Variables["User::FileLastAccessedDate"].Value = fileInfo.LastAccessTime;

                // Get size of the file in bytes
                Dts.Variables["User::FileSize"].Value = fileInfo.Length;

                // Get file attributes
                Dts.Variables["User::FileAttributes"].Value = fileInfo.Attributes.ToString();
                Dts.Variables["User::FileIsReadOnly"].Value = fileInfo.IsReadOnly;
                
                //////////////////////////////////////////////////////
                // Check if the file isn't locked by an other process
                try
                {
                    // Try to open the file. If it succeeds, set variable to false and close stream
                    FileStream fs = new FileStream(Dts.Variables["User::FilePath"].Value.ToString(), FileMode.Open);
                    Dts.Variables["User::FileInUse"].Value = false;
                    fs.Close();
                }
                catch (Exception ex)
                {
                    // If opening fails, it's probably locked by an other process
                    Dts.Variables["User::FileInUse"].Value = true;

                    // Log actual error to SSIS to be sure 
                    Dts.Events.FireWarning(0, "Get File Properties", ex.Message, string.Empty, 0);
                }

                //////////////////////////////////////////////////////
                // Get the Windows domain user name of the file owner
                FileSecurity fileSecurity = fileInfo.GetAccessControl();
                IdentityReference identityReference = fileSecurity.GetOwner(typeof(NTAccount));
                Dts.Variables["User::FileOwner"].Value = identityReference.Value;
            }

            Dts.TaskResult = (int)ScriptResults.Success;
        }
    }
}
###########################################################################################################################################################################################
###########################################################################################################################################################################################
###########################################################################################################################################################################################
###########################################################################################################################################################################################
###########################################################################################################################################################################################


# Loads the SQL Server Management Objects (SMO)  

$ErrorActionPreference = "Stop"
  
$sqlpsreg="HKLM:\SOFTWARE\Microsoft\PowerShell\1\ShellIds\Microsoft.SqlServer.Management.PowerShell.sqlps"  
  
if (Get-ChildItem $sqlpsreg -ErrorAction "SilentlyContinue")  
{  
    throw "SQL Server Provider for Windows PowerShell is not installed."  
}  
else  
{  
    $item = Get-ItemProperty $sqlpsreg  
    $sqlpsPath = [System.IO.Path]::GetDirectoryName($item.Path)  
}  
  
$assemblylist =
"Microsoft.SqlServer.Management.Common",  
"Microsoft.SqlServer.Smo",  
"Microsoft.SqlServer.Dmf ",  
"Microsoft.SqlServer.Instapi ",  
"Microsoft.SqlServer.SqlWmiManagement ",  
"Microsoft.SqlServer.ConnectionInfo ",  
"Microsoft.SqlServer.SmoExtended ",  
"Microsoft.SqlServer.SqlTDiagM ",  
"Microsoft.SqlServer.SString ",  
"Microsoft.SqlServer.Management.RegisteredServers ",  
"Microsoft.SqlServer.Management.Sdk.Sfc ",  
"Microsoft.SqlServer.SqlEnum ",  
"Microsoft.SqlServer.RegSvrEnum ",  
"Microsoft.SqlServer.WmiEnum ",  
"Microsoft.SqlServer.ServiceBrokerEnum ",  
"Microsoft.SqlServer.ConnectionInfoExtended ",  
"Microsoft.SqlServer.Management.Collector ",  
"Microsoft.SqlServer.Management.CollectorEnum",  
"Microsoft.SqlServer.Management.Dac",  
"Microsoft.SqlServer.Management.DacEnum",  
"Microsoft.SqlServer.Management.Utility"  
  
foreach ($asm in $assemblylist)  
{  
    $asm = [Reflection.Assembly]::LoadWithPartialName($asm)  
}  
 
 
 <# 
Push-Location  
cd $sqlpsPath  
update-FormatData -prependpath SQLProvider.Format.ps1xml
Pop-Location  
#>


$SmoServer = New-Object Microsoft.SqlServer.Smo.Server 'BIPRODSQL'


$SmoServer.Databases | 
  % {
        $_.Name | oh

    }



###########################################################################################################################################################################################
###########################################################################################################################################################################################
###########################################################################################################################################################################################
###########################################################################################################################################################################################
###########################################################################################################################################################################################


[String]$SrcCodePath = "C:\Users\e51375n\Desktop\SourceSampleCodeTemplate.000.cs"

[String]$DestCodePath = "C:\Users\e51375n\Desktop\CodeGenBin001\GetFileAttributes-INST-$((Get-Date).ToString('yyyy.MM.ddThh.mm.ss')).cs"


$replaceSet = @(  
  , @('User::FilePath', 'User::thisCSV_File_FullPath')
  , @('User::FileExists', 'User::thisCSV_File_Exists')
  , @('User::FileCreationDate', 'User::thisCSV_File_CreatedDt')
  , @('User::FileLastModifiedDate', 'User::thisCSV_File_ModifiedDt')
  , @('User::FileLastAccessedDate', 'User::thisCSV_File_AccessedDt')
  , @('User::FileSize', 'User::thisCSV_File_Size')
  , @('User::FileAttributes', 'User::thisCSV_File_Attributes')
  , @('User::FileIsReadOnly', 'User::thisCSV_File_IsReadOnly')
  , @('User::FileInUse', 'User::thisCSV_File_IsInUse')
  , @('User::FileOwner', 'User::thisCSV_File_Owner')
  )

  $thisScript = Get-Content -LiteralPath $SrcCodePath -Raw 


$replaceSet | 
  % {
      "Replacing string $($_[0].ToString()) with $($_[1].ToString())" | Write-Host -ForegroundColor Green -BackgroundColor DarkGray
      $thisScript = $thisScript.Replace(($_[0].ToString()),($_[1].ToString()))
    }

$thisScript | Out-File -LiteralPath "C:\Users\e51375n\Desktop\CodeGenBin001\GetFileAttributes-INST-$((Get-Date).ToString('yyyy.MM.ddThh.mm.ss')).cs" -Encoding unicode -Force
$thisScript | oh
$thisScript | Set-Clipboard


###########################################################################################################################################################################################
###########################################################################################################################################################################################
###########################################################################################################################################################################################
###########################################################################################################################################################################################
###########################################################################################################################################################################################



[String]$SSIS_Expression = ''
[String]$Category
[String]$Identifer
[String]$TypeCast
[String]$thisExpressionLine = ''
[RegEx]$VariableMatchPatt = '@\[(?<category>[A-z]+)::(?<identifer>[A-Z]*+)\]'
$VariableList = @(
   '@[System::ErrorCode]'
 , '@[System::ErrorDescription]'
 , '@[System::FailedConfigurations]'
 , '@[System::IgnoreConfigurationsOnLoad]'
 , '@[System::PackageID]'
 , '@[System::PackageName]'
 , '@[System::SourceName]'
 , '@[System::SourceDescription]'
 , '@[System::TaskID]'
 , '@[User::SQLcmd_Product]'
 , '@[System::TaskName]'
 , '@[User::OutputFilePath]'
 , '@[User::StartDate]'
 , '@[User::SQLcmd_RevisionDates]'
 , '@[User::SQLcmd_Product]'
)


$VariableList | 
  % {
        # Re-initialize text parsing string fragments
        $Category = $null
        $Identifer = $null
        $TypeCast = ''
        
        if($VariableMatchPatt.IsMatch($_))
            {
                $Category = $Matches['category']
                $Identifer = $Matches['identifer']

                if(!$Identifer)
                  {
                    Write-Error "Could not parse the 'identifier' named group in given variable list member: `n`t$_`nwhen matched to the RegEx:`n`t$($VariableMatchPatt.ToString())"
                  }
                $TypeCast = '(DT_STR,255)'

                <#
                switch($Identifer)
                    {
                        'ErrorCode'  
                            { $TypeCast = '(DT_STR,250)'; }
                        'PackageID'  
                            { $TypeCast = '(DT_STR,250)'; }
                        'TaskID'     
                            { $TypeCast = '(DT_STR,250)'; }
                        'StartDate'  
                            { $TypeCast = '(DT_STR,50)'; }

                        
                        ''
                            { $TypeCast = '(DT_STR,50)'; }
                        ''
                            { $TypeCast = '(DT_STR,50)'; }
                        '' 
                            { $TypeCast = '(DT_STR,50)'; }
                        '' 
                            { $TypeCast = '(DT_STR,50)'; }
                        '' 
                            { $TypeCast = '(DT_STR,50)'; }
                        
                        default 
                            { $TypeCast = '(DT_STR,255)'; }
                    }
                    #>

                    $thisExpressionLine = "`"$($_): `" + REPLACENULL($($TypeCast)$_,'') + `"\n`"`n"
                    $SSIS_Expression += $thisExpressionLine
                    
                    Write-Host "INFO: Added line: `n`t$thisExpressionLine`nto the SSIS expression string." -ForegroundColor White -BackgroundColor DarkGray

                }
        else
          {
            Write-Error "Could not match given variable list member: `n`t$_`nto the RegEx:`n`t$($VariableMatchPatt.ToString())"
          }
    }

Write-Host "Final SSIS Exression: " -ForegroundColor Green -BackgroundColor Black

$SSIS_Expression | % { Write-Host "`t$_" -ForegroundColor Blue -BackgroundColor Black }


$SSIS_Expression | Set-Clipboard


###########################################################################################################################################################################################
###########################################################################################################################################################################################
###########################################################################################################################################################################################
###########################################################################################################################################################################################
###########################################################################################################################################################################################





