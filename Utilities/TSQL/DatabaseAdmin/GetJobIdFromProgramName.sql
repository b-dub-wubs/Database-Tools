USE [Analytics_WS]
GO

IF OBJECT_ID('[dbo].[GetJobIdFromProgramName]','fn') IS NOT NULL
    DROP FUNCTION [dbo].[GetJobIdFromProgramName]
GO 

CREATE FUNCTION [dbo].[GetJobIdFromProgramName] (
   @program_name nvarchar(128)
)
RETURNS uniqueidentifier
AS
BEGIN
DECLARE @start_of_job_id int
SET @start_of_job_id = CHARINDEX('(Job 0x', @program_name) + 7
RETURN CASE WHEN @start_of_job_id > 0 THEN CAST(
      SUBSTRING(@program_name, @start_of_job_id + 06, 2) + SUBSTRING(@program_name, @start_of_job_id + 04, 2) + 
      SUBSTRING(@program_name, @start_of_job_id + 02, 2) + SUBSTRING(@program_name, @start_of_job_id + 00, 2) + '-' +
      SUBSTRING(@program_name, @start_of_job_id + 10, 2) + SUBSTRING(@program_name, @start_of_job_id + 08, 2) + '-' +
      SUBSTRING(@program_name, @start_of_job_id + 14, 2) + SUBSTRING(@program_name, @start_of_job_id + 12, 2) + '-' +
      SUBSTRING(@program_name, @start_of_job_id + 16, 4) + '-' +
      SUBSTRING(@program_name, @start_of_job_id + 20,12) AS uniqueidentifier)
   ELSE NULL
   END
END --FUNCTION
GO

-- Sample usage
SELECT *
FROM msdb.dbo.sysjobs
WHERE
job_id = analytics_ws.[dbo].[GetJobIdFromProgramName]('SQLAgent - TSQL JobStep (Job 0xA551FD7A33D1B34BAD4CBD6C8241E399 : Step 2)')
