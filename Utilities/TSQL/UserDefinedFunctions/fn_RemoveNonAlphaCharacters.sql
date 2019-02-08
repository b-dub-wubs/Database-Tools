
USE [Analytics_WS]
GO 

IF OBJECT_ID('dbo.[fn_RemoveNonAlphaCharacters]') IS NOT NULL   
    DROP FUNCTION dbo.[fn_RemoveNonAlphaCharacters]
GO 

CREATE FUNCTION [dbo].[fn_RemoveNonAlphaCharacters] 
( 
    @Temp VARCHAR(1000) 
)
RETURNS VARCHAR(1000)
AS
BEGIN

    DECLARE @KeepValues AS VARCHAR(50)
    SET @KeepValues = '%[^a-z]%'
    WHILE PATINDEX(@KeepValues , @Temp) > 0
        SET @Temp = STUFF(@Temp , PATINDEX(@KeepValues , @Temp) , 1 , '')

    RETURN @Temp
END

