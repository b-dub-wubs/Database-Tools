
USE DNB 
GO

IF OBJECT_ID('sp_startProc', 'P') IS NOT NULL
	DROP PROCEDURE sp_startProc
GO

CREATE PROCEDURE sp_startProc
(
	@procName varchar(max)
)
AS
BEGIN
		 DECLARE @startTime DATETIME = GETDATE()
		 declare @err varchar(max)

		 SET @err = '-----------------------'
		 RAISERROR ( @err, 0, 1 )

		 SET @err = @procName + ' started at: ' + CONVERT(varchar(255), GETDATE(), 121)
		 RAISERROR ( @err, 0,1) 

END
