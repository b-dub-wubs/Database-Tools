
USE [Analytics_WS]
GO

IF EXISTS (SELECT *
           FROM   sys.objects
           WHERE  object_id = OBJECT_ID(N'dbo.fn_getFirstOfMonth')
                  AND type IN ( N'FN', N'IF', N'TF', N'FS', N'FT' ))
  DROP FUNCTION dbo.fn_getFirstOfMonth
GO 


CREATE FUNCTION [dbo].fn_getFirstOfMonth
(
    @date DATE
)
RETURNS DATE 
AS
BEGIN

    RETURN CAST(DATEADD(
        mm, 
        DATEDIFF(mm, 0, @date), 
        0
    ) AS DATE)

END
GO
