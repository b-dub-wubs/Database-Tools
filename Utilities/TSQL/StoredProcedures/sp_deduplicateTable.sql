
IF @@SERVERNAME != 'S26'
BEGIN
    RAISERROR('Run on S26',16,1)
    RETURN
END 

USE [Analytics_WS]

IF OBJECT_ID('[dbo].[sp_deduplicateTable]','P') IS NOT NULL
    DROP PROCEDURE [dbo].[sp_deduplicateTable]
GO

CREATE PROCEDURE [dbo].[sp_deduplicateTable]
(
    @tblName VARCHAR(4000)
    ,@columns VARCHAR(MAX)
    ,@identityColumnName VARCHAR(4000) = 'AutoId'
)
AS
BEGIN

    DECLARE @cleanUpSql VARCHAR(MAX) = '
        DELETE 
            [b]
        FROM 
            '+@tblName+' AS [b]
            JOIN (
                SELECT
                    ['+@identityColumnName+']
                FROM
                    (
                        SELECT
                            ['+@identityColumnName+']
                            ,ROW_NUMBER() OVER ( PARTITION BY '+SUBSTRING(RTRIM(@columns),1,LEN(RTRIM(@columns))-1)+' ORDER BY (SELECT 1) ) AS [rownum]
                        FROM
                            '+@tblName+' AS [l]
                    ) AS [a]
                WHERE 
                    [a].[rownum] > 1
            ) [a]
            ON [a].['+@identityColumnName+'] = [b].['+@identityColumnName+']
    '
    --SELECT @cleanUpSql
    EXEC(@cleanUpSql)

END

