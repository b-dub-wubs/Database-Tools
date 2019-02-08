
USE [Analytics_WS]
GO

IF OBJECT_ID('fn_AddBusinessDays') IS NOT NULL  
    DROP FUNCTION fn_AddBusinessDays
GO

CREATE FUNCTION [dbo].fn_AddBusinessDays 
( 
    @Date DATE, 
    @n INT 
)
RETURNS DATE
AS
BEGIN

    DECLARE @d INT;
    SET @d = 4 - SIGN(@n) * ( 4 - DATEPART(DW , @Date) );
    RETURN DATEADD(D,@n+((ABS(@n)+@d-2)/5)*2*SIGN(@n)-@d/7,@Date);

END