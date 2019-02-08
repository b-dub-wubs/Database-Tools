-- =============================================
-- Create the DBAmp stored procedures
-- Note: DO NOT USE FOR SQL 2000. DBAmp is not supported for SQL 2000.
-- 
-- 1. Make sure before executing that you are adding this stored procedure to your salesforce backups database
-- 2. If DBAmp is not installed at c:\Program Files\DBAmp, search and replace @ProgDir with the proper DBAmp directory.
-- 3. Execute this script to add the stored proceduers to the salesforce backups database
-- =============================================

IF not exists (Select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA = 'dbo' and TABLE_NAME = 'TablesToSkip')
	Begin
		Create Table TablesToSkip
		(TableName nvarchar(255) Not Null,
		SkipReason nvarchar(255)
		)
	End
	
--Function for adding version to starting syntax for stored procedures		
IF EXISTS (SELECT name
	   FROM   sysobjects
	   WHERE  name = N'SF_Version'
	   AND 	  type = N'FN')
    DROP FUNCTION dbo.SF_Version
GO
CREATE FUNCTION  dbo.SF_Version ()
RETURNS nvarchar(20)
As
Begin
	declare @current_version nvarchar(20)
	set @current_version = 'V3.7.2'
	RETURN @current_version
END
GO

IF EXISTS (SELECT name
	   FROM   sysobjects
	   WHERE  name = N'SF_IsBigObject'
	   AND 	  type = 'P')
    DROP PROCEDURE SF_IsBigObject
GO

Create PROCEDURE [dbo].[SF_IsBigObject] 
@table_name NVARCHAR(MAX), 
@IsBigObject Int OUTPUT

AS

set @IsBigObject = 0

declare @big_object_index int
declare @custom_object_index int

set @big_object_index = CHARINDEX(REVERSE('__b'),REVERSE(@table_name))
set @custom_object_index = CHARINDEX(REVERSE('__c'),REVERSE(@table_name))

if @big_object_index <> 0
Begin
	if((@big_object_index < @custom_object_index and @custom_object_index <> '0') or (@big_object_index > @custom_object_index and @custom_object_index = '0')) 
	Begin
		set @IsBigObject = 1
	end
END 
Go

IF EXISTS (SELECT name
	   FROM   sysobjects
	   WHERE  name = N'SF_Split'
	   AND 	  type = N'TF')
    DROP FUNCTION SF_Split
GO
CREATE FUNCTION [dbo].[SF_Split]
(
      @FullText varchar(Max),
      @Delimiter varchar(5) = ',',
      @RemoveQuote bit = 0
)
RETURNS @RtnValue table
(
      Id int identity(1,1),
      Data nvarchar(max)
)
AS
BEGIN
      DECLARE @Cnt INT
      Declare @Data nvarchar(max)
      SET @Cnt = 1
 
      WHILE (CHARINDEX(@Delimiter,@FullText)>0)
      BEGIN
            set @Data = LTRIM(RTRIM(SUBSTRING(@FullText,1,CHARINDEX(@Delimiter,@FullText)-1)))
            If Left(@Data,1) ='"' AND @RemoveQuote = 1
set @Data = SUBSTRING(@Data,2,LEN(@Data)-2)
            INSERT INTO @RtnValue (Data) Values(@Data)

 
            SET @FullText = SUBSTRING(@FullText,CHARINDEX(@Delimiter,@FullText)+1,LEN(@FullText))
            SET @Cnt = @Cnt + 1
      END
 
      set @Data = LTRIM(RTRIM(@FullText))
      
      If Len(@Data) > 0
      begin
 If Left(@Data,1) ='"' AND @RemoveQuote = 1
set @Data = SUBSTRING(@Data,2,LEN(@Data)-2)
 INSERT INTO @RtnValue (Data) Values(@Data)
      end

      RETURN
END

GO
--Procedure checking if the Salesforce object is valid
IF EXISTS (SELECT name
	   FROM   sysobjects
	   WHERE  name = N'SF_IsValidSFObject'
	   AND 	  type = 'P')
    DROP PROCEDURE SF_IsValidSFObject
GO

CREATE PROCEDURE SF_IsValidSFObject
	@table_server sysname,
	@table_name sysname

AS
-- Parameters: @table_name             - Salesforce object to validate (i.e. Account)

-- Return Code: 0 if not valid
--				1 if valid

Begin
	declare @sql nvarchar(max)
	declare @objectname nvarchar(100)
	declare @parmlist nvarchar(4000)
	select @sql = 'Select @NAMEOUT = Name from '
	select @sql = @sql + @table_server + '...sys_sfobjects' + ' where' + ' Name = ' + '''' + @table_name + ''''
	select @parmlist = '@NAMEOUT nvarchar(100) OUTPUT'
	exec sp_executesql @sql,@parmlist, @NAMEOUT=@objectname OUTPUT
	If @objectname is Null
		RETURN 0
	else
		RETURN 1
END
Go

IF EXISTS (SELECT name
	   FROM   sysobjects
	   WHERE  name = N'SF_IsValidSFField'
	   AND 	  type = 'P')
    DROP PROCEDURE SF_IsValidSFField
GO

Create PROCEDURE [dbo].[SF_IsValidSFField]
	@table_server sysname,
	@table_name sysname,
	@field_name nvarchar(250)
AS
-- Parameters: @table_server		   - Linked Server
--			   @table_name             - Salesforce object (i.e. Account)
--			   @field_name			   - Salesforce field to validate (i.e. Id)
	   	
-- Return Code: 0 if not valid
--				1 if valid

Begin
	declare @sql nvarchar(max)
	declare @fieldname nvarchar(100)
	declare @parmlist nvarchar(4000)
	select @sql = 'Select @NAMEOUT = DeveloperName from '
	select @sql = @sql + @table_server + '...fielddefinition' + ' where' + ' EntityDefinitionId = ' + '''' + @table_name + '''' + ' And DeveloperName = ' + '''' + @field_name + ''''
	select @parmlist = '@NAMEOUT nvarchar(250) OUTPUT'
	exec sp_executesql @sql,@parmlist, @NAMEOUT=@fieldname OUTPUT
	If @fieldname is Null
		RETURN 0
	else
		RETURN 1
END
Go

IF EXISTS (SELECT name
	   FROM   sysobjects
	   WHERE  name = N'SF_Logger'
	   AND 	  type = 'P')
    DROP PROCEDURE SF_Logger
GO
CREATE PROCEDURE [dbo].[SF_Logger]
	@SPName sysname,
	@Status nvarchar(20),
	@Message nvarchar(max)
AS
--If you want to enable logging, see the DBAmp Doc for the DBAmp Performance Package
return 0
go

IF EXISTS (SELECT name
	   FROM   sysobjects
	   WHERE  name = N'SF_CopyNoDrop'
	   AND 	  type = 'P')
    DROP PROCEDURE SF_CopyNoDrop
GO
Create PROCEDURE [dbo].[SF_CopyNoDrop]
	@prev_table sysname,
	@table_name sysname
AS

declare @sql nvarchar(max)
declare @DropColumnName nvarchar(100)
declare @AddColumnName nvarchar(100)
declare @DataType nvarchar(100)
declare @DataTypeLength bigint
declare @NumericScale int
declare @ColumnList nvarchar(max)
declare @delim_table_name sysname
declare @diff_schema_count int
declare @NullVar nvarchar(50)

set @delim_table_name = '[' + @table_name + ']'


-- Delete current rows in local table
-- If not using transactional replication then you could 
--    switch to the truncate
--set @sql = 'truncate table ' + @delim_table_name
set @sql = 'delete ' + @delim_table_name
exec sp_executesql @sql


--Drop all columns, except Id, from local table
DECLARE DropColumnsLocalTable CURSOR Local Fast_Forward FOR
	Select c1.COLUMN_NAME, c1.DATA_TYPE, c1.IS_NULLABLE, c1.CHARACTER_MAXIMUM_LENGTH, c1.NUMERIC_SCALE
	FROM INFORMATION_SCHEMA.COLUMNS c1, INFORMATION_SCHEMA.TABLES t1
	WHERE c1.TABLE_NAME=@table_name and t1.TABLE_NAME = c1.TABLE_NAME and t1.TABLE_TYPE = 'BASE TABLE'
	EXCEPT
	Select c1.COLUMN_NAME, c1.DATA_TYPE, c1.IS_NULLABLE, c1.CHARACTER_MAXIMUM_LENGTH, c1.NUMERIC_SCALE
	FROM INFORMATION_SCHEMA.COLUMNS c1, INFORMATION_SCHEMA.TABLES t1
	WHERE c1.TABLE_NAME=@prev_table and t1.TABLE_NAME = c1.TABLE_NAME and t1.TABLE_TYPE = 'BASE TABLE'
OPEN DropColumnsLocalTable

While 1=1
Begin
	FETCH NEXT FROM DropColumnsLocalTable into @DropColumnName, @DataType, @NullVar, @DataTypeLength, @NumericScale
	if @@error <> 0 or @@fetch_status <> 0 break
	Begin
		set @sql = 'Alter Table ' + @delim_table_name + ' Drop Column ' + @DropColumnName
		--print 'Dropping ' + @DropColumnName
		exec sp_executesql @sql
	End
end
close DropColumnsLocalTable
deallocate DropColumnsLocalTable

--Add all columns, except Id, from previous table to local table
DECLARE AddColumnsLocalTable CURSOR Local Fast_Forward FOR
	Select c1.COLUMN_NAME, c1.DATA_TYPE, c1.IS_NULLABLE, c1.CHARACTER_MAXIMUM_LENGTH, c1.NUMERIC_SCALE
	FROM INFORMATION_SCHEMA.COLUMNS c1, INFORMATION_SCHEMA.TABLES t1
	WHERE c1.TABLE_NAME=@prev_table and t1.TABLE_NAME = c1.TABLE_NAME and t1.TABLE_TYPE = 'BASE TABLE'
	EXCEPT
	Select c1.COLUMN_NAME, c1.DATA_TYPE, c1.IS_NULLABLE, c1.CHARACTER_MAXIMUM_LENGTH, c1.NUMERIC_SCALE
	FROM INFORMATION_SCHEMA.COLUMNS c1, INFORMATION_SCHEMA.TABLES t1
	WHERE c1.TABLE_NAME=@table_name and t1.TABLE_NAME = c1.TABLE_NAME and t1.TABLE_TYPE = 'BASE TABLE'
OPEN AddColumnsLocalTable

While 1=1
Begin
	FETCH NEXT FROM AddColumnsLocalTable into @AddColumnName, @DataType, @NullVar, @DataTypeLength, @NumericScale
	if @@error <> 0 or @@fetch_status <> 0 break
	If @NullVar = 'Yes'
		Set @NullVar = 'NULL'
	Else
		Set @NullVar = 'NOT NULL'
	
	If @DataTypeLength is not null and @DataType = 'ntext'
	Begin
		set @sql = 'Alter Table ' + @delim_table_name + ' Add ' + @AddColumnName + ' ntext ' + @NullVar
	End
	Else If @DataTypeLength is not null and @DataTypeLength = -1
	Begin
		set @sql = 'Alter Table ' + @delim_table_name + ' Add ' + @AddColumnName + ' nvarchar(max) ' + @NullVar
	End
	Else If @DataTypeLength is not null
	Begin
		set @sql = 'Alter Table ' + @delim_table_name + ' Add ' + @AddColumnName + ' ' + @DataType + '(' + Cast(@DataTypeLength as nvarchar(100)) + ') ' + @NullVar
	End
	Else If @NumericScale is not null
	Begin
		set @sql = 'Alter Table ' + @delim_table_name + ' Add ' + @AddColumnName + ' ' + @DataType + '(18, ' + Cast(@NumericScale as nvarchar(100)) + ') ' + @NullVar
	End
	Else if @DataTypeLength is null
	Begin
		set @sql = 'Alter Table ' + @delim_table_name + ' Add ' + @AddColumnName + ' ' + @DataType + ' ' + @NullVar
	End
	--print @sql
	exec sp_executesql @sql
end
close AddColumnsLocalTable
deallocate AddColumnsLocalTable

set @ColumnList = 'Id'

--Build column list for insert statement and select statement
DECLARE ColumnsList CURSOR Local Fast_Forward FOR
		Select c.COLUMN_NAME
		from INFORMATION_SCHEMA.COLUMNS c, INFORMATION_SCHEMA.TABLES t
		Where c.TABLE_NAME = t.TABLE_NAME and t.TABLE_TYPE = 'BASE TABLE' and t.TABLE_SCHEMA = c.TABLE_SCHEMA and c.TABLE_NAME = @prev_table and c.COLUMN_NAME <> 'Id'
	OPEN ColumnsList

	While 1=1
	Begin
		FETCH NEXT FROM ColumnsList into @AddColumnName
		if @@error <> 0 or @@fetch_status <> 0 break

		set @ColumnList = @ColumnList + ', ' + @AddColumnName  
		
	end
	close ColumnsList
	deallocate ColumnsList

--Build insert into, select statement and execute it
set @sql = 'Insert Into ' + @delim_table_name + '(' + @ColumnList + ')' 
			+ ' select ' + @ColumnList + ' from ' + @prev_table
exec sp_executesql @sql
Go

-- =============================================
-- Create procedure SF_Replicate
-- Similiar to the old SF_Replicate but maintains a primary ID key on the table
-- To Use:
-- 1. Make sure before executing that you are adding this stored procedure to your salesforce backups database
-- 2. If needed, modify the @ProgDir on line 28 for the directory containing the DBAmp.exe program
-- 3. Execute this script to add the SF_Replicate proc to the salesforce backups database
-- =============================================
IF EXISTS (SELECT name
	   FROM   sysobjects
	   WHERE  name = N'SF_Replicate'
	   AND 	  type = 'P')
    DROP PROCEDURE SF_Replicate
GO
Create PROCEDURE [dbo].[SF_Replicate]
	@table_server sysname,
	@table_name sysname,
	@options	nvarchar(255) = NULL
AS
-- Parameters: @table_server           - Salesforce Linked Server name (i.e. SALESFORCE)
--             @table_name             - Salesforce object to copy (i.e. Account)

-- @ProgDir - Directory containing the DBAmp.exe. Defaults to the DBAmp program directory
-- If needed, modify this for your installation
declare @ProgDir   	varchar(250) 
set @ProgDir = 'C:\"Program Files"\DBAmp\'

declare @Result 	int
declare @Command 	nvarchar(4000)
declare @time_now	char(8)
set NOCOUNT ON

print '--- Starting SF_Replicate for ' + @table_name + ' ' +  dbo.SF_Version()
declare @LogMessage nvarchar(max)
declare @SPName nvarchar(50)
set @SPName = 'SF_Replicate:' + Convert(nvarchar(255), NEWID(), 20)
set @LogMessage = 'Parameters: ' + @table_server + ' ' + @table_name + ' ' + ISNULL(@options, ' ') + ' Version: ' +  dbo.SF_Version()
Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
print @time_now + ': ' + @LogMessage
exec SF_Logger @SPName, N'Starting',@LogMessage

declare @delim_table_name sysname
declare @prev_table sysname
declare @delim_prev_table sysname
declare @server sysname
declare @database sysname
declare @UsingFiles int
set @UsingFiles = 0
declare @EndingMessageThere int
set @EndingMessageThere = 0

-- Put delimeters around names so we can name tables User, etc...
set @delim_table_name = '[' + @table_name + ']'
set @prev_table = @table_name + '_Previous' + CONVERT(nvarchar(30), GETDATE(), 126) 
set @prev_table = REPLACE(@prev_table, '-', '')
set @prev_table = REPLACE(@prev_table, ':', '')
set @prev_table = REPLACE(@prev_table, '.', '')
set @delim_prev_table = '[' + @prev_table + ']'

-- Determine whether the local table and the previous copy exist
declare @table_exist int
declare @prev_exist int

set @table_exist = 0
set @prev_exist = 0;
IF EXISTS (SELECT 1
    FROM INFORMATION_SCHEMA.TABLES
    WHERE TABLE_TYPE='BASE TABLE' 
    AND TABLE_NAME=@table_name)
        set @table_exist = 1
IF (@@ERROR <> 0) GOTO ERR_HANDLER

IF EXISTS (SELECT 1
    FROM INFORMATION_SCHEMA.TABLES
    WHERE TABLE_TYPE='BASE TABLE' 
    AND TABLE_NAME=@prev_table)
        set @prev_exist = 1
IF (@@ERROR <> 0) GOTO ERR_HANDLER

if @table_exist = 1
begin
	-- Make sure that the table doesn't have any keys defined
	IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    		   WHERE CONSTRAINT_TYPE = 'FOREIGN KEY' AND TABLE_NAME=@table_name )
        begin
 	   Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
	   print @time_now + ': Error: The table contains foreign keys and cannot be replicated.' 
	   set @LogMessage = 'Error: The table contains foreign keys and cannot be replicated.'
	   exec SF_Logger @SPName, N'Message', @LogMessage
	   GOTO ERR_HANDLER
	end
end

-- If the previous table exists, drop it
Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
print @time_now + ': Drop ' + @prev_table + ' if it exists.'
set @LogMessage = 'Drop ' + @prev_table + ' if it exists.'
exec SF_Logger @SPName, N'Message', @LogMessage
if (@prev_exist = 1)
        exec ('Drop table ' + @delim_prev_table)
IF (@@ERROR <> 0) GOTO ERR_HANDLER

-- Create an empty local table with the current structure of the Salesforce object
Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
print @time_now + ': Create ' + @prev_table + ' with new structure.'
set @LogMessage = 'Create ' + @prev_table + ' with new structure.'
exec SF_Logger @SPName, N'Message', @LogMessage

begin try
exec ('Select Top 0 * into ' + @delim_prev_table + ' from ' + @table_server + '...' + @delim_table_name )
end try
begin catch
	Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
	print @time_now + ': Error: Salesforce table does not exist: ' + @table_name
	set @LogMessage = 'Error: Salesforce table does not exist: ' + @table_name
	exec SF_Logger @SPName, N'Message', @LogMessage
	print @time_now +
		': Error: ' + ERROR_MESSAGE();
	set @LogMessage = 'Error: ' + ERROR_MESSAGE()
	exec SF_Logger @SPName, N'Message', @LogMessage
	GOTO ERR_HANDLER
end catch

-- Retrieve current server name and database
select @server = @@servername, @database = DB_NAME()
SET @server = CAST(SERVERPROPERTY('ServerName') AS sysname) 

If exists(select Data
	from SF_Split(SUBSTRING(@options, 1, 1000), ',', 1) 
	where Data like '%oldway%')
	Begin
		-- Execute DBAmp.exe to load table from Salesforce
		Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
		print @time_now + ': Run the DBAmp.exe program.' 
		set @LogMessage = 'Run the DBAmp.exe program.'
		exec SF_Logger @SPName, N'Message', @LogMessage
		set @options = Replace(@options, 'oldway', '')
		set @Command = @ProgDir + 'DBAmp.exe Export' 
		if (@options is not null)
		begin
			set @Command = @Command + ':' + Replace(@options, ' ', '')
		end
	End
Else
Begin
If exists(select Data
	from SF_Split(SUBSTRING(@options, 1, 1000), ',', 1) 
	where Data like '%bulkapi%' or Data like '%pkchunk%')
	Begin
		set @UsingFiles = 1
		set @Command = @ProgDir + 'DBAmpNet2.exe Export' 
	End
else
Begin
    set @UsingFiles = 1
	set @Command = @ProgDir + 'DBAmpNet2.exe Exportsoap'
End
if (@options is not null)
begin
	set @Command = @Command + ' "' + 'Replicate:' + Replace(@options, ' ', '') + '" '
end
Else 
Begin
	set @Command = @Command + ' "' + 'Replicate' + '" '
End
End

set @Command = @Command + ' "' + @prev_table + '" '
set @Command = @Command + ' "' + @server + '" '
set @Command = @Command + ' "' + @database + '" '
set @Command = @Command + ' "' + @table_server + '" '

-- Create temp table to hold output
declare @errorlog table (line varchar(255))

begin try
insert into @errorlog
	exec @Result = master..xp_cmdshell @Command
end try
begin catch
   print 'Error occurred running the Replicate program'	
	Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
	print @time_now + ': Error occurred running the Replicate program'
	set @LogMessage = 'Error occurred running the Replicate program'
	exec SF_Logger @SPName, N'Message', @LogMessage
	print @time_now +
		': Error: ' + ERROR_MESSAGE();
	set @LogMessage = 'Error: ' + ERROR_MESSAGE()
	exec SF_Logger @SPName, N'Message', @LogMessage
		
     -- Roll back any active or uncommittable transactions before
     -- inserting information in the ErrorLog.
     IF XACT_STATE() <> 0
     BEGIN
         ROLLBACK TRANSACTION;
     END
    
  set @Result = -1
end catch

if @@ERROR <> 0
   set @Result = -1

-- print output to msgs
declare @line varchar(255)
declare @printCount int
Set @printCount = 0

DECLARE tables_cursor CURSOR FOR SELECT line FROM @errorlog
OPEN tables_cursor
FETCH NEXT FROM tables_cursor INTO @line
WHILE (@@FETCH_STATUS <> -1)
BEGIN
   if @line is not null 
	begin
	print @line
	if CHARINDEX('Operation successful.',@line) > 0
	begin
		set @EndingMessageThere = 1
	end
	exec SF_Logger @SPName,N'Message', @line
	Set @printCount = @printCount + 1
	end
   FETCH NEXT FROM tables_cursor INTO @line
END
deallocate tables_cursor

if @Result = -1 or @printCount = 0 or @printCount = 1 or (@EndingMessageThere = 0 and @UsingFiles = 1)
BEGIN
  	Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
	print @time_now + ': Error: Replicate program was unsuccessful.'
	set @LogMessage = 'Error: Replicate program was unsuccessful.'
	exec SF_Logger @SPName, N'Message', @LogMessage
	print @time_now + ': Error: Command string is ' + @Command
	set @LogMessage = 'Error: Command string is ' + @Command
	exec SF_Logger @SPName, N'Message', @LogMessage
	
	--Clean up any previous table
	IF EXISTS (SELECT 1
		FROM INFORMATION_SCHEMA.TABLES
		WHERE TABLE_TYPE='BASE TABLE'
		AND TABLE_NAME=@prev_table)
	begin
	   exec ('Drop table ' + @prev_table)
	end
	
  	GOTO RESTORE_ERR_HANDLER
END

declare @primarykey_exists as int
set @primarykey_exists = 0

if @table_exist = 1
begin
	-- Check to see if the table had a primary key defined
	IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    		   WHERE CONSTRAINT_TYPE = 'PRIMARY KEY' AND TABLE_NAME=@table_name )
    begin
		Set @primarykey_exists = 1
	end
end

-- Change for V2.14.2:  Always create primary key
Set @primarykey_exists = 1

if Lower(@table_name) = 'oauthtoken' set @primarykey_exists = 0
if Lower(@table_name) = 'apexpageinfo' set @primarykey_exists = 0
if Lower(@table_name) = 'recentlyviewed' set @primarykey_exists = 0
if Lower(@table_name) = 'datatype' set @primarykey_exists = 0
if Lower(@table_name) = 'loginevent' set @primarykey_exists = 0
if Lower(@table_name) = 'casearticle' set @primarykey_exists = 0
if Lower(@table_name) = 'publisher' set @primarykey_exists = 0
if Lower(@table_name) = 'auradefinitioninfo' set @primarykey_exists = 0
if Lower(@table_name) = 'auradefinitionbundleinfo' set @primarykey_exists = 0 
set @options = Lower(@options)

BEGIN TRY
    BEGIN TRANSACTION;
	If ISNULL(@options, ' ') like '%nodrop%'
	Begin
		if (@table_exist = 0)
		Begin
			Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
			print @time_now + ': Rename previous table from ' + @prev_table + ' to ' + @table_name
			set @LogMessage = 'Rename previous table from ' + @prev_table + ' to ' + @table_name
			exec SF_Logger @SPName, N'Message', @LogMessage
			exec sp_rename @prev_table, @table_name
		End
		else
		Begin
			exec SF_CopyNoDrop @prev_table, @table_name
		End
	End
	Else
	Begin
		-- If the local table exists, drop it
		Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
		print @time_now + ': Drop ' + @table_name + ' if it exists.'
		set @LogMessage = 'Drop ' + @table_name + ' if it exists.'
		exec SF_Logger @SPName, N'Message', @LogMessage
		if (@table_exist = 1)
			exec ('Drop table ' + @delim_table_name)

		-- Backup previous table into current
		Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
		print @time_now + ': Rename previous table from ' + @prev_table + ' to ' + @table_name
		set @LogMessage = 'Rename previous table from ' + @prev_table + ' to ' + @table_name
		exec SF_Logger @SPName, N'Message', @LogMessage
		exec sp_rename @prev_table, @table_name
	End
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
	If ISNULL(@options, ' ') like '%nodrop%'
	Begin
		Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
		print @time_now + ': Error occurred copying records to the table.'
		set @LogMessage = 'Error occurred copying records to the table.'
		exec SF_Logger @SPName, N'Message', @LogMessage
		print @time_now +
			': Error: ' + ERROR_MESSAGE();
		set @LogMessage = 'Error: ' + ERROR_MESSAGE()
		exec SF_Logger @SPName, N'Message', @LogMessage
	End
	Else
	Begin
		Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
		print @time_now + ': Error occurred dropping and renaming the table.'
		set @LogMessage = 'Error occurred dropping and renaming the table.'
		exec SF_Logger @SPName, N'Message', @LogMessage
		print @time_now +
			': Error: ' + ERROR_MESSAGE();
		set @LogMessage = 'Error: ' + ERROR_MESSAGE()
		exec SF_Logger @SPName, N'Message', @LogMessage
	End

     -- Roll back any active or uncommittable transactions before
     -- inserting information in the ErrorLog.
     IF XACT_STATE() <> 0
     BEGIN
         ROLLBACK TRANSACTION;
     END
     goto ERR_HANDLER
END CATCH

--Clean up any previous table
IF EXISTS (SELECT 1
    FROM INFORMATION_SCHEMA.TABLES
    WHERE TABLE_TYPE='BASE TABLE'
    AND TABLE_NAME=@prev_table)
begin
   exec ('Drop table ' + @prev_table)
end

-- Recreate Primary Key is needed
If ISNULL(@options, ' ') not like '%nodrop%' OR @table_exist = 0
BEGIN
	BEGIN TRY
		Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
		print @time_now + ': Create primary key on ' + @table_name
		set @LogMessage = 'Create primary key on ' + @table_name
		exec SF_Logger @SPName, N'Message', @LogMessage
		if (@primarykey_exists = 1)
		   -- Add Id as Primary Key
		   exec ('Alter table ' + @delim_table_name + ' Add Constraint PK_' + @table_name + '_Id Primary Key NONCLUSTERED (Id) ')
	END TRY
	BEGIN CATCH
		Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
		print @time_now + ': Error occurred creating primary key for table.'
		set @LogMessage = 'Error occurred creating primary key for table.'
		exec SF_Logger @SPName, N'Message', @LogMessage
		print @time_now +
			': Warning: ' + ERROR_MESSAGE();
		set @LogMessage = 'Warning: ' + ERROR_MESSAGE()
		exec SF_Logger @SPName, N'Message', @LogMessage
		
		 -- Roll back any active or uncommittable transactions before
		 -- inserting information in the ErrorLog.
		 IF XACT_STATE() <> 0
		 BEGIN
			 ROLLBACK TRANSACTION;
		 END
		 --goto ERR_HANDLER
	END CATCH
END

print '--- Ending SF_Replicate. Operation successful.'
set @LogMessage = 'Ending - Operation Successful.' 
exec SF_Logger @SPName,N'Successful', @LogMessage
set NOCOUNT OFF
return 0

RESTORE_ERR_HANDLER:
print('--- Ending SF_Replicate. Operation FAILED.')
set @LogMessage = 'Ending - Operation Failed.' 
exec SF_Logger @SPName, N'Failed',@LogMessage
RAISERROR ('--- Ending SF_Replicate. Operation FAILED.',16,1)
set NOCOUNT OFF
return 1

ERR_HANDLER:
print('--- Ending SF_Replicate. Operation FAILED.')
set @LogMessage = 'Ending - Operation Failed.' 
exec SF_Logger @SPName,N'Failed', @LogMessage
RAISERROR ('--- Ending SF_Replicate. Operation FAILED.',16,1)
set NOCOUNT OFF
return 1
go

IF EXISTS (SELECT name
	   FROM   sysobjects
	   WHERE  name = N'SF_BulkOps'
	   AND 	  type = 'P')
    DROP PROCEDURE SF_BulkOps
GO


Create PROCEDURE [dbo].[SF_BulkOps]
	@operation nvarchar(200),
	@table_server sysname,
	@table_name sysname,
	@opt_param1	nvarchar(512) = ' ',
	@opt_param2 nvarchar(512) = ' '
AS
-- Parameters: @operation		- Operation to perform (Update, Insert, Delete)
--             @table_server           	- Salesforce Linked Server name (i.e. SALESFORCE)
--             @table_name             	- SQL Table containing ID's to delete

-- @ProgDir - Directory containing the DBAmp.exe. Defaults to the DBAmp program directory
-- If needed, modify this for your installation
declare @ProgDir   	varchar(250) 
set @ProgDir = 'C:\"Program Files"\DBAmp\'

declare @Result 	int
declare @Command 	nvarchar(4000)
declare @time_now	char(8)
declare @errorLines varchar(max)
set @errorLines = 'SF_BulkOps Error: '
set NOCOUNT ON

print '--- Starting SF_BulkOps for ' + @table_name + ' ' +  dbo.SF_Version()
declare @LogMessage nvarchar(max)
declare @SPName nvarchar(50)
set @SPName = 'SF_BulkOps:' + Convert(nvarchar(255), NEWID(), 20)
set @LogMessage = 'Parameters: ' + @operation + ' ' +@table_server + ' ' + @table_name + ' ' + ISNULL(@opt_param1, ' ') + ' ' + ISNULL(@opt_param2, ' ') + ' Version: ' +  dbo.SF_Version()
exec SF_Logger @SPName, N'Starting',@LogMessage

declare @server sysname
declare @database sysname
declare @phrase nvarchar(100)
declare @Start int
declare @UsingBulkAPI2 int = 0
declare @UsingOldWay int = 0
declare @UsingNewSOAP int = 1
declare @End int
declare @delim_table_name sysname
set @delim_table_name = '[' + @table_name + ']'

declare @isBigObject int
set @isBigObject = 0
exec SF_IsBigObject @table_name, @isBigObject Output

if (@isBigObject = 1)
Begin
	Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
	print @time_now + ': Error: Big Objects are not supported with SF_BulkOps. ' 
    set @LogMessage = 'Error: Big Objects are not supported with SF_BulkOps.'
    exec SF_Logger @SPName, N'Message', @LogMessage
    GOTO ERR_HANDLER
End

set @operation = lower(@operation)
set @operation = Replace(@operation, ' ', '')

-- Determine whether the local table and the previous copy exist
declare @table_exist int
set @table_exist = 0

IF EXISTS (SELECT 1
    FROM INFORMATION_SCHEMA.TABLES
    WHERE TABLE_TYPE='BASE TABLE' 
    AND TABLE_NAME=@table_name)
        set @table_exist = 1
IF (@@ERROR <> 0) GOTO ERR_HANDLER
	
If @operation like '%ignorefailures(%'
Begin
	set @Start = PATINDEX('%ignorefailures(%', @operation)
	set @End = CHARINDEX(')', @operation, @Start) + 1
	set @phrase = SUBSTRING(@operation, @Start, @End - @Start)
	set @operation = REPLACE(@operation, @phrase, '')
End

if CHARINDEX('upsert',@operation) <> 0 and @opt_param1 = ' '
BEGIN
  	Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
	print @time_now + ': Error: External Id Field Name was not provided.'
	set @LogMessage = 'Error: External Id Field Name was not provided.'
	exec SF_Logger @SPName, N'Message', @LogMessage
	set @errorLines = @errorLines + @time_now + ': Error: External Id Field Name was not provided.'
  	GOTO ERR_HANDLER
END
if CHARINDEX('upsert',@operation) <> 0 and @opt_param1 like '%,%'
BEGIN
  	Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
	print @time_now + ': Error: External Id Field Name was not provided before the soap headers parameter.'
	set @LogMessage = 'Error: External Id Field Name was not provided before the soap headers parameter.'
	exec SF_Logger @SPName, N'Message', @LogMessage
	set @errorLines = @errorLines + @time_now + ': Error: External Id Field Name was not provided before the soap headers parameter.'
  	GOTO ERR_HANDLER
END

-- Retrieve current server name and database
select @server = @@servername, @database = DB_NAME()
SET @server = CAST(SERVERPROPERTY('ServerName') AS sysname) 

-- Execute a linked server query to wake up the provider
declare @noTimeZoneConversion char(5)
declare @sql nvarchar(4000)
declare @parmlist nvarchar(300)
select @sql = 'Select @TZOUT = NoTimeZoneConversion from ' 
select @sql = @sql + @table_server + '...sys_sfsession'
select @parmlist = '@TZOUT char(5) OUTPUT'
exec sp_executesql @sql,@parmlist, @TZOUT=@noTimeZoneConversion OUTPUT
IF (@@ERROR <> 0) GOTO ERR_HANDLER

-- Execute DBAmp.exe to bulk delete objects from Salesforce
Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
print @time_now + ': Run the DBAmp.exe program.' 
set @LogMessage = 'Run the DBAmp.exe program.'
exec SF_Logger @SPName, N'Message', @LogMessage
set @Command = @ProgDir + 'DBAmp.exe ' + @operation + ' ' + @table_name 

set @Command = @Command + ' "' + @server + '" '
set @Command = @Command + ' "' + @database + '" '
set @Command = @Command + ' "' + @table_server + '" '
if CHARINDEX('upsert',@operation) <> 0
begin
	set @Command = @Command + ' "' + @opt_param1 + '" '
	set @Command = @Command + ' "' + @opt_param2 + '" '
end
else
begin
   set @Command = @Command + ' "' + @opt_param1 + '" '
end

-- Create temp table to hold output
declare @errorlog TABLE (line varchar(255))
insert into @errorlog
	exec @Result = master..xp_cmdshell @Command

-- print output to msgs
declare @line varchar(255)
declare @printCount int
set @printCount = 0
DECLARE tables_cursor CURSOR FOR SELECT line FROM @errorlog
OPEN tables_cursor
FETCH NEXT FROM tables_cursor INTO @line
WHILE (@@FETCH_STATUS <> -1)
BEGIN
   if @line is not null
	begin
   	print @line 
   	exec SF_Logger @SPName,N'Message', @line
   	set @errorLines = @errorLines + @line
   	set @printCount = @printCount +1	
	end
   FETCH NEXT FROM tables_cursor INTO @line
END
deallocate tables_cursor

declare @Data nvarchar(100)
declare @Percent int
declare @PercentageOfRowsFailed decimal(10, 3)

set @Data = (Select Data
	from SF_Split(@phrase, ',', 1) 
	where Data like '%ignorefailures(%')

set @Percent = (Select SUBSTRING(@Data, CHARINDEX('(', @Data) + 1, CHARINDEX(')', @Data) - CHARINDEX('(', @Data) - 1))

If @Data like '%ignorefailures(%'
Begin
	set @Percent = @Percent
	Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
	print @time_now + ': Allowed Failure Percent = ' + Cast(@Percent as varchar) + '.'
	set @LogMessage = 'Allowed Failure Percent = ' + Cast(@Percent as varchar) + '.'
	exec SF_Logger @SPName, N'Message', @LogMessage
End
Else
	set @Percent = '0'

select @parmlist = '@PercentFailed decimal(10, 3) OUTPUT'
set @sql = '(Select @PercentFailed =
(Select Cast(Sum(Case When Error not like ' + '''' + '%Operation Successful%' + '''' + ' or Error is null Then 1 Else 0 End) As decimal(10, 3)) As ErrorTotal from ' + @delim_table_name + ')' +
'/
(select Cast(Count(*) as decimal(10, 3)) As Total from ' + @delim_table_name + '))'
exec sp_executesql @sql, @parmlist, @PercentFailed=@PercentageOfRowsFailed OUTPUT

if @PercentageOfRowsFailed is not null
Begin
	set @PercentageOfRowsFailed = @PercentageOfRowsFailed*100
	Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
	print @time_now + ': Percent Failed = ' + Cast(@PercentageOfRowsFailed as varchar) + '.'
	set @LogMessage = 'Percent Failed = ' + Cast(@PercentageOfRowsFailed as varchar) + '.'
	exec SF_Logger @SPName, N'Message', @LogMessage
End

-- If there is an error
if @Result = -1 or @printCount = 0
Begin
    -- If too many failures 
	If @PercentageOfRowsFailed > @Percent  or @Percent = '0'
	Begin
		Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
		print @time_now + ': Error: DBAmp.exe was unsuccessful.'
		set @LogMessage = 'Error: DBAmp.exe was unsuccessful.'
		exec SF_Logger @SPName, N'Message', @LogMessage
		print @time_now + ': Error: Command string is ' + @Command
		set @LogMessage = 'Error: Command string is ' + @Command
		exec SF_Logger @SPName, N'Message', @LogMessage
		GOTO RESTORE_ERR_HANDLER
	End
End

print '--- Ending SF_BulkOps. Operation successful.'
set @LogMessage = 'Ending - Operation Successful.' 
exec SF_Logger @SPName, N'Successful',@LogMessage
set NOCOUNT OFF
return 0

RESTORE_ERR_HANDLER:

print '--- Ending SF_BulkOps. Operation FAILED.'
set @LogMessage = 'Ending - Operation Failed.' 
exec SF_Logger @SPName,N'Failed', @LogMessage
set NOCOUNT OFF
RAISERROR (@errorLines,16,1)
return 1

ERR_HANDLER:

print '--- Ending SF_BulkOps. Operation FAILED.'
set @LogMessage = 'Ending - Operation Failed.' 
exec SF_Logger @SPName, N'Failed',@LogMessage
set NOCOUNT OFF
RAISERROR (@errorLines,16,1)
return 1
Go


-- =============================================
-- Create procedure SF_Refresh
-- =============================================
IF EXISTS (SELECT name
	   FROM   sysobjects
	   WHERE  name = N'SF_Refresh'
	   AND 	  type = 'P')
    DROP PROCEDURE SF_Refresh
GO

CREATE PROCEDURE [dbo].[SF_Refresh]
	@table_server sysname,
	@table_name sysname,
	@schema_error_action varchar(100) = 'no',
	@verify_action varchar(100) = 'no',
	@bulkapi_option varchar(100) = null
AS
-- NOTE: This stored procedure will not work on SQL 2000.
--
-- Parameters: @table_server           - Salesforce Linked Server name (i.e. SALESFORCE)
--             @table_name             - Salesforce object to copy (i.e. Account)
--             @schema_error_action    - Controls the action for a schema change 
--                                     -    'No' : FAIL on a schema change
--                                     -    'Yes' : The table will be replicated instead
--									   -	'NoDrop': The table will be replicated with NoDrop
--                                     -    'Subset' : The new columns are ignored and the current
--                                                     subset of local table columns are refreshed.
--                                     -               Columns deleted on salesforce ARE NOT deleted locally. 
--                                     -    'SubsetDelete' : The new columns are ignored and the current
--                                                     subset of local table columns are refreshed.
--                                     -               Columns deleted on salesforce ARE deleted locally. 
--									   -    'Repair' :  The Max(SystemModStamp of the local table is used and 
--                                                      alternate method of handling deletes is used (slower)
--             @verify_action		   - Controls the row count compare behavior
--                                     -    'No' : Do not compare row counts
--                                     -    'Warn' : Compare row counts and issue warning if different
--                                     -    'Fail' : Compare row counts and fail the proc if different
--             @bulkapi_option  		- Options for using the bulkapi for the delta table
--    

-- @ProgDir - Directory containing the DBAmp.exe. Defaults to the DBAmp program directory
-- If needed, modify this for your installation
declare @ProgDir   	varchar(250) 
set @ProgDir = 'C:\"Program Files"\DBAmp\'

declare @Command 	nvarchar(4000)
declare @Result 	int
declare @sql		nvarchar(max)
declare @parmlist	nvarchar(4000)
declare @columnList nvarchar(max)
declare @deletecolumnList nvarchar(max)
declare @colname	nvarchar(500)
declare @time_now	char(8)
set NOCOUNT ON

print '--- Starting SF_Refresh for ' + @table_name + ' ' +  dbo.SF_Version()
declare @LogMessage nvarchar(max)
declare @SPName nvarchar(50)
set @SPName = 'SF_Refresh:' + Convert(nvarchar(255), NEWID(), 20)
set @LogMessage = 'Parameters: ' + @table_server + ' ' + @table_name + ' '+ @schema_error_action + ' ' 
set @LogMessage = @LogMessage + ' ' + @verify_action + ' '+ ISNULL(@bulkapi_option, ' ') + ' Version: ' +  dbo.SF_Version()
exec SF_Logger @SPName, N'Starting', @LogMessage

declare @delim_table_name sysname
declare @refresh_table sysname
declare @delim_refresh_table sysname
declare @delta_table sysname
declare @delim_delta_table sysname
declare @deleted_table sysname
declare @deleted_table_ts sysname
declare @delim_deleted_table sysname

declare @server sysname
declare @database sysname
declare @timestamp_col_name nvarchar(2000)
declare @is_history_table int
declare @diff_schema_count int

declare @big_object_index int
set @big_object_index = CHARINDEX(REVERSE('__b'),REVERSE(@table_name))

if (@big_object_index = 1)
Begin
	Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
	print @time_now + ': Error: Big Objects are not supported with SF_Refresh ' 
    set @LogMessage = 'Error: Big Objects are not supported with SF_Refresh'
    exec SF_Logger @SPName, N'Message', @LogMessage
    GOTO ERR_HANDLER
End

set @schema_error_action = Lower(@schema_error_action)
set @verify_action = Lower(@verify_action)
Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))

-- Validate parameters
if  @schema_error_action is null
   begin
	  print @time_now + ': Error: Invalid Schema Action Parameter: Cannot be Null ' 
	  set @LogMessage = 'Error: Invalid Schema Action Parameter: Cannot be Null'
	  exec SF_Logger @SPName, N'Message', @LogMessage
  	  GOTO ERR_HANDLER
   end
if  @schema_error_action <> 'yes' and
    @schema_error_action <> 'no' and
	@schema_error_action <> 'nodrop' and
     @schema_error_action <> 'subset' and
     @schema_error_action <> 'repair' and
      @schema_error_action <> 'subsetdelete' 
   begin
	  print @time_now + ': Error: Invalid Schema Action Parameter: ' + @schema_error_action
	  set @LogMessage = 'Error: Invalid Schema Action Parameter: ' + @schema_error_action
	  exec SF_Logger @SPName, N'Message', @LogMessage
  	  GOTO ERR_HANDLER
   end
   
if @schema_error_action <> 'no'
begin
	print @time_now + ': Using Schema Error Action of ' + @schema_error_action
	set @LogMessage = 'Using Schema Error Action of ' + @schema_error_action
	exec SF_Logger @SPName, N'Message', @LogMessage
end

if  @verify_action <> 'no' and
    @verify_action <> 'warn' and
     @verify_action <> 'fail' 
   begin
	  print @time_now + ': Error: Invalid Verify Action Parameter: ' + @verify_action
	  set @LogMessage = 'Error: Invalid Verify Action Parameter: ' + @verify_action
	  exec SF_Logger @SPName, N'Message', @LogMessage
  	  GOTO ERR_HANDLER
   end

-- Put delimeters around names so we can name tables User, etc...
set @delim_table_name = '[' + @table_name + ']'
set @refresh_table = 'TableRefreshTime'
set @delim_refresh_table = '[' + @refresh_table + ']'
set @delta_table = @table_name + '_Delta' + CONVERT(nvarchar(30), GETDATE(), 126) 
set @delim_delta_table = '[' + @delta_table + ']'
set @deleted_table = @table_name + '_Deleted'
set @deleted_table_ts = @deleted_table + CONVERT(nvarchar(30), GETDATE(), 126)
set @delim_deleted_table = '[' + @deleted_table_ts + ']'


-- Determine whether the local table and the previous copy exist
declare @table_exist int
declare @refresh_exist int
declare @delta_exist int
declare @deleted_exist int
declare @char_count varchar(10)

set @table_exist = 0
IF EXISTS (SELECT 1
    FROM INFORMATION_SCHEMA.TABLES
    WHERE TABLE_TYPE='BASE TABLE' 
    AND TABLE_NAME=@table_name)
        set @table_exist = 1
IF (@@ERROR <> 0) GOTO ERR_HANDLER

-- Create table to track refresh times
set @refresh_exist = 0
IF EXISTS (SELECT 1
    FROM INFORMATION_SCHEMA.TABLES
    WHERE TABLE_TYPE='BASE TABLE' 
    AND TABLE_NAME=@refresh_table)
        set @refresh_exist = 1
IF (@@ERROR <> 0) GOTO ERR_HANDLER
if (@refresh_exist = 0)
begin
   exec ('Create Table ' + @refresh_table + ' (TblName nvarchar(255) null, LastRefreshTime datetime null default CURRENT_TIMESTAMP) ')
   IF (@@ERROR <> 0) GOTO ERR_HANDLER
end

--Validate if object exists on Salesforce
declare @sf_obj_exists int
begin try
exec @sf_obj_exists =  SF_IsValidSFObject @table_server,@table_name
end try
begin catch
	Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
	print @time_now + ': Error: Unable to validate object: ' + Error_Message()
	set @LogMessage = ': Error: Unable to validate object: ' + Error_Message()
	exec SF_Logger @SPName, N'Message', @LogMessage
	GOTO ERR_HANDLER
end catch
if @sf_obj_exists = 0
Begin
	Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
	print @time_now + ': Error: Salesforce table does not exist: ' + @table_name
	set @LogMessage = 'Error: Salesforce table does not exist: ' + @table_name
	exec SF_Logger @SPName, N'Message', @LogMessage
	GOTO ERR_HANDLER
End


-- If table does not exist then replicate it
if (@table_exist = 0)
begin
	Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
	print @time_now + ': Local table does not exist. Using SF_Replicate to create the local table.'
	set @LogMessage = 'Local table does not exist. Using SF_Replicate to create the local table.'
	exec SF_Logger @SPName, N'Message', @LogMessage
	goto REPLICATE_EXIT
end

-- Get the flags from DBAmp for this table
declare @replicateable char(5)
declare @deletable char(5)
select @sql = 'Select @DFOUT = Deletable, @RFOUT = Replicateable,@TSOUT = TimestampField from ' 
select @sql = @sql + @table_server + '...sys_sfobjects where Name ='''
select @sql = @sql + @table_name + ''''
select @parmlist = '@DFOUT char(5) OUTPUT, @RFOUT char(5) OUTPUT, @TSOUT char(50) OUTPUT'
exec sp_executesql @sql,@parmlist, @DFOUT = @deletable OUTPUT, @RFOUT=@replicateable OUTPUT,@TSOUT=@timestamp_col_name OUTPUT
IF (@@ERROR <> 0) GOTO ERR_HANDLER

--print @timestamp_col_name
if (@timestamp_col_name = 'CreatedDate') 
begin
	set @is_history_table = 1
end
else if (@timestamp_col_name = 'SystemModstamp')
begin
	set @is_history_table = 0
end
else
begin
	-- Cannot do a normal refresh because the table has no timestamp column
  	Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
	print @time_now + ': Table does not contain a timestamp column needed to refresh. Using SF_Replicate to create table.'
	set @LogMessage = 'Table does not contain a timestamp column needed to refresh. Using SF_Replicate to create table.'
	exec SF_Logger @SPName, N'Message', @LogMessage
	goto REPLICATE_EXIT
end

-- Get the last refresh time from the refresh table
-- This serves as the 'last run' time for the refresh
-- We subtract 30 mins to allow for long units of work on the salesforce side
declare @last_time smalldatetime
declare @table_crtime smalldatetime

-- Get create time of the base table. This is the last replicate time
select @table_crtime = DATEADD(mi,-30,create_date) FROM sys.objects WHERE name = @table_name and type='U'

-- Get the latest timestamp from the Refresh table
select @sql = 'Select @LastTimeOUT = DATEADD(mi,-30,LastRefreshTime) from ' + @refresh_table 
select @sql = @sql + ' where TblName= ''' + @table_name + ''''
select @parmlist = '@LastTimeOUT datetime OUTPUT'
exec sp_executesql @sql,@parmlist, @LastTimeOUT=@last_time OUTPUT
IF (@@ERROR <> 0 OR @last_time is null)
begin
	set @last_time = @table_crtime
end

if (@schema_error_action = 'repair')
begin
	-- Get the latest timestamp from the local table itself
	select @sql = 'Select @LastTimeOUT = DATEADD(mi,-30,MAX(' + @timestamp_col_name + ')) from ' + @delim_table_name 
	select @parmlist = '@LastTimeOUT datetime OUTPUT'
	--print @sql
	exec sp_executesql @sql,@parmlist, @LastTimeOUT=@last_time OUTPUT
	IF (@@ERROR <> 0 OR @last_time is null)
	begin
		set @last_time = @table_crtime
	end
end


-- if the last refresh time was before the last replicate time, use the last replicate time instead
if (@last_time < @table_crtime) and (@schema_error_action != 'repair')
   set @last_time = @table_crtime

-- Get the NoTimeZoneConversion flag from DBAmp
declare @noTimeZoneConversion char(5)
select @sql = 'Select @TZOUT = NoTimeZoneConversion from ' 
select @sql = @sql + @table_server + '...sys_sfsession'
select @parmlist = '@TZOUT char(5) OUTPUT'
exec sp_executesql @sql,@parmlist, @TZOUT=@noTimeZoneConversion OUTPUT
IF (@@ERROR <> 0) GOTO ERR_HANDLER

-- If NoTimeZoneConversion is true then convert last_time to GMT
if (@noTimeZoneConversion = 'true')
begin
  	Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
	print @time_now + ': DBAmp is using GMT for all datetime calculations.'
	SET @last_time = DATEADD(Hour, DATEDIFF(Hour, GETDATE(), GETUTCDATE()), @last_time)
end

Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
print @time_now + ': Using last run time of ' + Convert(nvarchar(24),@last_time,120)
set @LogMessage = 'Using last run time of ' + Convert(nvarchar(24),@last_time,120) 
exec SF_Logger @SPName,N'Message', @LogMessage

-- If the delta table exists, drop it
set @delta_exist = 0;
IF EXISTS (SELECT 1
    FROM INFORMATION_SCHEMA.TABLES
    WHERE TABLE_TYPE='BASE TABLE'
    AND TABLE_NAME=@delta_table)
        set @delta_exist = 1
IF (@@ERROR <> 0) GOTO ERR_HANDLER

if (@delta_exist = 1)
        exec ('Drop table ' + @delim_delta_table)
IF (@@ERROR <> 0) GOTO ERR_HANDLER

-- Retrieve current server name and database
select @server = @@servername, @database = DB_NAME()
SET @server = CAST(SERVERPROPERTY('ServerName') AS sysname) 


-- Create an empty local table with the current structure of the Salesforce object
Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
--print @time_now + ': Create ' + @delta_table + ' with new structure.'
Select @sql = 'Select Top 0 * into ' + @delim_delta_table + ' from ' + @table_server + '...' + @delim_table_name 
begin try
	exec sp_executesql @sql
end try
begin catch
	Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
	print @time_now + ': Error when creating delta table. ' + ERROR_MESSAGE()
	set @LogMessage = 'Error when creating delta table. ' + ERROR_MESSAGE()
	exec SF_Logger @SPName, N'Message', @LogMessage 
	GOTO ERR_HANDLER
end catch

-- Remember query time as the the start of the interval
declare @queryTime datetime
select @queryTime = (Select CURRENT_TIMESTAMP)

-- Populate new delta table with updated rows	
if @bulkapi_option is null
begin
	select @sql = 'Insert ' + @delim_delta_table + ' Select * from ' + @table_server + '...' + @delim_table_name + ' where ' + @timestamp_col_name + ' > @LastTimeIN'
	select @parmlist = '@LastTimeIN datetime'
	exec sp_executesql @sql, @parmlist, @LastTimeIN=@last_time
	IF (@@ERROR <> 0) GOTO ERR_HANDLER
end
else
begin
	-- Use bulkapi
	-- Execute DBAmp.exe to query using the bulkapi
	Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
	print @time_now + ': Run the DBAmp.exe program.'
	set @LogMessage = 'Run the DBAmp.exe program.'
	exec SF_Logger @SPName, N'Message', @LogMessage
	set @Command = @ProgDir + 'DBAmp.exe ExportBulk' 
	set @Command = @Command + ':' + @bulkapi_option
	set @Command = @Command + ' "' + @delta_table + '" '
	set @Command = @Command + ' "' + @server + '" '
	set @Command = @Command + ' "' + @database + '" '
	set @Command = @Command + ' "' + @table_server + '" '
	-- Add where clause
	set @Command = @Command + ' "where ' + RTRIM(@timestamp_col_name) +'>' + Convert(nvarchar(24),@last_time,120) + '" '
	
	-- Create temp table to hold output
	declare @errorlog TABLE (line varchar(255))
	insert into @errorlog
		exec @Result = master..xp_cmdshell @Command

	-- print output to msgs
	declare @line varchar(255)
	declare @printCount int
	set @printCount = 0
	DECLARE tables_cursor CURSOR FOR SELECT line FROM @errorlog
	OPEN tables_cursor
	FETCH NEXT FROM tables_cursor INTO @line
	WHILE (@@FETCH_STATUS <> -1)
	BEGIN
	   if @line is not null
		begin
   		print @line 
   		--set @errorLines = @errorLines + @line
   		set @printCount = @printCount +1	
		end
	   FETCH NEXT FROM tables_cursor INTO @line
	END
	deallocate tables_cursor


	if @Result = -1 or @printCount = 0
	BEGIN
  		Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
		print @time_now + ': Error: DBAmp.exe was unsuccessful.'
		set @LogMessage = 'Error: DBAmp.exe was unsuccessful.'
		exec SF_Logger @SPName, N'Message', @LogMessage
		print @time_now + ': Error: Command string is ' + @Command
		set @LogMessage = 'Error: Command string is ' + @Command
		exec SF_Logger @SPName, N'Message', @LogMessage
  		GOTO ERR_HANDLER
	END
end

-- Delete any overlap rows in the delta table
-- These are rows we've already synched but got picked up due to the 10 min sliding window
select @sql = 'delete ' + @delim_delta_table + ' where exists '
select @sql = @sql + '(select Id from ' + @delim_table_name + ' where Id= ' + @delim_delta_table +'.Id '
select @sql = @sql + ' and ' + @timestamp_col_name + ' = ' + @delim_delta_table + '.' + @timestamp_col_name + ')'

exec sp_executesql @sql
IF (@@ERROR <> 0) GOTO ERR_HANDLER

-- Get the count of records from the delta table
declare @delta_count int
select @sql = 'Select @DeltaCountOUT = Count(*) from ' + @delim_delta_table
select @parmlist = '@DeltaCountOUT int OUTPUT'
exec sp_executesql @sql,@parmlist, @DeltaCountOUT=@delta_count OUTPUT
IF (@@ERROR <> 0) GOTO ERR_HANDLER

-- Print number of rows in delta table
Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
Select @char_count = (select CAST(@delta_count as VARCHAR(10)))
print @time_now + ': Identified ' + @char_count + ' updated/inserted rows.'

set @LogMessage = 'Identified ' + @char_count + ' updated/inserted rows.'
exec SF_Logger @SPName, N'Message',@LogMessage

-- If no records have changed then move on to deletes
if (@delta_count = 0) goto DELETE_PROCESS

-- Check to see if the column structure is the same
declare @cnt1 int
declare @cnt2 int
Select @cnt1 = Count(*) FROM INFORMATION_SCHEMA.COLUMNS v1 WHERE v1.TABLE_NAME=@delta_table 
		AND NOT EXISTS (Select COLUMN_NAME from INFORMATION_SCHEMA.COLUMNS v2 
		Join INFORMATION_SCHEMA.TABLES t1
		On v2.TABLE_NAME = t1.TABLE_NAME and t1.TABLE_SCHEMA = v2.TABLE_SCHEMA
		where (t1.TABLE_TYPE = 'BASE TABLE') and
		v2.TABLE_NAME=@table_name and v1.COLUMN_NAME = v2.COLUMN_NAME and v1.DATA_TYPE = v2.DATA_TYPE 
		and v1.IS_NULLABLE = v2.IS_NULLABLE
		and ISNULL(v1.CHARACTER_MAXIMUM_LENGTH,0) = ISNULL(v2.CHARACTER_MAXIMUM_LENGTH,0))
IF (@@ERROR <> 0) GOTO ERR_HANDLER

Select @cnt2 = Count(*) FROM INFORMATION_SCHEMA.COLUMNS v1
		Join INFORMATION_SCHEMA.TABLES t1
		On v1.TABLE_NAME = t1.TABLE_NAME and t1.TABLE_SCHEMA = v1.TABLE_SCHEMA
		WHERE (t1.TABLE_TYPE = 'BASE TABLE') and v1.TABLE_NAME=@table_name 
		AND NOT EXISTS (Select COLUMN_NAME from INFORMATION_SCHEMA.COLUMNS v2 where 
		v2.TABLE_NAME=@delta_table and v1.COLUMN_NAME = v2.COLUMN_NAME and v1.DATA_TYPE = v2.DATA_TYPE 
		and v1.IS_NULLABLE = v2.IS_NULLABLE
		and ISNULL(v1.CHARACTER_MAXIMUM_LENGTH,0) = ISNULL(v2.CHARACTER_MAXIMUM_LENGTH,0))
IF (@@ERROR <> 0) GOTO ERR_HANDLER

set @diff_schema_count = @cnt1 + @cnt2

if (@diff_schema_count > 0)
begin
	Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
	
		Select v1.COLUMN_NAME into #Test1 FROM INFORMATION_SCHEMA.COLUMNS v1 WHERE v1.TABLE_NAME=@delta_table 
		And v1.COLUMN_NAME Not in (Select COLUMN_NAME from INFORMATION_SCHEMA.COLUMNS v2 
		Join INFORMATION_SCHEMA.TABLES t1
		On v2.TABLE_NAME = t1.TABLE_NAME and t1.TABLE_SCHEMA = v2.TABLE_SCHEMA
		where (t1.TABLE_TYPE = 'BASE TABLE') and 
		v2.TABLE_NAME=@table_name and v1.COLUMN_NAME = v2.COLUMN_NAME and v1.DATA_TYPE = v2.DATA_TYPE 
		and v1.IS_NULLABLE = v2.IS_NULLABLE
		and ISNULL(v1.CHARACTER_MAXIMUM_LENGTH,0) = ISNULL(v2.CHARACTER_MAXIMUM_LENGTH,0))

		Select v1.COLUMN_NAME into #Test2 FROM INFORMATION_SCHEMA.COLUMNS v1 
		Join INFORMATION_SCHEMA.TABLES t1
		On v1.TABLE_NAME = t1.TABLE_NAME and t1.TABLE_SCHEMA = v1.TABLE_SCHEMA
		WHERE (t1.TABLE_TYPE = 'BASE TABLE') and v1.TABLE_NAME=@table_name 
		AND v1.COLUMN_NAME not in (Select COLUMN_NAME from INFORMATION_SCHEMA.COLUMNS v2 where 
		v2.TABLE_NAME=@delta_table and v1.COLUMN_NAME = v2.COLUMN_NAME and v1.DATA_TYPE = v2.DATA_TYPE 
		and v1.IS_NULLABLE = v2.IS_NULLABLE 
		and ISNULL(v1.CHARACTER_MAXIMUM_LENGTH,0) = ISNULL(v2.CHARACTER_MAXIMUM_LENGTH,0))

	  declare @ColumnName sysname

	  declare ColumnCompare_cursor cursor 
	  for 
		 select a.COLUMN_NAME from #Test1 a

	  open ColumnCompare_cursor

	  while 1 = 1
	  begin
	  fetch next from ColumnCompare_cursor into @ColumnName
		if @@error <> 0 or @@fetch_status <> 0 break
		    begin
				print @time_now + ': Error: ' + @ColumnName + ' exists in the delta table but does not exist in the local table or has a different definition.'
				set @LogMessage = 'Error: ' + @ColumnName + ' exists in the delta table but does not exist in the local table or has a different definition.'
				exec SF_Logger @SPName, N'Message',@LogMessage
			end
	  end

	  close ColumnCompare_cursor
	  deallocate ColumnCompare_cursor

	  declare ColumnCompare2_cursor cursor 
	  for 	
	     select a.COLUMN_NAME from #Test2 a

	  open ColumnCompare2_cursor

	  while 1 = 1
	  begin
	  fetch next from ColumnCompare2_cursor into @ColumnName
		if @@error <> 0 or @@fetch_status <> 0 break
		    begin
				print @time_now + ': Error: ' + @ColumnName + ' exists in the local table but does not exist in the delta table or has a different definition.'
				set @LogMessage = 'Error: ' + @ColumnName + ' exists in the local table but does not exist in the delta table or has a different definition.'
				exec SF_Logger @SPName, N'Message',@LogMessage
			end
	  end

	  close ColumnCompare2_cursor
	  deallocate ColumnCompare2_cursor
	  
	if (@schema_error_action = 'yes') or (@schema_error_action = 'nodrop')
	begin
		print @time_now + ': Table schema has changed. The table will be replicated instead.'
		set @LogMessage = 'Table schema has changed. The table will be replicated instead.'
		exec SF_Logger @SPName, N'Message', @LogMessage
		exec ('Drop table ' + @delim_delta_table)
		goto REPLICATE_EXIT
	end
   
   if (@schema_error_action = 'no')
   begin
	  print @time_now + ': Error: Table schema has changed and therefore the table cannot be refreshed.'
	  set @LogMessage = 'Error: Table schema has changed and therefore the table cannot be refreshed.'
	  exec SF_Logger @SPName, N'Message',@LogMessage
	  exec ('Drop table ' + @delim_delta_table)
  	  GOTO ERR_HANDLER
   end
   
    -- Schema changed so try to build a subset of columns
	-- Build list of columns in common
	declare colname_cursor cursor for 
		SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS v1 WHERE v1.TABLE_NAME= @table_name 
		AND EXISTS (Select COLUMN_NAME from INFORMATION_SCHEMA.COLUMNS v2 
		where v2.TABLE_NAME= @delta_table 
		and v1.COLUMN_NAME = v2.COLUMN_NAME and v1.DATA_TYPE = v2.DATA_TYPE and v1.IS_NULLABLE = v2.IS_NULLABLE 
		and ISNULL(v1.CHARACTER_MAXIMUM_LENGTH,0)= ISNULL(v2.CHARACTER_MAXIMUM_LENGTH,0) and v1.TABLE_SCHEMA = v2.TABLE_SCHEMA)

	OPEN colname_cursor
	set @columnList = ''
	
	while 1 = 1
	begin
		fetch next from colname_cursor into @colname
		if @@error <> 0 or @@fetch_status <> 0 break
		set @columnList = @columnList + '[' + @colname + ']' + ','
	end
	close colname_cursor
	deallocate colname_cursor

	if Len(@columnList) = 0
	begin
		print @time_now + ': Error: Table schema has changed with no columns in common. Therefore the table cannot be refreshed.'
		set @LogMessage = 'Error: Table schema has changed with no columns in common. Therefore the table cannot be refreshed.'
		exec SF_Logger @SPName, N'Message', @LogMessage
		exec ('Drop table ' + @delim_delta_table)
		GOTO ERR_HANDLER
	end
					
	SET @columnList = SUBSTRING(@columnList, 1, Len(@columnList) - 1)

	-- Build list of columns that need to deleted in the local table
	declare colname_cursor cursor for 
		SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS v1 WHERE v1.TABLE_NAME= @table_name 
		AND not EXISTS (Select COLUMN_NAME from INFORMATION_SCHEMA.COLUMNS v2 
		where v2.TABLE_NAME= @delta_table 
		and v1.COLUMN_NAME = v2.COLUMN_NAME )

	OPEN colname_cursor
	set @deletecolumnList = ''
	while 1 = 1
	begin
		fetch next from colname_cursor into @colname
		if @@error <> 0 or @@fetch_status <> 0 break
		set @deletecolumnList = @deletecolumnList + '[' + @colname + ']' + ','
	end
	close colname_cursor
	deallocate colname_cursor

	if Len(@deletecolumnList) > 0
	begin
		SET @deletecolumnList = SUBSTRING(@deletecolumnList, 1, Len(@deletecolumnList) - 1)
	end
					
	print @time_now + ': Warning: Table schema has changed. SF_Refresh will use the valid subset of columns.'
	set @LogMessage = 'Warning: Table schema has changed. SF_Refresh will use the valid subset of columns.'
	exec SF_Logger @SPName, N'Message', @LogMessage
end
else
begin
	-- Build list of columns anyway
	declare colname_cursor cursor for 
		SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS v1 WHERE v1.TABLE_NAME= @table_name 
		AND EXISTS (Select COLUMN_NAME from INFORMATION_SCHEMA.COLUMNS v2 
		where v2.TABLE_NAME= @delta_table 
		and v1.COLUMN_NAME = v2.COLUMN_NAME and v1.DATA_TYPE = v2.DATA_TYPE and v1.IS_NULLABLE = v2.IS_NULLABLE 
		and ISNULL(v1.CHARACTER_MAXIMUM_LENGTH,0)= ISNULL(v2.CHARACTER_MAXIMUM_LENGTH,0) and v1.TABLE_SCHEMA = v2.TABLE_SCHEMA)

	OPEN colname_cursor
	set @columnList = ''
	
	while 1 = 1
	begin
		fetch next from colname_cursor into @colname
		if @@error <> 0 or @@fetch_status <> 0 break
		set @columnList = @columnList + '[' + @colname + ']' + ','
	end
	close colname_cursor
	deallocate colname_cursor

	SET @columnList = SUBSTRING(@columnList, 1, Len(@columnList) - 1)
End

DELETE_PROCESS:
-- Skip deleted stuff for nondeleteable tables
-- Commented out to allow correct operation for read only users
--if (@deletable = 'false') goto SKIPDELETED

-- If the deleted table exists, drop it and recreate it
set @deleted_exist = 0;
IF EXISTS (SELECT 1
    FROM INFORMATION_SCHEMA.TABLES
    WHERE TABLE_TYPE='BASE TABLE'
    AND TABLE_NAME=@deleted_table_ts)
        set @deleted_exist = 1
IF (@@ERROR <> 0) GOTO ERR_HANDLER

if (@deleted_exist = 1)
        exec ('Drop table ' + @delim_deleted_table)
IF (@@ERROR <> 0) GOTO ERR_HANDLER

select @sql = 'Create table ' +  @delim_deleted_table
select @sql = @sql + ' (Id nchar(18) null ) '
exec (@sql)
IF (@@ERROR <> 0) GOTO ERR_HANDLER

if (@replicateable = 'true') and (@schema_error_action != 'repair')and (Lower(@table_name) != 'currencytype')
begin
	-- Object supports GetDelete api so use it to retrieve deleted ids
	select @sql = 'Insert ' + @delim_deleted_table + ' Select * from openquery(' 
	select @sql = @sql + @table_server + ',''Select Id from ' + @deleted_table 
	select @sql = @sql + ' where startdate=''''' + Convert(nvarchar(24),@last_time,120) + ''''''')' 
	--print @sql

BEGIN TRY
	   	exec (@sql)
END TRY
BEGIN CATCH
	Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
	print @time_now + ': Error occurred fetching deleted rows.'	
	set @LogMessage = 'Error occurred fetching deleted rows.'
	exec SF_Logger @SPName, N'Message', @LogMessage
	print @time_now +
		': Error: ' + ERROR_MESSAGE();
	set @LogMessage = 'Error: ' + ERROR_MESSAGE()
	exec SF_Logger @SPName, N'Message', @LogMessage
		
     -- Roll back any active or uncommittable transactions before
     -- inserting information in the ErrorLog.
     IF XACT_STATE() <> 0
     BEGIN
         ROLLBACK TRANSACTION;
     END
     Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
	if (@schema_error_action = 'yes') or (@schema_error_action = 'nodrop')
	begin
		print @time_now + ': Error occurred while fetching deleted rows. The table will be replicated instead.'
		set @LogMessage = 'Error occurred while fetching deleted rows. The Table will be replicated instead.'
		exec SF_Logger @SPName, N'Message', @LogMessage
		goto REPLICATE_EXIT
	end
	else
	begin
     goto ERR_HANDLER
    end
END CATCH

end
else
begin
	-- Use alternate method to discover deleted id's
	Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
	print @time_now + ': Using alternate method to determine deleted records.' 
	set @LogMessage = 'Using alternate method to determine deleted records.'
	exec SF_Logger @SPName, N'Message', @LogMessage
	-- Create new deleted table for non-replicatable tables
	select @sql = 'Insert ' + @delim_deleted_table + ' Select Id from ' + @delim_table_name
	select @sql = @sql + ' where Id not in (select Id from ' + @table_server + '...' + @delim_table_name + ')'
	exec sp_executesql @sql
	IF (@@ERROR <> 0) GOTO ERR_HANDLER
end

-- Delete any rows in the deleted table that already have been deleted
-- These are rows we've already synched but got picked up due to the 10 min sliding window
select @sql = 'delete ' + @delim_deleted_table + ' where not exists '
select @sql = @sql + '(select Id from ' + @delim_table_name + ' where Id= ' + @delim_deleted_table +'.Id)'
exec sp_executesql @sql
IF (@@ERROR <> 0) GOTO ERR_HANDLER

-- Get the count of records from the deleted table
declare @deleted_count int
select @sql = 'Select @DeletedCountOUT = Count(*) from ' + @delim_deleted_table
select @parmlist = '@DeletedCountOUT int OUTPUT'
exec sp_executesql @sql,@parmlist, @DeletedCountOUT=@deleted_count OUTPUT
IF (@@ERROR <> 0) GOTO ERR_HANDLER

-- Print number of rows in deleted table
Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
Select @char_count = (select CAST(@deleted_count as VARCHAR(10)))
print @time_now + ': Identified ' + @char_count + ' deleted rows.'

set @LogMessage = 'Identified ' + @char_count + ' deleted rows.'
exec SF_Logger @SPName,N'Message', @LogMessage

if (@deleted_count <> 0)
begin
	-- Delete rows from local table that exist in deleted table
	Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
	print @time_now + ': Removing deleted rows from ' + @table_name 
	set @LogMessage = 'Removing deleted rows from ' + @table_name
	exec SF_Logger @SPName, N'Message', @LogMessage

	select @sql = 'delete ' + @delim_table_name + ' where Id IN (select Id from ' + @delim_deleted_table + ' )'
	exec sp_executesql @sql
	IF (@@ERROR <> 0) GOTO ERR_HANDLER
end

SKIPDELETED:
if (@delta_count > 0)
begin
	BEGIN TRAN
	Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
	print @time_now + ': Adding updated/inserted rows into ' + @table_name 
	set @LogMessage = 'Adding updated/inserted rows into ' + @table_name
	exec SF_Logger @SPName, N'Message', @LogMessage
	
	if @is_history_table = 0 or @table_name = 'OpportunityHistory'
	begin
		-- Delete rows from local table that exist in delta table
		-- History tables skip this step because updates are not allowed
		select @sql = 'delete ' + @delim_table_name + ' where Id IN (select Id from ' + @delim_delta_table + ' )'
		exec sp_executesql @sql
		IF (@@ERROR <> 0) 
		begin
		   ROLLBACK
		   GOTO ERR_HANDLER
		end
	end
	
	-- Insert delta rows into local table
	if (@diff_schema_count > 0 )
	begin
		if Len(@deletecolumnList) > 0 and @schema_error_action = 'subsetdelete'
		begin
			-- Remove any deleted columns
			Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
			print @time_now + ': Removing the following deleted columns ' + @deletecolumnList
			set @LogMessage = 'Removing the following deleted columns ' + @deletecolumnList
			exec SF_Logger @SPName, N'Message', @LogMessage
			 
			select @sql = 'alter table ' + @delim_table_name + ' drop column ' + @deletecolumnList	
			exec sp_executesql @sql
			IF (@@ERROR <> 0) 
			begin
			   ROLLBACK
			   GOTO ERR_HANDLER
			end
		end
			
		-- Now insert the new rows
		select @sql = 'insert ' + @delim_table_name + '(' + @columnList + ')' 
					+ ' select ' + @columnList + ' from ' + @delim_delta_table
		exec sp_executesql @sql
		IF (@@ERROR <> 0) 
		begin
		   ROLLBACK
		   GOTO ERR_HANDLER
		end
	end
	else
	begin
		select @sql = 'insert ' + @delim_table_name + '(' + @columnList + ')' 
					+ ' select ' + @columnList + ' from ' + @delim_delta_table
		exec sp_executesql @sql
		IF (@@ERROR <> 0) 
		begin
		   ROLLBACK
		   GOTO ERR_HANDLER
		end
	end
		
	COMMIT
end
	
SUCCESS:
-- Reset Last Refresh in the Refresh table for this object
exec ('delete ' + @refresh_table + ' where TblName =''' + @table_name + '''')
select @sql = 'insert into ' + @refresh_table + '(TblName,LastRefreshTime) Values(''' + @table_name + ''',''' + Convert(nvarchar(24),@queryTime,126) +''')'
--print @sql
exec sp_executesql @sql

-- We don't need the deleted and delta tables so drop them
exec ('Drop table ' + @delim_deleted_table)
exec ('Drop table ' + @delim_delta_table)

-- Report row count difference
declare @differ_count int
select @sql = 'Select @DifferCountOUT = Count(Id)-min(expr0) from ' + @delim_table_name
select @sql = @sql + ' ,openquery(' + @table_server + ',''Select Count(Id) from ' + @table_name + ' '')'
select @parmlist = '@DifferCountOUT int OUTPUT'

if  @verify_action <> 'no' 
begin
	exec sp_executesql @sql,@parmlist, @DifferCountOUT=@differ_count OUTPUT
	IF (@@ERROR = 0)
	Begin
	   if @differ_count <> 0 
		  begin
			Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
			declare @action varchar(100)
		    if  @verify_action = 'warn' 
				set @action = 'Warning'
		    else set @action = 'Error'
			print @time_now + ': ' + @action + ': The row counts of the local table and salesforce differ by ' + Cast(@differ_count as varchar(10)) + ' rows.'
			set @LogMessage = @action + ': The row counts of the local table and salesforce differ by ' + Cast(@differ_count as varchar(10)) + ' rows.'
			exec SF_Logger @SPName,N'Message', @LogMessage			
			-- Fail the proc if user requested
			if @verify_action = 'fail'
			   RAISERROR ('--- Ending SF_Refresh. Operation FAILED.',16,1)
		  end
	End
End

print '--- Ending SF_Refresh. Operation successful.'
set @LogMessage = 'Ending - Operation Successful.' 
exec SF_Logger @SPName,N'Successful', @LogMessage
set NOCOUNT OFF
return 0

ERR_HANDLER:
-- We don't need the deleted and delta tables so drop them
IF EXISTS (SELECT 1
    FROM INFORMATION_SCHEMA.TABLES
    WHERE TABLE_TYPE='BASE TABLE'
    AND TABLE_NAME=@deleted_table_ts)
begin
   exec ('Drop table ' + @delim_deleted_table)
end

IF EXISTS (SELECT 1
    FROM INFORMATION_SCHEMA.TABLES
    WHERE TABLE_TYPE='BASE TABLE'
    AND TABLE_NAME=@delta_table)
begin
   exec ('Drop table ' + @delim_delta_table)
end
print('--- Ending SF_Refresh. Operation FAILED.')
set @LogMessage = 'Ending - Operation Failed.' 
exec SF_Logger @SPName,N'Failed', @LogMessage
RAISERROR ('--- Ending SF_Refresh. Operation FAILED.',16,1)
set NOCOUNT OFF
return 1

REPLICATE_EXIT:
-- We don't need the deleted and delta tables so drop them
IF EXISTS (SELECT 1
    FROM INFORMATION_SCHEMA.TABLES
    WHERE TABLE_TYPE='BASE TABLE'
    AND TABLE_NAME=@deleted_table_ts)
begin
   exec ('Drop table ' + @delim_deleted_table)
end

IF EXISTS (SELECT 1
    FROM INFORMATION_SCHEMA.TABLES
    WHERE TABLE_TYPE='BASE TABLE'
    AND TABLE_NAME=@delta_table)
begin
   exec ('Drop table ' + @delim_delta_table)
end

set @LogMessage = 'Ending - Branching to SF_Replicate.' 
exec SF_Logger @SPName, N'Failed',@LogMessage
If @schema_error_action = 'nodrop'
Begin
	exec SF_Replicate @table_server, @table_name, 'nodrop'
End
else
Begin
	exec SF_Replicate @table_server, @table_name
End
set NOCOUNT OFF
return 0
GO


-- =============================================
-- Create procedure SF_RefreshAll
--
-- To Use:
-- 1. Modify the use statement on line 6 to point to your salesforce backup database
-- 2. Execute this script to add the SF_RefreshAll proc to the salesforce backups database
-- 3. Calling example:  exec SF_RefreshAll 'SALESFORCE'
-- =============================================
IF EXISTS (SELECT name 
	   FROM   sysobjects 
	   WHERE  name = N'SF_RefreshAll' 
	   AND 	  type = 'P')
    DROP PROCEDURE SF_RefreshAll
GO


CREATE PROCEDURE SF_RefreshAll 
	@table_server sysname,
	@replicate_on_schema_error sysname = 'No',
	@verify_action varchar(100) = 'no'
AS
-- Input Parameter @table_server - Linked Server Name
--             @replicate_on_schema_error - Controls whether to go ahead and replicate for a schema change or non refreshable table 
--                                        -    If the value is Yes then a replicate will be done for schema changes and non refreshable tables
--                                        -    If the value is Subset then a refresh with the common subset of columns will be done
--             @replicate_on_schema_error    - Controls the action for a schema change 
--                                     -    'No' : FAIL on a schema change
--                                     -    'Yes' : The table will be replicated instead
--                                     -    'Subset' : The new columns are ignored and the current
--                                                     subset of local table columns are refreshed.
--                                     -               Columns deleted on salesforce ARE NOT deleted locally. 
--                                     -    'SubsetDelete' : The new columns are ignored and the current
--                                                     subset of local table columns are refreshed.
--                                     -               Columns deleted on salesforce ARE deleted locally. 
--									   -    'Repair' :  The Max(SystemModStamp of the local table is used and 
--                                                      alternate method of handling deletes is used (slower)
--             @verify_action		   - Controls the row count compare behavior
--                                     -    'No' : Do not compare row counts
--                                     -    'Warn' : Compare row counts and issue warning if different
--                                     -    'Fail' : Compare row counts and fail the proc if different

set NOCOUNT ON
print N'--- Starting SF_RefreshAll' + ' ' +  dbo.SF_Version()
declare @LogMessage nvarchar(max)
declare @SPName nvarchar(50)
set @SPName = 'SF_RefreshAll:' + Convert(nvarchar(255), NEWID(), 20)
set @LogMessage = 'Parameters: ' + @table_server + ' ' + @replicate_on_schema_error + ' ' + @verify_action + ' Version: ' +  dbo.SF_Version()
exec SF_Logger @SPName,N'Starting', @LogMessage

if (@replicate_on_schema_error = 'Yes' or @replicate_on_schema_error = 'yes')
   print N'Warning: Replicating tables that are non-refreshable or that have schema changes.'
   set @LogMessage = 'Warning: Replicating tables that are non-refreshable or that have schema changes.'
   exec SF_Logger @SPName, N'Message', @LogMessage

Create Table #tmpSF ([Name] sysname not null, TimestampField nvarchar(128)not null, Queryable varchar(5) not null)
declare @sql nvarchar(4000)
set @sql = 'Select Name,TimestampField,Queryable from ' + @table_server + '...sys_sfobjects'
Insert #tmpSF EXEC (@sql)
if (@@error <> 0) goto ERR_HANDLER

declare @tn sysname
declare @timestampfield nvarchar(128)
declare @suberror int
set @suberror = 0

declare @queryable varchar(5)
declare tbls_cursor cursor local fast_forward
for select [Name],TimestampField, Queryable from #tmpSF

open tbls_cursor

while 1 = 1
begin
   fetch next from tbls_cursor into @tn,@timestampfield,@queryable
   if @@error <> 0 or @@fetch_status <> 0 break

   -- To skip tables, add a statement similiar to the statement below
   -- if @tn = 'SolutionHistory' CONTINUE
   
   -- The IdeaComment table must now be skipped.
   -- With API 24.0, sf does not allow select all rows for that table.
   if @tn = 'IdeaComment' CONTINUE
   
      -- The UserRecordAccess table must now be skipped.
   -- With API 24.0, sf does not allow select all rows for that table.
   if @tn = 'UserRecordAccess' CONTINUE
     
   -- The vote table must now be skipped.
   -- With API 17.0, sf does not allow select all rows for that table.
   if @tn = 'Vote' CONTINUE
   
   -- The ContentDocumentLink table must now be skipped.
   -- With API 21.0, sf does not allow select all rows for that table.
   if @tn = 'ContentDocumentLink' CONTINUE
 
    -- The FeedItem table must now be skipped.
   -- With API 21.0, sf does not allow select all rows for that table.
   if @tn = 'FeedItem' CONTINUE
   
    -- Skip the EventLogFile table due to size of the blobs
   if @tn = 'EventLogFile' CONTINUE

    -- Skip the EngagementHistory table because you cannot query on SystemModstamp
   if @tn = 'EngagementHistory' CONTINUE
      
   -- Skip these tables due to api restriction
   if @tn='FieldDefinition' CONTINUE
   if @tn='ListViewChartInstance' CONTINUE
   
   -- Feed tables consume huge quantities of API calls
   -- Therefore, we skip them. Comment out the lines if you would like to include them.
   if LEFT(@tn,4) = 'Feed' CONTINUE
   if RIGHT(@tn,4) = 'Feed' CONTINUE
   
   -- Skip all APEX tables becauase they have little value
   if LEFT(@tn,4) = 'Apex' CONTINUE 

   -- Knowledge _kav tables cannot handle a select without where clause so we skip them
   if RIGHT(@tn,4) = '_kav' CONTINUE
   if @tn = 'KnowledgeArticleVersion' CONTINUE
   
   if @tn = 'PlatformAction' CONTINUE
   if @tn = 'CollaborationGroupRecord' CONTINUE
   
   -- Skip offending data.com tables
   if @tn = 'DatacloudDandBCompany' CONTINUE
   if @tn = 'DcSocialProfile' CONTINUE
   if @tn = 'DataCloudConnect' CONTINUE
   if @tn = 'DatacloudCompany' CONTINUE
   if @tn = 'DatacloudContact' CONTINUE
   if @tn = 'DatacloudSocialHandle' CONTINUE
   if @tn = 'DcSocialProfileHandle' CONTINUE
   if @tn = 'DatacloudAddress' CONTINUE
   if @tn = 'OwnerChangeOptionInfo' CONTINUE
   
   if @tn = 'ContentFolderMember' CONTINUE   
   if @tn = 'EntityParticle' CONTINUE  
   if @tn = 'EntityDescription' CONTINUE 
   if @tn = 'EntityDefinition' CONTINUE 
   if @tn = 'Publisher' CONTINUE
   if @tn = 'RelationshipDomain' CONTINUE   
   if @tn = 'RelationshipInfo' CONTINUE  
   if @tn = 'ServiceFieldDataType' CONTINUE
   if @tn = 'UserEntityAccess' CONTINUE
   if @tn = 'PicklistValueInfo' CONTINUE
   if @tn = 'SearchLayout' CONTINUE
   if @tn = 'UserFieldAccess' CONTINUE
   if @tn= 'DataType' CONTINUE

   
   if @tn = 'FieldPermissions' CONTINUE
   if @tn = 'ContentFolderItem' CONTINUE
   if @tn = 'DataStatistics' CONTINUE
   if @tn = 'FlexQueueItem' CONTINUE
   if @tn = 'ContentHubItem' continue
   if @tn = 'OwnerChangeOptionInfo' continue
   if @tn = 'OutgoingEmail' continue
   if @tn = 'OutgoingEmailRelation' continue
   if @tn = 'NetworkUserHistoryRecent' continue
   if @tn = 'RecordActionHistory' continue

   	-- tables not queryable summer 2018
   if @tn = 'AppTabMember' continue
   if @tn = 'ColorDefinition' continue
   if @tn = 'IconDefinition' continue
   
   -- Skip External objects because we cant select all rows
   if RIGHT(@tn,3) = '__x' CONTINUE 
   
   -- Skip big objects
   declare @isBigObject int
   set @isBigObject = 0
   exec SF_IsBigObject @tn, @isBigObject Output

   if (@isBigObject = 1)
	  continue
	  
   if exists(Select TableName from TablesToSkip where @tn like TableName)
	  continue
	  
   if @timestampfield <> 'SystemModstamp' and @timestampfield <> 'CreatedDate' 
   begin
      -- print @tn + ' ' + @queryable
      if ((@replicate_on_schema_error = 'Yes' or @replicate_on_schema_error = 'yes') and @queryable = 'true')
      begin
	    -- Call SF_Replicate for this table
	    begin try
		  exec SF_Replicate @table_server, @tn
	    end try
	    begin catch
		  print 'Error: SF_Replicate failed for table ' + @tn
		  set @LogMessage = 'Error: SF_Replicate failed for table ' + @tn
		  exec SF_Logger @SPName, N'Message', @LogMessage
			 print 
				'Error ' + CONVERT(VARCHAR(50), ERROR_NUMBER()) +
				', Severity ' + CONVERT(VARCHAR(5), ERROR_SEVERITY()) +
				', State ' + CONVERT(VARCHAR(5), ERROR_STATE()) + 
				', Line ' + CONVERT(VARCHAR(5), ERROR_LINE());
			 print 
				ERROR_MESSAGE();
			set @LogMessage = ERROR_MESSAGE()
			-- Comment out to avoid issues in log table
			--exec SF_Logger @SPName, N'Message', @LogMessage

			 -- Roll back any active or uncommittable transactions before
			 -- inserting information in the ErrorLog.
			 IF XACT_STATE() <> 0
			 BEGIN
				 ROLLBACK TRANSACTION;
			 END
		  set @suberror = 1
	    end catch
		continue
	  end
	  else
	  begin
	    -- skip this table
	    CONTINUE
	  end
   end
   
   -- Call SF_Refresh for this table
   begin try
		exec SF_Refresh @table_server, @tn , @replicate_on_schema_error, @verify_action
   end try
   begin catch
	 print 'Error: SF_Refresh failed for table ' + @tn
	 set @LogMessage = 'Error: SF_Refresh failed for table ' + @tn
	 exec SF_Logger @SPName, N'Message', @LogMessage
	 print 
		'Error ' + CONVERT(VARCHAR(50), ERROR_NUMBER()) +
		', Severity ' + CONVERT(VARCHAR(5), ERROR_SEVERITY()) +
		', State ' + CONVERT(VARCHAR(5), ERROR_STATE()) + 
		', Line ' + CONVERT(VARCHAR(5), ERROR_LINE());
	 print 
		ERROR_MESSAGE();
		set @LogMessage = ERROR_MESSAGE()
		exec SF_Logger @SPName, N'Message', @LogMessage 
		
     -- Roll back any active or uncommittable transactions before
     -- inserting information in the ErrorLog.
     IF XACT_STATE() <> 0
     BEGIN
         ROLLBACK TRANSACTION;
     END
	 set @suberror = 1
   end catch
   
 end

close tbls_cursor
deallocate tbls_cursor

if @suberror = 1 goto ERR_HANDLER

Drop table #tmpSF

-- Turn NOCOUNT back off

print N'--- Ending SF_RefreshAll. Operation successful.'
set @LogMessage = 'Ending - Operation Successful.' 
exec SF_Logger @SPName,N'Successful', @LogMessage
set NOCOUNT OFF
return 0


ERR_HANDLER:
-- If we encounter an error creating the view, then indicate by returning 1
Drop table #tmpSF

set @LogMessage = 'Ending - Operation Failed.' 
exec SF_Logger @SPName,N'Failed', @LogMessage
-- Turn NOCOUNT back off
print N'--- Ending SF_RefreshAll. Operation failed.'
set @LogMessage = 'Ending - Operation Failed.'
exec SF_Logger @SPName, N'Failed', @LogMessage
RAISERROR ('--- Ending SF_RefreshAll. Operation FAILED.',16,1)
set NOCOUNT OFF
return 1
go

-- =============================================
-- Create procedure SF_Replicate3
-- To Use:
-- 1. Make sure before executing that you are adding this stored procedure to your salesforce backups database
-- 2. If needed, modify the @ProgDir on line 28 for the directory containing the DBAmp.exe program
-- 3. Execute this script to add the SF_Replicate3 proc to the salesforce backups database
-- =============================================
IF EXISTS (SELECT name
	   FROM   sysobjects
	   WHERE  name = N'SF_Replicate3'
	   AND 	  type = 'P')
    DROP PROCEDURE SF_Replicate3
GO

CREATE PROCEDURE SF_Replicate3
	@table_server sysname,
	@table_name sysname,
	@options nvarchar(255) = NULL
AS
-- Parameters: @table_server           - Salesforce Linked Server name (i.e. SALESFORCE)
--             @table_name             - Salesforce object to copy (i.e. Account)


declare @Result 	int
declare @Command 	nvarchar(4000)
declare @time_now	char(8)
set NOCOUNT ON

print '--- Starting SF_Replicate3 for ' + @table_name + ' ' +  dbo.SF_Version()
declare @delim_table_name sysname
declare @prev_table sysname
declare @delim_prev_table sysname
declare @server sysname
declare @database sysname
declare @LogMessage nvarchar(max)
declare @SPName nvarchar(50)
set @SPName = 'SF_Replicate3:' + CONVERT(nvarchar(255), NEWID(), 20)
set @LogMessage = 'Parameters: ' + @table_server + ' ' + @table_name + ' ' + ISNULL(@options, ' ') + ' Version: ' +  dbo.SF_Version()
exec SF_Logger @SPName, N'Starting', @LogMessage

-- Put delimeters around names so we can name tables User, etc...
set @delim_table_name = '[' + @table_name + ']'
set @prev_table = @table_name + '_Previous' + CONVERT(nvarchar(30), GETDATE(), 126) 
set @prev_table = REPLACE(@prev_table, '-', '')
set @prev_table = REPLACE(@prev_table, ':', '')
set @prev_table = REPLACE(@prev_table, '.', '')
set @delim_prev_table = '[' + @prev_table + ']'

-- Determine whether the local table and the previous copy exist
declare @table_exist int
declare @prev_exist int

set @table_exist = 0
set @prev_exist = 0;
IF EXISTS (SELECT 1
    FROM INFORMATION_SCHEMA.TABLES
    WHERE TABLE_TYPE='BASE TABLE' 
    AND TABLE_NAME=@table_name)
        set @table_exist = 1
IF (@@ERROR <> 0) GOTO ERR_HANDLER

IF EXISTS (SELECT 1
    FROM INFORMATION_SCHEMA.TABLES
    WHERE TABLE_TYPE='BASE TABLE' 
    AND TABLE_NAME=@prev_table)
        set @prev_exist = 1
IF (@@ERROR <> 0) GOTO ERR_HANDLER

-- Get the sessionId from DBAmp. This also tests connectivity to salesforce.com
declare @sql nvarchar(4000)
declare @parmlist nvarchar(512)

if @table_exist = 1
begin
	-- Make sure that the table doesn't have any keys defined
	IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    		   WHERE CONSTRAINT_TYPE = 'FOREIGN KEY' AND TABLE_NAME=@table_name)
        begin
 	   Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
	   print @time_now + ': Error: The table contains foreign keys and cannot be replicated.'
	   set @LogMessage = 'Error: The table contains foreign keys and cannot be replicated.'
	   exec SF_Logger @SPName, N'Message', @LogMessage
	   GOTO ERR_HANDLER
	end
end

-- If the previous table exists, drop it
Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
print @time_now + ': Drop ' + @prev_table + ' if it exists.'
set @LogMessage = 'Drop ' + @prev_table + ' if it exists.'
exec SF_Logger @SPName, N'Message', @LogMessage
if (@prev_exist = 1)
        exec ('Drop table ' + @delim_prev_table)
IF (@@ERROR <> 0) GOTO ERR_HANDLER

-- Create an empty local table with the current structure of the Salesforce object
Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
print @time_now + ': Create ' + @prev_table + ' with new structure.'
set @LogMessage = 'Create ' + @prev_table + ' with new structure.'
exec SF_Logger @SPName, N'Message', @LogMessage

begin try
exec ('Select Top 0 * into ' + @delim_prev_table + ' from ' + @table_server + '...' + @delim_table_name )
end try
begin catch
	Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
	print @time_now + ': Error: Salesforce table does not exist: ' + @table_name
	set @LogMessage = 'Error: Salesforce table does not exist: ' + @table_name
	exec SF_Logger @SPName, N'Message', @LogMessage
	print @time_now +
		': Error: ' + ERROR_MESSAGE();
	set @LogMessage = 'Error: ' + ERROR_MESSAGE()
	exec SF_Logger @SPName, N'Message', @LogMessage
	GOTO ERR_HANDLER
end catch

exec ('Insert into ' + @delim_prev_table + ' select * from openquery(' + @table_server + ',''Select * from ' + @table_name + '  '')')
IF (@@ERROR <> 0) GOTO RESTORE_ERR_HANDLER

declare @primarykey_exists as int
set @primarykey_exists = 0

if @table_exist = 1
begin
	-- Check to see if the table had a primary key defined
	IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    		   WHERE CONSTRAINT_TYPE = 'PRIMARY KEY' AND TABLE_NAME=@table_name )
    begin
		Set @primarykey_exists = 1
	end
end

-- Change for V2.14.2:  Always create primary key
Set @primarykey_exists = 1

-- If the local table exists, drop it
Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
print @time_now + ': Drop ' + @table_name + ' if it exists.'
set @LogMessage = 'Drop ' + @table_name + ' if it exists.'
exec SF_Logger @SPName, N'Message', @LogMessage
if (@table_exist = 1)
	exec ('Drop table ' + @delim_table_name)
IF (@@ERROR <> 0) GOTO ERR_HANDLER

-- Backup previous table into current
Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
print @time_now + ': Rename previous table from ' + @prev_table + ' to ' + @table_name
set @LogMessage = 'Rename previous table from ' + @prev_table + ' to ' + @table_name
exec SF_Logger @SPName, N'Message', @LogMessage
exec sp_rename @prev_table, @table_name
IF (@@ERROR <> 0) GOTO ERR_HANDLER

declare @totalrows int 
set @totalrows = 0
select @sql = 'Select @rowscopiedOUT = count(Id) from ' + @delim_table_name
select @parmlist = '@rowscopiedOUT int OUTPUT'
exec sp_executesql @sql, @parmlist, @rowscopiedOUT = @totalrows OUTPUT

Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
print @time_now + ': ' + Cast(@totalrows AS nvarchar(10)) + ' rows copied.'
set @LogMessage = @time_now + ': ' + Cast(@totalrows AS nvarchar(10)) + ' rows copied.'
exec SF_Logger @SPName, N'Message', @LogMessage

-- Recreate Primary Key is needed
Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
print @time_now + ': Create primary key on ' + @table_name
set @LogMessage = 'Create primary key on ' + @table_name
exec SF_Logger @SPName, N'Message', @LogMessage
if (@primarykey_exists = 1)
   -- Add Id as Primary Key
   exec ('Alter table ' + @delim_table_name + ' Add Constraint PK_' + @table_name + '_Id Primary Key NONCLUSTERED (Id) ')
IF (@@ERROR <> 0) GOTO ERR_HANDLER

print '--- Ending SF_Replicate3. Operation successful.'
set @LogMessage = 'Ending - Operation Successful.'
exec SF_Logger @SPName, N'Successful', @LogMessage
set NOCOUNT OFF
return 0

RESTORE_ERR_HANDLER:
print('--- Ending SF_Replicate3. Operation FAILED.')
set @LogMessage = 'Ending - Operation Failed.'
exec SF_Logger @SPName, N'Failed', @LogMessage
RAISERROR ('--- Ending SF_Replicate3. Operation FAILED.',16,1)
set NOCOUNT OFF
return 1

ERR_HANDLER:
print('--- Ending SF_Replicate3. Operation FAILED.')
set @LogMessage = 'Ending - Operation Failed.'
exec SF_Logger @SPName, N'Failed', @LogMessage	
RAISERROR ('--- Ending SF_Replicate3. Operation FAILED.',16,1)
set NOCOUNT OFF
return 1
GO


-- =============================================
-- Create procedure SF_ReplicateIAD
-- To Use:
-- 1. Make sure before executing that you are adding this stored procedure to your salesforce backups database
-- 2. If needed, modify the @ProgDir on line 28 for the directory containing the DBAmp.exe program
-- 3. Execute this script to add the SF_Replicate proc to the salesforce backups database
-- =============================================
IF EXISTS (SELECT name
	   FROM   sysobjects
	   WHERE  name = N'SF_ReplicateIAD'
	   AND 	  type = 'P')
    DROP PROCEDURE SF_ReplicateIAD
GO

CREATE PROCEDURE [dbo].[SF_ReplicateIAD]
		@table_server sysname,
	@table_name sysname,
	@options	nvarchar(255) = NULL

AS
-- Parameters: @table_server           - Salesforce Linked Server name (i.e. SALESFORCE)
--             @table_name             - Salesforce object to copy (i.e. Account)

-- @ProgDir - Directory containing the DBAmp.exe. Defaults to the DBAmp program directory
-- If needed, modify this for your installation
declare @ProgDir   	varchar(250) 
set @ProgDir = 'C:\"Program Files"\DBAmp\'

declare @Result 	int
declare @Command 	nvarchar(4000)
declare @time_now	char(8)
set NOCOUNT ON

print '--- Starting SF_ReplicateIAD for ' + @table_name + ' ' +  dbo.SF_Version()
declare @LogMessage nvarchar(max)
declare @SPName nvarchar(50)
set @SPName = 'SF_ReplicateIAD:' + Convert(nvarchar(255), NEWID(), 20)
set @LogMessage = 'Parameters: ' + @table_server + ' ' + @table_name + ' ' + ISNULL(@options, ' ') + ' Version: ' +  dbo.SF_Version()
Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
print @time_now + ': ' + @LogMessage
exec SF_Logger @SPName, N'Starting',@LogMessage

declare @delim_table_name sysname
declare @prev_table sysname
declare @delim_prev_table sysname
declare @delete_table sysname
declare @delim_delete_table sysname
declare @server sysname
declare @database sysname
declare @UsingFiles int
set @UsingFiles = 0
declare @EndingMessageThere int
set @EndingMessageThere = 0

-- Error out on big objects
declare @isBigObject int
set @isBigObject = 0
exec SF_IsBigObject @table_name, @isBigObject Output

if (@isBigObject = 1)
Begin
	Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
	print @time_now + ': Error: Big Objects are not supported with SF_ReplicateIAD ' 
    set @LogMessage = 'Error: Big Objects are not supported with SF_ReplicateIAD'
    exec SF_Logger @SPName, N'Message', @LogMessage
    GOTO ERR_HANDLER
End

Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
print @time_now + ': DBAmpNet2 is being used with queryAll.'
set @LogMessage = 'DBAmpNet2 is being used with queryAll.'
exec SF_Logger @SPName, N'Message', @LogMessage
if @options is null or @options = ''
Begin
	set @options = 'queryall'
end
Else
Begin
	set @options = @options + ', queryall'
End



-- Put delimeters around names so we can name tables User, etc...
set @delim_table_name = '[' + @table_name + ']'
set @prev_table = @table_name + '_Previous' + CONVERT(nvarchar(30), GETDATE(), 126) 
set @prev_table = REPLACE(@prev_table, '-', '')
set @prev_table = REPLACE(@prev_table, ':', '')
set @prev_table = REPLACE(@prev_table, '.', '')
set @delim_prev_table = '[' + @prev_table + ']'
set @delete_table = @table_name + '_DeleteIAD'
set @delim_delete_table = '[' + @delete_table + ']'

-- Determine whether the local table and the previous copy exist
declare @table_exist int
declare @prev_exist int
declare @delete_exist int

set @table_exist = 0
set @prev_exist = 0;
set @delete_exist = 0;

IF EXISTS (SELECT 1
    FROM INFORMATION_SCHEMA.TABLES
    WHERE TABLE_TYPE='BASE TABLE' 
    AND TABLE_NAME=@table_name)
        set @table_exist = 1
IF (@@ERROR <> 0) GOTO ERR_HANDLER

IF EXISTS (SELECT 1
    FROM INFORMATION_SCHEMA.TABLES
    WHERE TABLE_TYPE='BASE TABLE' 
    AND TABLE_NAME=@prev_table)
        set @prev_exist = 1
IF (@@ERROR <> 0) GOTO ERR_HANDLER

IF EXISTS (SELECT 1
    FROM INFORMATION_SCHEMA.TABLES
    WHERE TABLE_TYPE='BASE TABLE' 
    AND TABLE_NAME=@delete_table)
        set @delete_exist = 1
IF (@@ERROR <> 0) GOTO ERR_HANDLER

if @table_exist = 1
begin
	-- Make sure that the table doesn't have any keys defined
	IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    		   WHERE CONSTRAINT_TYPE = 'FOREIGN KEY' AND TABLE_NAME=@table_name )
        begin
 	   Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
	   print @time_now + ': Error: The table contains foreign keys and cannot be replicated.'
	   set @LogMessage = 'Error: The table contains foreign keys and cannot be replicated.'
	   exec SF_Logger @SPName, N'Message', @LogMessage
	   GOTO ERR_HANDLER
	end
end

-- If the previous table exists, drop it
Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
print @time_now + ': Drop ' + @prev_table + ' if it exists.'
set @LogMessage = 'Drop ' + @prev_table + ' if it exists.'
exec SF_Logger @SPName, N'Message', @LogMessage
if (@prev_exist = 1)
        exec ('Drop table ' + @delim_prev_table)
IF (@@ERROR <> 0) GOTO ERR_HANDLER

-- If the delete table exists, drop it
Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
print @time_now + ': Drop ' + @delete_table + ' if it exists.'
set @LogMessage = 'Drop ' + @delete_table + ' if it exists.'
exec SF_Logger @SPName, N'Message', @LogMessage
if (@delete_exist = 1)
        exec ('Drop table ' + @delim_delete_table)
IF (@@ERROR <> 0) GOTO ERR_HANDLER


-- Create an empty local table with the current structure of the Salesforce object
Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
print @time_now + ': Create ' + @prev_table + ' with new structure.'
set @LogMessage = 'Create ' + @prev_table + ' with new structure.'
exec SF_Logger @SPName, N'Message', @LogMessage

begin try
exec ('Select Top 0 * into ' + @delim_prev_table + ' from ' + @table_server + '...' + @delim_table_name )
end try
begin catch
	Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
	print @time_now + ': Error: Salesforce table does not exist: ' + @table_name
	set @LogMessage = 'Error: Salesforce table does not exist: ' + @table_name
	exec SF_Logger @SPName, N'Message', @LogMessage
	print @time_now +
		': Error: ' + ERROR_MESSAGE();
	set @LogMessage = 'Error: ' + ERROR_MESSAGE()
	exec SF_Logger @SPName, N'Message', @LogMessage
	GOTO ERR_HANDLER
end catch

-- Make sure there is an IsDeleted column
IF NOT EXISTS (SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE COLUMN_NAME='IsDeleted' 
    AND TABLE_NAME=@prev_table)
BEGIN
   Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
   print @time_now + ': Error: The table does not contain the required IsDeleted column.' 
   set @LogMessage = 'Error: The table does not contain the required IsDeleted column.'
   exec SF_Logger @SPName, N'Message', @LogMessage
   GOTO ERR_HANDLER
END


-- Retrieve current server name and database
select @server = @@servername, @database = DB_NAME()
SET @server = CAST(SERVERPROPERTY('ServerName') AS sysname) 

If exists(select Data
	from SF_Split(SUBSTRING(@options, 1, 1000), ',', 1) 
	where Data like '%bulkapi%' or Data like '%pkchunk%')
	Begin
		set @UsingFiles = 1
		Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
		print @time_now + ': Run the DBAmpNet2.exe program.' 
		set @LogMessage = 'Run the DBAmpNet2.exe program.'
		exec SF_Logger @SPName, N'Message', @LogMessage
		set @Command = @ProgDir + 'DBAmpNet2.exe Export' 
	End
	else
	Begin
		Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
		print @time_now + ': Run the DBAmpNet2.exe program.' 
		set @LogMessage = 'Run the DBAmpNet2.exe program.'
		exec SF_Logger @SPName, N'Message', @LogMessage
		set @Command = @ProgDir + 'DBAmpNet2.exe Exportsoap'
	End

if (@options is not null)
begin
	set @Command = @Command + ' "' + 'Replicate:' + Replace(@options, ' ', '') + '" '
end
Else 
Begin
	set @Command = @Command + ' "' + 'Replicate' + '" '
End

set @Command = @Command + ' "' + @prev_table + '" '
set @Command = @Command + ' "' + @server + '" '
set @Command = @Command + ' "' + @database + '" '
set @Command = @Command + ' "' + @table_server + '" '

-- Create temp table to hold output
declare @errorlog table (line varchar(255))

begin try
insert into @errorlog
	exec @Result = master..xp_cmdshell @Command
end try
begin catch
   print 'Error occurred running the DBAmp.exe program'	
	Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
	print @time_now + ': Error occurred running the DBAmp.exe program'	
	set @LogMessage = 'Error occurred running the DBAmp.exe program'
	exec SF_Logger @SPName, N'Message', @LogMessage
	print @time_now +
		': Error: ' + ERROR_MESSAGE();
		set @LogMessage = 'Error: ' + ERROR_MESSAGE()
		exec SF_Logger @SPName, N'Message', @LogMessage
		
     -- Roll back any active or uncommittable transactions before
     -- inserting information in the ErrorLog.
     IF XACT_STATE() <> 0
     BEGIN
         ROLLBACK TRANSACTION;
     END
    
  set @Result = -1
end catch

if @@ERROR <> 0
   set @Result = -1

-- print output to msgs
declare @line varchar(255)
declare @printCount int
Set @printCount = 0

DECLARE tables_cursor CURSOR FOR SELECT line FROM @errorlog
OPEN tables_cursor
FETCH NEXT FROM tables_cursor INTO @line
WHILE (@@FETCH_STATUS <> -1)
BEGIN
   if @line is not null 
	begin
	print @line
	if CHARINDEX('DBAmpNet2 Operation successful.',@line) > 0
	begin
		set @EndingMessageThere = 1
	end
	exec SF_Logger @SPName,N'Message', @line
	Set @printCount = @printCount + 1
	end
   FETCH NEXT FROM tables_cursor INTO @line
END
deallocate tables_cursor


if @Result = -1 or @printCount = 0 or @printCount = 1 or (@EndingMessageThere = 0 and @UsingFiles = 1)
BEGIN
  	Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
	print @time_now + ': Error: DBAmp.exe was unsuccessful.'
	set @LogMessage = 'Error: DBAmp.exe was unsuccessful.'
	exec SF_Logger @SPName, N'Message', @LogMessage
	print @time_now + ': Error: Command string is ' + @Command
	set @LogMessage = 'Error: Command string is ' + @Command
	exec SF_Logger @SPName, N'Message', @LogMessage
  	GOTO RESTORE_ERR_HANDLER
END

-- If the local table currently exists,
-- capture the deleted rows and
-- check to see if the column structure is the same
declare @diff_schema_count int
declare @columnList nvarchar(max)
declare @colname	nvarchar(500)
declare @sql nvarchar(max)

if @table_exist = 1
BEGIN
	-- Build a table of the deleted rows
	BEGIN TRY
		-- Create an empty local table with the current structure of the Salesforce object
		Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
		print @time_now + ': Create ' + @delete_table + ' with new structure.'
		set @LogMessage = 'Create ' + @delete_table + ' with new structure.'
		exec SF_Logger @SPName, N'Message', @LogMessage
		exec ('Select Top 0 * into ' + @delim_delete_table + ' from ' +  @delim_table_name )
		
		-- Populate it
		select @sql = 'Insert ' + @delim_delete_table + ' Select * from ' + @delim_table_name
		select @sql = @sql + ' where Id not in (select Id from ' + @delim_prev_table + ')'
		exec sp_executesql @sql
		IF (@@ERROR <> 0) GOTO ERR_HANDLER
		
		-- Mark them as deleted
		exec ('Update ' + @delim_delete_table + ' set IsDeleted = ''true'' ')
	
	
		-- Get the count of records from the deleted table
		declare @deleted_count int
		declare @parmlist	nvarchar(4000)
		declare @char_count varchar(10)
		select @sql = 'Select @DeletedCountOUT = Count(*) from ' + @delim_delete_table
		select @parmlist = '@DeletedCountOUT int OUTPUT'
		exec sp_executesql @sql,@parmlist, @DeletedCountOUT=@deleted_count OUTPUT
		IF (@@ERROR <> 0) GOTO ERR_HANDLER

		-- Print number of rows in deleted table
		Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
		Select @char_count = (select CAST(@deleted_count as VARCHAR(10)))
		print @time_now + ': Identified ' + @char_count + ' hard deleted rows.'
		set @LogMessage = 'Identified ' + @char_count + ' hard deleted rows.'
		exec SF_Logger @SPName, N'Message', @LogMessage
		
		-- Check if the column structure has changed
		declare @cnt1 int
		declare @cnt2 int
		
		Select @cnt1 = Count(*) FROM INFORMATION_SCHEMA.COLUMNS v1 WHERE v1.TABLE_NAME=@prev_table 
				AND NOT EXISTS (Select COLUMN_NAME from INFORMATION_SCHEMA.COLUMNS v2 where 
				v2.TABLE_NAME=@table_name and v1.COLUMN_NAME = v2.COLUMN_NAME and v1.DATA_TYPE = v2.DATA_TYPE 
				and v1.IS_NULLABLE = v2.IS_NULLABLE and v1.ORDINAL_POSITION = v2.ORDINAL_POSITION 
				and ISNULL(v1.CHARACTER_MAXIMUM_LENGTH,0) = ISNULL(v2.CHARACTER_MAXIMUM_LENGTH,0))
		IF (@@ERROR <> 0) GOTO ERR_HANDLER
		
		Select @cnt2 = Count(*) FROM INFORMATION_SCHEMA.COLUMNS v1 WHERE v1.TABLE_NAME=@table_name
				AND NOT EXISTS (Select COLUMN_NAME from INFORMATION_SCHEMA.COLUMNS v2 where 
				v2.TABLE_NAME=@prev_table and v1.COLUMN_NAME = v2.COLUMN_NAME and v1.DATA_TYPE = v2.DATA_TYPE 
				and v1.IS_NULLABLE = v2.IS_NULLABLE and v1.ORDINAL_POSITION = v2.ORDINAL_POSITION 
				and ISNULL(v1.CHARACTER_MAXIMUM_LENGTH,0) = ISNULL(v2.CHARACTER_MAXIMUM_LENGTH,0))
		IF (@@ERROR <> 0) GOTO ERR_HANDLER
		
		set @diff_schema_count = @cnt1 + @cnt2

		if (@diff_schema_count > 0)
		begin
			Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
			print @time_now + ': Table schema has changed.'
			set @LogMessage = 'Table schema has changed.'
			exec SF_Logger @SPName, N'Message', @LogMessage

			-- Schema changed so try to build a subset of columns
			-- Build list of columns in common
			declare colname_cursor cursor for 
				SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS v1 WHERE v1.TABLE_NAME= @table_name 
				AND EXISTS (Select COLUMN_NAME from INFORMATION_SCHEMA.COLUMNS v2 
				where v2.TABLE_NAME= @prev_table 
				and v1.COLUMN_NAME = v2.COLUMN_NAME and v1.DATA_TYPE = v2.DATA_TYPE and v1.IS_NULLABLE = v2.IS_NULLABLE 
				and ISNULL(v1.CHARACTER_MAXIMUM_LENGTH,0)= ISNULL(v2.CHARACTER_MAXIMUM_LENGTH,0) and v1.TABLE_SCHEMA = v2.TABLE_SCHEMA)

			OPEN colname_cursor
			set @columnList = ''
			
			while 1 = 1
			begin
				fetch next from colname_cursor into @colname
				if @@error <> 0 or @@fetch_status <> 0 break
				set @columnList = @columnList + @colname + ','
			end
			close colname_cursor
			deallocate colname_cursor

			if Len(@columnList) = 0
			begin
				print @time_now + ': Error: Table schema has changed with no columns in common. Therefore the table cannot be replicated.'
				set @LogMessage = 'Error: Table schema has changed with no columns in common. Therefore the table cannot be replicated.'
				exec SF_Logger @SPName, N'Message', @LogMessage
				GOTO ERR_HANDLER
			end
							
			SET @columnList = SUBSTRING(@columnList, 1, Len(@columnList) - 1)
								
			-- Now insert the new rows
			select @sql = 'insert ' + @delim_prev_table + '(' + @columnList + ')' 
						+ ' select ' + @columnList + ' from ' + @delim_delete_table
			exec sp_executesql @sql
			IF (@@ERROR <> 0) 
			   GOTO ERR_HANDLER
		end
		else
		begin
			-- Insert deleted rows into the previous table
			select @sql = 'insert ' + @delim_prev_table + ' select * from ' + @delim_delete_table
			exec sp_executesql @sql
			IF (@@ERROR <> 0) 
			begin
			   GOTO ERR_HANDLER
			end
		end
	END TRY
	BEGIN CATCH
		Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
		print @time_now + ': Error occurred while building a table of hard deleted rows.'
		set @LogMessage = 'Error occurred while building a table of hard deleted rows.'
		exec SF_Logger @SPName, N'Message', @LogMessage
		print @time_now +
			': Error: ' + ERROR_MESSAGE();
			set @LogMessage = 'Error: ' + ERROR_MESSAGE()
			exec SF_Logger @SPName, N'Message', @LogMessage
			
		 -- Roll back any active or uncommittable transactions before
		 -- inserting information in the ErrorLog.
		 IF XACT_STATE() <> 0
		 BEGIN
			 ROLLBACK TRANSACTION;
		 END
		 goto ERR_HANDLER
	END CATCH	
end

set @options = Lower(@options)

BEGIN TRY
    BEGIN TRANSACTION;
	If ISNULL(@options, ' ') like '%nodrop%'
	Begin
		if (@table_exist = 0)
		Begin
			Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
			print @time_now + ': Rename previous table from ' + @prev_table + ' to ' + @table_name
			set @LogMessage = 'Rename previous table from ' + @prev_table + ' to ' + @table_name
			exec SF_Logger @SPName, N'Message', @LogMessage
			exec sp_rename @prev_table, @table_name
		End
		else
		Begin
			exec SF_CopyNoDrop @prev_table, @table_name
		End
	End
	Else
	Begin
		-- If the local table exists, drop it
		Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
		print @time_now + ': Drop ' + @table_name + ' if it exists.'
		set @LogMessage = 'Drop ' + @table_name + ' if it exists.'
		exec SF_Logger @SPName, N'Message', @LogMessage
		if (@table_exist = 1)
			exec ('Drop table ' + @delim_table_name)

		-- Backup previous table into current
		Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
		print @time_now + ': Rename previous table from ' + @prev_table + ' to ' + @table_name
		set @LogMessage = 'Rename previous table from ' + @prev_table + ' to ' + @table_name
		exec SF_Logger @SPName, N'Message', @LogMessage
		exec sp_rename @prev_table, @table_name
	End
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
	If ISNULL(@options, ' ') like '%nodrop%'
	Begin
		Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
		print @time_now + ': Error occurred copying records to the table.'
		set @LogMessage = 'Error occurred copying records to the table.'
		exec SF_Logger @SPName, N'Message', @LogMessage
		print @time_now +
			': Error: ' + ERROR_MESSAGE();
		set @LogMessage = 'Error: ' + ERROR_MESSAGE()
		exec SF_Logger @SPName, N'Message', @LogMessage
	End
	Else
	Begin
		Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
		print @time_now + ': Error occurred dropping and renaming the table.'
		set @LogMessage = 'Error occurred dropping and renaming the table.'
		exec SF_Logger @SPName, N'Message', @LogMessage
		print @time_now +
			': Error: ' + ERROR_MESSAGE();
		set @LogMessage = 'Error: ' + ERROR_MESSAGE()
		exec SF_Logger @SPName, N'Message', @LogMessage
	End

     -- Roll back any active or uncommittable transactions before
     -- inserting information in the ErrorLog.
     IF XACT_STATE() <> 0
     BEGIN
         ROLLBACK TRANSACTION;
     END
     goto ERR_HANDLER
END CATCH

--Clean up any previous table
IF EXISTS (SELECT 1
    FROM INFORMATION_SCHEMA.TABLES
    WHERE TABLE_TYPE='BASE TABLE'
    AND TABLE_NAME=@prev_table)
begin
   exec ('Drop table ' + @prev_table)
end

-- Recreate Primary Key is needed
If ISNULL(@options, ' ') not like '%nodrop%' OR @table_exist = 0
BEGIN
	BEGIN TRY
		Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
		print @time_now + ': Create primary key on ' + @table_name
		set @LogMessage = 'Create primary key on ' + @table_name
		exec SF_Logger @SPName, N'Message', @LogMessage
		-- Add Id as Primary Key
		exec ('Alter table ' + @delim_table_name + ' Add Constraint PK_' + @table_name + '_Id Primary Key NONCLUSTERED (Id) ')
	END TRY
	BEGIN CATCH
		Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
		print @time_now + ': Error occurred creating primary key for table.'
		set @LogMessage = 'Error occurred creating primary key for table.'
		exec SF_Logger @SPName, N'Message', @LogMessage
		print @time_now +
			': Warning: ' + ERROR_MESSAGE();
		set @LogMessage = 'Warning: ' + ERROR_MESSAGE()
		exec SF_Logger @SPName, N'Message', @LogMessage
		
		 -- Roll back any active or uncommittable transactions before
		 -- inserting information in the ErrorLog.
		 IF XACT_STATE() <> 0
		 BEGIN
			 ROLLBACK TRANSACTION;
		 END
		 --goto ERR_HANDLER
	END CATCH
END

print '--- Ending SF_ReplicateIAD. Operation successful.'
set @LogMessage = 'Ending - Operation Successful.' 
exec SF_Logger @SPName,N'Successful', @LogMessage
set NOCOUNT OFF
return 0

RESTORE_ERR_HANDLER:
print('--- Ending SF_ReplicateIAD. Operation FAILED.')
set @LogMessage = 'Ending - Operation Failed.' 
exec SF_Logger @SPName, N'Failed',@LogMessage
RAISERROR ('--- Ending SF_ReplicateIAD. Operation FAILED.',16,1)
set NOCOUNT OFF
return 1

ERR_HANDLER:
print('--- Ending SF_ReplicateIAD. Operation FAILED.')
set @LogMessage = 'Ending - Operation Failed.' 
exec SF_Logger @SPName,N'Failed', @LogMessage
RAISERROR ('--- Ending SF_ReplicateIAD. Operation FAILED.',16,1)
set NOCOUNT OFF
return 1
Go

-- =============================================
-- Create procedure SF_ReplicateAll
--
-- This stored procedure will replicate every Salesforce object (including custom objects).
-- If it encounters an error replicating an object, it will note that in the messages 
-- and continue to the next object.
--
-- To Use:
-- 1. Modify the use statement on line 6 to point to your salesforce backup database
-- 2. Execute this script to add the SF_ReplicateAll proc to the salesforce backups database
-- 3. Calling example:  exec SF_ReplicateAll 'SALESFORCE'
-- =============================================
IF EXISTS (SELECT name 
	   FROM   sysobjects 
	   WHERE  name = N'SF_ReplicateAll' 
	   AND 	  type = 'P')
    DROP PROCEDURE SF_ReplicateAll
GO


CREATE PROCEDURE SF_ReplicateAll 
	@table_server sysname 
AS
-- Input Parameter @table_server - Linked Server Name
print N'--- Starting SF_ReplicateAll' + ' ' +  dbo.SF_Version()
set NOCOUNT ON
declare @LogMessage nvarchar(max)
declare @SPName nvarchar(50)
set @SPName = 'SF_ReplicateAll:' + Convert(nvarchar(255), NEWID(), 20)
set @LogMessage = 'Parameters: ' + @table_server + ' Version: ' +  dbo.SF_Version()
exec SF_Logger @SPName, N'Starting',@LogMessage

Create Table #tmpSF ([Name] sysname not null, Queryable varchar(5) not null)
declare @sql nvarchar(4000)
set @sql = 'Select Name,Queryable from ' + @table_server + '...sys_sfobjects'
Insert #tmpSF EXEC (@sql)
if (@@error <> 0) goto ERR_HANDLER

declare @tn sysname
declare @queryable varchar(5)
declare @ReplicateError int
Set @ReplicateError = 0

declare tbls_cursor cursor local fast_forward
for select [Name],Queryable from #tmpSF


open tbls_cursor

while 1 = 1
begin
   fetch next from tbls_cursor into @tn, @queryable
   if @@error <> 0 or @@fetch_status <> 0 break

-- print @tn + ' ' + @queryable
   if @queryable = 'false' CONTINUE
   
   -- To skip tables, add a statement similiar to the statement below
   -- if @tn = 'SolutionHistory' CONTINUE
   
   -- The IdeaComment table must now be skipped.
   -- With API 24.0, sf does not allow select all rows for that table.
   if @tn = 'IdeaComment' CONTINUE
   
   -- The UserRecordAccess table must now be skipped.
   -- With API 24.0, sf does not allow select all rows for that table.
   if @tn = 'UserRecordAccess' CONTINUE
   
   -- The vote table must now be skipped.
   -- With API 17.0, sf does not allow select all rows for that table.
   if @tn = 'Vote' CONTINUE
   
   -- Skip these tables due to api restriction
   if @tn='FieldDefinition' CONTINUE
   if @tn='ListViewChartInstance' CONTINUE

   -- The ContentDocumentLink table must now be skipped.
   -- With API 21.0, sf does not allow select all rows for that table.
   if @tn = 'ContentDocumentLink' CONTINUE
 
   -- Skip the EventLogFile table due to size of the blobs
   if @tn = 'EventLogFile' CONTINUE

    -- The FeedItem table must now be skipped.
   -- With API 21.0, sf does not allow select all rows for that table.
   if @tn = 'FeedItem' CONTINUE

   -- Feed tables consume huge quantities of API calls
   -- Therefore, we skip them. Comment out the lines if you would like to include them.
   if LEFT(@tn,4) = 'Feed' CONTINUE
   if RIGHT(@tn,4) = 'Feed' CONTINUE
   
   -- Skip all APEX table because they have little use
   if LEFT(@tn,4) = 'Apex' CONTINUE
   
   -- Knowledge _kav tables cannot handle a select without where clause so we skip them
   if RIGHT(@tn,4) = '_kav' CONTINUE
   if @tn = 'KnowledgeArticleVersion' CONTINUE
   
   if @tn = 'PlatformAction' CONTINUE
   if @tn = 'CollaborationGroupRecord' CONTINUE
   
   -- Skip offending data.com tables
   if @tn = 'DatacloudDandBCompany' CONTINUE
   if @tn = 'DcSocialProfile' CONTINUE
   if @tn = 'DataCloudConnect' CONTINUE
   if @tn = 'DatacloudCompany' CONTINUE
   if @tn = 'DatacloudContact' CONTINUE
   if @tn = 'DatacloudSocialHandle' CONTINUE
   if @tn = 'DcSocialProfileHandle' CONTINUE
   if @tn = 'DatacloudAddress' CONTINUE
   if @tn = 'OwnerChangeOptionInfo' CONTINUE
   
   if @tn = 'ContentFolderMember' CONTINUE   
   if @tn = 'EntityParticle' CONTINUE  
   if @tn = 'EntityDescription' CONTINUE 
   if @tn = 'EntityDefinition' CONTINUE   
   if @tn = 'Publisher' CONTINUE
   if @tn = 'RelationshipDomain' CONTINUE   
   if @tn = 'RelationshipInfo' CONTINUE  
   if @tn = 'ServiceFieldDataType' CONTINUE
   if @tn = 'UserEntityAccess' CONTINUE
   if @tn = 'PicklistValueInfo' CONTINUE
   if @tn = 'SearchLayout' CONTINUE
   if @tn = 'UserFieldAccess' CONTINUE
   if @tn= 'ContentFolderItem' CONTINUE
   if @tn= 'DataType' CONTINUE
   
   if @tn = 'FieldPermissions' CONTINUE
   if @tn = 'DataStatistics' CONTINUE
   if @tn = 'FlexQueueItem' CONTINUE
   if @tn = 'ContentHubItem' continue
   if @tn = 'OwnerChangeOptionInfo' continue
   if @tn = 'OutgoingEmail' continue
   if @tn = 'OutgoingEmailRelation' continue
   if @tn = 'NetworkUserHistoryRecent' continue
 
	-- tables not queryable summer 2018
   if @tn = 'AppTabMember' continue
   if @tn = 'ColorDefinition' continue
   if @tn = 'IconDefinition' continue
   
   
      -- Skip External objects because we cant select all rows
   if RIGHT(@tn,3) = '__x' CONTINUE 
   
   -- Skip big objects
   declare @isBigObject int
   set @isBigObject = 0
   exec SF_IsBigObject @tn, @isBigObject Output

   if (@isBigObject = 1)
	  continue
	  
   if exists(Select TableName from TablesToSkip where @tn like TableName)
	  continue
	  
   -- Call SF_Replicate for this table
   begin try
      exec SF_Replicate @table_server, @tn
   end try
   begin catch
      print 'Error: SF_Replicate failed for table ' + @tn
	  set @LogMessage = 'Error: SF_Replicate failed for table ' + @tn
	  exec SF_Logger @SPName, N'Message', @LogMessage
 	 print 
		'Error ' + CONVERT(VARCHAR(50), ERROR_NUMBER()) +
		', Severity ' + CONVERT(VARCHAR(5), ERROR_SEVERITY()) +
		', State ' + CONVERT(VARCHAR(5), ERROR_STATE()) + 
		', Line ' + CONVERT(VARCHAR(5), ERROR_LINE());
	 print 
		ERROR_MESSAGE();
		set @LogMessage = ERROR_MESSAGE()
		-- Comment out to avoid issues in log table
		-- exec SF_Logger @SPName, N'Message', @LogMessage 
		
     -- Roll back any active or uncommittable transactions before
     -- inserting information in the ErrorLog.
     IF XACT_STATE() <> 0
     BEGIN
         ROLLBACK TRANSACTION;
     END
     set @ReplicateError = 1
   end catch
 end

close tbls_cursor
deallocate tbls_cursor

-- If one of the tables failed to replicate jump to error handler
if @ReplicateError = 1 goto ERR_HANDLER

Drop table #tmpSF

set @LogMessage = 'Ending - Operation Successful.' 
exec SF_Logger @SPName, N'Successful',@LogMessage
-- Turn NOCOUNT back off
set NOCOUNT OFF
print N'--- Ending SF_ReplicateAll. Operation successful.'
return 0


ERR_HANDLER:
-- If we encounter an error, then indicate by returning 1
Drop table #tmpSF

set @LogMessage = 'Ending - Operation Failed.' 
exec SF_Logger @SPName,N'Successful', @LogMessage
-- Turn NOCOUNT back off
set NOCOUNT OFF
print N'--- Ending SF_ReplicateAll. Operation failed.'
RAISERROR ('--- Ending SF_ReplicateAll. Operation FAILED.',16,1)
return 1
go


-- =============================================
-- Create procedure SF_UploadFile
-- To Use:
-- 1. Make sure before executing that you are adding this stored procedure to your salesforce backups database
-- 2. If needed, modify the @ProgDir on line 28 for the directory containing the DBAmp.exe program
-- 3. Execute this script to add the SF_UploadFile proc to the salesforce backups database
-- =============================================
IF EXISTS (SELECT name
	   FROM   sysobjects
	   WHERE  name = N'SF_UploadFile'
	   AND 	  type = 'P')
    DROP PROCEDURE SF_UploadFile
GO

CREATE PROCEDURE SF_UploadFile
	@table_server sysname,
	@table_name sysname,
        @id nchar(18),
	@file_name nvarchar(512)
AS
-- Parameters: @table_server           	- Salesforce Linked Server name (i.e. SALESFORCE)
--             @table_name             	- SQL Table containing Body field to store file in
--             @id			- Salesforce object id to upload file to
--             @file_name		- File name to upload 
--
-- @ProgDir - Directory containing the DBAmp.exe. Defaults to the DBAmp program directory
-- If needed, modify this for your installation
declare @ProgDir   	varchar(250) 
set @ProgDir = 'C:\"Program Files"\DBAmp\'

declare @Result 	int
declare @Command 	nvarchar(4000)

print '--- Starting SF_UploadFile for ' + @table_name + ' ' +  dbo.SF_Version()
declare @server sysname
declare @database sysname

set NOCOUNT ON

-- Retrieve current server name and database
select @server = @@servername, @database = DB_NAME()
SET @server = CAST(SERVERPROPERTY('ServerName') AS sysname) 


-- Execute DBAmp.exe to bulk delete objects from Salesforce
print 'Run the DBAmp.exe program.' 
set @Command = @ProgDir + 'DBAmp.exe Upload ' + @table_name 
set @Command = @Command + ' "' + @server + '" '
set @Command = @Command + ' "' + @database + '" '
set @Command = @Command + ' "' + @table_server + '" '
set @Command = @Command + ' "' + @file_name + '" '
set @Command = @Command + ' "' + @id + '" '

exec @Result = master..xp_cmdshell @Command
if @Result = -1
BEGIN
  	Print 'Error: DBAmp.exe was unsuccessful.'
  	GOTO RESTORE_ERR_HANDLER
END

print '--- Ending SF_UploadFile. Operation successful.'
set NOCOUNT OFF
return 0

RESTORE_ERR_HANDLER:
set NOCOUNT OFF
print '--- Ending SF_UploadFile. Operation FAILED.'
return 1

ERR_HANDLER:
set NOCOUNT OFF
print '--- Ending SF_UploadFile. Operation FAILED.'
return 1
GO

-- =============================================
-- Create procedure SF_DropKeys
-- To Use:
-- 1. Make sure before executing that you are adding this stored procedure to your salesforce backups database
-- 2. Execute this script to add the SF_DropKeys proc to the salesforce backups database
-- NOTE: For V2.14.2 the proc no longer drops the primary key
-- =============================================
IF EXISTS (SELECT name 
	   FROM   sysobjects 
	   WHERE  name = N'SF_DropKeys' 
	   AND 	  type = 'P')
    DROP PROCEDURE SF_DropKeys
GO

CREATE PROCEDURE SF_DropKeys @table_server sysname 
AS

declare @time_now	char(8)
Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
print @time_now + ': Starting SF_DropKeys.' + ' ' +  dbo.SF_Version()

DECLARE @table sysname
DECLARE @ftable sysname
DECLARE @fkey sysname

set NOCOUNT ON

CREATE TABLE #tempFK (
   PKTABLE_QUALIFIER sysname null,
   PKTABLE_OWNER sysname null,
   PKTABLE_NAME sysname,
   PKCOLUMN_NAME sysname,
   FKTABLE_QUALIFIER sysname null,
   FKTABLE_OWNER sysname null,
   FKTABLE_NAME sysname,
   FKCOLUMN_NAME sysname,
   KEY_SEQ smallint,
   UPDATE_RULE smallint,
   DELETE_RULE smallint,
   FK_NAME sysname null,
   PK_NAME sysname null,
   DEFERABILITY smallint)


-- Fetch all the user tables in this database that are salesforce.com tables
DECLARE curTable SCROLL CURSOR FOR 
   SELECT db.TABLE_NAME 
   FROM INFORMATION_SCHEMA.TABLES db
   WHERE db.TABLE_TYPE = 'BASE TABLE' 
ORDER BY db.TABLE_NAME

OPEN curTable

FETCH FIRST FROM curTable INTO @table

WHILE (@@FETCH_STATUS = 0)
BEGIN
   -- For each table, get the foreign and primary keys for that table 
   -- and add to our temp table of fkeys to be dropped
   INSERT INTO #tempFK exec sp_fkeys @table
   FETCH NEXT FROM curTable INTO @table
END
CLOSE curTable
DEALLOCATE curTable

-- Now go through and drop all the foreign keys
DECLARE curFK SCROLL CURSOR FOR SELECT FKTABLE_NAME, FK_NAME FROM #tempFK
OPEN curFK
FETCH FIRST FROM curFK INTO @ftable, @fkey
WHILE (@@FETCH_STATUS = 0)
BEGIN
   EXEC ('ALTER TABLE [' + @ftable + '] DROP CONSTRAINT ' + @fkey )
   if (@@error <> 0) goto ERR_HANDLER
   FETCH NEXT FROM curFK INTO @ftable, @fkey
END
CLOSE curFK
DEALLOCATE curFK


Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
print @time_now + ': Ending SF_DropKeys. Operation successful..'
set NOCOUNT OFF
return 0

ERR_HANDLER:
set NOCOUNT OFF
Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
print @time_now + ': Ending SF_DropKeys. Operation FAILED.'
RAISERROR ('--- Ending SF_DropKeys. Operation FAILED.',16,1)
return 1
GO
-- =============================================
-- Create procedure SF_CreateKeys
-- To Use:
-- 1. Make sure before executing that you are adding this stored procedure to your salesforce backups database
-- 2. Execute this script to add the SF_CreateKeys proc to the salesforce backups database
-- NOTE: As of V2.14.2 this proc does not create primary keys. Primary keys are now created by sf_replicate
-- =============================================
IF EXISTS (SELECT name 
	   FROM   sysobjects 
	   WHERE  name = N'SF_CreateKeys' 
	   AND 	  type = 'P')
    DROP PROCEDURE SF_CreateKeys
GO


CREATE PROCEDURE SF_CreateKeys 
	@table_server sysname 
AS
-- Input Parameter @table_server - Linked Server Name
set NOCOUNT ON

declare @time_now	char(8)
Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
print @time_now + ': Starting SF_CreateKeys.' + ' ' +  dbo.SF_Version()

-- Now for each table in the database that exists in Salesforce, create a Primary Key for Id
Create Table #tmpSF (TABLE_CAT sysname null, 
					TABLE_SCEM sysname null, 
					TABLE_NAME sysname, 
					TABLE_TYPE varchar(32), 
					REMARKS varchar(254))
Insert #tmpSF EXEC sp_tables_ex @table_server
if (@@error <> 0) 
	begin
	   print ERROR_MESSAGE()
	   goto BYE
	end
	
declare @tn			sysname
declare @delim_tn	sysname
declare @table_exist int
declare @sql		nvarchar(4000)

-- Now add the Foreign keys
Create Table #tmpFK (
	PKTABLE_CAT sysname null,
	PKTABLE_SCHEM sysname null,
	PKTABLE_NAME sysname null,
	PKCOLUMN_NAME sysname null,
	FKTABLE_CAT sysname null,
	FKTABLE_SCHEM sysname null,
	FKTABLE_NAME sysname null,
	FKCOLUMN_NAME sysname null,
	KEY_SEQ smallint,
	UPDATE_RULE smallint,
	DELETE_RULE smallint,
	FK_NAME sysname null,
	PK_NAME sysname null,
	DEFERRABILITY smallint)
 
Insert #tmpFK EXEC sp_foreignkeys @table_server
if (@@error <> 0) 
	begin
	   print ERROR_MESSAGE()
	   goto BYE
	end

declare keys_cursor cursor local fast_forward
for 
   select PKTABLE_NAME, PKCOLUMN_NAME, FKTABLE_NAME, FKCOLUMN_NAME, DELETE_RULE 
   from #tmpFK fk
   where PKTABLE_NAME in (Select TABLE_NAME from INFORMATION_SCHEMA.TABLES where TABLE_TYPE = 'BASE TABLE' )
	and   FKTABLE_NAME in (Select TABLE_NAME from INFORMATION_SCHEMA.TABLES where TABLE_TYPE = 'BASE TABLE' )


declare @pkTable	sysname
declare @delim_pkTable sysname
declare @pkColumn	sysname
declare @fkTable	sysname
declare @delim_fkTable sysname
declare @fkColumn	sysname
declare @deleteRule smallint

open keys_cursor

while 1 = 1
begin
	fetch next from keys_cursor into @pkTable, @pkColumn, @fkTable, @fkColumn, @deleteRule
	if @@error <> 0 or @@fetch_status <> 0 break

	-- Skip the obvious FK to the User table
	if @fkColumn = 'LastModifiedById' or @fkColumn = 'CreatedById' continue

	set @delim_fkTable = '[' + @fkTable + ']'
	set @delim_pkTable = '[' + @pkTable + ']'
	select @sql = 'Alter table ' + @delim_fkTable + ' with nocheck add Constraint FK_' + @fkTable + '_' + @fkColumn + '_' +@pkTable
	select @sql = @sql + ' Foreign Key('
	select @sql = @sql + @fkColumn + ') references ' + @delim_pkTable + '(' + @pkColumn +') '
	begin try
		exec sp_executesql @sql		
	end try
	begin catch
	   print 'Error occurred while creating a foreign key: ' + @sql 	
	  -- print ERROR_MESSAGE();
		CONTINUE
	end catch	

	-- Disable the just created foreign key
	select @sql = 'Alter table ' + @delim_fkTable + ' nocheck Constraint FK_' + @fkTable + '_' + @fkColumn + '_' +@pkTable
	begin try
		exec sp_executesql @sql		
	end try
	begin catch
	   print 'Error occurred while disabling a foreign key: ' + @sql 	
	  -- print ERROR_MESSAGE();
		CONTINUE
	end catch
end

-- Clean up
close keys_cursor
deallocate keys_cursor
Drop table #tmpFK

BYE:
Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
print @time_now + ': Ending SF_CreateKeys.'
set NOCOUNT OFF
return 0
GO

IF EXISTS (SELECT name
	   FROM   sysobjects
	   WHERE  name = N'SF_ColCompare'
	   AND 	  type = 'P')
    DROP PROCEDURE SF_ColCompare
GO

CREATE PROCEDURE SF_ColCompare
	@operation nvarchar(20), 
	@table_server sysname,
	@load_tablename	sysname 

AS

-- Input Parameter @operation - Must be either 'Insert','Upsert','Update','Delete'
-- Input Parameter @table_server - Linked Server Name
-- Input Parameter @load_tablename - Existing bulkops table
print N'--- Starting SF_ColCompare' + ' ' +  dbo.SF_Version()

-- Quick parameter check
if LOWER(@operation) not in ('insert','upsert','update','delete')
begin
	RAISERROR ('--- Ending SF_ColCompare. Error: Invalid operation parameter.',16,1)
	return 1
end

IF  not EXISTS (SELECT 1
    FROM INFORMATION_SCHEMA.TABLES
    WHERE TABLE_TYPE='BASE TABLE' 
    AND TABLE_NAME=@load_tablename)
begin
	RAISERROR ('--- Ending SF_ColCompare. Error: Table to compare does not exist.',16,1)
	return 1
end

set NOCOUNT ON

declare @base_tablename sysname
declare @work sysname
declare @sql nvarchar(4000)
declare @uscore_pos int
declare @uuc_pos int
declare @rc int

-- derive base table name from load table name
set @work = @load_tablename

-- Is this a custom table
set @uuc_pos = CHARINDEX('__c',@work)
if @uuc_pos = 0 
	begin
		set @uscore_pos = CHARINDEX('_',@work)

		if @uscore_pos = 0
			set @base_tablename = @work
		else
			set @base_tablename = SUBSTRING(@work,1,@uscore_pos-1)
	end
else
	begin
		set @base_tablename = SUBSTRING(@work,1,@uuc_pos+2)
	end

-- Create problems table
CREATE TABLE #problems (
	ErrorDesc [nvarchar](1000)
)

-- Get a temporary sffields table
CREATE TABLE #sffields(
	[ObjectName] [nvarchar](128),
	[Name] [nvarchar](128) ,
	[Type] [nvarchar](32) ,
	[SQLDefinition] [nvarchar](128),
	[Createable] [varchar](5),
	[Updateable] [varchar](5)
)

set @sql = 'Insert into #sffields '
set @sql = @sql + 'Select [ObjectName],[Name],[Type],[SQLDefinition],[Createable],[Updateable] '
set @sql = @sql + 'from '+ @table_server + '...sys_sffields'
exec (@sql)
IF (@@ERROR <> 0) GOTO ERR_HANDLER

-- Clear out columns not belonging to the base table
delete #sffields where ObjectName != @base_tablename
IF (@@ERROR <> 0) GOTO ERR_HANDLER

-- Which cols of the load table do not exist in base table
insert into #problems
select 'Salesforce object ' +@base_tablename + ' does not contain column ' + lt.COLUMN_NAME
from INFORMATION_SCHEMA.COLUMNS lt
where lt.TABLE_NAME = @load_tablename and LOWER(lt.COLUMN_NAME) != 'error' and
not exists(select * from #sffields bt where LOWER(bt.[Name]) = LOWER(lt.COLUMN_NAME))
IF (@@ERROR <> 0) GOTO ERR_HANDLER

-- Which cols of the load table exist but are not createable
if LOWER(@operation) in ('insert','upsert')
begin
	insert into #problems
	select 'Column ' +lt.COLUMN_NAME +' is not insertable into the salesforce object ' +@base_tablename
	from INFORMATION_SCHEMA.COLUMNS lt, #sffields bt
	where lt.TABLE_NAME = @load_tablename and 
		  LOWER(lt.COLUMN_NAME) != 'error' and
		  LOWER(lt.COLUMN_NAME) != 'id' and
		  LOWER(bt.[Name]) = LOWER(lt.COLUMN_NAME) and
		  bt.[Createable] = 'false'
	IF (@@ERROR <> 0) GOTO ERR_HANDLER
end
	
-- Which cols of the load table exist but are not updateable
if LOWER(@operation) in ('update')
begin
	insert into #problems
	select 'Column ' + lt.COLUMN_NAME + ' is not updateable in the salesforce object ' + @base_tablename
	from INFORMATION_SCHEMA.COLUMNS lt, #sffields bt
	where lt.TABLE_NAME = @load_tablename and 
		  LOWER(lt.COLUMN_NAME) != 'error' and
		  LOWER(lt.COLUMN_NAME) != 'id' and
		  LOWER(bt.[Name]) = LOWER(lt.COLUMN_NAME) and
		  bt.[Updateable] = 'false'
	IF (@@ERROR <> 0) GOTO ERR_HANDLER
end  

-- Were there any problems ? If so return error and print table
if EXISTS(Select * from #problems)
begin
	set @rc = 1
	select * from #problems
	print 'Problems found with ' + @load_tablename +'. See output table for details.'
end
else
begin
	set @rc = 0
	print 'No problems found with ' + @load_tablename + '.'
end

-- Return to caller
if @rc = 1
	RAISERROR ('--- Ending SF_ColCompare. Operation FAILED.',16,1)

SET NOCOUNT OFF
return @rc

ERR_HANDLER:
RAISERROR ('--- Ending SF_ColCompare. Operation FAILED.',16,1)
SET NOCOUNT OFF
return 1
GO

IF EXISTS (SELECT name
	   FROM   sysobjects
	   WHERE  name = N'SF_Generate'
	   AND 	  type = 'P')
    DROP PROCEDURE SF_Generate
GO

CREATE PROCEDURE SF_Generate
	@operation nvarchar(20), 
	@table_server sysname,
	@load_tablename	sysname 

AS

-- Input Parameter @operation - Must be either 'Insert','Upsert','Update','Delete'
-- Input Parameter @table_server - Linked Server Name
-- Input Parameter @load_tablename - Existing bulkops table
print N'--- Starting SF_Generate' + ' ' +  dbo.SF_Version()
if LOWER(@operation) not in ('insert','upsert','update','delete')
begin
	RAISERROR ('--- Ending SF_Generate. Error: Invalid operation parameter.',16,1)
	return 1
end

IF  EXISTS (SELECT 1
    FROM INFORMATION_SCHEMA.TABLES
    WHERE TABLE_TYPE='BASE TABLE' 
    AND TABLE_NAME=@load_tablename)
begin
	RAISERROR ('--- Ending SF_Generate. Error: Table to generate already exists.',16,1)
	return 1
end

set NOCOUNT ON

declare @base_tablename sysname
declare @work sysname
declare @sql nvarchar(max)
declare @uscore_pos int
declare @uuc_pos int
declare @uue_pos int
declare @uus_pos int
declare @uuh_pos int
declare @uuk_pos int
declare @rc int

-- derive base table name from load table name
set @work = lower(@load_tablename)

-- Is this a custom table
set @uuc_pos = CHARINDEX('__c',@work)
set @uue_pos = CHARINDEX('__e',@work)
set @uus_pos = CHARINDEX('__share',@work)
set @uuh_pos = CHARINDEX('__history',@work)
set @uuk_pos = CHARINDEX('__kav',@work)
if @uuc_pos <> 0 
	begin
		set @base_tablename = SUBSTRING(@work,1,@uuc_pos+2)
	end
else if @uue_pos <> 0 
	begin
		set @base_tablename = SUBSTRING(@work,1,@uue_pos+2)
	end
else if @uus_pos <> 0
	begin
		set @base_tablename = SUBSTRING(@work,1,@uus_pos+6)
	end
else if @uuh_pos <> 0
	begin
		set @base_tablename = SUBSTRING(@work,1,@uuh_pos+8)
	end
else if @uuk_pos <> 0
	begin
		set @base_tablename = SUBSTRING(@work,1,@uuk_pos+4)
	end
else
	begin
		set @uscore_pos = CHARINDEX('_',@work)

		if @uscore_pos = 0
			set @base_tablename = @work
		else
			set @base_tablename = SUBSTRING(@work,1,@uscore_pos-1)
	end

-- Get a temporary sffields table
CREATE TABLE #sffields(
	[ObjectName] [nvarchar](128),
	[Name] [nvarchar](128) ,
	[Type] [nvarchar](32) ,
	[SQLDefinition] [nvarchar](128),
	[Createable] [varchar](5),
	[Updateable] [varchar](5)
)

set @sql = 'Insert into #sffields '
set @sql = @sql + 'Select [ObjectName],[Name],[Type],[SQLDefinition],[Createable],[Updateable] '
set @sql = @sql + 'from '+ @table_server + '...sys_sffields'
exec (@sql)
IF (@@ERROR <> 0) GOTO ERR_HANDLER

-- Clear out columns not belonging to the base table
delete #sffields where ObjectName != @base_tablename
IF (@@ERROR <> 0) GOTO ERR_HANDLER

set @sql = 'Create Table ' + @load_tablename + ' ('
set @sql = @sql + '[Id] nchar(18) null'
set @sql = @sql + ',[Error] nvarchar(2000) null'

-- Generate rest of columns
declare @c_Name nvarchar(512)
declare @c_SQLDefinition nvarchar(512)
declare @c_Createable char(5)
declare @c_Updateable char(5)

declare flds_cursor cursor local fast_forward
for select [Name],[SQLDefinition],[Createable],[Updateable] from #sffields

open flds_cursor
IF (@@ERROR <> 0) GOTO ERR_HANDLER

while 1 = 1
begin
	fetch next from flds_cursor into @c_Name,@c_SQLDefinition,@c_Createable,@c_Updateable
	if @@error <> 0 or @@fetch_status <> 0 break
	
	if Lower(@c_Name) = 'id' continue
	if Lower(@operation) in ('insert','upsert') and @c_Createable = 'true '
	begin
		set @sql = @sql + ',[' + @c_Name + '] ' + @c_SQLDefinition
	end
	else if Lower(@operation) in ('update') and @c_Updateable = 'true '
	begin
		set @sql = @sql + ',[' + @c_Name + '] ' + @c_SQLDefinition
	end
end

set @sql = @sql + ')'

close flds_cursor
deallocate flds_cursor

-- Print CREATE TABLE and execute it to create the table
print @sql
exec (@sql)
set @rc = 0

-- Return to caller
if @rc = 1
	RAISERROR ('--- Ending SF_Generate. Operation FAILED.',16,1)

SET NOCOUNT OFF
return @rc

ERR_HANDLER:
RAISERROR ('--- Ending SF_Generate. Operation FAILED.',16,1)
SET NOCOUNT OFF
return 1
GO
-- =============================================
-- Create procedure SF_RefreshIAD
-- To Use:
-- 1. Make sure before executing that you are adding this stored procedure to your salesforce backups database
-- 2. If needed, modify the @ProgDir on line 28 for the directory containing the DBAmp.exe program
-- 3. Execute this script to add the SF_RefreshIAD proc to the salesforce backups database
-- =============================================
IF EXISTS (SELECT name
	   FROM   sysobjects
	   WHERE  name = N'SF_RefreshIAD'
	   AND 	  type = 'P')
    DROP PROCEDURE SF_RefreshIAD
GO

CREATE PROCEDURE SF_RefreshIAD
	@table_server sysname,
	@table_name sysname,
	@schema_error_action varchar(100) = 'no'
AS
-- Parameters: @table_server           - Salesforce Linked Server name (i.e. SALESFORCE)
--             @table_name             - Salesforce object to copy (i.e. Account)
--             @schema_error_action    - Controls the action for a schema change 
--                                     -    'No' : FAIL on a schema change
--                                     -    'Yes' : The table will be replicated instead
--									   -	'NoDrop': The table will be replicated with NoDrop
--                                     -    'Subset' : The new columns are ignored and the current
--                                                     subset of local table columns are refreshed.
--                                     -               Columns deleted on salesforce ARE NOT deleted locally. 

declare @Result 	int
declare @Command 	nvarchar(max)
declare @sql		nvarchar(max)
declare @parmlist	nvarchar(4000)
declare @columnList nvarchar(max)
declare @deletecolumnList nvarchar(max)
declare @colname	nvarchar(500)
declare @time_now	char(8)
set NOCOUNT ON

print '--- Starting SF_RefreshIAD for ' + @table_name + ' ' +  dbo.SF_Version()
declare @LogMessage nvarchar(max)
declare @SPName nvarchar(50)
set @SPName = 'SF_RefreshIAD:' + Convert(nvarchar(255), NEWID(), 20)
set @LogMessage = 'Parameters: ' + @table_server + ' ' + @table_name + ' ' + @schema_error_action + ' ' + ' Version: ' +  dbo.SF_Version()
exec SF_Logger @SPName, N'Starting', @LogMessage

declare @delim_table_name sysname
declare @refresh_table sysname
declare @delim_refresh_table sysname
declare @delta_table sysname
declare @delim_delta_table sysname
declare @deleted_table sysname
declare @delim_deleted_table sysname
declare @queryall_table sysname
declare @delim_queryall_table sysname

declare @server sysname
declare @database sysname
declare @timestamp_col_name nvarchar(2000)
declare @is_history_table int
declare @diff_schema_count int

-- Error out on big objects
declare @isBigObject int
set @isBigObject = 0
exec SF_IsBigObject @table_name, @isBigObject Output

if (@isBigObject = 1)
Begin
	Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
	print @time_now + ': Error: Big Objects are not supported with SF_RefreshIAD ' 
    set @LogMessage = 'Error: Big Objects are not supported with SF_RefreshIAD'
    exec SF_Logger @SPName, N'Message', @LogMessage
    GOTO ERR_HANDLER
End

set @schema_error_action = Lower(@schema_error_action)

Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))

-- Validate parameters
if  @schema_error_action <> 'yes' and
    @schema_error_action <> 'no' and
	@schema_error_action <> 'nodrop' and
     @schema_error_action <> 'subset' 
   begin
	  print @time_now + ': Error: Invalid Schema Action Parameter: ' + @schema_error_action
	  set @LogMessage = 'Error: Invalid Schema Action Parameter: ' + @schema_error_action
	  exec SF_Logger @SPName, N'Message', @LogMessage
  	  GOTO ERR_HANDLER
   end
   
if @schema_error_action <> 'no'
begin
	print @time_now + ': Using Schema Error Action of ' + @schema_error_action
	set @LogMessage = 'Using Schema Error Action of ' + @schema_error_action
	exec SF_Logger @SPName, N'Message', @LogMessage
end


-- Put delimeters around names so we can name tables User, etc...
set @delim_table_name = '[' + @table_name + ']'
set @refresh_table = 'TableRefreshTime'
set @delim_refresh_table = '[' + @refresh_table + ']'
set @delta_table = @table_name + '_Delta' + CONVERT(nvarchar(30), GETDATE(), 126) 
set @delim_delta_table = '[' + @delta_table + ']'
set @deleted_table = @table_name + '_Deleted'
set @delim_deleted_table = '[' + @deleted_table + ']'
set @queryall_table = @table_name + '_QueryAll'
set @delim_queryall_table = '[' + @queryall_table + ']'


-- Determine whether the local table and the previous copy exist
declare @table_exist int
declare @refresh_exist int
declare @delta_exist int
declare @deleted_exist int
declare @char_count varchar(10)

set @table_exist = 0
IF EXISTS (SELECT 1
    FROM INFORMATION_SCHEMA.TABLES
    WHERE TABLE_TYPE='BASE TABLE' 
    AND TABLE_NAME=@table_name)
        set @table_exist = 1
IF (@@ERROR <> 0) GOTO ERR_HANDLER

set @refresh_exist = 0
IF EXISTS (SELECT 1
    FROM INFORMATION_SCHEMA.TABLES
    WHERE TABLE_TYPE='BASE TABLE' 
    AND TABLE_NAME=@refresh_table)
        set @refresh_exist = 1
IF (@@ERROR <> 0) GOTO ERR_HANDLER


if (@refresh_exist = 0)
begin
   exec ('Create Table ' + @refresh_table + ' (TblName nvarchar(255) null, LastRefreshTime datetime null default CURRENT_TIMESTAMP) ')
   IF (@@ERROR <> 0) GOTO ERR_HANDLER
end

--Validate if object exists on Salesforce
declare @sf_obj_exists int
exec @sf_obj_exists =  SF_IsValidSFObject @table_server,@table_name
if @sf_obj_exists = 0
Begin
	Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
	print @time_now + ': Error: Salesforce table does not exist: ' + @table_name
	set @LogMessage = 'Error: Salesforce table does not exist: ' + @table_name
	exec SF_Logger @SPName, N'Message', @LogMessage
	GOTO ERR_HANDLER
End

-- If table does not exist then replicate it
if (@table_exist = 0)
begin
	Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
	print @time_now + ': Local table does not exist. Using SF_ReplicateIAD to create the local table.'
	set @LogMessage = 'Local table does not exist. Using SF_ReplicateIAD to create the local table.'
	exec SF_Logger @SPName, N'Message', @LogMessage
	goto REPLICATE_EXIT
end

-- Get the flags from DBAmp for this table
declare @replicateable char(5)
declare @deletable char(5)
select @sql = 'Select @DFOUT = Deletable, @RFOUT = Replicateable,@TSOUT = TimestampField from ' 
select @sql = @sql + @table_server + '...sys_sfobjects where Name ='''
select @sql = @sql + @table_name + ''''
select @parmlist = '@DFOUT char(5) OUTPUT, @RFOUT char(5) OUTPUT, @TSOUT char(50) OUTPUT'
exec sp_executesql @sql,@parmlist, @DFOUT = @deletable OUTPUT, @RFOUT=@replicateable OUTPUT,@TSOUT=@timestamp_col_name OUTPUT
IF (@@ERROR <> 0) GOTO ERR_HANDLER

--print @timestamp_col_name
if (@timestamp_col_name = 'CreatedDate') 
begin
	set @is_history_table = 1
end
else if (@timestamp_col_name = 'SystemModstamp')
begin
	set @is_history_table = 0
end
else
begin
	-- Cannot do a normal refresh because the table has no timestamp column
  	Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
	print @time_now + ': Table does not contain a timestamp column needed to refresh. Using SF_ReplicateIAD to create table.'
	set @LogMessage = 'Table does not contain a timestamp column needed to refresh. Using SF_ReplicateIAD to create table.'
	exec SF_Logger @SPName, N'Message', @LogMessage
	goto REPLICATE_EXIT
end


-- Get the last refresh time from the refresh table
-- This serves as the 'last run' time for the refresh
-- We subtract 30 mins to allow for long units of work on the salesforce side
declare @last_time smalldatetime
declare @table_crtime smalldatetime

-- Get create time of the base table. This is the last replicate time
select @table_crtime = DATEADD(mi,-30,create_date) FROM sys.objects WHERE name = @table_name and type='U'

-- Get the latest timestamp from the Refresh table
select @sql = 'Select @LastTimeOUT = DATEADD(mi,-30,LastRefreshTime) from ' + @refresh_table 
select @sql = @sql + ' where TblName= ''' + @table_name + ''''
select @parmlist = '@LastTimeOUT datetime OUTPUT'
exec sp_executesql @sql,@parmlist, @LastTimeOUT=@last_time OUTPUT
IF (@@ERROR <> 0 OR @last_time is null)
begin
	set @last_time = @table_crtime
end

-- if the last refresh time was before the last replicate time, use the last replicate time instead
if (@last_time < @table_crtime)
   set @last_time = @table_crtime

-- Get the NoTimeZoneConversion flag from DBAmp
declare @noTimeZoneConversion char(5)
select @sql = 'Select @TZOUT = NoTimeZoneConversion from ' 
select @sql = @sql + @table_server + '...sys_sfsession'
select @parmlist = '@TZOUT char(5) OUTPUT'
exec sp_executesql @sql,@parmlist, @TZOUT=@noTimeZoneConversion OUTPUT
IF (@@ERROR <> 0) GOTO ERR_HANDLER

-- If NoTimeZoneConversion is true then convert last_time to GMT
if (@noTimeZoneConversion = 'true')
begin
  	Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
	print @time_now + ': DBAmp is using GMT for all datetime calculations.'
	set @LogMessage = 'DBAmp is using GMT for all datetime calculations.'
	exec SF_Logger @SPName, N'Message', @LogMessage
	SET @last_time = DATEADD(Hour, DATEDIFF(Hour, GETDATE(), GETUTCDATE()), @last_time)
end

Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
print @time_now + ': Using last run time of ' + Convert(nvarchar(24),@last_time,120)
set @LogMessage = 'Using last run time of ' + CONVERT(nvarchar(24), @last_time, 120)
exec SF_Logger @SPName, N'Message', @LogMessage

-- If the delta table exists, drop it
set @delta_exist = 0;
IF EXISTS (SELECT 1
    FROM INFORMATION_SCHEMA.TABLES
    WHERE TABLE_TYPE='BASE TABLE'
    AND TABLE_NAME=@delta_table)
        set @delta_exist = 1
IF (@@ERROR <> 0) GOTO ERR_HANDLER

if (@delta_exist = 1)
        exec ('Drop table ' + @delim_delta_table)
IF (@@ERROR <> 0) GOTO ERR_HANDLER

-- Create new delta table with updated rows
-- Retrieve current server name and database
select @server = @@servername, @database = DB_NAME()
SET @server = CAST(SERVERPROPERTY('ServerName') AS sysname) 


-- Create an empty local table with the current structure of the Salesforce object
Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
--print @time_now + ': Create ' + @delta_table + ' with new structure.'
exec ('Select Top 0 * into ' + @delim_delta_table + ' from ' + @table_server + '...' + @queryall_table )
IF (@@ERROR <> 0) GOTO ERR_HANDLER

-- Remember query time as the the start of the interval
declare @queryTime datetime
select @queryTime = (Select CURRENT_TIMESTAMP)

-- Use the queryall table to pick up archived and deleted rows	
select @sql = 'Insert ' + @delim_delta_table + ' Select * from ' + @table_server + '...' + @queryall_table + ' where ' + @timestamp_col_name + ' > @LastTimeIN'
select @parmlist = '@LastTimeIN datetime'
exec sp_executesql @sql, @parmlist, @LastTimeIN=@last_time
IF (@@ERROR <> 0) GOTO ERR_HANDLER

-- Delete any overlap rows in the delta table
-- These are rows we've already synched but got picked up due to the 10 min sliding window
select @sql = 'delete ' + @delim_delta_table + ' where exists '
select @sql = @sql + '(select Id from ' + @delim_table_name + ' where Id= ' + @delim_delta_table +'.Id '
if @table_name = 'OpportunityHistory'
begin
	select @sql = @sql + ')'
end
else
begin
	select @sql = @sql + ' and ' + @timestamp_col_name + ' = ' + @delim_delta_table + '.' + @timestamp_col_name + ')'
end
exec sp_executesql @sql
IF (@@ERROR <> 0) GOTO ERR_HANDLER

-- Get the count of records from the delta table
declare @delta_count int
select @sql = 'Select @DeltaCountOUT = Count(*) from ' + @delim_delta_table
select @parmlist = '@DeltaCountOUT int OUTPUT'
exec sp_executesql @sql,@parmlist, @DeltaCountOUT=@delta_count OUTPUT
IF (@@ERROR <> 0) GOTO ERR_HANDLER

-- Print number of rows in delta table
Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
Select @char_count = (select CAST(@delta_count as VARCHAR(10)))
print @time_now + ': Identified ' + @char_count + ' updated/inserted rows.'


set @LogMessage = 'Identified ' + @char_count + ' updated/inserted rows.'
exec SF_Logger @SPName, N'Message', @LogMessage

-- If no records have changed then we are done
if (@delta_count = 0) goto SUCCESS

-- Check to see if the column structure is the same
declare @cnt1 int
declare @cnt2 int
Select @cnt1 = Count(*) FROM INFORMATION_SCHEMA.COLUMNS v1 WHERE v1.TABLE_NAME=@delta_table 
		AND NOT EXISTS (Select COLUMN_NAME from INFORMATION_SCHEMA.COLUMNS v2 
		Join INFORMATION_SCHEMA.TABLES t1
		On v2.TABLE_NAME = t1.TABLE_NAME and t1.TABLE_SCHEMA = v2.TABLE_SCHEMA
		where (t1.TABLE_TYPE = 'BASE TABLE') and
		v2.TABLE_NAME=@table_name and v1.COLUMN_NAME = v2.COLUMN_NAME and v1.DATA_TYPE = v2.DATA_TYPE 
		and v1.IS_NULLABLE = v2.IS_NULLABLE
		and ISNULL(v1.CHARACTER_MAXIMUM_LENGTH,0) = ISNULL(v2.CHARACTER_MAXIMUM_LENGTH,0))
IF (@@ERROR <> 0) GOTO ERR_HANDLER

Select @cnt2 = Count(*) FROM INFORMATION_SCHEMA.COLUMNS v1
		Join INFORMATION_SCHEMA.TABLES t1
		On v1.TABLE_NAME = t1.TABLE_NAME and t1.TABLE_SCHEMA = v1.TABLE_SCHEMA
		WHERE (t1.TABLE_TYPE = 'BASE TABLE') and v1.TABLE_NAME=@table_name 
		AND NOT EXISTS (Select COLUMN_NAME from INFORMATION_SCHEMA.COLUMNS v2 where 
		v2.TABLE_NAME=@delta_table and v1.COLUMN_NAME = v2.COLUMN_NAME and v1.DATA_TYPE = v2.DATA_TYPE 
		and v1.IS_NULLABLE = v2.IS_NULLABLE
		and ISNULL(v1.CHARACTER_MAXIMUM_LENGTH,0) = ISNULL(v2.CHARACTER_MAXIMUM_LENGTH,0))
IF (@@ERROR <> 0) GOTO ERR_HANDLER

set @diff_schema_count = @cnt1 + @cnt2

if (@diff_schema_count > 0)
begin
	Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
	if (@schema_error_action = 'yes') or (@schema_error_action = 'nodrop')
	begin
		print @time_now + ': Table schema has changed. The table will be replicated instead.'
		set @LogMessage = 'Table schema has changed. The table will be replicated instead.'
		exec SF_Logger @SPName, N'Message', @LogMessage
		exec ('Drop table ' + @delim_delta_table)
		goto REPLICATE_EXIT
	end
   
   if (@schema_error_action = 'no')
   begin
	  print @time_now + ': Error: Table schema has changed and therefore the table cannot be refreshed.'
	  set @LogMessage = 'Error: Table schema has changed and therefore the table cannot be refreshed.'
	  exec SF_Logger @SPName, N'Message', @LogMessage
	  exec ('Drop table ' + @delim_delta_table)
  	  GOTO ERR_HANDLER
   end
   
    -- Schema changed so try to build a subset of columns
	-- Build list of columns in common
	declare colname_cursor cursor for 
		SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS v1 WHERE v1.TABLE_NAME= @table_name 
		AND EXISTS (Select COLUMN_NAME from INFORMATION_SCHEMA.COLUMNS v2 
		where v2.TABLE_NAME= @delta_table 
		and v1.COLUMN_NAME = v2.COLUMN_NAME and v1.DATA_TYPE = v2.DATA_TYPE and v1.IS_NULLABLE = v2.IS_NULLABLE 
		and ISNULL(v1.CHARACTER_MAXIMUM_LENGTH,0)= ISNULL(v2.CHARACTER_MAXIMUM_LENGTH,0) and v1.TABLE_SCHEMA = v2.TABLE_SCHEMA)

	OPEN colname_cursor
	set @columnList = ''
	
	while 1 = 1
	begin
		fetch next from colname_cursor into @colname
		if @@error <> 0 or @@fetch_status <> 0 break
		set @columnList = @columnList + '[' + @colname + ']' + ','
	end
	close colname_cursor
	deallocate colname_cursor

	if Len(@columnList) = 0
	begin
		print @time_now + ': Error: Table schema has changed with no columns in common. Therefore the table cannot be refreshed.'
		set @LogMessage = 'Error: Table schema has changed with no columns in common. Therefore the table cannot be refreshed.'
		exec SF_Logger @SPName, N'Message', @LogMessage
		exec ('Drop table ' + @delim_delta_table)
		GOTO ERR_HANDLER
	end
					
	SET @columnList = SUBSTRING(@columnList, 1, Len(@columnList) - 1)

	-- Build list of columns that need to deleted in the local table
	declare colname_cursor cursor for 
		SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS v1 WHERE v1.TABLE_NAME= @table_name 
		AND not EXISTS (Select COLUMN_NAME from INFORMATION_SCHEMA.COLUMNS v2 
		where v2.TABLE_NAME= @delta_table 
		and v1.COLUMN_NAME = v2.COLUMN_NAME )

	OPEN colname_cursor
	set @deletecolumnList = ''
	while 1 = 1
	begin
		fetch next from colname_cursor into @colname
		if @@error <> 0 or @@fetch_status <> 0 break
		set @deletecolumnList = @deletecolumnList + '[' + @colname + ']' + ','
	end
	close colname_cursor
	deallocate colname_cursor

	if Len(@deletecolumnList) > 0
	begin
		SET @deletecolumnList = SUBSTRING(@deletecolumnList, 1, Len(@deletecolumnList) - 1)
	end
					
	print @time_now + ': Warning: Table schema has changed. SF_Refresh will use the valid subset of columns.'
	set @LogMessage = 'Warning: Table schema has changed. SF_Refresh will use the valid subset of columns.'
	exec SF_Logger @SPName, N'Message', @LogMessage
end
else
begin
	-- Build list of columns anyway
	declare colname_cursor cursor for 
		SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS v1 WHERE v1.TABLE_NAME= @table_name 
		AND EXISTS (Select COLUMN_NAME from INFORMATION_SCHEMA.COLUMNS v2 
		where v2.TABLE_NAME= @delta_table 
		and v1.COLUMN_NAME = v2.COLUMN_NAME and v1.DATA_TYPE = v2.DATA_TYPE and v1.IS_NULLABLE = v2.IS_NULLABLE 
		and ISNULL(v1.CHARACTER_MAXIMUM_LENGTH,0)= ISNULL(v2.CHARACTER_MAXIMUM_LENGTH,0) and v1.TABLE_SCHEMA = v2.TABLE_SCHEMA)

	OPEN colname_cursor
	set @columnList = ''
	
	while 1 = 1
	begin
		fetch next from colname_cursor into @colname
		if @@error <> 0 or @@fetch_status <> 0 break
		set @columnList = @columnList + '[' + @colname + ']' + ','
	end
	close colname_cursor
	deallocate colname_cursor

	SET @columnList = SUBSTRING(@columnList, 1, Len(@columnList) - 1)
End

if (@delta_count <> 0)
begin
	BEGIN TRAN
	Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
	print @time_now + ': Adding updated/inserted rows into ' + @table_name 
	set @LogMessage = 'Adding updated/inserted rows into ' + @table_name
	exec SF_Logger @SPName, N'Message', @LogMessage

	if @is_history_table = 0 
	begin
		-- Delete rows from local table that exist in delta table
		-- History tables skip this step because updates are not allowed
		select @sql = 'delete ' + @delim_table_name + ' where Id IN (select Id from ' + @delim_delta_table + ' )'
		exec sp_executesql @sql
		IF (@@ERROR <> 0) 
		begin
		   ROLLBACK
		   GOTO ERR_HANDLER
		end
	end
	
	-- Insert delta rows into local table
	if (@diff_schema_count > 0 )
	begin
		if Len(@deletecolumnList) > 0 and @schema_error_action = 'subsetdelete'
		begin
			-- Remove any deleted columns
			Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
			print @time_now + ': Removing the following deleted columns ' + @deletecolumnList
			set @LogMessage = 'Removing the following deleted columns ' + @deletecolumnList
			exec SF_Logger @SPName, N'Message', @LogMessage
			 
			select @sql = 'alter table ' + @delim_table_name + ' drop column ' + @deletecolumnList	
			exec sp_executesql @sql
			IF (@@ERROR <> 0) 
			begin
			   ROLLBACK
			   GOTO ERR_HANDLER
			end
		end
			
		-- Now insert the new rows
		select @sql = 'insert ' + @delim_table_name + '(' + @columnList + ')' 
					+ ' select ' + @columnList + ' from ' + @delim_delta_table
		exec sp_executesql @sql
		IF (@@ERROR <> 0) 
		begin
		   ROLLBACK
		   GOTO ERR_HANDLER
		end
	end
	else
	begin
		select @sql = 'insert ' + @delim_table_name + '(' + @columnList + ')' 
					+ ' select ' + @columnList + ' from ' + @delim_delta_table
		exec sp_executesql @sql
		IF (@@ERROR <> 0) 
		begin
		   ROLLBACK
		   GOTO ERR_HANDLER
		end
	end
	
	COMMIT
end
	
SUCCESS:
-- Reset Last Refresh in the Refresh table for this object
exec ('delete ' + @refresh_table + ' where TblName =''' + @table_name + '''')
select @sql = 'insert into ' + @refresh_table + '(TblName,LastRefreshTime) Values(''' + @table_name + ''',''' + Convert(nvarchar(24),@queryTime,126) +''')'
--print @sql
exec sp_executesql @sql

-- We don't need the delta tables so drop them
exec ('Drop table ' + @delim_delta_table)

print '--- Ending SF_RefreshIAD. Operation successful.'
set @LogMessage = 'Ending - Operation Successful.'
exec SF_Logger @SPName, N'Successful', @LogMessage
set NOCOUNT OFF
return 0

ERR_HANDLER:
-- We don't need the deleted and delta tables so drop them
IF EXISTS (SELECT 1
    FROM INFORMATION_SCHEMA.TABLES
    WHERE TABLE_TYPE='BASE TABLE'
    AND TABLE_NAME=@delta_table)
begin
   exec ('Drop table ' + @delim_delta_table)
end
print('--- Ending SF_RefreshIAD. Operation FAILED.')
set @LogMessage = 'Ending - Operation Failed.'
exec SF_Logger @SPName, N'Failed', @LogMessage
RAISERROR ('--- Ending SF_RefreshIAD. Operation FAILED.',16,1)
set NOCOUNT OFF
return 1

REPLICATE_EXIT:
-- Reset Last Refresh in the Refresh table for this object
-- BUGFIX: This is not needed so it is commented out
-- exec ('delete ' + @refresh_table + ' where TblName =''' + @table_name + '''')
IF EXISTS (SELECT 1
    FROM INFORMATION_SCHEMA.TABLES
    WHERE TABLE_TYPE='BASE TABLE'
    AND TABLE_NAME=@delta_table)
begin
   exec ('Drop table ' + @delim_delta_table)
end

set @LogMessage = 'Ending - Branching to SF_Replicate.' 
exec SF_Logger @SPName, N'Failed',@LogMessage
If @schema_error_action = 'nodrop'
Begin
	exec SF_ReplicateIAD @table_server, @table_name, 'nodrop'
End
else
Begin
	exec SF_ReplicateIAD @table_server, @table_name
End
set NOCOUNT OFF
return 0
Go

-- =============================================
-- Create procedure SF_VASQuery
-- To Use:
-- 1. Make sure before executing that you are adding this stored procedure to your salesforce backups database
-- 2. If needed, modify the @ProgDir on line 28 for the directory containing the DBAmpReplicate.exe program
-- 3. Execute this script to add the SF_VASQuery proc to the salesforce backups database
-- =============================================
IF EXISTS (SELECT name
	   FROM   sysobjects
	   WHERE  name = N'SF_VASQuery'
	   AND 	  type = 'P')
    DROP PROCEDURE SF_VASQuery
GO

CREATE PROCEDURE SF_VASQuery
AS

declare @Result 	int
declare @Command 	nvarchar(4000)
declare @sql		nvarchar(4000)
declare @parmlist	nvarchar(4000)
declare @time_now	char(8)

print '--- Starting SF_VASQuery' + ' ' +  dbo.SF_Version()
declare @refresh_table sysname
declare @delim_refresh_table sysname

-- Put delimeters around names 
set @refresh_table = 'VASSnaps'
set @delim_refresh_table = '[' + @refresh_table + ']'

declare @refresh_exist int

set @refresh_exist = 0
IF EXISTS (SELECT 1
    FROM INFORMATION_SCHEMA.TABLES
    WHERE TABLE_TYPE='BASE TABLE' 
    AND TABLE_NAME=@refresh_table)
        set @refresh_exist = 1
IF (@@ERROR <> 0) GOTO ERR_HANDLER

if (@refresh_exist = 0)
begin
   exec ('Create Table ' + @refresh_table + ' (TotalAvail BigInt null, LargestBlock BigInt null, MultiPage BigInt null, CLR_Multi BigInt null,CLR_VRes BigInt null,CLR_VCmt BigInt null,SnapTime datetime null default CURRENT_TIMESTAMP) ')
   IF (@@ERROR <> 0) GOTO ERR_HANDLER
end

Declare @TotalAvail as Bigint
Declare @LargestBlock as Bigint
Declare @MultiPage as Bigint
Declare @CLR_Multi as Bigint
Declare @CLR_VRes  as Bigint
Declare @CLR_VCmt  as Bigint

-- Get allocations by the MultiPage Manager
-- Unable to retrieve in SQL 2012
--Select @MultiPage = sum(multi_pages_kb) 
--from sys.dm_os_memory_clerks
Select @MultiPage = 0

-- Get CLR memory usage
-- Unable to retrieve in SQL 2012
select @CLR_Multi = 0, 
		@CLR_VRes = sum(virtual_memory_reserved_kb),
		@CLR_VCmt = sum(virtual_memory_committed_kb) from sys.dm_os_memory_clerks 
		where type like '%clr%'


-- Get TotalAvail and LargestBlock
Select @TotalAvail = SUM(CONVERT(BIGINT,Size)*Free)/1024 
      ,@LargestBlock = CAST(MAX(Size) AS BIGINT)/1024 
from
(SELECT 
    Size = VaDump.Size,  
    Free = SUM(CASE(CONVERT(INT, VaDump.Base)^0) WHEN 0 THEN 1 ELSE 0 END) 
FROM 
( 
    SELECT  CONVERT(VARBINARY, SUM(region_size_in_bytes)) 
    AS Size, region_allocation_base_address AS Base 
    FROM sys.dm_os_virtual_address_dump  
    WHERE region_allocation_base_address <> 0x0 
    GROUP BY region_allocation_base_address  
 UNION   
    SELECT CONVERT(VARBINARY, region_size_in_bytes), region_allocation_base_address 
    FROM sys.dm_os_virtual_address_dump 
    WHERE region_allocation_base_address  = 0x0 
) 
AS VaDump 
GROUP BY Size
) as VASummary
where Free <>0

-- Add a VAS snapshot to the table
select @sql = 'insert into ' + @refresh_table + '(TotalAvail, LargestBlock, MultiPage, CLR_Multi, CLR_VRes, CLR_VCmt) '
select @sql = @sql + 'Values(' + Cast(@TotalAvail as nvarchar) + 
							','+ Cast(@LargestBlock as nvarchar) + 
							','+ Cast(@MultiPage as nvarchar) + 
							','+ Cast(@CLR_Multi as nvarchar) + 
							','+ Cast(@CLR_VRes as nvarchar) + 
							','+ Cast(@CLR_VCmt as nvarchar) + ')'
print @sql
exec sp_executesql @sql

print '--- Ending SF_VASQuery. Operation successful.'
return 0

ERR_HANDLER:
set NOCOUNT OFF
print('--- Ending SF_VASQuery. Operation FAILED.')
RAISERROR ('--- Ending SF_VASQuery. Operation FAILED.',16,1)
return 1

GO

IF EXISTS (SELECT name
	   FROM   sysobjects
	   WHERE  name = N'SF_RemoveDeletesIAD'
	   AND 	  type = 'P')
    DROP PROCEDURE SF_RemoveDeletesIAD
GO

CREATE PROCEDURE [dbo].[SF_RemoveDeletesIAD]
	@table_server sysname,
	@table_name sysname
AS
-- NOTE: This stored procedure will not work on SQL 2000.
--
-- Parameters: @table_server           - Salesforce Linked Server name (i.e. SALESFORCE)
--             @table_name             - Salesforce object to copy (i.e. Account)
declare @Result 	int
declare @sql		nvarchar(max)
declare @parmlist	nvarchar(4000)
declare @columnList nvarchar(max)
declare @deletecolumnList nvarchar(max)
declare @colname	nvarchar(500)
declare @time_now	char(8)

print '--- Starting SF_RemoveDeletesIAD for ' + @table_name + ' ' +  dbo.SF_Version()
declare @delim_table_name sysname
declare @refresh_table sysname
declare @delim_refresh_table sysname
declare @delta_table sysname
declare @delim_delta_table sysname
declare @deleted_table sysname
declare @delim_deleted_table sysname

declare @server sysname
declare @database sysname
declare @char_count varchar(10)
declare @queryall_table sysname
declare @delim_queryall_table sysname


set NOCOUNT ON

-- Put delimeters around names so we can name tables User, etc...
set @delim_table_name = '[' + @table_name + ']'
set @deleted_table = @table_name + '_Deleted'
set @delim_deleted_table = '[' + @deleted_table + ']'
set @queryall_table = @table_name + '_QueryAll'
set @delim_queryall_table = '[' + @queryall_table + ']'


-- Use alternate method to discover deleted id's
Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
print @time_now + ': Using alternate method to determine deleted records.' 

-- If the deleted table exists, drop it 
declare @deleted_exist int
set @deleted_exist = 0;
IF EXISTS (SELECT 1
    FROM INFORMATION_SCHEMA.TABLES
    WHERE TABLE_TYPE='BASE TABLE'
    AND TABLE_NAME=@deleted_table)
        set @deleted_exist = 1
IF (@@ERROR <> 0) GOTO ERR_HANDLER

if (@deleted_exist = 1)
        exec ('Drop table ' + @delim_deleted_table)
IF (@@ERROR <> 0) GOTO ERR_HANDLER

-- Create new deleted table for non-replicatable tables
select @sql = 'Select Id into ' + @delim_deleted_table + ' from ' + @delim_table_name
select @sql = @sql + ' where Id not in (select Id from ' + @table_server + '...' + @queryall_table 
select @sql = @sql + ' where IsDeleted = ''false'')'
exec sp_executesql @sql
IF (@@ERROR <> 0) GOTO ERR_HANDLER

-- Get the count of records from the deleted table
declare @deleted_count int
select @sql = 'Select @DeletedCountOUT = Count(*) from ' + @delim_deleted_table
select @parmlist = '@DeletedCountOUT int OUTPUT'
exec sp_executesql @sql,@parmlist, @DeletedCountOUT=@deleted_count OUTPUT
IF (@@ERROR <> 0) GOTO ERR_HANDLER

-- Print number of rows in deleted table
Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
Select @char_count = (select CAST(@deleted_count as VARCHAR(10)))
print @time_now + ': Identified ' + @char_count + ' deleted rows.'

if (@deleted_count <> 0)
begin
	-- Delete rows from local table that exist in deleted table
	Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
	print @time_now + ': Removing deleted rows from ' + @table_name 
	
	select @sql = 'delete ' + @delim_table_name + ' where Id IN (select Id from ' + @delim_deleted_table + ' )'
	exec sp_executesql @sql
	IF (@@ERROR <> 0) GOTO ERR_HANDLER
end


SUCCESS:
-- We don't need the deleted table so drop them
exec ('Drop table ' + @delim_deleted_table)

print '--- Ending SF_RemoveDeletesIAD. Operation successful.'
set NOCOUNT OFF
return 0

ERR_HANDLER:
set NOCOUNT OFF
print('--- Ending SF_RemoveDeletesIAD. Operation FAILED.')
RAISERROR ('--- Ending SF_RemoveDeletesIAD. Operation FAILED.',16,1)
return 1

GO

IF EXISTS (SELECT name
	   FROM   sysobjects
	   WHERE  name = N'SF_ReplicateHistory'
	   AND 	  type = 'P')
    DROP PROCEDURE SF_ReplicateHistory
GO


-- =============================================
-- Create procedure SF_ReplicateHistory
-- 
-- This stored procedure is a "Hail Mary" pass to
-- try and replicate a history table when the
-- normal sf_replicate will NOT work due to
-- timeout issues on the salesforce server.
-- =============================================
CREATE PROCEDURE [SF_ReplicateHistory]
	@table_server sysname,
	@table_name sysname
AS
-- Parameters: @table_server           - Salesforce Linked Server name (i.e. SALESFORCE)
--             @table_name             - Salesforce object to copy (i.e. Account)

declare @Result 	int
declare @Command 	nvarchar(4000)
declare @time_now	char(8)
set NOCOUNT ON

print '--- Starting SF_ReplicateHistory for ' + @table_name + ' ' +  dbo.SF_Version()
declare @LogMessage nvarchar(max)
declare @SPName nvarchar(50)
set @SPName = 'SF_ReplicateHistory:' + Convert(nvarchar(255), NEWID(), 20)
set @LogMessage = 'Parameters: ' + @table_server + ' ' + @table_name + ' ' + ' Version: ' +  dbo.SF_Version()
exec SF_Logger @SPName, N'Starting',@LogMessage

declare @delim_table_name sysname
declare @prev_table sysname
declare @delim_prev_table sysname
declare @base_object sysname
declare @parentId_name sysname
declare @server sysname
declare @database sysname

-- Is it really a history table
declare @isHistory int
declare @nameLength int
set @isHistory = 0

if RIGHT(@table_name,7) = 'History'
   set @isHistory =1 
if RIGHT(@table_name,7) = 'history'
   set @isHistory =1
if @isHistory = 0
begin
   Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
   print @time_now + ': Error: The table is not a history table.'
   set @LogMessage = 'Error: The table is not a history table.'
   exec SF_Logger @SPName, N'Message', @LogMessage
   GOTO ERR_HANDLER
end 

set @nameLength = LEN(@table_name) 
set @base_object = LEFT(@table_name, @nameLength - 7)
-- Handle exception for OpportunityFieldHistory
if LOWER(@base_object) = 'opportunityfield' set @base_object='Opportunity'
set @parentId_name = @base_object + 'Id'

if RIGHT(@base_object,2) = '__'
begin
   set @base_object = @base_object + 'c'
   set @parentId_name = 'ParentId'
end

-- Put delimeters around names so we can name tables User, etc...
set @delim_table_name = '[' + @table_name + ']'
set @prev_table = @table_name + '_Previous'
set @delim_prev_table = '[' + @prev_table + ']'

-- Determine whether the local table and the previous copy exist
declare @table_exist int
declare @prev_exist int

set @table_exist = 0
set @prev_exist = 0;
IF EXISTS (SELECT 1
    FROM INFORMATION_SCHEMA.TABLES
    WHERE TABLE_TYPE='BASE TABLE' 
    AND TABLE_NAME=@table_name)
        set @table_exist = 1
IF (@@ERROR <> 0) GOTO ERR_HANDLER

IF EXISTS (SELECT 1
    FROM INFORMATION_SCHEMA.TABLES
    WHERE TABLE_TYPE='BASE TABLE' 
    AND TABLE_NAME=@prev_table)
        set @prev_exist = 1
IF (@@ERROR <> 0) GOTO ERR_HANDLER

-- Get the sessionId from DBAmp. This also tests connectivity to salesforce.com
declare @sql nvarchar(4000)
declare @parmlist nvarchar(512)

if @table_exist = 1
begin
	-- Make sure that the table doesn't have any keys defined
	IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    		   WHERE CONSTRAINT_TYPE = 'FOREIGN KEY' AND TABLE_NAME=@table_name)
        begin
 	   Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
	   print @time_now + ': Error: The table contains foreign keys and cannot be replicated.'
	   set @LogMessage = 'Error: The table contains foreign keys and cannot be replicated.'
       exec SF_Logger @SPName, N'Message', @LogMessage
	   GOTO ERR_HANDLER
	end
end

-- If the previous table exists, drop it
Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
print @time_now + ': Drop ' + @prev_table + ' if it exists.'
set @LogMessage = 'Drop ' + @prev_table + ' if it exists.'
exec SF_Logger @SPName, N'Message', @LogMessage
if (@prev_exist = 1)
        exec ('Drop table ' + @delim_prev_table)
IF (@@ERROR <> 0) GOTO ERR_HANDLER

-- Create an empty local table with the current structure of the Salesforce object
Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
print @time_now + ': Create ' + @prev_table + ' with new structure.'
set @LogMessage = 'Create ' + @prev_table + ' with new structure.'
exec SF_Logger @SPName, N'Message', @LogMessage

BEGIN TRY
	exec ('Select top 0 * into ' + @delim_prev_table + ' from ' + @table_server + '...' + @delim_table_name )

	-- Now do the insert into that table
	exec ('Insert ' + @delim_prev_table + '(' + @parentId_name + ',CreatedById,CreatedDate,Field,Id,IsDeleted,NewValue,OldValue)' +
		  ' select * from openquery(' + @table_server + 
		  ',''Select Id, (Select CreatedById,CreatedDate,Field,Id,IsDeleted,NewValue,OldValue from Histories) from ' +
		  @base_object + ' '') where Histories_CreatedById is not null')
END TRY
BEGIN CATCH
	Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
	print @time_now + ': Error occurred populating the _Previous table.'	
	print @time_now +
		': Error: ' + ERROR_MESSAGE();
	set @LogMessage = 'Error: ' + ERROR_MESSAGE()
	exec SF_Logger @SPName, N'Message', @LogMessage
	
     -- Roll back any active or uncommittable transactions before
     -- inserting information in the ErrorLog.
     IF XACT_STATE() <> 0
     BEGIN
         ROLLBACK TRANSACTION;
     END
     goto ERR_HANDLER
END CATCH

declare @totalrows int 
set @totalrows = 0
select @sql = 'Select @rowscopiedOUT = count(Id) from ' + @delim_table_name
select @parmlist = '@rowscopiedOUT int OUTPUT'
exec sp_executesql @sql, @parmlist, @rowscopiedOUT = @totalrows OUTPUT

Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
print @time_now + ': ' + Cast(@totalrows AS nvarchar(10)) + ' rows copied.'
set @LogMessage = @time_now + ': ' + Cast(@totalrows AS nvarchar(10)) + ' rows copied.'
exec SF_Logger @SPName, N'Message', @LogMessage
	  
declare @primarykey_exists as int

Set @primarykey_exists = 1

BEGIN TRY
    BEGIN TRANSACTION;
	-- If the local table exists, drop it
	Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
	print @time_now + ': Drop ' + @table_name + ' if it exists.'
	set @LogMessage = 'Drop ' + @table_name + ' if it exists.'
	exec SF_Logger @SPName, N'Message', @LogMessage
	if (@table_exist = 1)
		exec ('Drop table ' + @delim_table_name)

	-- Backup previous table into current
	Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
	print @time_now + ': Rename previous table from ' + @prev_table + ' to ' + @table_name
	set @LogMessage = 'Rename previous table from ' + @prev_table + ' to ' + @table_name
	exec SF_Logger @SPName, N'Message', @LogMessage
	exec sp_rename @prev_table, @table_name

    -- If the DDL statement succeeds, commit the transaction.
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
	Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
	print @time_now + ': Error occurred dropping and renaming the table.'	
	print @time_now +
		': Error: ' + ERROR_MESSAGE();
	set @LogMessage = 'Error: ' + ERROR_MESSAGE();
	exec SF_Logger @SPName, N'Message', @LogMessage
		
     -- Roll back any active or uncommittable transactions before
     -- inserting information in the ErrorLog.
     IF XACT_STATE() <> 0
     BEGIN
         ROLLBACK TRANSACTION;
     END
     goto ERR_HANDLER
END CATCH

-- Recreate Primary Key is needed
BEGIN TRY
	Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
	print @time_now + ': Create primary key on ' + @table_name
	set @LogMessage = 'Create primary key on ' + @table_name
	exec SF_Logger @SPName, N'Message', @LogMessage
	if (@primarykey_exists = 1)
	   -- Add Id as Primary Key
	   exec ('Alter table ' + @delim_table_name + ' Add Constraint PK_' + @table_name + '_Id Primary Key NONCLUSTERED (Id) ')
END TRY
BEGIN CATCH
	Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
	print @time_now + ': Error occurred creating primary key for table.'	
	print @time_now +
		': Error: ' + ERROR_MESSAGE();
	set @LogMessage = 'Error: ' + ERROR_MESSAGE();
	exec SF_Logger @SPName, N'Message', @LogMessage
		
     -- Roll back any active or uncommittable transactions before
     -- inserting information in the ErrorLog.
     IF XACT_STATE() <> 0
     BEGIN
         ROLLBACK TRANSACTION;
     END
     goto ERR_HANDLER
END CATCH

print '--- Ending SF_ReplicateHistory. Operation successful.'
set @LogMessage = 'Ending - Operation Successful.' 
exec SF_Logger @SPName,N'Successful', @LogMessage
set NOCOUNT OFF
return 0

RESTORE_ERR_HANDLER:
set NOCOUNT OFF
print('--- Ending SF_ReplicateHistory. Operation FAILED.')
set @LogMessage = 'Ending - Operation Failed.' 
exec SF_Logger @SPName,N'Failed', @LogMessage
RAISERROR ('--- Ending SF_ReplicateHistory. Operation FAILED.',16,1)
return 1

ERR_HANDLER:
set NOCOUNT OFF
print('--- Ending SF_ReplicateHistory. Operation FAILED.')
set @LogMessage = 'Ending - Operation Failed.' 
exec SF_Logger @SPName,N'Failed', @LogMessage
RAISERROR ('--- Ending SF_ReplicateHistory. Operation FAILED.',16,1)
return 1
GO

IF EXISTS (SELECT name
	   FROM   sysobjects
	   WHERE  name = N'SF_Metadata'
	   AND 	  type = 'P')
    DROP PROCEDURE SF_Metadata
GO


CREATE PROCEDURE [SF_Metadata]
    @operation  nvarchar(255),
	@table_server sysname,
	@table_name sysname

AS
-- Parameters: @table_server           - Salesforce Linked Server name (i.e. SALESFORCE)
--             @table_name             - Table containing metadata

-- @ProgDir - Directory containing the DBAmpNet.exe. Defaults to the DBAmp program directory
-- If needed, modify this for your installation
declare @ProgDir   	varchar(250) 
set @ProgDir = 'C:\"Program Files"\DBAmp\'

declare @Result 	int
declare @Command 	nvarchar(4000)
declare @time_now	char(8)
set NOCOUNT ON

print '--- Starting SF_Metadata for ' + @table_name + ' ' +  dbo.SF_Version()
declare @LogMessage nvarchar(max)
declare @SPName nvarchar(50)
set @SPName = 'SF_Metadata:' + Convert(nvarchar(255), NEWID(), 20)
set @LogMessage = 'Parameters: ' + @operation + ' ' + @table_server + ' ' + @table_name + ' ' + ' Version: ' +  dbo.SF_Version()
exec SF_Logger @SPName, N'Starting',@LogMessage

declare @delim_table_name sysname
declare @server sysname
declare @database sysname

-- Execute a linked server query to wake up the provider
declare @noTimeZoneConversion char(5)
declare @sql nvarchar(4000)
declare @parmlist nvarchar(30)
select @sql = 'Select @TZOUT = NoTimeZoneConversion from ' 
select @sql = @sql + @table_server + '...sys_sfsession'
select @parmlist = '@TZOUT char(5) OUTPUT'
exec sp_executesql @sql,@parmlist, @TZOUT=@noTimeZoneConversion OUTPUT
IF (@@ERROR <> 0) GOTO ERR_HANDLER


-- Put delimeters around names so we can name tables User, etc...
set @delim_table_name = '[' + @table_name + ']'

-- Determine whether the local table exist
declare @table_exist int

set @table_exist = 0
IF EXISTS (SELECT 1
    FROM INFORMATION_SCHEMA.TABLES
    WHERE TABLE_TYPE='BASE TABLE' 
    AND TABLE_NAME=@table_name)
        set @table_exist = 1
IF (@@ERROR <> 0) GOTO ERR_HANDLER

-- Retrieve current server name and database
select @server = @@servername, @database = DB_NAME()
SET @server = CAST(SERVERPROPERTY('ServerName') AS sysname) 

-- Execute DBAmpNet.exe to load table from Salesforce
Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
print @time_now + ': Run the DBAmpNet2.exe program.' 
set @LogMessage = 'Run the DBAmpNet2.exe program.'
exec SF_Logger @SPName, N'Message', @LogMessage
set @Command = @ProgDir + 'DBAmpNet2.exe ' 
if (@operation is not null)
begin
	set @Command = @Command + @operation
end
set @Command = @Command + ' "' + '" '
set @Command = @Command + ' "' + @table_name + '" '
set @Command = @Command + ' "' + @server + '" '
set @Command = @Command + ' "' + @database + '" '
set @Command = @Command + ' "' + @table_server + '" '

-- Create temp table to hold output
declare @errorlog table (line varchar(255))

begin try
insert into @errorlog
	exec @Result = master..xp_cmdshell @Command
end try
begin catch
   print 'Error occurred running the DBAmpNet2.exe program'	
	Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
	print @time_now + ': Error occurred running the DBAmpNet2.exe program'	
	set @LogMessage = 'Error occurred running the DBAmpNet2.exe program'
	exec SF_Logger @SPName, N'Message', @LogMessage
	print @time_now +
		': Error: ' + ERROR_MESSAGE();
		set @LogMessage = 'Error: ' + ERROR_MESSAGE()
		exec SF_Logger @SPName, N'Message', @LogMessage
		
     -- Roll back any active or uncommittable transactions before
     -- inserting information in the ErrorLog.
     IF XACT_STATE() <> 0
     BEGIN
         ROLLBACK TRANSACTION;
     END
    
  set @Result = -1
end catch

if @@ERROR <> 0
   set @Result = -1

-- print output to msgs
declare @line varchar(255)
declare @printCount int
Set @printCount = 0

DECLARE tables_cursor CURSOR FOR SELECT line FROM @errorlog
OPEN tables_cursor
FETCH NEXT FROM tables_cursor INTO @line
WHILE (@@FETCH_STATUS <> -1)
BEGIN
   if @line is not null 
	begin
	print @line
	exec SF_Logger @SPName,N'Message', @line
	Set @printCount = @printCount + 1
	end
   FETCH NEXT FROM tables_cursor INTO @line
END
deallocate tables_cursor

if @Result = -1 or @printCount = 0
BEGIN
  	Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
	print @time_now + ': Error: DBAmpNet2.exe was unsuccessful.'
	set @LogMessage = 'Error: DBAmpNet2.exe was unsuccessful.'
	exec SF_Logger @SPName, N'Message', @LogMessage
	print @time_now + ': Error: Command string is ' + @Command
	set @LogMessage = 'Error: Command string is ' + @Command
	exec SF_Logger @SPName, N'Message', @LogMessage
  	GOTO RESTORE_ERR_HANDLER
END

print '--- Ending SF_Metadata. Operation successful.'
set @LogMessage = 'Ending - Operation Successful.' 
exec SF_Logger @SPName,N'Successful', @LogMessage
set NOCOUNT OFF
return 0

RESTORE_ERR_HANDLER:
print('--- Ending SF_Metadata. Operation FAILED.')
set @LogMessage = 'Ending - Operation Failed.' 
exec SF_Logger @SPName, N'Failed',@LogMessage
RAISERROR ('--- Ending SF_Metadata. Operation FAILED.',16,1)
set NOCOUNT OFF
return 1

ERR_HANDLER:
print('--- Ending SF_Metadata. Operation FAILED.')
set @LogMessage = 'Ending - Operation Failed.' 
exec SF_Logger @SPName,N'Failed', @LogMessage
RAISERROR ('--- Ending SF_Metadata. Operation FAILED.',16,1)
set NOCOUNT OFF
return 1
GO

IF EXISTS (SELECT name
	   FROM   sysobjects
	   WHERE  name = N'SF_ReplicateLarge'
	   AND 	  type = 'P')
    DROP PROCEDURE SF_ReplicateLarge
GO
Create PROCEDURE [dbo].[SF_ReplicateLarge]
@table_server sysname,
@table_name sysname,
@batchsize int = 250000,
@restartId nvarchar(255) = NULL
 
AS
-- Parameters: @table_server           - Salesforce Linked Server name (i.e. SALESFORCE)
--             @table_name             - Salesforce object to copy (i.e. Account)
 
-- @ProgDir - Directory containing the DBAmp.exe. Defaults to the DBAmp program directory
-- If needed, modify this for your installation
declare @ProgDir   varchar(250) 
set @ProgDir = 'C:\"Program Files"\DBAmp\'
 
declare @bulkapi_option nvarchar(255)
declare @Result int
declare @Command nvarchar(4000)
declare @time_now char(8)
declare @sql nvarchar(max)
declare @sqlNoOffset nvarchar(max)
declare @parmlist nvarchar(4000)
declare @EndingMessageThere int

set NOCOUNT ON
 
print '--- Starting SF_ReplicateLarge for ' + @table_name + ' ' +  dbo.SF_Version()
declare @LogMessage nvarchar(max)
declare @SPName nvarchar(50)
set @SPName = 'SF_ReplicateLarge:' + Convert(nvarchar(255), NEWID(), 20)
set @LogMessage = 'Parameters: ' + @table_server + ' ' + @table_name + ' ' + ISNULL(@bulkapi_option, ' ') + ' Version: ' +  dbo.SF_Version()
exec SF_Logger @SPName, N'Starting',@LogMessage
 
-- Check batchsize
if (@batchsize < 1 or @batchsize > 250000)
begin
   Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
  print @time_now + ': Error: Batchsize must be between 1 and 250000.' 
  set @LogMessage = 'Error: Batchsize must be between 1 and 250000.'
  exec SF_Logger @SPName, N'Message', @LogMessage 
  GOTO ERR_HANDLER
end
 
declare @delim_table_name sysname
declare @prev_table sysname
declare @delim_prev_table sysname
declare @server sysname
declare @database sysname
 
-- Is it a history or share table
-- If so, chunking occurs on the parent id
declare @isHistory int
declare @isShare int
declare @nameLength int
declare @base_object sysname
declare @parentId_name sysname
declare @UsingFiles int
set @UsingFiles = 0
 
set @isHistory = 0
if LEN(@table_name) > 8
begin
if RIGHT(@table_name,7) = 'History'
  set @isHistory =1 
if RIGHT(@table_name,7) = 'history'
  set @isHistory =1
set @nameLength = LEN(@table_name) 
set @base_object = LEFT(@table_name, @nameLength - 7)
-- Handle exception for OpportunityFieldHistory
if LOWER(@base_object) = 'opportunityfield' set @base_object='Opportunity'
set @parentId_name = @base_object + 'Id'
 
if RIGHT(@base_object,2) = '__'
begin
  set @base_object = @base_object + 'c'
  set @parentId_name = 'ParentId'
end  
end
 
set @isShare = 0
if LEN(@table_name) > 6 and @isHistory = 0
begin
if RIGHT(@table_name,5) = 'Share'
  set @isShare =1 
if RIGHT(@table_name,5) = 'share'
  set @isShare =1
set @nameLength = LEN(@table_name) 
set @base_object = LEFT(@table_name, @nameLength - 5)
set @parentId_name = @base_object + 'Id'
 
if RIGHT(@base_object,2) = '__'
begin
  set @base_object = @base_object + 'c'
  set @parentId_name = 'ParentId'
end  
end 

-- Adjust batchsize if parent batching
if @batchsize = 250000 and (@isShare = 1 or @isHistory = 1)
begin
	set @batchsize = 25000
end

Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))  
print @time_now + ': Using batch size of '  + convert(nvarchar(25),@batchsize-1)  + ''')'
set @LogMessage = 'Using batch size of ' + convert(nvarchar(25), @batchsize-1) + ''')'
exec SF_Logger @SPName, N'Message', @LogMessage
 
-- Force bulkapi
if @bulkapi_option is null 
set @bulkapi_option = 'bulkapi'
else
set @bulkapi_option = 'bulkapi,' + @bulkapi_option 
 
 
-- Put delimeters around names so we can name tables User, etc...
set @delim_table_name = '[' + @table_name + ']'
set @prev_table = @table_name + '_Previous'
set @delim_prev_table = '[' + @prev_table + ']'
 
-- Determine whether the local table and the previous copy exist
declare @table_exist int
declare @prev_exist int
 
set @table_exist = 0
set @prev_exist = 0;
IF EXISTS (SELECT 1
    FROM INFORMATION_SCHEMA.TABLES
    WHERE TABLE_TYPE='BASE TABLE' 
    AND TABLE_NAME=@table_name)
        set @table_exist = 1
IF (@@ERROR <> 0) GOTO ERR_HANDLER
 
IF EXISTS (SELECT 1
    FROM INFORMATION_SCHEMA.TABLES
    WHERE TABLE_TYPE='BASE TABLE' 
    AND TABLE_NAME=@prev_table)
        set @prev_exist = 1
IF (@@ERROR <> 0) GOTO ERR_HANDLER

if @prev_exist = 0 and @restartId is not null
Begin
  Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
  print @time_now + ': Error: a restart Id is being used when the ' + @prev_table + ' does not exist.'
  set @LogMessage = 'Error: a restart Id is being used when the ' + @prev_table + ' does not exist.'
  exec SF_Logger @SPName, N'Message', @LogMessage
  GOTO ERR_HANDLER
End
 
if @table_exist = 1
begin
-- Make sure that the table doesn't have any keys defined
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
      WHERE CONSTRAINT_TYPE = 'FOREIGN KEY' AND TABLE_NAME=@table_name )
        begin
   Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
  print @time_now + ': Error: The table contains foreign keys and cannot be replicated.'
  set @LogMessage = 'Error: The table contains foreign keys and cannot be replicated.'
  exec SF_Logger @SPName, N'Message', @LogMessage
  GOTO ERR_HANDLER
end
end

if @restartId is null
Begin
	-- If the previous table exists, drop it
	Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
	print @time_now + ': Drop ' + @prev_table + ' if it exists.'
	set @LogMessage = 'Drop ' + @prev_table + ' if it exists.'
	exec SF_Logger @SPName, N'Message', @LogMessage
	if (@prev_exist = 1)
			exec ('Drop table ' + @delim_prev_table)
	IF (@@ERROR <> 0) GOTO ERR_HANDLER

	-- Create an empty local table with the current structure of the Salesforce object
	Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
	print @time_now + ': Create ' + @prev_table + ' with new structure.'
	set @LogMessage = 'Create ' + @prev_table + ' with new structure.'
	exec SF_Logger @SPName, N'Message', @LogMessage 

	begin try
	exec ('Select Top 0 * into ' + @delim_prev_table + ' from ' + @table_server + '...' + @delim_table_name )
	end try
	begin catch
		Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
		print @time_now + ': Error: Salesforce table does not exist: ' + @table_name
		set @LogMessage = 'Error: Salesforce table does not exist: ' + @table_name
		exec SF_Logger @SPName, N'Message', @LogMessage
		print @time_now +
			': Error: ' + ERROR_MESSAGE();
		set @LogMessage = 'Error: ' + ERROR_MESSAGE()
		exec SF_Logger @SPName, N'Message', @LogMessage
		GOTO ERR_HANDLER
	end catch
End

-- Retrieve current server name and database
select @server = @@servername, @database = DB_NAME()
SET @server = CAST(SERVERPROPERTY('ServerName') AS sysname) 
 
declare @WhereClause nvarchar(512)
declare @StartId nvarchar(18)
declare @EndId nvarchar(18)
declare @AllDone int
if @restartId is Null
Begin
	set @StartId = '000000000000000'
End
Else
Begin
	set @StartId = @restartId
End
set @AllDone = 0
 
LOOP:
-- Query for EndId
Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
print @time_now + ': Running query to determine next Id boundary.'
set @LogMessage = 'Running query to determine next Id boundary.'
--exec SF_Logger @SPName, N'Message', @LogMessage
set @EndId = null
select @sql = 'Select @ENDID_OUT = Id from openquery(' 
select @sql = @sql + @table_server + ',''select Id from '
if (@isHistory = 0 and @isShare = 0)
begin
select @sql = @sql + @table_name 
end
else
begin
select @sql = @sql + @base_object 
end
select @sql = @sql + '_QueryAll where Id > ' + '''''' + @StartId + ''''' order by Id asc limit 1 '
set @sqlNoOffset = @sql + ''')'

select @sql = @sql + 'offset ' + convert(nvarchar(25),@batchsize-1)  + ''')'
print @sql
select @parmlist = '@ENDID_OUT nvarchar(18) OUTPUT'

DECLARE @retry INT;
SET @retry = 5;
WHILE (@retry > 0)
BEGIN
    BEGIN TRY
		exec sp_executesql @sql,@parmlist, @ENDID_OUT=@EndId OUTPUT
		set @retry = 0
	End Try
	Begin Catch
        SET @retry = @retry - 1;
		if @retry = 0
		Begin
			Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
			print @time_now + ': Query to determine next Id boundary failed after 5 retries.'
			Goto ERR_HANDLER
		End
		Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
		print @time_now + ': Retry query to determine next Id boundary.'
	End Catch
End

IF (@@ERROR <> 0) GOTO ERR_HANDLER
if @EndId is null
begin
  set @AllDone = 1
  
  if (@StartId = '000000000000000')
  begin
    -- Need to determine prefix
    exec sp_executesql @sqlNoOffset,@parmlist, @ENDID_OUT=@EndId OUTPUT
    if @EndId is null
    Begin
		-- Zero records so just end
		--Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
		--print @time_now + ': Error occurred, the table has no rows.'
		GOTO END_LOOP
	end	
	set @EndId = LEFT(@EndId,3)	
  end
  else  -- else StartId is NOT all zeros
  begin 
	set @EndId = LEFT(@StartId,3)
  end
  
  set @EndId = @EndId + 'zzzzzzzzzzzz'   
end

set @Command = @ProgDir + 'DBAmpNet2.exe Export' 

Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
print @time_now + ': Run the DBAmpNet2.exe program.' 
set @LogMessage = 'Run the DBAmpNet2.exe program.'
--exec SF_Logger @SPName, N'Message', @LogMessage

set @EndingMessageThere = 0

-- Execute DBAmp.exe to get these rows from sf
set @Command = @Command + ' "' + 'Replicate:' + Replace(@bulkapi_option, ' ', '') + '" '
set @Command = @Command + ' "' + @prev_table + '" '
set @Command = @Command + ' "' + @server + '" '
set @Command = @Command + ' "' + @database + '" '
set @Command = @Command + ' "' + @table_server + '" '
 
-- Add where clause
if (@isHistory = 0 and @isShare = 0)
begin
set @WhereClause = ' "where Id>'''
end
else
begin
set @WhereClause = ' "where ' + @parentId_name + '>'''
end
set @WhereClause = @WhereClause + @StartId
set @WhereClause = @WhereClause + ''''
if @EndId is not null
begin
if (@isHistory = 0 and @isShare = 0)
begin
set @WhereClause = @WhereClause + ' and Id<='''
end
else
begin
set @WhereClause = @WhereClause + ' and ' + @parentId_name + '<='''
end
set @WhereClause = @WhereClause + @EndId
set @WhereClause = @WhereClause + ''' "'
end
--print @WhereClause
set @Command = @Command + @WhereClause
Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
print @time_now + ': Run the DBAmp.exe program for ' + @WhereClause
set @LogMessage = 'Run the DBAmp.exe program for ' + @WhereClause 
--exec SF_Logger @SPName, N'Message', @LogMessage
 
-- Create temp table to hold output
declare @errorlog table (line varchar(255))
 
delete from @errorlog

-- Execute DBAmp.exe to get these rows from sf
begin try
insert into @errorlog
exec @Result = master..xp_cmdshell @Command
end try
begin catch
  print 'Error occurred running the DBAmp.exe program'
Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
print @time_now + ': Error occurred running the DBAmp.exe program'
set @LogMessage = 'Error occurred running the DBAmp.exe program'
--exec SF_Logger @SPName, N'Message', @LogMessage
print @time_now +
': Error: ' + ERROR_MESSAGE();
set @LogMessage = 'Error: ' + ERROR_MESSAGE()
--exec SF_Logger @SPName, N'Message', @LogMessage
-- Roll back any active or uncommittable transactions before
-- inserting information in the ErrorLog.
IF XACT_STATE() <> 0
BEGIN
ROLLBACK TRANSACTION;
END
   
 set @Result = -1
end catch
 
if @@ERROR <> 0
  set @Result = -1
 
-- print output to msgs
declare @line varchar(255)
declare @printCount int
Set @printCount = 0
 
DECLARE tables_cursor CURSOR FOR SELECT line FROM @errorlog
OPEN tables_cursor
FETCH NEXT FROM tables_cursor INTO @line
WHILE (@@FETCH_STATUS <> -1)
BEGIN
  if @line is not null 
begin
print @line
if CHARINDEX('DBAmpNet2 Operation successful.',@line) > 0
	begin
		set @EndingMessageThere = 1
	end
--exec SF_Logger @SPName,N'Message', @line
Set @printCount = @printCount + 1
end
  FETCH NEXT FROM tables_cursor INTO @line
END
deallocate tables_cursor

if @Result = -1 or @printCount = 0 or @printCount = 1 or (@EndingMessageThere = 0 and @UsingFiles = 1)
BEGIN
  Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
print @time_now + ': Error: DBAmp.exe was unsuccessful.'
set @LogMessage = 'Error: DBAmp.exe was unsuccessful.'
--exec SF_Logger @SPName, N'Message', @LogMessage
print @time_now + ': Error: Command string is ' + @Command
set @LogMessage = 'Error: Command string is ' + @Command
--exec SF_Logger @SPName, N'Message', @LogMessage
  GOTO RESTORE_ERR_HANDLER
END
if @AllDone = 0
begin 
set @StartId = @EndId
goto LOOP
end

END_LOOP:
declare @primarykey_exists as int
set @primarykey_exists = 0
 
if @table_exist = 1
begin
-- Check to see if the table had a primary key defined
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
      WHERE CONSTRAINT_TYPE = 'PRIMARY KEY' AND TABLE_NAME=@table_name )
    begin
Set @primarykey_exists = 1
end
end
 
-- Change for V2.14.2:  Always create primary key
Set @primarykey_exists = 1
 
BEGIN TRY
    BEGIN TRANSACTION;
-- If the local table exists, drop it
Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
print @time_now + ': Drop ' + @table_name + ' if it exists.'
set @LogMessage = 'Drop ' + @table_name + ' if it exists.'
exec SF_Logger @SPName, N'Message', @LogMessage
if (@table_exist = 1)
exec ('Drop table ' + @delim_table_name)
 
-- Backup previous table into current
Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
print @time_now + ': Rename previous table from ' + @prev_table + ' to ' + @table_name
set @LogMessage = 'Rename previous table from ' + @prev_table + ' to ' + @table_name
exec SF_Logger @SPName, N'Message', @LogMessage
exec sp_rename @prev_table, @table_name
 
    -- If the DDL statement succeeds, commit the transaction.
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
print @time_now + ': Error occurred dropping and renaming the table.'
set @LogMessage = 'Error occurred dropping and renaming the table.'
exec SF_Logger @SPName, N'Message', @LogMessage 
print @time_now +
': Error: ' + ERROR_MESSAGE();
set @LogMessage = 'Error: ' + ERROR_MESSAGE()
exec SF_Logger @SPName, N'Message', @LogMessage
     -- Roll back any active or uncommittable transactions before
     -- inserting information in the ErrorLog.
     IF XACT_STATE() <> 0
     BEGIN
         ROLLBACK TRANSACTION;
     END
     goto ERR_HANDLER
END CATCH
 
-- Recreate Primary Key is needed
BEGIN TRY
Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
print @time_now + ': Create primary key on ' + @table_name
set @LogMessage = 'Create primary key on ' + @table_name
exec SF_Logger @SPName, N'Message', @LogMessage
if (@primarykey_exists = 1)
  -- Add Id as Primary Key
  exec ('Alter table ' + @delim_table_name + ' Add Constraint PK_' + @table_name + '_Id Primary Key NONCLUSTERED (Id) ')
END TRY
BEGIN CATCH
Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
print @time_now + ': Error occurred creating primary key for table.'
set @LogMessage = 'Error occurred creating primary key for table.'
exec SF_Logger @SPName, N'Message', @LogMessage
print @time_now +
': Warning: ' + ERROR_MESSAGE();
set @LogMessage = 'Warning: ' + ERROR_MESSAGE()
exec SF_Logger @SPName, N'Message', @LogMessage
     -- Roll back any active or uncommittable transactions before
     -- inserting information in the ErrorLog.
     IF XACT_STATE() <> 0
     BEGIN
         ROLLBACK TRANSACTION;
     END
     --goto ERR_HANDLER
END CATCH
 
print '--- Ending SF_ReplicateLarge. Operation successful.'
set @LogMessage = 'Ending - Operation Successful.' 
exec SF_Logger @SPName,N'Successful', @LogMessage
set NOCOUNT OFF
return 0
 
RESTORE_ERR_HANDLER:
print('--- Ending SF_ReplicateLarge. Operation FAILED.')
set @LogMessage = 'Ending - Operation Failed.' 
exec SF_Logger @SPName, N'Failed',@LogMessage
RAISERROR ('--- Ending SF_ReplicateLarge. Operation FAILED.',16,1)
set NOCOUNT OFF
return 1
 
ERR_HANDLER:
print('--- Ending SF_ReplicateLarge. Operation FAILED.')
set @LogMessage = 'Ending - Operation Failed.' 
exec SF_Logger @SPName,N'Failed', @LogMessage
RAISERROR ('--- Ending SF_ReplicateLarge. Operation FAILED.',16,1)
set NOCOUNT OFF
return 1
Go

IF EXISTS (SELECT name
	   FROM   sysobjects
	   WHERE  name = N'SF_ReplicateKAV'
	   AND 	  type = 'P')
    DROP PROCEDURE SF_ReplicateKAV
GO

Create PROCEDURE [dbo].[SF_ReplicateKAV]
	@table_server sysname,
	@table_name sysname,
	@options nvarchar(255) = NULL
AS
-- Parameters: @table_server           - Salesforce Linked Server name (i.e. SALESFORCE)
--             @table_name             - Salesforce object to copy (i.e. Account)


declare @Result 	int
declare @Command 	nvarchar(4000)
declare @time_now	char(8)
set NOCOUNT ON

print '--- Starting SF_ReplicateKAV for ' + @table_name + ' ' +  dbo.SF_Version()

declare @delim_table_name sysname
declare @prev_table sysname
declare @delim_prev_table sysname
declare @server sysname
declare @database sysname
declare @LogMessage nvarchar(max)
declare @SPName nvarchar(50)
declare @language nvarchar(100)
declare @table_namemissingv sysname
declare @sf_field_exists int

set @SPName = 'SF_ReplicateKAV:' + CONVERT(nvarchar(255), NEWID(), 20)
set @LogMessage = 'Parameters: ' + @table_server + ' ' + @table_name + ' ' + ISNULL(@options, ' ') + ' Version: ' +  dbo.SF_Version()
exec SF_Logger @SPName, N'Starting', @LogMessage

If exists(select Data
	from SF_Split(SUBSTRING(@options, 1, 1000), ',', 1) 
	where Data like '%bulkapi%' or Data like '%pkchunk%')
Begin
	Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
    print @time_now + ': Error: bulkapi and pkchunk options are not supported.'
    set @LogMessage = 'Error: bulkapi and pkchunk options are not supported.'
    exec SF_Logger @SPName, N'Message', @LogMessage
	GOTO ERR_HANDLER
End

-- Put delimeters around names so we can name tables User, etc...
set @delim_table_name = '[' + @table_name + ']'
set @prev_table = @table_name + '_Previous'
set @delim_prev_table = '[' + @prev_table + ']'

-- Determine whether the local table and the previous copy exist
declare @table_exist int
declare @prev_exist int

set @table_exist = 0
set @prev_exist = 0;
IF EXISTS (SELECT 1
    FROM INFORMATION_SCHEMA.TABLES
    WHERE TABLE_TYPE='BASE TABLE' 
    AND TABLE_NAME=@table_name)
        set @table_exist = 1
IF (@@ERROR <> 0) GOTO ERR_HANDLER

IF EXISTS (SELECT 1
    FROM INFORMATION_SCHEMA.TABLES
    WHERE TABLE_TYPE='BASE TABLE' 
    AND TABLE_NAME=@prev_table)
        set @prev_exist = 1
IF (@@ERROR <> 0) GOTO ERR_HANDLER

-- Get the sessionId from DBAmp. This also tests connectivity to salesforce.com
declare @sql nvarchar(4000)
declare @parmlist nvarchar(512)

if @table_exist = 1
begin
	-- Make sure that the table doesn't have any keys defined
	IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    		   WHERE CONSTRAINT_TYPE = 'FOREIGN KEY' AND TABLE_NAME=@table_name)
        begin
 	   Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
	   print @time_now + ': Error: The table contains foreign keys and cannot be replicated.'
	   set @LogMessage = 'Error: The table contains foreign keys and cannot be replicated.'
	   exec SF_Logger @SPName, N'Message', @LogMessage
	   GOTO ERR_HANDLER
	end
end

-- If the previous table exists, drop it
Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
print @time_now + ': Drop ' + @prev_table + ' if it exists.'
set @LogMessage = 'Drop ' + @prev_table + ' if it exists.'
exec SF_Logger @SPName, N'Message', @LogMessage
if (@prev_exist = 1)
        exec ('Drop table ' + @delim_prev_table)
IF (@@ERROR <> 0) GOTO ERR_HANDLER

-- Create an empty local table with the current structure of the Salesforce object
Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
print @time_now + ': Create ' + @prev_table + ' with new structure.'
set @LogMessage = 'Create ' + @prev_table + ' with new structure.'
exec SF_Logger @SPName, N'Message', @LogMessage

begin try
exec ('Select Top 0 * into ' + @delim_prev_table + ' from ' + @table_server + '...' + @delim_table_name )
end try
begin catch
	Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
	print @time_now + ': Error: Salesforce table does not exist: ' + @table_name
	set @LogMessage = 'Error: Salesforce table does not exist: ' + @table_name
	exec SF_Logger @SPName, N'Message', @LogMessage
	print @time_now +
		': Error: ' + ERROR_MESSAGE();
	set @LogMessage = 'Error: ' + ERROR_MESSAGE()
	exec SF_Logger @SPName, N'Message', @LogMessage
	GOTO ERR_HANDLER
end catch

exec @sf_field_exists = SF_IsValidSFField @table_server, 'KnowledgeArticle', 'MasterLanguage'
if @sf_field_exists = 1
Begin
	Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
	print @time_now + ': Supports multiple languages.'
	If @table_name like '%__kav%' 
	Begin	
		set @table_namemissingv = substring(@table_name, 1, (len(@table_name) - 1))
	End

	If @table_name = 'knowledgearticleversion'
	Begin	
		set @table_namemissingv = substring(@table_name, 1, (len(@table_name) - 7))
	End

	If @table_name like '%__kav%' or @table_name = 'knowledgearticleversion' 
	Begin

		set @sql = 'declare KavTables_cursor cursor for select distinct Language from ' + @table_server + '...KnowledgeArticleVersion' 
		exec sp_executesql @sql

		open KavTables_cursor 

		while 1 = 1
		begin
			fetch next from KavTables_cursor into @language
			if @@error <> 0 or @@fetch_status <> 0 break
			begin
				set @sql = 'Insert into ' + @delim_prev_table + ' select * from ' + @table_server + '...' + @delim_table_name + ' WHERE PublishStatus=' + '''' + 'online' + '''' + ' AND Language = ' + '''' + @language + ''''
				exec sp_executesql @sql
				IF (@@ERROR <> 0) GOTO RESTORE_ERR_HANDLER	
			end
		end

		close KavTables_cursor
		deallocate KavTables_cursor
	End
End
Else
Begin
	Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
	print @time_now + ': Supports single language.'
	set @sql = 'Select @language = LanguageLocaleKey from ' + @table_server + '...Organization'
	Begin Try
		exec sp_executesql @sql, N'@language nvarchar(100) OUTPUT', @language = @language OUTPUT
	End Try
	Begin Catch
		GOTO ERR_HANDLER
	End Catch
	set @sql = 'Insert into ' + @delim_prev_table + ' select * from ' + @table_server + '...' + @delim_table_name + ' WHERE PublishStatus=' + '''' + 'online' + '''' + ' AND Language = ' + '''' + @language + ''''
	Begin Try
		exec sp_executesql @sql
	End Try
	Begin Catch
		GOTO ERR_HANDLER
	End Catch
End
declare @primarykey_exists as int
set @primarykey_exists = 0

if @table_exist = 1
begin
	-- Check to see if the table had a primary key defined
	IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    		   WHERE CONSTRAINT_TYPE = 'PRIMARY KEY' AND TABLE_NAME=@table_name )
    begin
		Set @primarykey_exists = 1
	end
end

-- Change for V2.14.2:  Always create primary key
Set @primarykey_exists = 1

-- If the local table exists, drop it
Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
print @time_now + ': Drop ' + @table_name + ' if it exists.'
set @LogMessage = 'Drop ' + @table_name + ' if it exists.'
exec SF_Logger @SPName, N'Message', @LogMessage
if (@table_exist = 1)
	exec ('Drop table ' + @delim_table_name)
IF (@@ERROR <> 0) GOTO ERR_HANDLER

-- Backup previous table into current
Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
print @time_now + ': Rename previous table from ' + @prev_table + ' to ' + @table_name
set @LogMessage = 'Rename previous table from ' + @prev_table + ' to ' + @table_name
exec SF_Logger @SPName, N'Message', @LogMessage
exec sp_rename @prev_table, @table_name
IF (@@ERROR <> 0) GOTO ERR_HANDLER

declare @totalrows int 
set @totalrows = 0
select @sql = 'Select @rowscopiedOUT = count(Id) from ' + @delim_table_name
select @parmlist = '@rowscopiedOUT int OUTPUT'
exec sp_executesql @sql, @parmlist, @rowscopiedOUT = @totalrows OUTPUT

Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
print @time_now + ': ' + Cast(@totalrows AS nvarchar(10)) + ' rows copied.'
set @LogMessage = @time_now + ': ' + Cast(@totalrows AS nvarchar(10)) + ' rows copied.'
exec SF_Logger @SPName, N'Message', @LogMessage

BEGIN TRY
	Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
	print @time_now + ': Create primary key on ' + @table_name
	set @LogMessage = 'Create primary key on ' + @table_name
	exec SF_Logger @SPName, N'Message', @LogMessage
	if (@primarykey_exists = 1)
	   -- Add Id as Primary Key
	   exec ('Alter table ' + @delim_table_name + ' Add Constraint PK_' + @table_name + '_Id Primary Key NONCLUSTERED (Id) ')
END TRY
BEGIN CATCH
	Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
	print @time_now + ': Error occurred creating primary key for table.'
	set @LogMessage = 'Error occurred creating primary key for table.'
	exec SF_Logger @SPName, N'Message', @LogMessage
	print @time_now +
		': Warning: ' + ERROR_MESSAGE();
	set @LogMessage = 'Warning: ' + ERROR_MESSAGE()
	exec SF_Logger @SPName, N'Message', @LogMessage
	
	 -- Roll back any active or uncommittable transactions before
	 -- inserting information in the ErrorLog.
	 IF XACT_STATE() <> 0
	 BEGIN
		 ROLLBACK TRANSACTION;
	 END
	 --goto ERR_HANDLER
END CATCH

print '--- Ending SF_ReplicateKAV. Operation successful.'
set @LogMessage = 'Ending - Operation Successful.'
exec SF_Logger @SPName, N'Successful', @LogMessage
set NOCOUNT OFF
return 0

RESTORE_ERR_HANDLER:
print('--- Ending SF_ReplicateKAV. Operation FAILED.')
set @LogMessage = 'Ending - Operation Failed.'
exec SF_Logger @SPName, N'Failed', @LogMessage
RAISERROR ('--- Ending SF_ReplicateKAV. Operation FAILED.',16,1)
set NOCOUNT OFF
return 1

ERR_HANDLER:
print('--- Ending SF_ReplicateKAV. Operation FAILED.')
set @LogMessage = 'Ending - Operation Failed.'
exec SF_Logger @SPName, N'Failed', @LogMessage	
RAISERROR ('--- Ending SF_ReplicateKAV. Operation FAILED.',16,1)
set NOCOUNT OFF
return 1

GO

IF EXISTS (SELECT name
	   FROM   sysobjects
	   WHERE  name = N'SF_PopulateCaseArticle'
	   AND 	  type = 'P')
    DROP PROCEDURE SF_PopulateCaseArticle
GO

CREATE PROCEDURE [dbo].[SF_PopulateCaseArticle]
	@SourceLinkedServer sysname,
	@TargetLinkedServer sysname = null,
	@SourceDB nvarchar(50) = null
AS
Set NOCOUNT ON

declare @s nvarchar(1000)
declare @sql nvarchar(max)
declare @TargetDB nvarchar(50)
declare @time_now char(8)
declare @ColumnName nvarchar(1000)

print '--- Starting SF_PopulateCaseArticle' + ' ' + dbo.SF_Version()
Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
print @time_now + ': Parameters: ' + ' ' + ISNULL(@SourceLinkedServer, 'null') + ' ' + ISNULL(@TargetLinkedServer, 'null') + ' ' + ISNULL(@SourceDB, 'null')

If @SourceLinkedServer is null or @SourceLinkedServer like '%null%'
Begin
	Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
	print @time_now + ': Error: You must put in a valid Source Linked Server.' 
	goto ERR_HANDLER
end

If @TargetLinkedServer is null or @TargetLinkedServer like '%null%'
Begin
	Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
	print @time_now + ': Error: You must put in a valid Target Linked Server.' 
	goto ERR_HANDLER
end

If @SourceDB is null or @SourceDB like '%null%'
Begin
	Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
	print @time_now + ': Error: Enter a valid source database.' 
	goto ERR_HANDLER
End

set @TargetDB = QUOTENAME(DB_NAME())
set @SourceDB = QUOTENAME(@SourceDB)

--Drop CaseArticle_Load table if it exists
IF EXISTS (SELECT 1
    FROM INFORMATION_SCHEMA.TABLES
    WHERE TABLE_TYPE='BASE TABLE' 
    AND TABLE_NAME='CaseArticle_Load')
	Drop Table CaseArticle_Load

--Build CaseArticle_Load table
set @sql = 'select *, cast(' + '''' + '''' + ' as nvarchar(512)) as Error into CaseArticle_Load from ' + @SourceLinkedServer + '...CaseArticle'
Begin Try
	exec sp_executesql @sql
End Try
Begin Catch
	goto ERR_HANDLER
End Catch

--Replicate KnowledgeArticleVersion from Source
set @sql = 'exec SF_ReplicateKAV ' + '''' + @SourceLinkedServer + '''' + ', ' + '''' + 'KnowledgeArticleVersion' + ''''
set @s = @SourceDB + '.dbo.sp_executesql'
Begin Try
	exec @s @sql
End Try
Begin Catch
	goto ERR_HANDLER
end Catch

--Replicate KnowledgeArticleVersion from Target into Target DB
set @sql = 'exec SF_ReplicateKAV ' + '''' + @TargetLinkedServer + '''' + ', ' + '''' + 'KnowledgeArticleVersion' + ''''
set @s = @TargetDB + '.dbo.sp_executesql'
Begin Try
	exec @s @sql
End Try
Begin Catch
	goto ERR_HANDLER
end Catch

--Replicate Case from Target into Target DB
set @sql = 'exec SF_Replicate ' + '''' + @TargetLinkedServer + '''' + ', ' + '''' + 'Case' + ''''
set @s = @TargetDB + '.dbo.sp_executesql'
Begin Try
	exec @s @sql
End Try
Begin Catch
	goto ERR_HANDLER
end Catch

Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
print @time_now + ': Updating KnowledgeArticleId field with target Ids'

--Update KnowledgeArticleId field with target Ids
set @sql = 'Update ' + @TargetDB + '.dbo.CaseArticle_Load ' +
		   'Set KnowledgeArticleId = b.KnowledgeArticleId ' +
		   'From ' + @SourceDB + '.dbo.[KnowledgeArticleVersion] a, ' + @TargetDB + '.dbo.[KnowledgeArticleVersion] b, ' + @TargetDB + '.dbo.CaseArticle_Load c ' +
		   'where a.Language = b.Language and a.UrlName = b.UrlName and a.KnowledgeArticleId = c.KnowledgeArticleId'
Begin Try
	exec sp_executesql @sql
End Try
Begin Catch
	goto ERR_HANDLER
End Catch

Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
print @time_now + ': Updating CaseId field with target Ids'

--Update CaseId field with target Ids
set @sql = 'Update ' + @TargetDB + '.dbo.CaseArticle_Load ' +
		   'Set CaseId = c.Id ' +
		   'From ' + @TargetDB + '.dbo.[Case] c ' +
		   'where c.SourceId__c = ' + @TargetDB + '.dbo.CaseArticle_Load.CaseId'
Begin Try
	exec sp_executesql @sql
End Try
Begin Catch
	goto ERR_HANDLER
End Catch

Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
print @time_now + ': Renaming ArticleVersionNumber column'

set @ColumnName = @TargetDB + '.dbo.CaseArticle_Load.ArticleVersionNumber'

Begin Try
	exec sp_rename @ColumnName, 'ArticleVN', 'Column'
End Try
Begin Catch
	goto ERR_HANDLER
End Catch

--Insert CaseArticle into target Org
Begin Try
exec SF_BulkOps 'Insert', @TargetLinkedServer, 'CaseArticle_Load'
End Try
Begin Catch
	goto ERR_HANDLER
End Catch

print '--- Ending SF_PopulateCaseArticle. Operation successful.'
return 0

ERR_HANDLER:
print('--- Ending SF_PopulateCaseArticle. Operation FAILED.')
RAISERROR ('--- Ending SF_PopulateCaseArticle. Operation FAILED.',16,1)
return 1

Set NOCOUNT OFF
Go

IF EXISTS (SELECT name
	   FROM   sysobjects
	   WHERE  name = N'SF_BulkSOQL'
	   AND 	  type = 'P')
    DROP PROCEDURE SF_BulkSOQL
GO

Create PROCEDURE [dbo].[SF_BulkSOQL]
	@table_server sysname,
	@table_name sysname,
	@options	nvarchar(255) = NULL,
	@soql_statement	nvarchar(max) = NULL
AS
-- Parameters: @table_server           - Salesforce Linked Server name (i.e. SALESFORCE)
--             @table_name             - Salesforce object to copy (i.e. Account)

-- @ProgDir - Directory containing the DBAmp.exe. Defaults to the DBAmp program directory
-- If needed, modify this for your installation
declare @ProgDir   	varchar(250) 
set @ProgDir = 'C:\"Program Files"\DBAmp\'

declare @Result 	int
declare @Command 	nvarchar(4000)
declare @time_now	char(8)
set NOCOUNT ON

print '--- Starting SF_BulkSOQL for ' + @table_name + ' ' +  dbo.SF_Version()
declare @LogMessage nvarchar(max)
declare @SPName nvarchar(50)
set @SPName = 'SF_BulkSOQL:' + Convert(nvarchar(255), NEWID(), 20)
set @LogMessage = 'Parameters: ' + @table_server + ' ' + @table_name + ' ' + ISNULL(@options, ' ') + ' Version: ' +  dbo.SF_Version()
Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
print @time_now + ': ' + @LogMessage
exec SF_Logger @SPName, N'Starting',@LogMessage

declare @delim_table_name sysname
declare @prev_table sysname
declare @delim_prev_table sysname
declare @server sysname
declare @database sysname
declare @SOQLTable sysname
declare @UsingFiles int
set @UsingFiles = 0
declare @EndingMessageThere int
set @EndingMessageThere = 0
declare @UsingSOQLStatement int
set @UsingSOQLStatement = 0

-- Put delimeters around names so we can name tables User, etc...
set @delim_table_name = '[' + @table_name + ']'
set @prev_table = @table_name + '_Previous'
set @delim_prev_table = '[' + @prev_table + ']'
set @SOQLTable = @table_name + '_SOQL'

-- Determine whether the local table and the previous copy exist
declare @table_exist int
declare @prev_exist int
declare @soqltable_exist int
declare @SOQLStatement nvarchar(max)
declare @TempSOQLStatement nvarchar(max)
declare @sql nvarchar(1000)
declare @ParmDefinition nvarchar(500)
set @soqltable_exist = 0

IF EXISTS (SELECT 1
    FROM INFORMATION_SCHEMA.TABLES
    WHERE TABLE_TYPE='BASE TABLE' 
    AND TABLE_NAME=@SOQLTable)
        set @soqltable_exist = 1
IF (@@ERROR <> 0) GOTO ERR_HANDLER

if @soql_statement is not null
Begin
	set @UsingSOQLStatement = 1
	
	-- If the SOQL table exists, drop it
	Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
	print @time_now + ': Drop ' + @SOQLTable + ' if it exists.'
	set @LogMessage = 'Drop ' + @SOQLTable + ' if it exists.'
	exec SF_Logger @SPName, N'Message', @LogMessage
	if @soqltable_exist = 1
	Begin
		exec ('Drop table ' + @SOQLTable)
		IF (@@ERROR <> 0) GOTO ERR_HANDLER
	End

	-- Create SOQL table
	Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
	print @time_now + ': Creating table ' + @SOQLTable + '.'
	set @LogMessage = 'Creating table ' + @SOQLTable + '.'
    exec SF_Logger @SPName, N'Message', @LogMessage
	set @sql = 'CREATE TABLE ' + @SOQLTable + ' (SOQL nvarchar(max))'
	EXECUTE sp_executesql @sql
	set @soqltable_exist = 1
	
	-- Populate SOQL table
	Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
	print @time_now + ': Populating ' + @SOQLTable + ' with SOQL statement.'
	set @LogMessage = 'Populating ' + @SOQLTable + ' with SOQL statement.'
	exec SF_Logger @SPName, N'Message', @LogMessage
	set @sql = 'Insert Into ' + @SOQLTable + '(SOQL) values (''' + REPLACE(@soql_statement, '''', '''''') + ''')'
	EXECUTE sp_executesql @sql;
End

if @soqltable_exist = 0
Begin
   Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
   print @time_now + ': Error: The ' + @SOQLTable + ' table does not exist. Create an ' + @SOQLTable + ' table and populate it with a valid SOQL statement.'
   set @LogMessage = 'Error: The ' + @SOQLTable + ' table does not exist. Create an ' + @SOQLTable + ' table and populate it with a valid SOQL statement.'
   exec SF_Logger @SPName, N'Message', @LogMessage
   GOTO ERR_HANDLER
End

select @sql = N'select @SOQLStatementOut = SOQL from ' + @table_name + '_SOQL'
set @ParmDefinition = N'@SOQLStatementOut nvarchar(max) OUTPUT'
exec sp_executesql @sql, @ParmDefinition, @SOQLStatementOut = @SOQLStatement OUTPUT 

if @SOQLStatement is null or @SOQLStatement = ''
Begin
   Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
   print @time_now + ': Error: The SOQL Statement provided does not exist. Populate the SOQL column with a valid SOQL Statement.'
   set @LogMessage = 'Error: The SOQL Statement provided does not exist. Populate the SOQL column with a valid SOQL Statement.'
   exec SF_Logger @SPName, N'Message', @LogMessage
   GOTO ERR_HANDLER
End

set @table_exist = 0
set @prev_exist = 0;
IF EXISTS (SELECT 1
    FROM INFORMATION_SCHEMA.TABLES
    WHERE TABLE_TYPE='BASE TABLE' 
    AND TABLE_NAME=@table_name)
        set @table_exist = 1
IF (@@ERROR <> 0) GOTO ERR_HANDLER

IF EXISTS (SELECT 1
    FROM INFORMATION_SCHEMA.TABLES
    WHERE TABLE_TYPE='BASE TABLE' 
    AND TABLE_NAME=@prev_table)
        set @prev_exist = 1
IF (@@ERROR <> 0) GOTO ERR_HANDLER

if @table_exist = 1
begin
	-- Make sure that the table doesn't have any keys defined
	IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    		   WHERE CONSTRAINT_TYPE = 'FOREIGN KEY' AND TABLE_NAME=@table_name )
        begin
 	   Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
	   print @time_now + ': Error: The table contains foreign keys and cannot be replicated.' 
	   set @LogMessage = 'Error: The table contains foreign keys and cannot be replicated.'
	   exec SF_Logger @SPName, N'Message', @LogMessage
	   GOTO ERR_HANDLER
	end
end

-- If the previous table exists, drop it
Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
print @time_now + ': Drop ' + @prev_table + ' if it exists.'
set @LogMessage = 'Drop ' + @prev_table + ' if it exists.'
exec SF_Logger @SPName, N'Message', @LogMessage
if (@prev_exist = 1)
        exec ('Drop table ' + @delim_prev_table)
IF (@@ERROR <> 0) GOTO ERR_HANDLER

-- Create an empty local table with the current structure of the Salesforce object
Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
print @time_now + ': Create ' + @prev_table + ' with new structure.'
set @LogMessage = 'Create ' + @prev_table + ' with new structure.'
exec SF_Logger @SPName, N'Message', @LogMessage

set @TempSOQLStatement = REPLACE(@SOQLStatement, '''', '''''')

-- Create previous table from _SOQL table
begin try
exec ('Select * into ' + @delim_prev_table + ' from openquery(' + @table_server + ', ' + '''' + @TempSOQLStatement + ' Limit 0' + '''' + ') where 1=0')
end try
begin catch
	Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
	print @time_now + ': Error: Could not create previous table.'
	set @LogMessage = 'Error: Could not create previous table.'
	exec SF_Logger @SPName, N'Message', @LogMessage
	print @time_now +
		': Error: ' + ERROR_MESSAGE();
	set @LogMessage = 'Error: ' + ERROR_MESSAGE()
	exec SF_Logger @SPName, N'Message', @LogMessage
	GOTO ERR_HANDLER
end catch

-- Retrieve current server name and database
select @server = @@servername, @database = DB_NAME()
SET @server = CAST(SERVERPROPERTY('ServerName') AS sysname) 

-- Execute DBAmp.exe to load table from Salesforce
Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
print @time_now + ': Run the DBAmpNet2.exe program.' 
set @LogMessage = 'Run the DBAmpNet2.exe program.'
exec SF_Logger @SPName, N'Message', @LogMessage

set @UsingFiles = 1
set @Command = @ProgDir + 'DBAmpNet2.exe Export'
if @options is null or @options = ''
begin
	set @options = 'bulksoql'
end
else
begin
	set @options = @options + ', bulksoql'
end

if (@options is not null)
begin
	set @Command = @Command + ' "' + 'Replicate:' + Replace(@options, ' ', '') + '" '
end
set @Command = @Command + ' "' + @prev_table + '" '
set @Command = @Command + ' "' + @server + '" '
set @Command = @Command + ' "' + @database + '" '
set @Command = @Command + ' "' + @table_server + '" '
set @Command = @Command + ' "' + @table_name + '" '

-- Create temp table to hold output
declare @errorlog table (line varchar(255))

begin try
insert into @errorlog
	exec @Result = master..xp_cmdshell @Command
end try
begin catch
   print 'Error occurred running the DBAmp.exe program'	
	Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
	print @time_now + ': Error occurred running the DBAmpNet2.exe program'
	set @LogMessage = 'Error occurred running the DBAmpNet2.exe program'
	exec SF_Logger @SPName, N'Message', @LogMessage
	print @time_now +
		': Error: ' + ERROR_MESSAGE();
	set @LogMessage = 'Error: ' + ERROR_MESSAGE()
	exec SF_Logger @SPName, N'Message', @LogMessage
		
     -- Roll back any active or uncommittable transactions before
     -- inserting information in the ErrorLog.
     IF XACT_STATE() <> 0
     BEGIN
         ROLLBACK TRANSACTION;
     END
    
  set @Result = -1
end catch

if @@ERROR <> 0
   set @Result = -1

-- print output to msgs
declare @line varchar(255)
declare @printCount int
Set @printCount = 0

DECLARE tables_cursor CURSOR FOR SELECT line FROM @errorlog
OPEN tables_cursor
FETCH NEXT FROM tables_cursor INTO @line
WHILE (@@FETCH_STATUS <> -1)
BEGIN
   if @line is not null 
	begin
	print @line
	if CHARINDEX('DBAmpNet2 Operation successful.',@line) > 0
	begin
		set @EndingMessageThere = 1
	end
	exec SF_Logger @SPName,N'Message', @line
	Set @printCount = @printCount + 1
	end
   FETCH NEXT FROM tables_cursor INTO @line
END
deallocate tables_cursor

if @Result = -1 or @printCount = 0 or @printCount = 1 or (@EndingMessageThere = 0 and @UsingFiles = 1)
BEGIN
  	Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
	print @time_now + ': Error: DBAmpNet2.exe was unsuccessful.'
	set @LogMessage = 'Error: DBAmpNet2.exe was unsuccessful.'
	exec SF_Logger @SPName, N'Message', @LogMessage
	print @time_now + ': Error: Command string is ' + @Command
	set @LogMessage = 'Error: Command string is ' + @Command
	exec SF_Logger @SPName, N'Message', @LogMessage
  	GOTO RESTORE_ERR_HANDLER
END

declare @primarykey_exists as int
set @primarykey_exists = 0

if @table_exist = 1
begin
	-- Check to see if the table had a primary key defined
	IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    		   WHERE CONSTRAINT_TYPE = 'PRIMARY KEY' AND TABLE_NAME=@table_name )
    begin
		Set @primarykey_exists = 1
	end
end

-- Change for V2.14.2:  Always create primary key
Set @primarykey_exists = 1

if Lower(@table_name) = 'oauthtoken' set @primarykey_exists = 0
if Lower(@table_name) = 'apexpageinfo' set @primarykey_exists = 0
if Lower(@table_name) = 'recentlyviewed' set @primarykey_exists = 0
if Lower(@table_name) = 'datatype' set @primarykey_exists = 0
if Lower(@table_name) = 'loginevent' set @primarykey_exists = 0
if Lower(@table_name) = 'casearticle' set @primarykey_exists = 0
if Lower(@table_name) = 'publisher' set @primarykey_exists = 0
if Lower(@table_name) = 'auradefinitioninfo' set @primarykey_exists = 0
if Lower(@table_name) = 'auradefinitionbundleinfo' set @primarykey_exists = 0 
set @options = Lower(@options)

BEGIN TRY
    BEGIN TRANSACTION;
		-- If the local table exists, drop it
		Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
		print @time_now + ': Drop ' + @table_name + ' if it exists.'
		set @LogMessage = 'Drop ' + @table_name + ' if it exists.'
		exec SF_Logger @SPName, N'Message', @LogMessage
		if (@table_exist = 1)
			exec ('Drop table ' + @delim_table_name)

		-- Backup previous table into current
		Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
		print @time_now + ': Rename previous table from ' + @prev_table + ' to ' + @table_name
		set @LogMessage = 'Rename previous table from ' + @prev_table + ' to ' + @table_name
		exec SF_Logger @SPName, N'Message', @LogMessage
		exec sp_rename @prev_table, @table_name
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
	Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
	print @time_now + ': Error occurred dropping and renaming the table.'
	set @LogMessage = 'Error occurred dropping and renaming the table.'
	exec SF_Logger @SPName, N'Message', @LogMessage
	print @time_now +
		': Error: ' + ERROR_MESSAGE();
	set @LogMessage = 'Error: ' + ERROR_MESSAGE()
	exec SF_Logger @SPName, N'Message', @LogMessage

     -- Roll back any active or uncommittable transactions before
     -- inserting information in the ErrorLog.
     IF XACT_STATE() <> 0
     BEGIN
         ROLLBACK TRANSACTION;
     END
     goto ERR_HANDLER
END CATCH

--Clean up any previous table
IF EXISTS (SELECT 1
    FROM INFORMATION_SCHEMA.TABLES
    WHERE TABLE_TYPE='BASE TABLE'
    AND TABLE_NAME=@prev_table)
begin
   exec ('Drop table ' + @prev_table)
end

--if @UsingSOQLStatement = 1
--Begin
--	IF EXISTS (SELECT 1
--    FROM INFORMATION_SCHEMA.TABLES
--    WHERE TABLE_TYPE='BASE TABLE'
--    AND TABLE_NAME=@SOQLTable)
--	begin
--		exec ('Drop table ' + @SOQLTable)
--	end
--End

print '--- Ending SF_BulkSOQL. Operation successful.'
set @LogMessage = 'Ending - Operation Successful.' 
exec SF_Logger @SPName,N'Successful', @LogMessage
set NOCOUNT OFF
return 0

RESTORE_ERR_HANDLER:
print('--- Ending SF_BulkSOQL. Operation FAILED.')
set @LogMessage = 'Ending - Operation Failed.' 
exec SF_Logger @SPName, N'Failed',@LogMessage
RAISERROR ('--- Ending SF_BulkSOQL. Operation FAILED.',16,1)
set NOCOUNT OFF
return 1

ERR_HANDLER:
print('--- Ending SF_BulkSOQL. Operation FAILED.')
set @LogMessage = 'Ending - Operation Failed.' 
exec SF_Logger @SPName,N'Failed', @LogMessage
RAISERROR ('--- Ending SF_BulkSOQL. Operation FAILED.',16,1)
set NOCOUNT OFF
return 1
Go

IF EXISTS (SELECT name
	   FROM   sysobjects
	   WHERE  name = N'SF_DownloadBlobs'
	   AND 	  type = 'P')
    DROP PROCEDURE SF_DownloadBlobs
GO
Create PROCEDURE [dbo].[SF_DownloadBlobs]
	@table_server sysname,
	@table_name sysname
AS
-- Parameters: @table_server           - Salesforce Linked Server name (i.e. SALESFORCE)
--             @table_name             - Salesforce object to copy (i.e. Account)

-- @ProgDir - Directory containing the DBAmp.exe. Defaults to the DBAmp program directory
-- If needed, modify this for your installation
declare @ProgDir   	varchar(250) 
--set @ProgDir = 'C:\Users\Administrator\Documents\"Visual Studio 2013"\Projects\DBAmp\DBAmp\DBAmpNet2\bin\Debug\'
set @ProgDir = 'C:\"Program Files"\DBAmp\'

declare @Result 	int
declare @Command 	nvarchar(4000)
declare @time_now	char(8)
set NOCOUNT ON

print '--- Starting SF_DownloadBlobs for ' + @table_name + ' ' +  dbo.SF_Version()
declare @LogMessage nvarchar(max)
declare @SPName nvarchar(50)
set @SPName = 'SF_DownloadBlobs:' + Convert(nvarchar(255), NEWID(), 20)
set @LogMessage = 'Parameters: ' + @table_server + ' ' + @table_name + ' ' + ' Version: ' +  dbo.SF_Version()
Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
print @time_now + ': ' + @LogMessage
exec SF_Logger @SPName, N'Starting',@LogMessage

declare @delim_table_name sysname
declare @server sysname
declare @database sysname
declare @UsingFiles int
set @UsingFiles = 0
declare @EndingMessageThere int
set @EndingMessageThere = 0

-- Put delimeters around names so we can name tables User, etc...
set @delim_table_name = '[' + @table_name + ']'

-- Determine whether the local table and the previous copy exist
declare @table_exist int
declare @prev_exist int

set @table_exist = 0
set @prev_exist = 0;

-- Retrieve current server name and database
select @server = @@servername, @database = DB_NAME()
SET @server = CAST(SERVERPROPERTY('ServerName') AS sysname) 

-- Execute DBAmp.exe to load table from Salesforce
Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
print @time_now + ': Run the DBAmpNet2.exe program.' 
set @LogMessage = 'Run the DBAmpNet2.exe program.'
exec SF_Logger @SPName, N'Message', @LogMessage

set @UsingFiles = 1
set @Command = @ProgDir + 'DBAmpNet2.exe DownloadBlobs' 
set @Command = @Command + ' "' + 'DownloadBlobs' + '" '
set @Command = @Command + ' "' + @table_name + '" '
set @Command = @Command + ' "' + @server + '" '
set @Command = @Command + ' "' + @database + '" '
set @Command = @Command + ' "' + @table_server + '" '

-- Create temp table to hold output
declare @errorlog table (line varchar(255))

begin try
insert into @errorlog
	exec @Result = master..xp_cmdshell @Command
end try
begin catch
   print 'Error occurred running the DBAmp.exe program'	
	Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
	print @time_now + ': Error occurred running the DBAmpNet2.exe program'
	set @LogMessage = 'Error occurred running the DBAmpNet2.exe program'
	exec SF_Logger @SPName, N'Message', @LogMessage
	print @time_now +
		': Error: ' + ERROR_MESSAGE();
	set @LogMessage = 'Error: ' + ERROR_MESSAGE()
	exec SF_Logger @SPName, N'Message', @LogMessage
		
     -- Roll back any active or uncommittable transactions before
     -- inserting information in the ErrorLog.
     IF XACT_STATE() <> 0
     BEGIN
         ROLLBACK TRANSACTION;
     END
    
  set @Result = -1
end catch

if @@ERROR <> 0
   set @Result = -1

-- print output to msgs
declare @line varchar(255)
declare @printCount int
Set @printCount = 0

DECLARE tables_cursor CURSOR FOR SELECT line FROM @errorlog
OPEN tables_cursor
FETCH NEXT FROM tables_cursor INTO @line
WHILE (@@FETCH_STATUS <> -1)
BEGIN
   if @line is not null 
	begin
	print @line
	if CHARINDEX('DBAmpNet2 Operation successful.',@line) > 0
	begin
		set @EndingMessageThere = 1
	end
	exec SF_Logger @SPName,N'Message', @line
	Set @printCount = @printCount + 1
	end
   FETCH NEXT FROM tables_cursor INTO @line
END
deallocate tables_cursor

if @Result = -1 or @printCount = 0 or @printCount = 1 or (@EndingMessageThere = 0 and @UsingFiles = 1)
BEGIN
  	Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
	print @time_now + ': Error: DBAmpNet2.exe was unsuccessful.'
	set @LogMessage = 'Error: DBAmpNet2.exe was unsuccessful.'
	exec SF_Logger @SPName, N'Message', @LogMessage
	print @time_now + ': Error: Command string is ' + @Command
	set @LogMessage = 'Error: Command string is ' + @Command
	exec SF_Logger @SPName, N'Message', @LogMessage
  	GOTO RESTORE_ERR_HANDLER
END

print '--- Ending SF_DownloadBlobs. Operation successful.'
set @LogMessage = 'Ending - Operation Successful.' 
exec SF_Logger @SPName,N'Successful', @LogMessage
set NOCOUNT OFF
return 0

RESTORE_ERR_HANDLER:
print('--- Ending SF_DownloadBlobs. Operation FAILED.')
set @LogMessage = 'Ending - Operation Failed.' 
exec SF_Logger @SPName, N'Failed',@LogMessage
RAISERROR ('--- Ending SF_DownloadBlobs. Operation FAILED.',16,1)
set NOCOUNT OFF
return 1

ERR_HANDLER:
print('--- Ending SF_DownloadBlobs. Operation FAILED.')
set @LogMessage = 'Ending - Operation Failed.' 
exec SF_Logger @SPName,N'Failed', @LogMessage
RAISERROR ('--- Ending SF_DownloadBlobs. Operation FAILED.',16,1)
set NOCOUNT OFF
return 1
Go

IF EXISTS (SELECT name
	   FROM   sysobjects
	   WHERE  name = N'SF_TableLoader'
	   AND 	  type = 'P')
    DROP PROCEDURE SF_TableLoader
GO

Create PROCEDURE [dbo].[SF_TableLoader]
	@operation nvarchar(200),
	@table_server sysname,
	@table_name sysname,
	@opt_param1	nvarchar(512) = ' ',
	@opt_param2 nvarchar(512) = ' '
AS
-- Parameters: @operation		- Operation to perform (Update, Insert, Delete)
--             @table_server           	- Salesforce Linked Server name (i.e. SALESFORCE)
--             @table_name             	- SQL Table containing ID's to delete

-- @ProgDir - Directory containing the DBAmp.exe. Defaults to the DBAmp program directory
-- If needed, modify this for your installation
declare @ProgDir   	varchar(250) 
set @ProgDir = 'C:\"Program Files"\DBAmp\'

declare @Result 	int
declare @Command 	nvarchar(4000)
declare @time_now	char(8)
declare @errorLines varchar(max)
set @errorLines = 'SF_TableLoader Error: '
set NOCOUNT ON

print '--- Starting SF_TableLoader for ' + @table_name + ' ' +  dbo.SF_Version()
declare @LogMessage nvarchar(max)
declare @SPName nvarchar(50)
set @SPName = 'SF_TableLoader:' + Convert(nvarchar(255), NEWID(), 20)
set @LogMessage = 'Parameters: ' + @operation + ' ' +@table_server + ' ' + @table_name + ' ' + ISNULL(@opt_param1, ' ') + ' ' + ISNULL(@opt_param2, ' ') + ' Version: ' +  dbo.SF_Version()
exec SF_Logger @SPName, N'Starting',@LogMessage

declare @server sysname
declare @database sysname
declare @phrase nvarchar(100)
declare @Start int
declare @UsingSOAP int = 0
declare @UsingSOAPHeaders int = 0
declare @UsingBulkAPI int = 0
declare @UsingBulkAPI2 int = 0
declare @End int
declare @delim_table_name sysname
set @delim_table_name = '[' + @table_name + ']'
declare @result_table sysname
declare @result_exist int
declare @delim_result_table sysname
set @result_table = @table_name + '_Result'
set @delim_result_table = '[' + @result_table + ']'
declare @operationNotLower nvarchar(200)
set @operationNotLower = @operation
set @operation = lower(@operation)
set @operation = Replace(@operation, ' ', '')

-- Determine whether the local table and the previous copy exist
declare @table_exist int
set @table_exist = 0

IF EXISTS (SELECT 1
    FROM INFORMATION_SCHEMA.TABLES
    WHERE TABLE_TYPE='BASE TABLE' 
    AND TABLE_NAME=@table_name)
        set @table_exist = 1
IF (@@ERROR <> 0) GOTO ERR_HANDLER

set @result_exist = 0;
IF EXISTS (SELECT 1
    FROM INFORMATION_SCHEMA.TABLES
    WHERE TABLE_TYPE='BASE TABLE' 
    AND TABLE_NAME=@result_table)
        set @result_exist = 1
IF (@@ERROR <> 0) GOTO ERR_HANDLER

If exists(select Data
	from SF_Split(SUBSTRING(@operation, 1, 1000), ',', 1) 
	where Data like '%soap%')
	Begin
		set @UsingSOAP = 1
	End

If exists(select Data
	from SF_Split(SUBSTRING(@operation, 1, 1000), ',', 1) 
	where Data like '%bulkapi2%')
	Begin
		set @UsingBulkAPI2 = 1
	End

If exists(select Data
	from SF_Split(SUBSTRING(@operation, 1, 1000), ',', 1) 
	where Data like '%bulkapi%') and @UsingBulkAPI2 = 0
	Begin
		set @UsingBulkAPI = 1
	End
	
If exists(select Data
	from SF_Split(SUBSTRING(@operation, 1, 1000), ',', 1) 
	where Data like '%undelete%') and @UsingBulkAPI = 1
	Begin
		Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
		print @time_now + ': Error: The bulkapi switch cannot be used with the Undelete operation.'
		set @LogMessage = 'Error: The bulkapi switch cannot be used with the Undelete operation.'
		exec SF_Logger @SPName, N'Message', @LogMessage
  		GOTO ERR_HANDLER
	End

If exists(select Data
	from SF_Split(SUBSTRING(@operation, 1, 1000), ',', 1) 
	where Data like '%undelete%')
	Begin
		set @UsingSOAP = 1
	End
	
If exists(select Data
	from SF_Split(SUBSTRING(@operation, 1, 1000), ',', 1) 
	where Data like '%convertlead%')
	Begin
		set @UsingSOAP = 1
	End
	
If exists(select Data
	from SF_Split(SUBSTRING(@operation, 1, 1000), ',', 1) 
	where Data like '%bulkapi%') and @UsingSOAP = 1
	Begin
		Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
		print @time_now + ': Error: BulkAPI is the default. Cannot use BulkAPI and SOAP at the same time.'
		set @LogMessage = 'Error: BulkAPI is the default. Cannot use BulkAPI and SOAP at the same time.'
		exec SF_Logger @SPName, N'Message', @LogMessage
  		GOTO ERR_HANDLER
	End

If @UsingSOAP = 0
Begin
	If exists(select Data
		from SF_Split(SUBSTRING(@operation, 1, 1000), ',', 1) 
		where Data like '%harddelete%') and @UsingBulkAPI2 = 1
		Begin
			Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
			print @time_now + ': Error: HardDelete not supported by bulkapi2.' 
			set @LogMessage = 'Error: HardDelete not supported by bulkapi2.'
			exec SF_Logger @SPName, N'Message', @LogMessage
			goto ERR_HANDLER
		End
End

If @operation like '%ignorefailures(%'
Begin
	set @Start = PATINDEX('%ignorefailures(%', @operation)
	set @End = CHARINDEX(')', @operation, @Start) + 1
	set @phrase = SUBSTRING(@operation, @Start, @End - @Start)
	set @operationNotLower = REPLACE(@operation, @phrase, '')
End

if CHARINDEX('upsert',@operation) <> 0 and @opt_param2 <> ' '
BEGIN
  	set @UsingSOAPHeaders = 1
END

if CHARINDEX('upsert',@operation) = 0 and @opt_param1 <> ' '
BEGIN
  	set @UsingSOAPHeaders = 1
END

if CHARINDEX('upsert',@operation) <> 0 and @opt_param1 = ' '
BEGIN
  	Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
	print @time_now + ': Error: External Id Field Name was not provided.'
	set @LogMessage = 'Error: External Id Field Name was not provided.'
	exec SF_Logger @SPName, N'Message', @LogMessage
	set @errorLines = @errorLines + @time_now + ': Error: External Id Field Name was not provided.'
  	GOTO ERR_HANDLER
END

if CHARINDEX('upsert',@operation) <> 0 and @opt_param1 like '%,%'
BEGIN
  	Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
	print @time_now + ': Error: External Id Field Name was not provided before the soap headers parameter.'
	set @LogMessage = 'Error: External Id Field Name was not provided before the soap headers parameter.'
	exec SF_Logger @SPName, N'Message', @LogMessage
	set @errorLines = @errorLines + @time_now + ': Error: External Id Field Name was not provided before the soap headers parameter.'
  	GOTO ERR_HANDLER
END

-- Retrieve current server name and database
select @server = @@servername, @database = DB_NAME()
SET @server = CAST(SERVERPROPERTY('ServerName') AS sysname) 

-- Execute a linked server query to wake up the provider
declare @noTimeZoneConversion char(5)
declare @sql nvarchar(4000)
declare @parmlist nvarchar(300)
select @sql = 'Select @TZOUT = NoTimeZoneConversion from ' 
select @sql = @sql + @table_server + '...sys_sfsession'
select @parmlist = '@TZOUT char(5) OUTPUT'
exec sp_executesql @sql,@parmlist, @TZOUT=@noTimeZoneConversion OUTPUT
IF (@@ERROR <> 0) GOTO ERR_HANDLER

declare @rowCount int = 0
set @sql = 'Select @rowCount = Count(*) from ' + @delim_table_name
exec sp_executesql @sql, N'@rowCount INT OUTPUT', @rowCount = @rowCount OUTPUT

if (@UsingSOAP = 1 or @rowCount < 5000 or @UsingSOAPHeaders = 1) and @UsingBulkAPI = 0 and @UsingBulkAPI2 = 0
Begin
-- Execute DBAmpNet2.exe to run SOAP from Salesforce
	Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
	print @time_now + ': Run the DBAmpNet2.exe program.' 
	set @LogMessage = 'Run the DBAmpNet2.exe program.'
	exec SF_Logger @SPName, N'Message', @LogMessage
	set @Command = @ProgDir + 'DBAmpNet2.exe BulkOpsSoap'
	set @Command = @Command + ' "' + @operationNotLower + '" '
	set @Command = @Command + ' "' + @table_name + '" ' 
End
Else if @UsingBulkAPI2 = 1
Begin
	-- Execute DBAmpNet2.exe to run BulkAPI2 from Salesforce
	Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
	print @time_now + ': Run the DBAmpNet2.exe program.' 
	set @LogMessage = 'Run the DBAmpNet2.exe program.'
	exec SF_Logger @SPName, N'Message', @LogMessage
	set @Command = @ProgDir + 'DBAmpNet2.exe BulkOpsBulk'
	set @Command = @Command + ' "' + @operationNotLower + '" '
	set @Command = @Command + ' "' + @table_name + '" ' 
End
Else
Begin
	-- Execute DBAmpNet2.exe to run BulkAPI from Salesforce
	Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
	print @time_now + ': Run the DBAmpNet2.exe program.' 
	set @LogMessage = 'Run the DBAmpNet2.exe program.'
	exec SF_Logger @SPName, N'Message', @LogMessage
	set @Command = @ProgDir + 'DBAmpNet2.exe BulkOpsOldBulk'
	set @Command = @Command + ' "' + @operationNotLower + '" '
	set @Command = @Command + ' "' + @table_name + '" ' 
End

set @Command = @Command + ' "' + @server + '" '
set @Command = @Command + ' "' + @database + '" '
set @Command = @Command + ' "' + @table_server + '" '

if CHARINDEX('upsert',@operation) <> 0
begin
	set @Command = @Command + ' "' + @opt_param1 + '" '
	set @Command = @Command + ' "' + @opt_param2 + '" '
end
else
begin
   set @Command = @Command + ' "' + @opt_param1 + '" '
end

-- Create temp table to hold output
declare @errorlog TABLE (line varchar(255))
insert into @errorlog
	exec @Result = master..xp_cmdshell @Command

-- print output to msgs
declare @line varchar(255)
declare @printCount int
set @printCount = 0
DECLARE tables_cursor CURSOR FOR SELECT line FROM @errorlog
OPEN tables_cursor
FETCH NEXT FROM tables_cursor INTO @line
WHILE (@@FETCH_STATUS <> -1)
BEGIN
   if @line is not null
	begin
   	print @line 
   	exec SF_Logger @SPName,N'Message', @line
   	set @errorLines = @errorLines + @line
   	set @printCount = @printCount +1	
	end
   FETCH NEXT FROM tables_cursor INTO @line
END
deallocate tables_cursor

declare @Data nvarchar(100)
declare @Percent int
declare @PercentageOfRowsFailed decimal(10, 3)

set @Data = (Select Data
	from SF_Split(@phrase, ',', 1) 
	where Data like '%ignorefailures(%')

set @Percent = (Select SUBSTRING(@Data, CHARINDEX('(', @Data) + 1, CHARINDEX(')', @Data) - CHARINDEX('(', @Data) - 1))

If @Data like '%ignorefailures(%'
Begin
	set @Percent = @Percent
	Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
	print @time_now + ': Allowed Failure Percent = ' + Cast(@Percent as varchar) + '.'
	set @LogMessage = 'Allowed Failure Percent = ' + Cast(@Percent as varchar) + '.'
	exec SF_Logger @SPName, N'Message', @LogMessage
End
Else
	set @Percent = '0'
	
select @parmlist = '@PercentFailed decimal(10, 3) OUTPUT'
set @sql = '(Select @PercentFailed =
(Select Cast(Sum(Case When Error not like ' + '''' + '%Operation Successful%' + '''' + ' or Error is null Then 1 Else 0 End) As decimal(10, 3)) As ErrorTotal from ' + @delim_result_table + ')' +
'/
(select Cast(Count(*) as decimal(10, 3)) As Total from ' + @delim_result_table + '))'
exec sp_executesql @sql, @parmlist, @PercentFailed=@PercentageOfRowsFailed OUTPUT

if @PercentageOfRowsFailed is not null
Begin
	set @PercentageOfRowsFailed = @PercentageOfRowsFailed*100
	Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
	print @time_now + ': Percent Failed = ' + Cast(@PercentageOfRowsFailed as varchar) + '.'
	set @LogMessage = 'Percent Failed = ' + Cast(@PercentageOfRowsFailed as varchar) + '.'
	exec SF_Logger @SPName, N'Message', @LogMessage
End

-- If there is an error
if @Result = -1 or @printCount = 0
Begin
    -- If too many failures 
	If @PercentageOfRowsFailed > @Percent or @Percent = '0' or @PercentageOfRowsFailed is null
	Begin
		Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
		print @time_now + ': Error: DBAmpNet2.exe was unsuccessful.'
		set @LogMessage = 'Error: DBAmpNet2.exe was unsuccessful.'
		exec SF_Logger @SPName, N'Message', @LogMessage
		print @time_now + ': Error: Command string is ' + @Command
		set @LogMessage = 'Error: Command string is ' + @Command
		exec SF_Logger @SPName, N'Message', @LogMessage
		GOTO RESTORE_ERR_HANDLER
	End
End

print '--- Ending SF_TableLoader. Operation successful.'
set @LogMessage = 'Ending - Operation Successful.' 
exec SF_Logger @SPName, N'Successful',@LogMessage
set NOCOUNT OFF
return 0

RESTORE_ERR_HANDLER:

print '--- Ending SF_TableLoader. Operation FAILED.'
set @LogMessage = 'Ending - Operation Failed.' 
exec SF_Logger @SPName,N'Failed', @LogMessage
set NOCOUNT OFF
RAISERROR (@errorLines,16,1)
return 1

ERR_HANDLER:

print '--- Ending SF_TableLoader. Operation FAILED.'
set @LogMessage = 'Ending - Operation Failed.' 
exec SF_Logger @SPName, N'Failed',@LogMessage
set NOCOUNT OFF
RAISERROR (@errorLines,16,1)
return 1
Go

IF EXISTS (SELECT name
	   FROM   sysobjects
	   WHERE  name = N'SF_BulkSOQL_Refresh'
	   AND 	  type = 'P')
    DROP PROCEDURE SF_BulkSOQL_Refresh
GO
Create PROCEDURE [dbo].[SF_BulkSOQL_Refresh]
	@table_server sysname,
	@table_name sysname
AS
-- NOTE: This stored procedure will not work on SQL 2000.
--
-- Parameters: @table_server           - Salesforce Linked Server name (i.e. SALESFORCE)
--             @table_name             - Salesforce object to copy (i.e. Account)

-- @ProgDir - Directory containing the DBAmp.exe. Defaults to the DBAmp program directory
-- If needed, modify this for your installation
declare @ProgDir   	varchar(250) 
set @ProgDir = 'C:\"Program Files"\DBAmp\'

declare @Command 	nvarchar(4000)
declare @Result 	int
declare @sql		nvarchar(max)
declare @parmlist	nvarchar(4000)
declare @columnList nvarchar(max)
declare @deletecolumnList nvarchar(max)
declare @colname	nvarchar(500)
declare @time_now	char(8)
set NOCOUNT ON

print '--- Starting SF_BulkSOQL_Refresh for ' + @table_name + ' ' +  dbo.SF_Version()
declare @LogMessage nvarchar(max)
declare @SPName nvarchar(50)
set @SPName = 'SF_BulkSOQL_Refresh:' + Convert(nvarchar(255), NEWID(), 20)
set @LogMessage = 'Parameters: ' + @table_server + ' ' + @table_name
set @LogMessage = @LogMessage + ' ' + ' Version: ' +  dbo.SF_Version()
exec SF_Logger @SPName, N'Starting', @LogMessage

declare @delim_table_name sysname
declare @refresh_table sysname
declare @delim_refresh_table sysname
declare @delta_table sysname
declare @delim_delta_table sysname
declare @SOQLTable sysname

declare @server sysname
declare @database sysname
declare @timestamp_col_name nvarchar(2000)
declare @is_history_table int
declare @diff_schema_count int
declare @ParmDefinition nvarchar(500)
declare @SOQLStatement nvarchar(max)
declare @TempSOQLStatement nvarchar(max)
declare @start_time smalldatetime
declare @last_time_converted VARCHAR(33)

declare @big_object_index int
set @big_object_index = CHARINDEX(REVERSE('__b'),REVERSE(@table_name))

if (@big_object_index = 1)
Begin
	Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
	print @time_now + ': Error: Big Objects are not supported with SF_BulkSOQL_Refresh ' 
    set @LogMessage = 'Error: Big Objects are not supported with SF_BulkSOQL_Refresh'
    exec SF_Logger @SPName, N'Message', @LogMessage
    GOTO ERR_HANDLER
End

-- Put delimeters around names so we can name tables User, etc...
set @delim_table_name = '[' + @table_name + ']'
set @refresh_table = 'TableRefreshTime'
set @delim_refresh_table = '[' + @refresh_table + ']'
set @delta_table = @table_name + '_Delta' + CONVERT(nvarchar(30), GETDATE(), 126) 
set @delim_delta_table = '[' + @delta_table + ']'
set @SOQLTable = @table_name + '_SOQL'

-- Determine whether the local table and the previous copy exist
declare @table_exist int
declare @refresh_exist int
declare @delta_exist int
declare @deleted_exist int
declare @char_count varchar(10)

set @table_exist = 0
IF EXISTS (SELECT 1
    FROM INFORMATION_SCHEMA.TABLES
    WHERE TABLE_TYPE='BASE TABLE' 
    AND TABLE_NAME=@table_name)
        set @table_exist = 1
IF (@@ERROR <> 0) GOTO ERR_HANDLER

-- Create table to track refresh times
set @refresh_exist = 0
IF EXISTS (SELECT 1
    FROM INFORMATION_SCHEMA.TABLES
    WHERE TABLE_TYPE='BASE TABLE' 
    AND TABLE_NAME=@refresh_table)
        set @refresh_exist = 1
IF (@@ERROR <> 0) GOTO ERR_HANDLER
if (@refresh_exist = 0)
begin
   exec ('Create Table ' + @refresh_table + ' (TblName nvarchar(255) null, LastRefreshTime datetime null default CURRENT_TIMESTAMP) ')
   IF (@@ERROR <> 0) GOTO ERR_HANDLER
end

--Check if SOQL table exists
declare @soqltable_exist int
set @soqltable_exist = 0

IF EXISTS (SELECT 1
    FROM INFORMATION_SCHEMA.TABLES
    WHERE TABLE_TYPE='BASE TABLE' 
    AND TABLE_NAME=@SOQLTable)
        set @soqltable_exist = 1
IF (@@ERROR <> 0) GOTO ERR_HANDLER

if @soqltable_exist = 0
Begin
   Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
   print @time_now + ': Error: The ' + @SOQLTable + ' table does not exist. Create an ' + @SOQLTable + ' table and populate it with a valid SOQL statement.'
   set @LogMessage = 'Error: The ' + @SOQLTable + ' table does not exist. Create an ' + @SOQLTable + ' table and populate it with a valid SOQL statement.'
   exec SF_Logger @SPName, N'Message', @LogMessage
   GOTO ERR_HANDLER
End

select @sql = N'select @SOQLStatementOut = SOQL from ' + @table_name + '_SOQL'
set @ParmDefinition = N'@SOQLStatementOut nvarchar(max) OUTPUT'
exec sp_executesql @sql, @ParmDefinition, @SOQLStatementOut = @SOQLStatement OUTPUT 

-- Get the last refresh time from the refresh table
-- This serves as the 'last run' time for the refresh
-- We subtract 60 mins to allow for long units of work on the salesforce side
declare @last_time smalldatetime
declare @table_crtime smalldatetime

-- Get create time of the base table. This is the last replicate time
select @table_crtime = DATEADD(mi,-60,create_date) FROM sys.objects WHERE name = @table_name and type='U'

-- Get the latest timestamp from the Refresh table
select @sql = 'Select @LastTimeOUT = DATEADD(mi,-60,LastRefreshTime) from ' + @refresh_table 
select @sql = @sql + ' where TblName= ''' + @table_name + ''''
select @parmlist = '@LastTimeOUT datetime OUTPUT'
exec sp_executesql @sql,@parmlist, @LastTimeOUT=@last_time OUTPUT
IF (@@ERROR <> 0 OR @last_time is null)
begin
	set @last_time = @table_crtime
end

-- Get the NoTimeZoneConversion flag from DBAmp
declare @noTimeZoneConversion char(5)
select @sql = 'Select @TZOUT = NoTimeZoneConversion from ' 
select @sql = @sql + @table_server + '...sys_sfsession'
select @parmlist = '@TZOUT char(5) OUTPUT'
exec sp_executesql @sql,@parmlist, @TZOUT=@noTimeZoneConversion OUTPUT
IF (@@ERROR <> 0) GOTO ERR_HANDLER

-- last_time is always local to begin with, save @start_time as local time before flipping @last_time to UTC
set @start_time = @last_time
SET @last_time = DATEADD(Hour, DATEDIFF(Hour, GETDATE(), GETUTCDATE()), @last_time)

--convert last_time to UTC time with iso 8601 and offset
set @last_time_converted = CONVERT(VARCHAR(33), @last_time, 126) + 'Z'

Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
print @time_now + ': Using last run time of ' + Convert(nvarchar(24),@last_time,120)
set @LogMessage = 'Using last run time of ' + Convert(nvarchar(24),@last_time,120) 
exec SF_Logger @SPName,N'Message', @LogMessage

-- If the delta table exists, drop it
set @delta_exist = 0;
IF EXISTS (SELECT 1
    FROM INFORMATION_SCHEMA.TABLES
    WHERE TABLE_TYPE='BASE TABLE'
    AND TABLE_NAME=@delta_table)
        set @delta_exist = 1
IF (@@ERROR <> 0) GOTO ERR_HANDLER

if (@delta_exist = 1)
        exec ('Drop table ' + @delim_delta_table)
IF (@@ERROR <> 0) GOTO ERR_HANDLER

-- Retrieve current server name and database
select @server = @@servername, @database = DB_NAME()
SET @server = CAST(SERVERPROPERTY('ServerName') AS sysname) 

-- Create an empty local table with the current structure of the SOQL statement
set @TempSOQLStatement = LOWER(@SOQLStatement)
set @TempSOQLStatement = REPLACE(@TempSOQLStatement, '''', '''''')
set @TempSOQLStatement = REPLACE(@TempSOQLStatement, char(13) + char(10), ' ')

declare @index_of_where int
set @index_of_where = CHARINDEX(' where ', @TempSOQLStatement, 0)

--If where column exists, error out
if @index_of_where > 0
Begin
	Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
	print @time_now + ': The SOQL statement contains a where clause and therefore cannot be refreshed.'
	set @LogMessage = 'The SOQL statement contains a where clause and therefore cannot be refreshed.'
	exec SF_Logger @SPName, N'Message', @LogMessage 
	GOTO ERR_HANDLER
End

begin try
	exec ('Select * into ' + @delim_delta_table + ' from openquery(' + @table_server + ', ' + '''' + @TempSOQLStatement + ' Limit 0' + '''' + ') where 1=0')
end try
begin catch
	Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
	print @time_now + ': Error when creating delta table. ' + ERROR_MESSAGE()
	set @LogMessage = 'Error when creating delta table. ' + ERROR_MESSAGE()
	exec SF_Logger @SPName, N'Message', @LogMessage 
	GOTO ERR_HANDLER
end catch

-- Remember query time as the the start of the interval
declare @queryTime datetime
select @queryTime = (Select CURRENT_TIMESTAMP)

-- Populate new delta table with updated rows	
begin try
	exec ('Insert ' + @delim_delta_table + ' Select * from openquery(' + @table_server + ', ' + '''' + @TempSOQLStatement + ' where SystemModstamp > ' + @last_time_converted + '''' + ')')
end try	
begin catch
	Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
	print @time_now + ': Error occurred populating delta table with updated rows. ' + ERROR_MESSAGE()
	set @LogMessage = 'Error occurred populating delta table with updated rows. ' + ERROR_MESSAGE()
	exec SF_Logger @SPName, N'Message', @LogMessage 
	GOTO ERR_HANDLER
end catch

-- Delete any overlap rows in the delta table
-- These are rows we've already synched but got picked up due to the 10 min sliding window
select @sql = 'delete ' + @delim_delta_table + ' where exists '
select @sql = @sql + '(select Id from ' + @delim_table_name + ' where Id= ' + @delim_delta_table +'.Id '
select @sql = @sql + ' and SystemModstamp = ' + @delim_delta_table + '.SystemModstamp)'
exec sp_executesql @sql
IF (@@ERROR <> 0) GOTO ERR_HANDLER

-- Get the count of records from the delta table
declare @delta_count int
select @sql = 'Select @DeltaCountOUT = Count(*) from ' + @delim_delta_table
select @parmlist = '@DeltaCountOUT int OUTPUT'
exec sp_executesql @sql,@parmlist, @DeltaCountOUT=@delta_count OUTPUT
IF (@@ERROR <> 0) GOTO ERR_HANDLER

-- Print number of rows in delta table
Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
Select @char_count = (select CAST(@delta_count as VARCHAR(10)))
print @time_now + ': Identified ' + @char_count + ' updated/inserted rows.'

set @LogMessage = 'Identified ' + @char_count + ' updated/inserted rows.'
exec SF_Logger @SPName, N'Message',@LogMessage

-- If no records have changed then move on to deletes
if (@delta_count = 0) goto DELETE_PROCESS

---- Check to see if the column structure is the same
declare @cnt1 int
declare @cnt2 int
Select @cnt1 = Count(*) FROM INFORMATION_SCHEMA.COLUMNS v1 WHERE v1.TABLE_NAME=@delta_table 
		AND NOT EXISTS (Select COLUMN_NAME from INFORMATION_SCHEMA.COLUMNS v2 
		Join INFORMATION_SCHEMA.TABLES t1
		On v2.TABLE_NAME = t1.TABLE_NAME and t1.TABLE_SCHEMA = v2.TABLE_SCHEMA
		where (t1.TABLE_TYPE = 'BASE TABLE') and
		v2.TABLE_NAME=@table_name and v1.COLUMN_NAME = v2.COLUMN_NAME and v1.DATA_TYPE = v2.DATA_TYPE 
		and v1.IS_NULLABLE = v2.IS_NULLABLE
		and ISNULL(v1.CHARACTER_MAXIMUM_LENGTH,0) = ISNULL(v2.CHARACTER_MAXIMUM_LENGTH,0))
IF (@@ERROR <> 0) GOTO ERR_HANDLER

Select @cnt2 = Count(*) FROM INFORMATION_SCHEMA.COLUMNS v1
		Join INFORMATION_SCHEMA.TABLES t1
		On v1.TABLE_NAME = t1.TABLE_NAME and t1.TABLE_SCHEMA = v1.TABLE_SCHEMA
		WHERE (t1.TABLE_TYPE = 'BASE TABLE') and v1.TABLE_NAME=@table_name 
		AND NOT EXISTS (Select COLUMN_NAME from INFORMATION_SCHEMA.COLUMNS v2 where 
		v2.TABLE_NAME=@delta_table and v1.COLUMN_NAME = v2.COLUMN_NAME and v1.DATA_TYPE = v2.DATA_TYPE 
		and v1.IS_NULLABLE = v2.IS_NULLABLE
		and ISNULL(v1.CHARACTER_MAXIMUM_LENGTH,0) = ISNULL(v2.CHARACTER_MAXIMUM_LENGTH,0))
IF (@@ERROR <> 0) GOTO ERR_HANDLER

set @diff_schema_count = @cnt1 + @cnt2

if (@diff_schema_count > 0)
begin
	Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
	
		Select v1.COLUMN_NAME into #Test1 FROM INFORMATION_SCHEMA.COLUMNS v1 WHERE v1.TABLE_NAME=@delta_table 
		And v1.COLUMN_NAME Not in (Select COLUMN_NAME from INFORMATION_SCHEMA.COLUMNS v2 
		Join INFORMATION_SCHEMA.TABLES t1
		On v2.TABLE_NAME = t1.TABLE_NAME and t1.TABLE_SCHEMA = v2.TABLE_SCHEMA
		where (t1.TABLE_TYPE = 'BASE TABLE') and 
		v2.TABLE_NAME=@table_name and v1.COLUMN_NAME = v2.COLUMN_NAME and v1.DATA_TYPE = v2.DATA_TYPE 
		and v1.IS_NULLABLE = v2.IS_NULLABLE
		and ISNULL(v1.CHARACTER_MAXIMUM_LENGTH,0) = ISNULL(v2.CHARACTER_MAXIMUM_LENGTH,0))

		Select v1.COLUMN_NAME into #Test2 FROM INFORMATION_SCHEMA.COLUMNS v1 
		Join INFORMATION_SCHEMA.TABLES t1
		On v1.TABLE_NAME = t1.TABLE_NAME and t1.TABLE_SCHEMA = v1.TABLE_SCHEMA
		WHERE (t1.TABLE_TYPE = 'BASE TABLE') and v1.TABLE_NAME=@table_name 
		AND v1.COLUMN_NAME not in (Select COLUMN_NAME from INFORMATION_SCHEMA.COLUMNS v2 where 
		v2.TABLE_NAME=@delta_table and v1.COLUMN_NAME = v2.COLUMN_NAME and v1.DATA_TYPE = v2.DATA_TYPE 
		and v1.IS_NULLABLE = v2.IS_NULLABLE 
		and ISNULL(v1.CHARACTER_MAXIMUM_LENGTH,0) = ISNULL(v2.CHARACTER_MAXIMUM_LENGTH,0))

	  declare @ColumnName sysname

	  declare ColumnCompare_cursor cursor 
	  for 
		 select a.COLUMN_NAME from #Test1 a

	  open ColumnCompare_cursor

	  while 1 = 1
	  begin
	  fetch next from ColumnCompare_cursor into @ColumnName
		if @@error <> 0 or @@fetch_status <> 0 break
		    begin
				print @time_now + ': Error: ' + @ColumnName + ' exists in the delta table but does not exist in the local table or has a different definition.'
				set @LogMessage = 'Error: ' + @ColumnName + ' exists in the delta table but does not exist in the local table or has a different definition.'
				exec SF_Logger @SPName, N'Message',@LogMessage
			end
	  end

	  close ColumnCompare_cursor
	  deallocate ColumnCompare_cursor

	  declare ColumnCompare2_cursor cursor 
	  for 	
	     select a.COLUMN_NAME from #Test2 a

	  open ColumnCompare2_cursor

	  while 1 = 1
	  begin
	  fetch next from ColumnCompare2_cursor into @ColumnName
		if @@error <> 0 or @@fetch_status <> 0 break
		    begin
				print @time_now + ': Error: ' + @ColumnName + ' exists in the local table but does not exist in the delta table or has a different definition.'
				set @LogMessage = 'Error: ' + @ColumnName + ' exists in the local table but does not exist in the delta table or has a different definition.'
				exec SF_Logger @SPName, N'Message',@LogMessage
			end
	  end

	  close ColumnCompare2_cursor
	  deallocate ColumnCompare2_cursor

	  print @time_now + ': Error: Table schema has changed and therefore the table cannot be refreshed.'
	  set @LogMessage = 'Error: Table schema has changed and therefore the table cannot be refreshed.'
	  exec SF_Logger @SPName, N'Message',@LogMessage
	  exec ('Drop table ' + @delim_delta_table)
  	  GOTO ERR_HANDLER	
end

-- Schemas match, build list of columns
declare colname_cursor cursor for 
	SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS v1 WHERE v1.TABLE_NAME= @table_name 
	AND EXISTS (Select COLUMN_NAME from INFORMATION_SCHEMA.COLUMNS v2 
	where v2.TABLE_NAME= @delta_table 
	and v1.COLUMN_NAME = v2.COLUMN_NAME and v1.DATA_TYPE = v2.DATA_TYPE and v1.IS_NULLABLE = v2.IS_NULLABLE 
	and ISNULL(v1.CHARACTER_MAXIMUM_LENGTH,0)= ISNULL(v2.CHARACTER_MAXIMUM_LENGTH,0) and v1.TABLE_SCHEMA = v2.TABLE_SCHEMA)

OPEN colname_cursor
set @columnList = ''

while 1 = 1
begin
	fetch next from colname_cursor into @colname
	if @@error <> 0 or @@fetch_status <> 0 break
	set @columnList = @columnList + '[' + @colname + ']' + ','
end
close colname_cursor
deallocate colname_cursor

SET @columnList = SUBSTRING(@columnList, 1, Len(@columnList) - 1)

DELETE_PROCESS:
declare @deleted_table sysname
declare @deleted_table_ts sysname
declare @delim_deleted_table sysname

--Parse out object name in SOQL statement
declare @index_of_from int
declare @index_of_space_after_object_name int
declare @object_name nvarchar(255)
declare @length int

set @length = LEN(@TempSOQLStatement)
set @index_of_from = CHARINDEX(' from ', @TempSOQLStatement, 0) + 6
set @index_of_space_after_object_name = CHARINDEX(' ', @TempSOQLStatement, @index_of_from)

if @index_of_space_after_object_name = 0
Begin
	set @object_name = SUBSTRING(@TempSOQLStatement, @index_of_from, @length - @index_of_from + 1)
End
else
Begin
	set @object_name = SUBSTRING(@TempSOQLStatement, @index_of_from, @index_of_space_after_object_name - @index_of_from)
end

set @deleted_table = @object_name + '_Deleted'
set @deleted_table_ts = @deleted_table + CONVERT(nvarchar(30), GETDATE(), 126)
set @delim_deleted_table = '[' + @deleted_table_ts + ']'

-- If the deleted table exists, drop it and recreate it
set @deleted_exist = 0;
IF EXISTS (SELECT 1
    FROM INFORMATION_SCHEMA.TABLES
    WHERE TABLE_TYPE='BASE TABLE'
    AND TABLE_NAME=@deleted_table_ts)
        set @deleted_exist = 1
IF (@@ERROR <> 0) GOTO ERR_HANDLER

if (@deleted_exist = 1)
        exec ('Drop table ' + @delim_deleted_table)
IF (@@ERROR <> 0) GOTO ERR_HANDLER

select @sql = 'Create table ' +  @delim_deleted_table + ' (Id nchar(18) null ) '
exec (@sql)
IF (@@ERROR <> 0) GOTO ERR_HANDLER

-- retrieve deleted ids using object name from SOQL statement
select @sql = 'Insert ' + @delim_deleted_table + ' Select * from openquery(' 
select @sql = @sql + @table_server + ',''Select Id from ' + @deleted_table 
select @sql = @sql + ' where startdate=''''' + Convert(nvarchar(24),@start_time,120) + ''''''')' 
--print @sql

BEGIN TRY
	   	exec (@sql)
END TRY
BEGIN CATCH
	Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
	print @time_now + ': Error occurred fetching deleted rows.'	
	set @LogMessage = 'Error occurred fetching deleted rows.'
	exec SF_Logger @SPName, N'Message', @LogMessage
	print @time_now +
		': Error: ' + ERROR_MESSAGE();
	set @LogMessage = 'Error: ' + ERROR_MESSAGE()
	exec SF_Logger @SPName, N'Message', @LogMessage
		
     -- Roll back any active or uncommittable transactions before
     -- inserting information in the ErrorLog.
     IF XACT_STATE() <> 0
     BEGIN
         ROLLBACK TRANSACTION;
     END
     Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
     goto ERR_HANDLER
END CATCH

-- Delete any rows in the deleted table that already have been deleted
-- These are rows we've already synched but got picked up due to the 10 min sliding window
select @sql = 'delete ' + @delim_deleted_table + ' where not exists '
select @sql = @sql + '(select Id from ' + @delim_table_name + ' where Id= ' + @delim_deleted_table +'.Id)'
exec sp_executesql @sql
IF (@@ERROR <> 0) GOTO ERR_HANDLER

-- Get the count of records from the deleted table
declare @deleted_count int
select @sql = 'Select @DeletedCountOUT = Count(*) from ' + @delim_deleted_table
select @parmlist = '@DeletedCountOUT int OUTPUT'
exec sp_executesql @sql,@parmlist, @DeletedCountOUT=@deleted_count OUTPUT
IF (@@ERROR <> 0) GOTO ERR_HANDLER

-- Print number of rows in deleted table
Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
Select @char_count = (select CAST(@deleted_count as VARCHAR(10)))
print @time_now + ': Identified ' + @char_count + ' deleted rows.'

set @LogMessage = 'Identified ' + @char_count + ' deleted rows.'
exec SF_Logger @SPName,N'Message', @LogMessage

if (@deleted_count <> 0)
begin
	-- Delete rows from local table that exist in deleted table
	Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
	print @time_now + ': Removing deleted rows from ' + @table_name 
	set @LogMessage = 'Removing deleted rows from ' + @table_name
	exec SF_Logger @SPName, N'Message', @LogMessage

	select @sql = 'delete ' + @delim_table_name + ' where Id IN (select Id from ' + @delim_deleted_table + ' )'
	exec sp_executesql @sql
	IF (@@ERROR <> 0) GOTO ERR_HANDLER
end

SKIPDELETED:
if (@delta_count > 0)
begin
	BEGIN TRAN
	Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
	print @time_now + ': Adding updated/inserted rows into ' + @table_name 
	set @LogMessage = 'Adding updated/inserted rows into ' + @table_name
	exec SF_Logger @SPName, N'Message', @LogMessage

	-- Delete rows from local table that exist in delta table
	select @sql = 'delete ' + @delim_table_name + ' where Id IN (select Id from ' + @delim_delta_table + ' )'
	exec sp_executesql @sql
	IF (@@ERROR <> 0) 
	begin
	   ROLLBACK
	   GOTO ERR_HANDLER
	end
	
	select @sql = 'insert ' + @delim_table_name + '(' + @columnList + ')' 
				+ ' select ' + @columnList + ' from ' + @delim_delta_table
	exec sp_executesql @sql
	IF (@@ERROR <> 0) 
	begin
	   ROLLBACK
	   GOTO ERR_HANDLER
	end
	
	COMMIT
end
	
SUCCESS:
-- Reset Last Refresh in the Refresh table for this object
exec ('delete ' + @refresh_table + ' where TblName =''' + @table_name + '''')
select @sql = 'insert into ' + @refresh_table + '(TblName,LastRefreshTime) Values(''' + @table_name + ''',''' + Convert(nvarchar(24),@queryTime,126) +''')'
--print @sql
exec sp_executesql @sql

-- We don't need the deleted and delta tables so drop them
exec ('Drop table ' + @delim_deleted_table)
exec ('Drop table ' + @delim_delta_table)

print '--- Ending SF_BulkSOQL_Refresh. Operation successful.'
set @LogMessage = 'Ending - Operation Successful.' 
exec SF_Logger @SPName,N'Successful', @LogMessage
set NOCOUNT OFF
return 0

ERR_HANDLER:
-- We don't need the deleted and delta tables so drop them
IF EXISTS (SELECT 1
    FROM INFORMATION_SCHEMA.TABLES
    WHERE TABLE_TYPE='BASE TABLE'
    AND TABLE_NAME=@deleted_table_ts)
begin
  exec ('Drop table ' + @delim_deleted_table)
end

IF EXISTS (SELECT 1
    FROM INFORMATION_SCHEMA.TABLES
    WHERE TABLE_TYPE='BASE TABLE'
    AND TABLE_NAME=@delta_table)
begin
   exec ('Drop table ' + @delim_delta_table)
end
print('--- Ending SF_BulkSOQL_Refresh. Operation FAILED.')
set @LogMessage = 'Ending - Operation Failed.' 
exec SF_Logger @SPName,N'Failed', @LogMessage
RAISERROR ('--- Ending SF_BulkSOQL_Refresh. Operation FAILED.',16,1)
set NOCOUNT OFF
return 1
Go

IF EXISTS (SELECT name
	   FROM   sysobjects
	   WHERE  name = N'SF_BulkSOQLPrep'
	   AND 	  type = 'P')
    DROP PROCEDURE SF_BulkSOQLPrep
GO
Create PROCEDURE [dbo].[SF_BulkSOQLPrep]
	@table_server sysname,
	@table_name sysname,
	@options	nvarchar(255) = NULL,
	@soql_statement	nvarchar(max) = NULL
AS
-- Parameters: @table_server           - Salesforce Linked Server name (i.e. SALESFORCE)
--             @table_name             - Salesforce object to copy (i.e. Account)

-- @ProgDir - Directory containing the DBAmp.exe. Defaults to the DBAmp program directory
-- If needed, modify this for your installation
declare @ProgDir   	varchar(250) 
set @ProgDir = 'C:\"Program Files"\DBAmp\'

declare @Result 	int
declare @Command 	nvarchar(4000)
declare @time_now	char(8)
set NOCOUNT ON

print '--- Starting SF_BulkSOQLPrep for ' + @table_name + ' ' +  dbo.SF_Version()
declare @LogMessage nvarchar(max)
declare @SPName nvarchar(50)
set @SPName = 'SF_BulkSOQLPrep:' + Convert(nvarchar(255), NEWID(), 20)
set @LogMessage = 'Parameters: ' + @table_server + ' ' + @table_name + ' ' + ISNULL(@options, ' ') + ' Version: ' +  dbo.SF_Version()
Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
print @time_now + ': ' + @LogMessage
exec SF_Logger @SPName, N'Starting',@LogMessage

declare @delim_table_name sysname
declare @result_table sysname
declare @delim_result_table sysname
declare @server sysname
declare @database sysname
declare @SOQLTable sysname
declare @UsingFiles int
set @UsingFiles = 0
declare @EndingMessageThere int
set @EndingMessageThere = 0

-- Put delimeters around names so we can name tables User, etc...
set @delim_table_name = '[' + @table_name + ']'
set @result_table = @table_name + '_Result'
set @delim_result_table = '[' + @result_table + ']'
set @SOQLTable = @table_name + '_SOQL'

-- Determine whether the local table and the previous copy exist
declare @table_exist int
declare @result_exist int
declare @soqltable_exist int
declare @SOQLStatement nvarchar(max)
declare @TempSOQLStatement nvarchar(max)
declare @sql nvarchar(1000)
declare @ParmDefinition nvarchar(500)
set @soqltable_exist = 0

IF EXISTS (SELECT 1
    FROM INFORMATION_SCHEMA.TABLES
    WHERE TABLE_TYPE='BASE TABLE' 
    AND TABLE_NAME=@SOQLTable)
        set @soqltable_exist = 1
IF (@@ERROR <> 0) GOTO ERR_HANDLER

if @soql_statement is not null
Begin
	-- If the SOQL table exists, drop it
	Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
	print @time_now + ': Drop ' + @SOQLTable + ' if it exists.'
	set @LogMessage = 'Drop ' + @SOQLTable + ' if it exists.'
	exec SF_Logger @SPName, N'Message', @LogMessage
	if @soqltable_exist = 1
	Begin
		exec ('Drop table ' + @SOQLTable)
		IF (@@ERROR <> 0) GOTO ERR_HANDLER
	End

	-- Create SOQL table
	Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
	print @time_now + ': Creating table ' + @SOQLTable + '.'
	set @LogMessage = 'Creating table ' + @SOQLTable + '.'
    exec SF_Logger @SPName, N'Message', @LogMessage
	set @sql = 'CREATE TABLE ' + @SOQLTable + ' (SOQL nvarchar(max))'
	EXECUTE sp_executesql @sql
	set @soqltable_exist = 1
	
	-- Populate SOQL table
	Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
	print @time_now + ': Populating ' + @SOQLTable + ' with SOQL statement.'
	set @LogMessage = 'Populating ' + @SOQLTable + ' with SOQL statement.'
	exec SF_Logger @SPName, N'Message', @LogMessage
	set @sql = 'Insert Into ' + @SOQLTable + '(SOQL) values (''' + REPLACE(@soql_statement, '''', '''''') + ''')'
	EXECUTE sp_executesql @sql;
End

if @soqltable_exist = 0
Begin
   Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
   print @time_now + ': Error: The ' + @SOQLTable + ' table does not exist. Create an ' + @SOQLTable + ' table and populate it with a valid SOQL statement.'
   set @LogMessage = 'Error: The ' + @SOQLTable + ' table does not exist. Create an ' + @SOQLTable + ' table and populate it with a valid SOQL statement.'
   exec SF_Logger @SPName, N'Message', @LogMessage
   GOTO ERR_HANDLER
End

select @sql = N'select @SOQLStatementOut = SOQL from ' + @table_name + '_SOQL'
set @ParmDefinition = N'@SOQLStatementOut nvarchar(max) OUTPUT'
exec sp_executesql @sql, @ParmDefinition, @SOQLStatementOut = @SOQLStatement OUTPUT 

if @SOQLStatement is null or @SOQLStatement = ''
Begin
   Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
   print @time_now + ': Error: The SOQL Statement provided does not exist. Populate the SOQL column with a valid SOQL Statement.'
   set @LogMessage = 'Error: The SOQL Statement provided does not exist. Populate the SOQL column with a valid SOQL Statement.'
   exec SF_Logger @SPName, N'Message', @LogMessage
   GOTO ERR_HANDLER
End

set @table_exist = 0
set @result_exist = 0;
IF EXISTS (SELECT 1
    FROM INFORMATION_SCHEMA.TABLES
    WHERE TABLE_TYPE='BASE TABLE' 
    AND TABLE_NAME=@table_name)
        set @table_exist = 1
IF (@@ERROR <> 0) GOTO ERR_HANDLER

IF EXISTS (SELECT 1
    FROM INFORMATION_SCHEMA.TABLES
    WHERE TABLE_TYPE='BASE TABLE' 
    AND TABLE_NAME=@result_table)
        set @result_exist = 1
IF (@@ERROR <> 0) GOTO ERR_HANDLER

if @table_exist = 1
begin
	-- Make sure that the table doesn't have any keys defined
	IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    		   WHERE CONSTRAINT_TYPE = 'FOREIGN KEY' AND TABLE_NAME=@table_name )
        begin
 	   Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
	   print @time_now + ': Error: The table contains foreign keys and cannot be replicated.' 
	   set @LogMessage = 'Error: The table contains foreign keys and cannot be replicated.'
	   exec SF_Logger @SPName, N'Message', @LogMessage
	   GOTO ERR_HANDLER
	end
end

-- If the previous table exists, drop it
Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
print @time_now + ': Drop ' + @result_table + ' if it exists.'
set @LogMessage = 'Drop ' + @result_table + ' if it exists.'
exec SF_Logger @SPName, N'Message', @LogMessage
if (@result_exist = 1)
        exec ('Drop table ' + @delim_result_table)
IF (@@ERROR <> 0) GOTO ERR_HANDLER

-- Create an empty local table with the current structure of the Salesforce object
Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
print @time_now + ': Create ' + @result_table + ' with new structure.'
set @LogMessage = 'Create ' + @result_table + ' with new structure.'
exec SF_Logger @SPName, N'Message', @LogMessage

set @TempSOQLStatement = REPLACE(@SOQLStatement, '''', '''''')

-- Create previous table from _SOQL table
begin try
exec ('Select * into ' + @delim_result_table + ' from openquery(' + @table_server + ', ' + '''' + @TempSOQLStatement + '''' + ') where 1=0')
end try
begin catch
	Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
	print @time_now + ': Error: Could not create result table.'
	set @LogMessage = 'Error: Could not create result table.'
	exec SF_Logger @SPName, N'Message', @LogMessage
	print @time_now +
		': Error: ' + ERROR_MESSAGE();
	set @LogMessage = 'Error: ' + ERROR_MESSAGE()
	exec SF_Logger @SPName, N'Message', @LogMessage
	GOTO ERR_HANDLER
end catch

print '--- Ending SF_BulkSOQLPrep. Operation successful.'
set @LogMessage = 'Ending - Operation Successful.' 
exec SF_Logger @SPName,N'Successful', @LogMessage
set NOCOUNT OFF
return 0

RESTORE_ERR_HANDLER:
print('--- Ending SF_BulkSOQLPrep. Operation FAILED.')
set @LogMessage = 'Ending - Operation Failed.' 
exec SF_Logger @SPName, N'Failed',@LogMessage
RAISERROR ('--- Ending SF_BulkSOQLPrep. Operation FAILED.',16,1)
set NOCOUNT OFF
return 1

ERR_HANDLER:
print('--- Ending SF_BulkSOQLPrep. Operation FAILED.')
set @LogMessage = 'Ending - Operation Failed.' 
exec SF_Logger @SPName,N'Failed', @LogMessage
RAISERROR ('--- Ending SF_BulkSOQLPrep. Operation FAILED.',16,1)
set NOCOUNT OFF
return 1
Go








