
USE [Analytics_WS]
GO 

IF OBJECT_ID('dbo.[fn_GetNumberOfWords]') IS NOT NULL   
    DROP FUNCTION dbo.[fn_GetNumberOfWords]
GO 

CREATE FUNCTION dbo.[fn_GetNumberOfWords]
(
 @stringToSplit VARCHAR(8000)
,@numberOfWords INT
)
RETURNS VARCHAR(8000)
AS
BEGIN 

    SET @stringToSplit = LTRIM(RTRIM(@stringToSplit))
    DECLARE  @currentword VARCHAR(8000) = ''
            ,@returnstring VARCHAR(8000) = ''
            ,@wordcount INT = 0
            ,@index INT

    WHILE @wordcount < @numberOfWords AND LEN(@stringToSplit) > 0
    BEGIN
                
        SELECT @index = CHARINDEX(' ' , @stringToSplit)

        IF @index = 0
        BEGIN
            SELECT @currentword = LTRIM(RTRIM(@stringToSplit))
            SELECT @wordcount = @numberOfWords 
        END
        ELSE
        BEGIN
            IF ( LEN(@stringToSplit) - @index > 0 )
            BEGIN
                SELECT @currentword = LTRIM(RTRIM(LEFT(@stringToSplit , @index - 1)))--the new shortened string
                SELECT @stringToSplit = RIGHT(@stringToSplit , LEN(@stringToSplit) - @index) -- the rest
            END
        END

        SELECT @returnstring = @returnstring + ' ' + @currentword

        IF LEN(@currentword) > 1 OR @wordcount > 0 
            SELECT @wordcount = @wordcount + 1 
    END

    SET @returnstring = LTRIM(@returnstring)
    RETURN @returnstring

END
