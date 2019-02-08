-- =============================================
-- Create procedure SF_UpdateAccount
-- Stored procedure example for doing updates by Id on Account
-- Usage:
--     exec SF_UpdateAccount '00130000008hz55AAA','BillingCity','''Denver'''
-- or
--     exec SF_UpdateAccount '00130000008hz55AAA','AnnualRevenue','20000'
--
-- Execute this script to add the SF_UpdateAccount proc to your database before usage
-- =============================================
IF EXISTS (SELECT name
	   FROM   sysobjects
	   WHERE  name = N'SF_UpdateAccount'
	   AND 	  type = 'P')
    DROP PROCEDURE SF_UpdateAccount
GO

CREATE PROCEDURE SF_UpdateAccount
	@id nvarchar(18),
	@field nvarchar(50),
	@value nvarchar(2000)
AS
-- Parameters: @id           	- id of Account record to update
--             @field            - field name to update
--             @value		 - new value for field

declare @stmt nvarchar(4000)
set @stmt = 'update openquery(SALESFORCE,''Select Id,'
set @stmt = @stmt + @field + ' from Account where Id='
set @stmt = @stmt + '''''' + @id + ''''' '') set ' + @field + ' = ' +@value
-- print @stmt
exec (@stmt)
if (@@ERROR <> 0) 
   return -1
else
   return 0
go


