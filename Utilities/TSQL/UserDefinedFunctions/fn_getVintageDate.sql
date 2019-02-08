
USE [Analytics_WS]
GO

IF EXISTS (SELECT *
           FROM   sys.objects
           WHERE  object_id = OBJECT_ID(N'dbo.fn_getVintageDate')
                  AND type IN ( N'FN', N'IF', N'TF', N'FS', N'FT' ))
  DROP FUNCTION dbo.fn_getVintageDate
GO 


CREATE FUNCTION [dbo].fn_getVintageDate
(
    @date DATE,
    @endDate DATE = NULL 
)
RETURNS VARCHAR(10) 
AS
BEGIN
    IF @endDate IS NULL 
        SET @endDate = GETDATE()
        
    DECLARE @dateYear CHAR(4) = DATEPART(YEAR, @date)
    DECLARE @dateQuarter CHAR(1) = DATEPART(QUARTER, @date)

    RETURN 
        CASE 
            WHEN YEAR(@date) <= 2014 THEN @dateYear
            ELSE @dateYear + ' Q' + @dateQuarter
        END 

END
GO

