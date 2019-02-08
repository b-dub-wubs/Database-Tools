
USE [Analytics_WS]
GO

IF OBJECT_ID('[Analytics_WS].dbo.[sp_TableComparisonTest]') IS NOT NULL
    DROP PROCEDURE [sp_TableComparisonTest]
GO 

CREATE PROCEDURE sp_TableComparisonTest
(
    @origTblName VARCHAR(4000) 
    ,@profileName VARCHAR(4000) = 's28'
    ,@columns VARCHAR(4000) = '*'
    ,@dbName VARCHAR(255) = 'Analytics_DWH'
    ,@schemaName VARCHAR(255) = 'dbo'
)
AS
BEGIN

    DECLARE @sql VARCHAR(MAX) = '
        DECLARE  @testCountExcept BIGINT = 0
                ,@testCountExceptReverse BIGINT = 0
                ,@testCount BIGINT = 0
                ,@aggCount BIGINT = 0
                
        -- Get counts of tables
        SELECT @testCount = COUNT(*) FROM ['+@dbName+'].['+@schemaName+'].['+@origTblName+'_test] 
        SELECT @aggCount = COUNT(*) FROM ['+@dbName+'].['+@schemaName+'].['+@origTblName+']
        
        SELECT @testCountExcept = COUNT(*) FROM (
            SELECT '+@columns+' FROM ['+@dbName+'].['+@schemaName+'].['+@origTblName+']
            EXCEPT SELECT '+@columns+' FROM ['+@dbName+'].['+@schemaName+'].['+@origTblName+'_test]
        ) a

        SELECT @testCountExceptReverse = COUNT(*) FROM (
            SELECT '+@columns+' FROM ['+@dbName+'].['+@schemaName+'].['+@origTblName+'_test]
            EXCEPT SELECT '+@columns+' FROM ['+@dbName+'].['+@schemaName+'].['+@origTblName+']
        ) a
        
        -- All counts should line up
        DECLARE @outcome VARCHAR(50) = ''Fail '+@origTblName+' Test''
        IF @testCount = @aggCount AND @testCountExcept = 0 AND @testCountExceptReverse = 0
            SET @outcome = ''Pass '+@origTblName+' Test''
            
        DECLARE @results VARCHAR(4000) = ''
            '+@origTblName+': ''+CAST(@aggCount AS VARCHAR(40))+'', 
            '+@origTblName+' Test: ''+CAST(@testCount AS VARCHAR(40))+'', 
            Except Test: ''+CAST(@testCountExcept AS VARCHAR(40))+'', 
            Except Test Reverse: ''+CAST(@testCountExceptReverse AS VARCHAR(40))
        
        PRINT(@outcome)
        PRINT(@results)

        EXEC [msdb].[dbo].[sp_send_dbmail]
            @profile_name = '''+@profileName+''',
            @recipients = N''omouradi@nationalfunding.com'',
            @body = @results,
            @subject = @outcome
    '
    PRINT(@sql)
    EXEC(@sql)

END 

        
