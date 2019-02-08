
--IF @@SERVERNAME != 'S28'
--BEGIN
--    RAISERROR('Run on S28',16,1)
--    RETURN
--END

USE Analytics_WS
GO

IF OBJECT_ID('[dbo].[fn_WorkDays_V2]') IS NOT NULL
    DROP FUNCTION [dbo].[fn_WorkDays_V2]
GO

CREATE FUNCTION [dbo].[fn_WorkDays_V2]
(
    @StartDate DATETIME
   ,@EndDate   DATETIME = NULL --@EndDate replaced by @StartDate when DEFAULTed
   ,@allowNegativeDays BIT = 0
   ,@getPaymentDays BIT = 0
)
RETURNS INT
AS
BEGIN
    DECLARE @Swap DATETIME
    IF @StartDate IS NULL
        RETURN NULL
    IF @EndDate IS NULL
        SELECT @EndDate = @StartDate

    --Strip the time element from both dates (just to be safe) by converting to whole days and back to a date.
    --Usually faster than CONVERT.
    --0 is a date (01/01/1900 00:00:00.000)
    SELECT
        @StartDate = DATEADD([dd],DATEDIFF([dd],0,@StartDate),0)
        ,@EndDate = DATEADD([dd],DATEDIFF([dd],0,@EndDate),0)

    DECLARE @checkPastDate INT  = 1
    IF @allowNegativeDays = 1 AND @StartDate > @EndDate
    BEGIN
        SET @checkPastDate = -1
    END 

    --If the inputs are in the wrong order, reverse them.
    IF @StartDate > @EndDate 
        SELECT
            @Swap = @EndDate
            ,@EndDate = @StartDate
            ,@StartDate = @Swap

    --Calculate and return the number of workdays using the input parameters.
    --This is the meat of the function.
    --This is really just one formula with a couple of parts that are listed on separate lines for documentation purposes.

        DECLARE @ret INT = 
            @checkPastDate * (
            SELECT
                ( DATEDIFF([dd],@StartDate,@EndDate) + 1 ) /* Start with total number of days including weekends */
                - ( DATEDIFF([wk],@StartDate,@EndDate) * 2 ) /* Subtact 2 days for each full weekend */
                - ( CASE /* If StartDate is a Sunday, Subtract 1 */
                        WHEN DATENAME([dw],@StartDate) = 'Sunday'
                        THEN 1
                        ELSE 0
                    END )
                - ( CASE /* If EndDate is a Saturday, Subtract 1 */
                        WHEN DATENAME([dw],@EndDate) = 'Saturday'
                        THEN 1
                        ELSE 0
                    END )
                - (CASE WHEN @StartDate <= '11/28/13' THEN 1 ELSE 0 END)
                - (CASE WHEN @StartDate <= '12/25/13' THEN 1 ELSE 0 END)
                - (CASE WHEN @StartDate <= '1/1/14' THEN 1 ELSE 0 END)
                - (CASE WHEN @StartDate <= '1/20/14' THEN 1 ELSE 0 END)
                - (CASE WHEN @StartDate <= '2/17/14' THEN 1 ELSE 0 END)
            )
        
        IF @getPaymentDays = 1
            SET @ret = @ret
            - (CASE WHEN @StartDate <= '1/2/2017' THEN 1 ELSE 0 END)
            - (CASE WHEN @StartDate <= '1/16/2017' THEN 1 ELSE 0 END)
            - (CASE WHEN @StartDate <= '2/20/2017' THEN 1 ELSE 0 END)
            - (CASE WHEN @StartDate <= '5/29/2017' THEN 1 ELSE 0 END)
            - (CASE WHEN @StartDate <= '7/4/2017' THEN 1 ELSE 0 END)
            - (CASE WHEN @StartDate <= '9/4/2017' THEN 1 ELSE 0 END)
            - (CASE WHEN @StartDate <= '10/9/2017' THEN 1 ELSE 0 END)
            - (CASE WHEN @StartDate <= '11/11/2017' THEN 1 ELSE 0 END)
            - (CASE WHEN @StartDate <= '11/23/2017' THEN 1 ELSE 0 END)
            - (CASE WHEN @StartDate <= '12/25/2017' THEN 1 ELSE 0 END)
            - (CASE WHEN @StartDate <= '1/1/2018' THEN 1 ELSE 0 END)
            - (CASE WHEN @StartDate <= '1/1/2014' THEN 1 ELSE 0 END)
            - (CASE WHEN @StartDate <= '1/20/2014' THEN 1 ELSE 0 END)
            - (CASE WHEN @StartDate <= '2/17/2014' THEN 1 ELSE 0 END)
            - (CASE WHEN @StartDate <= '5/26/2014' THEN 1 ELSE 0 END)
            - (CASE WHEN @StartDate <= '7/4/2014' THEN 1 ELSE 0 END)
            - (CASE WHEN @StartDate <= '9/1/2014' THEN 1 ELSE 0 END)
            - (CASE WHEN @StartDate <= '10/13/2014' THEN 1 ELSE 0 END)
            - (CASE WHEN @StartDate <= '11/11/2014' THEN 1 ELSE 0 END)
            - (CASE WHEN @StartDate <= '11/27/2014' THEN 1 ELSE 0 END)
            - (CASE WHEN @StartDate <= '12/25/2014' THEN 1 ELSE 0 END)
            - (CASE WHEN @StartDate <= '1/1/2015' THEN 1 ELSE 0 END)
            - (CASE WHEN @StartDate <= '1/19/2015' THEN 1 ELSE 0 END)
            - (CASE WHEN @StartDate <= '2/16/2015' THEN 1 ELSE 0 END)
            - (CASE WHEN @StartDate <= '5/25/2015' THEN 1 ELSE 0 END)
            - (CASE WHEN @StartDate <= '7/3/2015' THEN 1 ELSE 0 END)
            - (CASE WHEN @StartDate <= '9/7/2015' THEN 1 ELSE 0 END)
            - (CASE WHEN @StartDate <= '10/12/2015' THEN 1 ELSE 0 END)
            - (CASE WHEN @StartDate <= '11/11/2015' THEN 1 ELSE 0 END)
            - (CASE WHEN @StartDate <= '11/26/2015' THEN 1 ELSE 0 END)
            - (CASE WHEN @StartDate <= '12/25/2015' THEN 1 ELSE 0 END)
            - (CASE WHEN @StartDate <= '1/1/2016' THEN 1 ELSE 0 END)
            - (CASE WHEN @StartDate <= '1/18/2016' THEN 1 ELSE 0 END)
            - (CASE WHEN @StartDate <= '2/15/2016' THEN 1 ELSE 0 END)
            - (CASE WHEN @StartDate <= '5/30/2016' THEN 1 ELSE 0 END)
            - (CASE WHEN @StartDate <= '7/4/2016' THEN 1 ELSE 0 END)
            - (CASE WHEN @StartDate <= '9/5/2016' THEN 1 ELSE 0 END)
            - (CASE WHEN @StartDate <= '10/10/2016' THEN 1 ELSE 0 END)
            - (CASE WHEN @StartDate <= '11/11/2016' THEN 1 ELSE 0 END)
            - (CASE WHEN @StartDate <= '11/24/2016' THEN 1 ELSE 0 END)
            - (CASE WHEN @StartDate <= '12/26/2016' THEN 1 ELSE 0 END)

        RETURN @ret

END
