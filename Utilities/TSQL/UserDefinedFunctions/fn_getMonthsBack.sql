
USE [DNB]
GO

IF EXISTS (SELECT *
           FROM   sys.objects
           WHERE  object_id = OBJECT_ID(N'dbo.fn_getMonthsBack')
                  AND type IN ( N'FN', N'IF', N'TF', N'FS', N'FT' ))
  DROP FUNCTION dbo.fn_getMonthsBack
GO 


CREATE FUNCTION [dbo].[fn_getMonthsBack]
(
    @monthsBack INT 
)
RETURNS VARCHAR(6)
AS
    BEGIN
        SET @monthsBack = -1 * @monthsBack

        DECLARE @stamp DATE = DATEADD(DAY,-DAY(GETDATE()) + 1,DATEADD(MONTH,@monthsBack,GETDATE()))
        DECLARE @twoDigitMonth VARCHAR(2) = DATEPART([mm],@stamp)
	   SET @twoDigitMonth = right('00' + @twoDigitMonth, 2) -- add left padding for 2 digit months
        DECLARE @fourDigitYear VARCHAR(4) = DATEPART([yyyy],@stamp)

        DECLARE @ret VARCHAR(6) = @fourDigitYear
                                  + @twoDigitMonth
        RETURN @ret
    END
GO

