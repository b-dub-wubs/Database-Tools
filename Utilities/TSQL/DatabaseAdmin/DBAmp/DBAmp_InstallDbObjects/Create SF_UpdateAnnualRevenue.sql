-- =============================================
-- Create procedure SF_UpdateAnnualRevenue
-- Stored procedure example for doing updates by Id on Account's AnnualRevenue
-- Usage:
--     exec SF_UpdateAnnualRevenue '00130000008hz55AAA',40000
--
-- Execute this script to add the SF_UpdateAnnualRevenue proc to your database before usage
-- =============================================
IF EXISTS (SELECT name
	   FROM   sysobjects
	   WHERE  name = N'SF_UpdateAnnualRevenue'
	   AND 	  type = 'P')
    DROP PROCEDURE SF_UpdateAnnualRevenue
GO

CREATE PROCEDURE SF_UpdateAnnualRevenue
	@id nvarchar(18),
	@value int
AS
-- Parameters: @id           	- id of Account record to update
--             @value		 - new value for field

declare @stmt nvarchar(4000)
set @stmt = 'update openquery(SALESFORCE,''Select AnnualRevenue from Account where Id='
set @stmt = @stmt + '''''' + @id + ''''' '') set AnnualRevenue = ' + CAST(@value as nvarchar(20))
print @stmt
exec (@stmt)
if (@@ERROR <> 0) 
   return -1
else
   return 0
go


