
/*

__SAMPLE EXECUTION CODE__

DECLARE @stat INT

EXEC dbo.sp_start_job_wait
    @job_name = 'Rebuild CreditModelAnalysis',
    @WaitTime = '00:00:05',  -- this is parameter for check frequency
    @JobCompletionStatus = @stat OUTPUT

SELECT @stat
*/

USE Analytics_WS
GO

IF OBJECT_ID('sp_start_job_wait','P') IS NOT NULL
    DROP PROCEDURE [sp_start_job_wait]
GO

CREATE PROCEDURE [dbo].[sp_start_job_wait](
    @job_name            SYSNAME
   ,@WaitTime            DATETIME = '00:00:05'  -- this is parameter for check frequency
   ,@JobCompletionStatus INT      = NULL OUTPUT)
AS
    BEGIN

        SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
        SET NOCOUNT ON

        -- DECLARE @job_name	sysname

        DECLARE @job_id UNIQUEIDENTIFIER
        DECLARE @job_owner SYSNAME

        --Createing TEMP TABLE

        CREATE TABLE [#xp_results]
        (
            [job_id]                UNIQUEIDENTIFIER NOT NULL
           ,[last_run_date]         INT NOT NULL
           ,[last_run_time]         INT NOT NULL
           ,[next_run_date]         INT NOT NULL
           ,[next_run_time]         INT NOT NULL
           ,[next_run_schedule_id]  INT NOT NULL
           ,[requested_to_run]      INT NOT NULL -- BOOL
           ,[request_source]        INT NOT NULL
           ,[request_source_id]     SYSNAME COLLATE database_default
                                            NULL
           ,[running]               INT NOT NULL -- BOOL
           ,[current_step]          INT NOT NULL
           ,[current_retry_attempt] INT NOT NULL
           ,[job_state]             INT NOT NULL
        ) 

        SELECT
            @job_id = [job_id]
        FROM
            [msdb].[dbo].[sysjobs]
        WHERE [name] = @job_name

        SELECT
            @job_owner = SUSER_SNAME()

        INSERT INTO [#xp_results]
        EXECUTE [master].[dbo].[xp_sqlagent_enum_jobs]
            1,
            @job_owner,
            @job_id 

        -- Start the job if the job is not running

        IF NOT EXISTS
            (
                SELECT TOP 1
                    *
                FROM
                    [#xp_results]
                WHERE [running] = 1
            ) 
            EXEC [msdb].[dbo].[sp_start_job]
                @job_name = @job_name

        -- Give 2 sec for think time.

        WAITFOR DELAY '00:00:02'

        DELETE FROM [#xp_results]
        INSERT INTO [#xp_results]
        EXECUTE [master].[dbo].[xp_sqlagent_enum_jobs]
            1,
            @job_owner,
            @job_id

        WHILE EXISTS
            (
                SELECT TOP 1
                    *
                FROM
                    [#xp_results]
                WHERE [running] = 1
            ) 
            BEGIN

                WAITFOR DELAY @WaitTime

                -- Information 

                RAISERROR('JOB IS RUNNING',0,1) WITH NOWAIT

                DELETE FROM [#xp_results]

                INSERT INTO [#xp_results]
                EXECUTE [master].[dbo].[xp_sqlagent_enum_jobs]
                    1,
                    @job_owner,
                    @job_id
            END

        SELECT
            @JobCompletionStatus = [run_status]
        FROM
            [msdb].[dbo].[sysjobhistory]
        WHERE [job_id] = @job_id

        IF @JobCompletionStatus = 1
            PRINT 'The job ran Successful'
        ELSE
        IF @JobCompletionStatus = 3
            PRINT 'The job is Cancelled'
        ELSE
            BEGIN
                RAISERROR('[ERROR]:%s job is either failed or not in good state. Please check',16,1,@job_name) WITH LOG
            END

        RETURN @JobCompletionStatus
    END

GO