USE [Analytics_WS]
GO

IF OBJECT_ID('[fn_RemoveNonNumericCharacters]') IS NOT NULL
    DROP FUNCTION [fn_RemoveNonNumericCharacters]
GO

CREATE FUNCTION [dbo].[fn_RemoveNonNumericCharacters] ( @Temp VARCHAR(1000) )
RETURNS VARCHAR(1000)
AS
BEGIN

    DECLARE @KeepValues AS VARCHAR(50)
    SET @KeepValues = '%[^0-9]%'
    WHILE PATINDEX(@KeepValues , @Temp) > 0
        SET @Temp = STUFF(@Temp , PATINDEX(@KeepValues , @Temp) , 1 , '')
    
    RETURN @Temp
END
GO

--Select dbo.[fn_RemoveNonNumericCharacters]('abc1234de-()f58ghi90jkl')