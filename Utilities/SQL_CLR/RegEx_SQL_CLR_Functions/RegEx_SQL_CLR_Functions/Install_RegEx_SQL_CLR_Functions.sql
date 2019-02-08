/*┌─────────────────────────────────────────────────────────────────────────────────────────────┐*\
  │ TITLE: Install RegEx SQL CLR Functions                                                      │
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤
  │ DESCRIPTION:                                                                                │
     Installs a set of CLR functions on DirectMail
     (can change to different DB, but must includ all DB's these are installed on 
     in the Step 2 in order to re-install the assembly)

     Run Step 4 for each database that you want to install the RegEx functions on
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤
  │ REVISION HISTORY:                                                                           │
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤
  │   DATE       AUTHOR          CHANGE DESCRIPTION                                             │
  │   ────────── ─────────────── ────────────────────────────────────────────────────────────── │
      2018.11.14 bwarner         Initial Draft
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤
  │ Notes for SQL Server 2017                                                                   │

    see https://docs.microsoft.com/en-us/sql/t-sql/statements/create-assembly-transact-sql?view=sql-server-2017
    note warning about CLR strict security in warning


  http://msdn.microsoft.com/en-us/library/ms131103.aspx

    the .NET assembly code and this script were adapted from:
    https://github.com/DevNambi/sql-server-regex

\*└─────────────────────────────────────────────────────────────────────────────────────────────┘*/


/*┌─────────────────────────────────────────────────────────────────────────────────────────────┐*\
  │ Step 1: Configure the server to enable CLR                                                  │

USE master
GO

EXEC sys.sp_configure 
    'clr enabled'
  , 1
RECONFIGURE WITH OVERRIDE
\*└─────────────────────────────────────────────────────────────────────────────────────────────┘*/

/*┌─────────────────────────────────────────────────────────────────────────────────────────────┐*\
  │ Step 2: Drop existing functions, and assembly, if they already exist                        │
\*└─────────────────────────────────────────────────────────────────────────────────────────────┘*/
USE DirectMail -- Specify target DB here
GO

ALTER DATABASE DirectMail SET TRUSTWORTHY ON
GO

IF OBJECT_ID('dbo.RegExEscape') IS NOT NULL
  BEGIN
    EXEC ('DROP FUNCTION dbo.RegExEscape');
  END
GO

IF OBJECT_ID('dbo.RegExUnescape') IS NOT NULL
  BEGIN
    EXEC ('DROP FUNCTION dbo.RegExUnescape');
  END
GO

IF OBJECT_ID('dbo.RegExIndex') IS NOT NULL
  BEGIN
    EXEC ('DROP FUNCTION dbo.RegExIndex');
  END
GO

IF OBJECT_ID('dbo.RegExIsMatch') IS NOT NULL
  BEGIN
    EXEC ('DROP FUNCTION dbo.RegExIsMatch');
  END
GO

IF OBJECT_ID('dbo.RegExMatch') IS NOT NULL
  BEGIN
    EXEC ('DROP FUNCTION dbo.RegExMatch');
  END
GO

IF OBJECT_ID('dbo.RegExGroupMatch') IS NOT NULL
  BEGIN
    EXEC ('DROP FUNCTION dbo.RegExGroupMatch');
  END
GO

IF OBJECT_ID('dbo.RegExReplace') IS NOT NULL
  BEGIN
    EXEC ('DROP FUNCTION dbo.RegExReplace');
  END
GO

IF OBJECT_ID('dbo.RegExMatches') IS NOT NULL
  BEGIN
    EXEC ('DROP FUNCTION dbo.RegExMatches');
  END
GO

IF OBJECT_ID('dbo.RegExSplit') IS NOT NULL
  BEGIN
    EXEC ('DROP FUNCTION dbo.RegExSplit');
  END
GO

IF OBJECT_ID('dbo.CompileRegEx') IS NOT NULL
  BEGIN
    EXEC ('DROP FUNCTION dbo.CompileRegEx');
  END
GO

IF OBJECT_ID('dbo.JaroWinklerProximity') IS NOT NULL
  BEGIN
    EXEC ('DROP FUNCTION dbo.JaroWinklerProximity');
  END
GO

IF OBJECT_ID('dbo.RegExIsMatchC') IS NOT NULL
  BEGIN
    EXEC ('DROP FUNCTION dbo.RegExIsMatchC');
  END
GO

IF OBJECT_ID('dbo.RegExMatchC') IS NOT NULL
  BEGIN
    EXEC ('DROP FUNCTION dbo.RegExMatchC');
  END
GO

IF OBJECT_ID('dbo.RegExGroupMatchC') IS NOT NULL
  BEGIN
    EXEC ('DROP FUNCTION dbo.RegExGroupMatchC');
  END
GO

IF OBJECT_ID('dbo.RegExReplaceC') IS NOT NULL
  BEGIN
    EXEC ('DROP FUNCTION dbo.RegExReplaceC');
  END
GO

IF OBJECT_ID('dbo.RegExMatchesC') IS NOT NULL
  BEGIN
    EXEC ('DROP FUNCTION dbo.RegExMatchesC');
  END
GO

IF OBJECT_ID('dbo.RegExSplitC') IS NOT NULL
  BEGIN
    EXEC ('DROP FUNCTION dbo.RegExSplitC');
  END
GO

IF OBJECT_ID('dbo.RegExOptionEnumeration') IS NOT NULL
  BEGIN
    EXEC ('DROP FUNCTION dbo.RegExOptionEnumeration');
  END
GO

IF OBJECT_ID('dbo.RegExIndexC') IS NOT NULL
  BEGIN
    EXEC ('DROP FUNCTION dbo.RegExIndexC');
  END
GO

/*┌─────────────────────────────────────────────────────────────────────────────────────────────┐*\
  │ Step 3: Create the assembly from the compiled DDL                                           │
\*└─────────────────────────────────────────────────────────────────────────────────────────────┘*/
IF EXISTS (
            SELECT 
              1
            FROM 
              sys.assembly_files f
              FULL OUTER JOIN
              sys.assemblies a
                ON f.assembly_id = a.assembly_id
              FULL OUTER JOIN
              sys.assembly_modules m
                ON a.assembly_id = m.assembly_id
            WHERE
              a.[name] = 'CLR_StringFunctions'
          )
  DROP ASSEMBLY
    CLR_StringFunctions
GO

DECLARE 
  @AssemblyLocation VARCHAR(8000)= 'C:\CLR_Assembly\CLR_StringFunctions.dll' 

CREATE ASSEMBLY 
  CLR_StringFunctions 
FROM 
  @AssemblyLocation 
WITH 
  PERMISSION_SET = UNSAFE
GO

/*┌─────────────────────────────────────────────────────────────────────────────────────────────┐*\
  │ Step 4: Create the UDFs that reference the CLR assembly                                     │
\*└─────────────────────────────────────────────────────────────────────────────────────────────┘*/

/*┌────────────────────────────────────────────────────────────────────┐*.
    RegEx Utility Functions
\*└────────────────────────────────────────────────────────────────────┘*/

IF OBJECT_ID('dbo.RegExOptionEnumeration') IS NOT NULL
  BEGIN
    EXEC ('DROP FUNCTION dbo.RegExOptionEnumeration');
  END
GO
CREATE FUNCTION 
  dbo.RegExOptionEnumeration
	  (
	      @IgnoreCase               BIT
      , @MultiLine                BIT
      , @ExplicitCapture          BIT
      , @SingleLine               BIT
      , @IgnorePatternWhitespace  BIT
      , @RightToLeft              BIT
      , @ECMAScript               BIT
      , @CultureInvariant         BIT
    )
RETURNS INT
AS EXTERNAL NAME 
   CLR_StringFunctions.UDF.RegExOptionEnumeration
GO

IF OBJECT_ID('dbo.RegExEscape') IS NOT NULL
  BEGIN
    EXEC ('DROP FUNCTION dbo.RegExEscape');
  END
GO
CREATE FUNCTION 
  dbo.RegExEscape
	  (
	      @input NVARCHAR(MAX)
    )
RETURNS NVARCHAR(MAX)
AS EXTERNAL NAME 
   CLR_StringFunctions.UDF.RegExEscape
GO

IF OBJECT_ID('dbo.RegExUnescape') IS NOT NULL
  BEGIN
    EXEC ('DROP FUNCTION dbo.RegExUnescape');
  END
GO
CREATE FUNCTION 
  dbo.RegExUnescape
	  (
	      @input NVARCHAR(MAX)
    )
RETURNS NVARCHAR(MAX)
AS EXTERNAL NAME 
   CLR_StringFunctions.UDF.RegExUnescape
GO

/*┌────────────────────────────────────────────────────────────────────┐*.
    Standard RegEx Functions (interperted)
\*└────────────────────────────────────────────────────────────────────┘*/

IF OBJECT_ID('dbo.RegExIsMatch') IS NOT NULL
  BEGIN
    EXEC ('DROP FUNCTION dbo.RegExIsMatch');
  END
GO

CREATE FUNCTION dbo.RegExIsMatch
  (
      @input    NVARCHAR(MAX)
    , @pattern  NVARCHAR(MAX)
    , @options  INT           = NULL
    --, @timeout  SMALLINT      = 0
  )
RETURNS BIT
AS
EXTERNAL NAME
  CLR_StringFunctions.UDF.IsMatch
GO

IF OBJECT_ID('dbo.RegExMatch') IS NOT NULL
  BEGIN
    EXEC ('DROP FUNCTION dbo.RegExMatch');
  END
GO

CREATE FUNCTION dbo.RegExMatch
  (
      @input    NVARCHAR(MAX)
    , @pattern  NVARCHAR(MAX)
    , @options  INT           = NULL
    --, @timeout  SMALLINT      = 0
  )
RETURNS NVARCHAR(MAX)
AS
EXTERNAL NAME
  CLR_StringFunctions.UDF.Match
GO


IF OBJECT_ID('dbo.RegExGroupMatch') IS NOT NULL
  BEGIN
    EXEC ('DROP FUNCTION dbo.RegExGroupMatch');
  END
GO

CREATE FUNCTION dbo.RegExGroupMatch
  (
      @input    NVARCHAR(MAX)
    , @pattern  NVARCHAR(MAX)
    , @group    NVARCHAR(MAX)
    , @options  INT           = NULL
    --, @timeout  SMALLINT      = 0
  )
RETURNS NVARCHAR(MAX)
AS
EXTERNAL NAME
  CLR_StringFunctions.UDF.GroupMatch
GO

IF OBJECT_ID('dbo.RegExReplace') IS NOT NULL
  BEGIN
    EXEC ('DROP FUNCTION dbo.RegExReplace');
  END
GO

CREATE FUNCTION dbo.RegExReplace
  (
      @input        NVARCHAR(MAX)
    , @pattern      NVARCHAR(MAX)
    , @replacement  NVARCHAR(MAX)
    , @options  INT           = NULL
    --, @timeout  SMALLINT      = 0
  )
RETURNS NVARCHAR(MAX)
AS
EXTERNAL NAME
  CLR_StringFunctions.UDF.Replace
GO

IF OBJECT_ID('dbo.RegExMatches') IS NOT NULL
  BEGIN
    EXEC ('DROP FUNCTION dbo.RegExMatches');
  END
GO

CREATE FUNCTION dbo.RegExMatches
  (
      @input    NVARCHAR(MAX)
    , @pattern  NVARCHAR(MAX)
    , @options  INT           = NULL
    --, @timeout  SMALLINT      = 0
  )
RETURNS TABLE
  (
      Position  INT
    , [Match]   NVARCHAR(MAX)
  )
EXTERNAL NAME
  CLR_StringFunctions.UDF.Matches
GO

IF OBJECT_ID('dbo.RegExSplit') IS NOT NULL
  BEGIN
    EXEC ('DROP FUNCTION dbo.RegExSplit');
  END
GO

CREATE FUNCTION dbo.RegExSplit
  (
      @input    NVARCHAR(MAX)
    , @pattern  NVARCHAR(MAX)
    , @options  INT           = NULL
    --, @timeout  SMALLINT      = 0
  )
RETURNS TABLE
  (
      Position  INT
    , [Match]   NVARCHAR(MAX)
  )
EXTERNAL NAME
  CLR_StringFunctions.UDF.Split
GO

IF OBJECT_ID('dbo.RegExIndex') IS NOT NULL
  BEGIN
    EXEC ('DROP FUNCTION dbo.RegExIndex');
  END
GO
CREATE FUNCTION 
  dbo.RegExIndex
	  (
	      @input    NVARCHAR(MAX)
      , @pattern  NVARCHAR(MAX)
      , @options  INT           = NULL
    )
RETURNS SMALLINT
AS EXTERNAL NAME 
   CLR_StringFunctions.UDF.RegExIndex
GO

/*┌────────────────────────────────────────────────────────────────────┐*.
    Compiled RegEx Related Functions 
\*└────────────────────────────────────────────────────────────────────┘*/

IF OBJECT_ID('dbo.CompileRegEx') IS NOT NULL
  BEGIN
    EXEC ('DROP FUNCTION dbo.CompileRegEx');
  END
GO

CREATE FUNCTION dbo.CompileRegEx
  (
      @pattern  NVARCHAR(MAX)
    , @options  INT           = NULL
    --, @timeout  SMALLINT      = 0
  )
RETURNS VARBINARY(MAX)
EXTERNAL NAME
  CLR_StringFunctions.UDF.CompileRegEx
GO

IF OBJECT_ID('dbo.RegExIsMatchC') IS NOT NULL
  BEGIN
    EXEC ('DROP FUNCTION dbo.RegExIsMatchC');
  END
GO

CREATE FUNCTION dbo.RegExIsMatchC
  (
      @input          NVARCHAR(MAX)
    , @compiled_regrx VARBINARY(MAX)
  )
RETURNS BIT
AS
EXTERNAL NAME
  CLR_StringFunctions.UDF.IsMatchC
GO

IF OBJECT_ID('dbo.RegExMatchC') IS NOT NULL
  BEGIN
    EXEC ('DROP FUNCTION dbo.RegExMatchC');
  END
GO

CREATE FUNCTION dbo.RegExMatchC
  (
      @input    NVARCHAR(MAX)
    , @compiled_regrx VARBINARY(MAX)
  )
RETURNS NVARCHAR(MAX)
AS
EXTERNAL NAME
  CLR_StringFunctions.UDF.MatchC
GO

IF OBJECT_ID('dbo.RegExGroupMatchC') IS NOT NULL
  BEGIN
    EXEC ('DROP FUNCTION dbo.RegExGroupMatchC');
  END
GO

CREATE FUNCTION dbo.RegExGroupMatchC
  (
      @input    NVARCHAR(MAX)
    , @compiled_regrx VARBINARY(MAX)
    , @group    NVARCHAR(MAX)
  )
RETURNS NVARCHAR(MAX)
AS
EXTERNAL NAME
  CLR_StringFunctions.UDF.GroupMatchC
GO

IF OBJECT_ID('dbo.RegExReplaceC') IS NOT NULL
  BEGIN
    EXEC ('DROP FUNCTION dbo.RegExReplaceC');
  END
GO

CREATE FUNCTION dbo.RegExReplaceC
  (
      @input        NVARCHAR(MAX)
    , @compiled_regrx VARBINARY(MAX)
    , @replacement  NVARCHAR(MAX)
  )
RETURNS NVARCHAR(MAX)
AS
EXTERNAL NAME
  CLR_StringFunctions.UDF.ReplaceC
GO

IF OBJECT_ID('dbo.RegExMatchesC') IS NOT NULL
  BEGIN
    EXEC ('DROP FUNCTION dbo.RegExMatchesC');
  END
GO

CREATE FUNCTION dbo.RegExMatchesC
  (
      @input    NVARCHAR(MAX)
    , @compiled_regrx VARBINARY(MAX)
  )
RETURNS TABLE
  (
      Position  INT
    , [Match]   NVARCHAR(MAX)
  )
EXTERNAL NAME
  CLR_StringFunctions.UDF.MatchesC
GO

IF OBJECT_ID('dbo.RegExSplitC') IS NOT NULL
  BEGIN
    EXEC ('DROP FUNCTION dbo.RegExSplitC');
  END
GO

CREATE FUNCTION dbo.RegExSplitC
  (
      @input    NVARCHAR(MAX)
    , @compiled_regrx VARBINARY(MAX)
  )
RETURNS TABLE
  (
      Position  INT
    , [Match]   NVARCHAR(MAX)
  )
EXTERNAL NAME
  CLR_StringFunctions.UDF.SplitC
GO

IF OBJECT_ID('dbo.RegExIndexC') IS NOT NULL
  BEGIN
    EXEC ('DROP FUNCTION dbo.RegExIndexC');
  END
GO
CREATE FUNCTION 
  dbo.RegExIndexC
	  (
	      @input          NVARCHAR(MAX)
      , @compiled_regrx VARBINARY(MAX)
    )
RETURNS SMALLINT
AS EXTERNAL NAME 
   CLR_StringFunctions.UDF.RegExIndexC
GO

/*┌────────────────────────────────────────────────────────────────────┐*.
    Matching / String Comparison Functions
\*└────────────────────────────────────────────────────────────────────┘*/

IF OBJECT_ID('dbo.JaroWinklerProximity') IS NOT NULL
  BEGIN
    EXEC ('DROP FUNCTION dbo.JaroWinklerProximity');
  END
GO

CREATE FUNCTION dbo.JaroWinklerProximity
  (
      @string1  NVARCHAR(MAX)
    , @string2  NVARCHAR(MAX)
  )
RETURNS FLOAT
AS
EXTERNAL NAME
  CLR_StringFunctions.UDF.JarrowWinklerProximity
GO




































