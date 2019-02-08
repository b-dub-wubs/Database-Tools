
USE [Analytics_WS]
GO

IF OBJECT_ID('dbo.sp_insert_StoredProcTimingStats') IS NOT NULL
    DROP PROCEDURE dbo.sp_insert_StoredProcTimingStats
GO

CREATE PROCEDURE dbo.[sp_insert_StoredProcTimingStats]
(
    @event VARCHAR(255) -- Begin/End
    ,@version VARCHAR(255)-- Old = 0, New = 1, Newer = 2
    ,@tableName VARCHAR(255)
    ,@timeStamp DATETIME = NULL -- GETDATE()
)
AS
BEGIN 
    IF @timeStamp IS NULL
        SET @timeStamp = GETDATE()

    IF OBJECT_ID('Analytics_WS.[dbo].[StoredProcTimingStats]', 'U') IS NULL
        CREATE TABLE Analytics_WS.[dbo].[StoredProcTimingStats] (
            [Event] VARCHAR(255),
            TS DATETIME, 
            [Version] VARCHAR(255), 
            TableName VARCHAR(255)
        )

    INSERT INTO
        Analytics_WS.[dbo].[StoredProcTimingStats]
    SELECT
        @event,
        @timeStamp,
        @version,
        @tableName

END 

/*
--Script below to see timing of procs
SELECT
    [spts].[Event],
    [spts].[Version],
    CAST([spts].[TS] AS DATE),
    [spts].[TableName],
    DATEDIFF(SECOND,[spts].[TS],[spts2].[TS]) AS TimeDiffSec
FROM
    [Analytics_WS].[dbo].[StoredProcTimingStats] AS [spts]
    LEFT JOIN [Analytics_WS].[dbo].[StoredProcTimingStats] AS [spts2]
        ON [spts2].[TableName] = [spts].[TableName]
        AND [spts2].[Version] = [spts].[Version]
        AND [spts2].[Event] != [spts].[Event]
        AND CAST([spts2].[TS] AS DATE) = CAST([spts].[TS] AS DATE)
WHERE
    [spts].[TableName] LIKE '%externall%'
    AND [spts].[Event] = 'begin'
ORDER BY 
    [spts].[TS] DESC 

*/
