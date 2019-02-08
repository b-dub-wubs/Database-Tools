
USE DNB 
GO

IF OBJECT_ID('sp_endProc', 'P') IS NOT NULL
	DROP PROCEDURE sp_endProc
GO

CREATE PROCEDURE sp_endProc
(
	@procName varchar(max)
	,@startTime datetime
)
AS
BEGIN
		 --PRINT ( CAST(@@ROWCOUNT AS VARCHAR) + ' rows inserted into AcqMailAttribution_tmp' )
		 DECLARE @endTime DATETIME = GETDATE()

		 declare @err varchar(max) = @procName + ' completed at: ' + CONVERT(varchar(255), @endTime, 121)
		 RAISERROR ( @err, 0,1 ) 

		 SET @err = @procName + ' took ' + CAST(DATEDIFF(mi, @startTime, @endTime) AS varchar) + ' minutes'
		 RAISERROR ( @err , 0, 1 ) 

		 SET @err = '-----------------------'
		 RAISERROR ( @err, 0, 1 )

		 select @procName + ' completed at: ' + CONVERT(varchar(255), @endTime, 121)
END
