
USE DNB
GO


IF OBJECT_ID('sp_bulkInsertTables', 'P') IS NOT NULL 
    DROP PROCEDURE [dbo].[sp_bulkInsertTables]
GO

CREATE PROCEDURE [dbo].[sp_bulkInsertTables](
    @DBNAME    VARCHAR(255)  = 'dnb'
   ,@TBLNAME   VARCHAR(255)
   ,@FILENAME  VARCHAR(255)
   ,@DIRECTORY VARCHAR(1000)
   ,@delimiter varchar(255) = ','
   ,@extension varchar(255) = 'csv'
   ,@rowTerminator varchar(255) = '\n'
   ,@schema varchar(255) = 'dbo'
   ,@startRowNum varchar(255) = '2'
)
AS
BEGIN

    DECLARE @rowTerminatorStr varchar(max) = ''
    IF @rowTerminator != 'NONE'
        SET @rowTerminatorStr = 'rowterminator='''+@rowTerminator+''','

    DECLARE @SQL VARCHAR(MAX) = '
        BULK INSERT
	           '+@DBNAME+'.'+@schema+'.'+@TBLNAME+'
        FROM 
	           '''+@DIRECTORY+@FILENAME+'.'+@extension+'''
        WITH 
	   (
		  fieldterminator='''+@delimiter+''',
		  '+@rowTerminatorStr+'
		  TABLOCK,
            FIRSTROW='+@startRowNum+'
	   )
    '
    --SELECT @sql

    EXEC (@SQL)
END
