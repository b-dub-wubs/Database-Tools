IF EXISTS (SELECT name 
	   FROM   sysobjects 
	   WHERE  name = N'SF_CreateViews' 
	   AND 	  type = 'P')
    DROP PROCEDURE SF_CreateViews
GO


CREATE PROCEDURE SF_CreateViews 
	@table_server sysname 
AS
-- Input Parameter @table_server - Linked Server Name
print N'--- Starting SF_CreateViews'
print N'--- (Ignore error msgs due to dropping non-existent views.)'
set NOCOUNT ON
Create Table #tmpSF (TABLE_CAT sysname null, TABLE_SCEM sysname null, TABLE_NAME sysname, TABLE_TYPE varchar(32), REMARKS varchar(254))
Insert #tmpSF EXEC sp_tables_ex @table_server
if (@@error <> 0) goto ERR_HANDLER

declare @tn sysname
declare @vn sysname
declare @cName sysname
declare @colNames nvarchar(max)
declare @sql nvarchar(max)
declare views_cursor cursor local fast_forward
for select TABLE_NAME from #tmpSF

open views_cursor

while 1 = 1
begin
   fetch next from views_cursor into @tn
   if @@error <> 0 or @@fetch_status <> 0 break

   -- Build list of columns for view
   Create Table #tmpCols (
		TABLE_CAT sysname null, 	
		TABLE_SCHEM sysname null,
		TABLE_NAME sysname,
		COLUMN_NAME sysname, 
		DATA_TYPE smallint,
		TYPE_NAME varchar(13),
		COLUMN_SIZE int,
		BUFFER_LENGTH int,
		DECIMAL_DIGITS smallint,
		NUM_PREC_RADIX smallint,
		NULLABLE smallint,
		REMARKS varchar(254) null,
		COLUMN_DEF varchar(254),
		SQL_DATA_TYPE smallint,
		SQL_DATETIME_SUB smallint,
		CHAR_OCTET_LENGTH int,
		ORDINAL_POSITION int,
		IS_NULLABLE varchar(254),
		SS_DATA_TYPE tinyint)
	
   Insert #tmpCols EXEC sp_columns_ex @table_server,@tn
   if (@@error <> 0) goto ERR_HANDLER

   declare cols_cursor cursor local fast_forward
   for select COLUMN_NAME from #tmpCols
   open cols_cursor

   fetch next from cols_cursor into @cName
   set @colNames = N' '
   while @@fetch_status = 0
   begin
     set @cName = quotename(@cName)
     set @colNames = @colNames + @cName + N','
     fetch next from cols_cursor into @cName
   end  

   -- Get rid of trailing , in colNames
   set	@colNames = left(@colNames,len(@colNames)-1)

   close cols_cursor
   deallocate cols_cursor   
   Drop table #tmpCols

   set @vn = @tn + N'_View'

   -- Drop the any existing view
   set @sql = N'DROP VIEW ' + @vn
   execute sp_executesql @sql

   --- Create the new view
   set @sql = N'CREATE VIEW ' + @vn + ' WITH VIEW_METADATA AS SELECT ' + @colNames + ' FROM ' + @table_server + '...' + quotename(@tn)
   print @sql
   execute sp_executesql @sql
   if (@@error <> 0) goto ERR_HANDLER

   -- Print confirmation output
   print @vn + N' created.'
 end

close views_cursor
deallocate views_cursor


Drop table #tmpSF

-- Turn NOCOUNT back off
set NOCOUNT OFF
print N'--- Ending SF_CreateViews. Operation successful.'
return 0


ERR_HANDLER:
-- If we encounter an error creating the view, then indicate by returning 1
Drop table #tmpSF

-- Turn NOCOUNT back off
set NOCOUNT OFF
print N'--- Ending SF_CreateViews. Operation failed.'
return 1
go


