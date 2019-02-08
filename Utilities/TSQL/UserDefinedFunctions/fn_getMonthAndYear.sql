
USE [DNB]
GO

IF EXISTS (SELECT *
           FROM   sys.objects
           WHERE  object_id = OBJECT_ID(N'dbo.fn_getMonthAndYear')
                  AND type IN ( N'FN', N'IF', N'TF', N'FS', N'FT' ))
  DROP FUNCTION dbo.fn_getMonthAndYear
GO 

CREATE FUNCTION dbo.fn_getMonthAndYear 
(
	@runDate varchar(8) = ''
)
RETURNS VARCHAR(255)
AS
BEGIN
	if @runDate = ''
		set @runDate = getdate()
		
	DECLARE @ret VARCHAR(255) = DATENAME(MONTH, @runDate) + '_' + CAST(YEAR(@runDate) AS VARCHAR(4))
    RETURN @ret
END
GO

