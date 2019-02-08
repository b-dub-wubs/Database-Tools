
USE [Analytics_WS]
GO

IF EXISTS (SELECT *
           FROM   sys.objects
           WHERE  object_id = OBJECT_ID(N'dbo.fn_getFirstOfQuarter')
                  AND type IN ( N'FN', N'IF', N'TF', N'FS', N'FT' ))
  DROP FUNCTION dbo.fn_getFirstOfQuarter
GO 


CREATE FUNCTION [dbo].fn_getFirstOfQuarter
(
    @date DATE
)
RETURNS DATE 
AS
BEGIN

    RETURN CAST(DATEADD(
        qq, 
        DATEDIFF(qq, 0, @date), 
        0
    ) AS DATE)

END
GO
