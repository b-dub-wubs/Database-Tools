
USE [DNB]
GO

IF EXISTS (SELECT *
           FROM   sys.objects
           WHERE  object_id = OBJECT_ID(N'dbo.fn_getMonthTblName')
                  AND type IN ( N'FN', N'IF', N'TF', N'FS', N'FT' ))
  DROP FUNCTION dbo.fn_getMonthTblName
GO 

CREATE FUNCTION dbo.fn_getMonthTblName 
(
     @dbName VARCHAR(255) 
    ,@tblName varchar(255)
	,@runDate varchar(8) = ''
)
RETURNS VARCHAR(255)
AS
BEGIN
        DECLARE @monthAndYear VARCHAR(255) = [dbo].[fn_getMonthAndYear](@runDate)
        DECLARE @tableNameSuffixed VARCHAR(255) = @tblName+'__'+@monthAndYear
        DECLARE @ret VARCHAR(255) = @dbName+'.dbo.'+@tableNameSuffixed
        RETURN @ret
END
GO

