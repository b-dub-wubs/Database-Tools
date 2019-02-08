
IF @@SERVERNAME != 'S26'
BEGIN
    RAISERROR('Run on S26',16,1)
    RETURN
END

USE Analytics_WS
GO

IF OBJECT_ID('fn_NumDayOfWeek') IS NOT NULL  
    DROP FUNCTION fn_NumDayOfWeek
GO

/*
    Get the number of times a specific day of the week will occur between two dates
    The result is inclusive
*/

CREATE FUNCTION [dbo].fn_NumDayOfWeek 
( 
    @startDate DATE, 
    @endDate DATE,
    @dayOfWeek VARCHAR(50)
)
RETURNS INT
AS
BEGIN

    IF @dayOfWeek = 'Monday'
        RETURN DATEDIFF(DAY , -7 , @endDate) / 7 - DATEDIFF(DAY , -6 , @startDate) / 7
    ELSE IF @dayOfWeek = 'Tuesday'
        RETURN DATEDIFF(DAY , -6 , @endDate) / 7 - DATEDIFF(DAY , -5 , @startDate) / 7
    ELSE IF @dayOfWeek = 'Wednesday'
        RETURN DATEDIFF(DAY , -5 , @endDate) / 7 - DATEDIFF(DAY , -4 , @startDate) / 7
    ELSE IF @dayOfWeek = 'Thursday'
        RETURN DATEDIFF(DAY , -4 , @endDate) / 7 - DATEDIFF(DAY , -3 , @startDate) / 7
    ELSE IF @dayOfWeek = 'Friday'
        RETURN DATEDIFF(DAY , -3 , @endDate) / 7 - DATEDIFF(DAY , -2 , @startDate) / 7
    ELSE IF @dayOfWeek = 'Saturday'
        RETURN DATEDIFF(DAY , -2 , @endDate) / 7 - DATEDIFF(DAY , -1 , @startDate) / 7
    ELSE IF @dayOfWeek = 'Sunday'
        RETURN DATEDIFF(DAY , -1 , @endDate) / 7 - DATEDIFF(DAY , 0 , @startDate) / 7

    RETURN -1000

END