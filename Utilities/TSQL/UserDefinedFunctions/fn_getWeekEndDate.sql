
USE [Analytics_WS]
GO

IF EXISTS (SELECT *
           FROM   sys.objects
           WHERE  object_id = OBJECT_ID(N'dbo.fn_getWeekEndDate')
                  AND type IN ( N'FN', N'IF', N'TF', N'FS', N'FT' ))
  DROP FUNCTION dbo.fn_getWeekEndDate
GO 


CREATE FUNCTION [dbo].fn_getWeekEndDate
(
    @date DATE
)
RETURNS DATE 
AS
BEGIN

    RETURN DATEADD(
        DAY, 
        7 - DATEPART(WEEKDAY, @date), 
        CAST(@date AS DATE)
    )

END
GO

