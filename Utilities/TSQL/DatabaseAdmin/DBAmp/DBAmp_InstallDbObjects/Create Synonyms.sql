IF EXISTS (SELECT name 
	   FROM   sysobjects 
	   WHERE  name = N'SF_CreateSynonyms' 
	   AND 	  type = 'P')
    DROP PROCEDURE SF_CreateSynonyms
GO


CREATE PROCEDURE SF_CreateSynonyms 
	@table_server sysname 
AS
-- Input Parameter @table_server - Linked Server Name
print N'--- Starting SF_CreateSynonyms'
print N'--- (Ignore error msgs due to dropping non-existent views.)'
set NOCOUNT ON
Create Table #tmpSF (TABLE_CAT sysname null, TABLE_SCEM sysname null, TABLE_NAME sysname, TABLE_TYPE varchar(32), REMARKS varchar(254))
Insert #tmpSF EXEC sp_tables_ex @table_server
if (@@error <> 0) goto ERR_HANDLER

declare @tn sysname
declare @vn sysname
declare @cName sysname
declare @colNames nvarchar(4000)
declare @sql nvarchar(4000)
declare views_cursor cursor local fast_forward
for select TABLE_NAME from #tmpSF

open views_cursor

while 1 = 1
begin
   fetch next from views_cursor into @tn
   if @@error <> 0 or @@fetch_status <> 0 break

   set @vn = N'[' + @tn + N']'

   -- Drop the any existing view
   set @sql = N'DROP SYNONYM ' + @vn
   execute sp_executesql @sql

   --- Create the new view
   set @sql = N'CREATE SYNONYM ' + quotename(@tn) + ' FOR '  + @table_server + '...' + quotename(@tn)
   execute sp_executesql @sql
   if (@@error <> 0) goto ERR_HANDLER

   -- Print confirmation output
   print @vn + N' synonym created.'
 end

close views_cursor
deallocate views_cursor


Drop table #tmpSF

-- Turn NOCOUNT back off
set NOCOUNT OFF
print N'--- Ending SF_CreateSynonyms. Operation successful.'
return 0


ERR_HANDLER:
-- If we encounter an error creating the view, then indicate by returning 1
Drop table #tmpSF

-- Turn NOCOUNT back off
set NOCOUNT OFF
print N'--- Ending SF_CreateSynonyms. Operation failed.'
return 1
go


