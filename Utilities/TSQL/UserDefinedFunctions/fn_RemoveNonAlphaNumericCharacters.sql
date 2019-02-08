
USE [Analytics_WS]
GO 

IF OBJECT_ID('dbo.[fn_RemoveNonAlphaNumericCharacters]') IS NOT NULL   
    DROP FUNCTION dbo.[fn_RemoveNonAlphaNumericCharacters]
GO 

CREATE FUNCTION [dbo].[fn_RemoveNonAlphaNumericCharacters] 
( 
    @Temp VARCHAR(1000),
    @doLower BIT = 0
)
RETURNS VARCHAR(1000)
AS
BEGIN

    DECLARE @KeepValues AS VARCHAR(50)
    SET @KeepValues = '%[^a-zA-Z0-9]%'
    WHILE PATINDEX(@KeepValues , @Temp) > 0
        SET @Temp = STUFF(@Temp , PATINDEX(@KeepValues , @Temp) , 1 , '')

    IF @doLower = 1
        SET @Temp = LOWER(@Temp)

    RETURN @Temp
END

