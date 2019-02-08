-- =============================================
-- Create procedure SF_DeleteAccount
-- Stored procedure example for doing deletes by Id on Account
-- Usage:
--     exec SF_DeleteAccount '00130000008hz55AAA'
--
-- Execute this script to add the SF_DeleteAccount proc to your database before usage
-- =============================================
IF EXISTS (SELECT name
	   FROM   sysobjects
	   WHERE  name = N'SF_DeleteAccount'
	   AND 	  type = 'P')
    DROP PROCEDURE SF_DeleteAccount
GO

CREATE PROCEDURE SF_DeleteAccount
	@id nvarchar(18)
AS
-- Parameters: @id           	- id of Account record to delete

declare @stmt nvarchar(4000)
set @stmt = 'delete openquery(SALESFORCE,''Select Id from Account where Id='
set @stmt = @stmt + '''''' + @id + ''''' '') ' 
print @stmt
exec (@stmt)
if (@@ERROR <> 0) 
   return -1
else
   return 0
go


