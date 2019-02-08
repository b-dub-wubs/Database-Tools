-- =============================================
-- Create the DBAmp Performamce Package stored procedures
-- Execute this script to add the stored proceduers to the salesforce backups database
-- =============================================
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

declare @log_table sysname
declare @delim_log_table sysname
declare @sql nvarchar(max)
declare @logCount int
declare @logMaxCount int
set @logMaxCount = 500000
set @logCount = .25*@logMaxCount
-- Comment this line to turn logging on
--return 0

declare @log_exist int

set @log_exist = 0
IF EXISTS (SELECT 1
    FROM INFORMATION_SCHEMA.TABLES
    WHERE TABLE_TYPE='BASE TABLE' 
    AND TABLE_NAME='DBAmp_Log')
        set @log_exist = 1
IF (@@ERROR <> 0) return 0

if (@log_exist = 0)
begin
   Create Table DBAmp_Log
   (SPName sysname null,
   Status nvarchar(20) null,
   Message nvarchar(max),
   LogTime datetime null default (getdate()),
   Seen int Default 0
   )
   IF (@@ERROR <> 0) return 0
end
else
begin
	-- Check for log wrap
	-- If the log is too big, delete 1/4 of it
	if (Select COUNT(LogTime) from DBAmp_Log nolock) > @logMaxCount
	Begin
		DELETE FROM DBAmp_Log
		WHERE LogTime IN (SELECT TOP(@logCount) LogTime 
								FROM DBAmp_Log nolock
									ORDER BY LogTime asc)
	End
end

-- Add a messge to the log
SET @Message = REPLACE(@Message,'''','''''')  -- Fix issue with single quotes
Insert Into DBAmp_Log(SPName, Status, Message)
Values(Cast(@SPName as nvarchar(256)), @Status, @Message)
return 0

go


declare @log_exist int

set @log_exist = 0
IF EXISTS (SELECT 1
    FROM INFORMATION_SCHEMA.TABLES
    WHERE TABLE_TYPE='BASE TABLE' 
    AND TABLE_NAME='DBAmp_Log')
        set @log_exist = 1
if @log_exist = 0
begin
   Create Table DBAmp_Log
   (SPName sysname null,
   Status nvarchar(20) null,
   Message nvarchar(max),
   LogTime datetime null default (getdate()),
   Seen int Default 0
   )
   Create Index SPNameIndex on DBAmp_Log(SPName)
end
go


IF EXISTS (SELECT name
	   FROM   sysobjects
	   WHERE  name = N'DBAmp_BulkOps_Perf'
	   AND 	  type = 'V')
    DROP VIEW DBAmp_BulkOps_Perf
GO
Create VIEW DBAmp_BulkOps_Perf
As 
(
Select 'SF_BulkOps' as Type, SPName, 

ISNULL((Select LogTime
From DBAmp_Log As i6
Where Message Like 'Ending%' and o.SPName = i6.SPName), 0) As "LogTime",

(select Data
from SF_Split(SUBSTRING(Message, 13, 1000), ' ', 1)
where Id = 2) As "LinkedServer",

(select Data
from SF_Split(SUBSTRING(Message, 13, 1000), ' ', 1)
where Id = 3) As "Object",

(Select Top 1 Case When DATEDIFF(SS, o.LogTime, i4.LogTime) = '0' Then '1' Else DATEDIFF(SS, o.LogTime, i4.LogTime) End
From DBAmp_Log As i4
Where Message Like '%Ending%' and o.SPName = i4.SPName) As "RunTimeSeconds",

ISNULL((Select Case When Status = 'Failed' Then 'True' Else 'False' End
From DBAmp_Log As i5
Where Status = 'Failed' and o.SPName = i5.SPName), 'False') As "Failed",

(select Data
from SF_Split(SUBSTRING(Message, 13, 1000), ' ', 1)
where Id = 1) As "BulkOpsAction",

Cast(ISNULL((Select Top 1 Substring(Message, 11, Case When PATINDEX('% rows read%', Message) - 11 < 0 then 0 else PATINDEX('% rows read%', Message) - 11 End) 
From DBAmp_Log As i1
Where PATINDEX('% rows read%', Message) <> 0 and i1.SPName = o.SPName ), 0) as int) As "RowsRead",

Cast(ISNULL((Select Top 1 Substring(Message, 11, Case When PATINDEX('% rows successfully%', Message) - 11 < 0 then 0 else PATINDEX('% rows successfully%', Message) - 11 End) 
From DBAmp_Log As i2
Where PATINDEX('% rows successfully%', Message) <> 0 and i2.SPName = o.SPName), 0) As Int) As "RowsSuccessfull",

Cast(ISNULL((Select Top 1 Substring(Message, 11, Case When PATINDEX('% rows fail%', Message) - 11 < 0 then 0 else PATINDEX('% rows fail%', Message) - 11 End)  
From DBAmp_Log As i3
Where PATINDEX('% rows fail%', Message) <> 0 and i3.SPName = o.SPName), 0) As Int) + 
Cast(ISNULL((Select Top 1 Substring(Message, 11, Case When PATINDEX('% rows unprocessed%', Message) - 11 < 0 then 0 else PATINDEX('% rows unprocessed%', Message) - 11 End)  
From DBAmp_Log As i3
Where PATINDEX('% rows unprocessed%', Message) <> 0 and i3.SPName = o.SPName), 0) As Int) As "RowsFailed",

(Select Seen
from DBAmp_Log i4
where Message Like 'Ending%' and o.SPName = i4.SPName) as "Seen"

From DBAmp_Log As o
Where SPName Like '%SF_Bulk%' and Status = 'Starting' and exists (select SPName from DBAmp_Log where o.SPName = SPName and Message Like 'Ending%')
)

GO

IF EXISTS (SELECT name
	   FROM   sysobjects
	   WHERE  name = N'DBAmp_TableLoader_Perf'
	   AND 	  type = 'V')
    DROP VIEW DBAmp_TableLoader_Perf
GO
Create VIEW DBAmp_TableLoader_Perf
As 
(
Select 'SF_TableLoader' as Type, SPName, 

ISNULL((Select LogTime
From DBAmp_Log As i6
Where Message Like 'Ending%' and o.SPName = i6.SPName), 0) As "LogTime",

(select Data
from SF_Split(SUBSTRING(Message, 13, 1000), ' ', 1)
where Id = 2) As "LinkedServer",

(select Data
from SF_Split(SUBSTRING(Message, 13, 1000), ' ', 1)
where Id = 3) As "Object",

(Select Top 1 Case When DATEDIFF(SS, o.LogTime, i4.LogTime) = '0' Then '1' Else DATEDIFF(SS, o.LogTime, i4.LogTime) End
From DBAmp_Log As i4
Where Message Like '%Ending%' and o.SPName = i4.SPName) As "RunTimeSeconds",

ISNULL((Select Case When Status = 'Failed' Then 'True' Else 'False' End
From DBAmp_Log As i5
Where Status = 'Failed' and o.SPName = i5.SPName), 'False') As "Failed",

(select Data
from SF_Split(SUBSTRING(Message, 13, 1000), ' ', 1)
where Id = 1) As "TableLoaderAction",

Cast(ISNULL((Select Top 1 Substring(Message, 11, Case When PATINDEX('% rows read%', Message) - 11 < 0 then 0 else PATINDEX('% rows read%', Message) - 11 End) 
From DBAmp_Log As i1
Where PATINDEX('% rows read%', Message) <> 0 and i1.SPName = o.SPName ), 0) as int) As "RowsRead",

Cast(ISNULL((Select Top 1 Substring(Message, 11, Case When PATINDEX('% rows successfully%', Message) - 11 < 0 then 0 else PATINDEX('% rows successfully%', Message) - 11 End) 
From DBAmp_Log As i2
Where PATINDEX('% rows successfully%', Message) <> 0 and i2.SPName = o.SPName), 0) As Int) As "RowsSuccessfull",

Cast(ISNULL((Select Top 1 Substring(Message, 11, Case When PATINDEX('% rows fail%', Message) - 11 < 0 then 0 else PATINDEX('% rows fail%', Message) - 11 End)  
From DBAmp_Log As i3
Where PATINDEX('% rows fail%', Message) <> 0 and i3.SPName = o.SPName), 0) As Int) + 
Cast(ISNULL((Select Top 1 Substring(Message, 11, Case When PATINDEX('% rows unprocessed%', Message) - 11 < 0 then 0 else PATINDEX('% rows unprocessed%', Message) - 11 End)  
From DBAmp_Log As i3
Where PATINDEX('% rows unprocessed%', Message) <> 0 and i3.SPName = o.SPName), 0) As Int) As "RowsFailed",

(Select Seen
from DBAmp_Log i4
where Message Like 'Ending%' and o.SPName = i4.SPName) as "Seen"

From DBAmp_Log As o
Where SPName Like '%SF_TableLoader%' and Status = 'Starting' and exists (select SPName from DBAmp_Log where o.SPName = SPName and Message Like 'Ending%')
)

GO

IF EXISTS (SELECT name
	   FROM   sysobjects
	   WHERE  name = N'DBAmp_Replicate_Perf'
	   AND 	  type = 'V')
    DROP VIEW DBAmp_Replicate_Perf
GO
Create VIEW DBAmp_Replicate_Perf
As 
(
Select 'SF_Replicate' as Type, SPName,

ISNULL((Select LogTime
From DBAmp_Log As b4
Where Message Like 'Ending%' and r.SPName = b4.SPName), 0) As "LogTime",

(select Data
from SF_Split(SUBSTRING(Message, 13, 1000), ' ', 1)
where Id = 1) As "LinkedServer",

(select Data
from SF_Split(SUBSTRING(Message, 13, 1000), ' ', 1)
where Id = 2) As "Object",

ISNULL((Select Top 1 Case When DATEDIFF(SS, r.LogTime, b2.LogTime) = '0' Then '1' Else DATEDIFF(SS, r.LogTime, b2.LogTime) End
From DBAmp_Log As b2
Where Message like '%Ending%' and r.SPName = b2.SPName), 0) As "RunTimeSeconds",

ISNULL((Select Case When Status = 'Failed' Then 'True' Else 'False' End
From DBAmp_Log As b3
Where Status = 'Failed' and r.SPName = b3.SPName), 'False') As "Failed",

Cast(ISNULL((Select Substring(Message, 11, Case When PATINDEX('% rows copied.%', Message) - 11 < 0 then 0 else PATINDEX('% rows copied.%', Message) - 11 End)
From DBAmp_Log As b1
Where PATINDEX('% rows copied.%', Message) <> 0 and b1.SPName = r.SPName), 0) AS Int) As "RowsCopied",

(Select Seen
from DBAmp_Log b4
where Message Like 'Ending%' and r.SPName = b4.SPName) as "Seen"

From DBAmp_Log As r
Where (SPName Like '%SF_Replicate:%' 
or SPName Like '%SF_ReplicateIAD:%'
or SPName Like '%SF_ReplicateLarge:%'
or SPName Like '%SF_ReplicateHistory:%'   
or SPName Like '%SF_ReplicateKAV:%' 
or SPName Like '%SF_Replicate3:%')
 and Status = 'Starting' 
 and exists (select SPName from DBAmp_Log where r.SPName = SPName and Message Like 'Ending%')
)

GO

IF EXISTS (SELECT name
	   FROM   sysobjects
	   WHERE  name = N'DBAmp_Refresh_Perf'
	   AND 	  type = 'V')
    DROP VIEW DBAmp_Refresh_Perf
GO
Create VIEW DBAmp_Refresh_Perf
As 
(
Select  'SF_Refresh' as Type, SPName, 

ISNULL((Select LogTime
From DBAmp_Log As a5
Where Message Like 'Ending%' and p.SPName = a5.SPName), 0) As "LogTime",

(select Data
from SF_Split(SUBSTRING(Message, 13, 1000), ' ', 1)
where Id = 1) As "LinkedServer",

(select Data
from SF_Split(SUBSTRING(Message, 13, 1000), ' ', 1)
where Id = 2) As "Object",

ISNULL((Select Top 1 Case When DATEDIFF(SS, p.LogTime, a3.LogTime) = '0' Then '1' Else DATEDIFF(SS, p.LogTime, a3.LogTime) End
From DBAmp_Log As a3
Where Message like 'Ending%' and p.SPName = a3.SPName), 0) As "RunTimeSeconds",

ISNULL((Select Case When Status = 'Failed' Then 'True' Else 'False' End
From DBAmp_Log As a4
Where Status = 'Failed' and p.SPName = a4.SPName), 'False') As "Failed",

Cast(IsNull((Select Top 1 Substring(Message, 11, Case When PATINDEX('% updated/inserted%', Message) - 11 < 0 then 0 else PATINDEX('% updated/inserted%', Message) - 11 End)
From DBAmp_Log As a1
Where PATINDEX('% updated/inserted%', Message) <> 0 and Message Like 'Identified%' and a1.SPName = p.SPName), 0) AS int)  As "RowsUpdatedOrInserted",

Cast(IsNull((Select Top 1 Substring(Message, 11, Case When PATINDEX('% deleted%', Message) - 11 < 0 then 0 else PATINDEX('% deleted%', Message) - 11 End) 
from DBAmp_Log As a2
Where PATINDEX('% deleted rows%', Message) <> 0 and Message Like 'Identified%' and a2.SPName = p.SPName), 0) AS int)  As "RowsDeleted",

(Select Seen
from DBAmp_Log a5
where Message Like 'Ending%' and p.SPName = a5.SPName) as "Seen"

From DBAmp_Log As p
Where (SPName Like 'SF_RefreshIAD:%' or SPName Like 'SF_Refresh:%') and Status = 'Starting' and exists (select SPName from DBAmp_Log where p.SPName = SPName and Message Like 'Ending%')
)

Go

IF EXISTS (SELECT name
	   FROM   sysobjects
	   WHERE  name = N'SF_DBAmpLogDumpAndMark'
	   AND 	  type = 'P')
    DROP PROCEDURE SF_DBAmpLogDumpAndMark
GO
CREATE PROCEDURE [dbo].[SF_DBAmpLogDumpAndMark]
	@Name nvarchar(50),
	@Quiet int = 1
AS

declare @time_now char(8)
declare @LogTimeCutoff datetime
set @Name = LOWER(@Name)


If @Name <> 'sf_replicate' and @Name <> 'sf_refresh' and @Name <> 'sf_bulkops'
Begin
	If @Quiet = 0
	Begin
		Select @time_now = (select Convert(char(8),CURRENT_TIMESTAMP, 8))
		print @time_now + ': Error: You must put in SF_Replicate, SF_Refresh, or SF_BulkOps for the Name parameter.' 
	End
	RAISERROR ('',16,1)
	return 1
End 

Begin Try
	If @Name = 'sf_replicate'
	Begin
		set @LogTimeCutoff = (select top 1 LogTime from DBAmp_Log
		where SPName Like '%SF_Replicate%' and Message Like 'Ending%'
		order by LogTime desc)

		select * from DBAmp_Replicate_Perf
		where (LogTime > ISNULL((Select Max(LogTime) from DBAmp_Log where Seen = 1 and SPName Like '%SF_Replicate%' and Message Like 'Ending%'), 0)) and (LogTime <= @LogTimeCutoff)
		order by LogTime asc

		Update DBAmp_Log
		set Seen = 1
		where LogTime = @LogTimeCutoff and SPName Like '%SF_Replicate%' and Message Like 'Ending%'
	End

	If @Name = 'sf_refresh'
	Begin
		set @LogTimeCutoff = (select top 1 LogTime from DBAmp_Log
		where SPName Like '%SF_Refresh%' and Message Like 'Ending%'
		order by LogTime desc)

		select * from DBAmp_Refresh_Perf
		where (LogTime > ISNULL((Select Max(LogTime) from DBAmp_Log where Seen = 1 and SPName Like '%SF_Refresh%' and Message Like 'Ending%'), 0)) and (LogTime <= @LogTimeCutoff)
		order by LogTime asc

		Update DBAmp_Log
		set Seen = 1
		where LogTime = @LogTimeCutoff and SPName Like '%SF_Refresh%' and Message Like 'Ending%'
	End

	If @Name = 'sf_bulkops'
	Begin
		set @LogTimeCutoff = (select top 1 LogTime from DBAmp_Log
		where SPName Like '%SF_BulkOps%' and Message Like 'Ending%'
		order by LogTime desc)

		select * from DBAmp_BulkOps_Perf
		where LogTime > ISNULL((Select Max(LogTime) from DBAmp_Log where Seen = 1 and SPName Like '%SF_BulkOps%' and Message Like 'Ending%'), 0) and (LogTime <= @LogTimeCutoff)
		order by LogTime asc

		Update DBAmp_Log
		set Seen = 1
		where LogTime = @LogTimeCutoff and SPName Like '%SF_BulkOps%' and Message Like 'Ending%'
	End
	return 0
End Try
Begin Catch
	If @Quiet = 0
	Begin
		print ERROR_MESSAGE()
	End
	RAISERROR ('',16,1)
	return 1
End Catch

Go

IF EXISTS (SELECT name
	   FROM   sysobjects
	   WHERE  name = N'SF_DBAmpLogDumpAndMarkAll'
	   AND 	  type = 'P')
    DROP PROCEDURE SF_DBAmpLogDumpAndMarkAll
GO
CREATE PROCEDURE [dbo].[SF_DBAmpLogDumpAndMarkAll]
AS

exec SF_DBAmpLogDumpAndMark 'SF_Replicate'

exec SF_DBAmpLogDumpAndMark 'SF_Refresh'

exec SF_DBAmpLogDumpAndMark 'SF_BulkOps'
GO