/*┌─────────────────────────────────────────────────────────────────────────────────────────────┐*\
  │ TITLE: User Defined Function DDL                                                            │
  │   DirectMail.logging.udf_DurrationStr
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤
  │ DESCRIPTION:                                                                                │
      
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤
  │ REVISION HISTORY:                                                                           │
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤
  │   DATE       AUTHOR          CHANGE DESCRIPTION                                             │
  │   ────────── ─────────────── ────────────────────────────────────────────────────────────── │
      2018.12.19 bwarner         Initial Draft
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤
  │ UNIT TESTING SCRIPTS:                                                                       │

    DECLARE 
        @From_t DATETIME2 = GETDATE()
      , @To_t DATETIME2 = DATEADD(minute,56,DATEADD(millisecond,547,DATEADD(second,23,DATEADD(hour,7,DATEADD(day,0,GETDATE())))))

    SELECT
        From_t = @From_t
      , To_t = @To_t

    SELECT 
      TestResult = logging.udf_DurrationStr(@From_t,@To_t)
    , TestResult2 = logging.udf_DurrationStr(@To_t,@From_t)

\*└─────────────────────────────────────────────────────────────────────────────────────────────┘*/
USE DirectMail
GO


IF  EXISTS (SELECT * FROM sys.objects WHERE [object_id] = OBJECT_ID(N'logging.udf_DurrationStr') AND [type_desc] LIKE 'SQL%FUNCTION')
	DROP FUNCTION 
    logging.udf_DurrationStr
GO

CREATE FUNCTION 
  logging.udf_DurrationStr
    (
        @From   DATETIME2
      , @To     DATETIME2
    )
RETURNS
  VARCHAR(128)
AS
BEGIN

  DECLARE 
      @durr_str     VARCHAR(128) = ''
    , @days         INT
    , @hours        INT
    , @minutes      INT
    , @seconds      INT
    , @milliseconds INT
    

  IF @From > @To
    BEGIN
      SET @durr_str += '-'
      DECLARE @switch_dt DATETIME2 = @From
      SET @From = @To
      SET @To = @switch_dt
    END

  SET @days         = FLOOR(DATEDIFF(HOUR,@From,@To) / 24)
  SET @To           = DATEADD(DAY,-@days,@To)

  SET @hours        = FLOOR(DATEDIFF(MINUTE,@From,@To) / 60)
  SET @To           = DATEADD(HOUR,-@hours,@To)

  SET @minutes      = FLOOR(DATEDIFF(SECOND,@From,@To) / 60)
  SET @To           = DATEADD(MINUTE,-@minutes,@To)

  SET @seconds      = FLOOR(DATEDIFF(MILLISECOND,@From,@To) / 1000)
  SET @To           = DATEADD(SECOND,-@seconds,@To)

  SET @milliseconds = DATEDIFF(MILLISECOND,@From,@To) % 1000

  IF @days > 0
    SET @durr_str += REPLACE(CONVERT(VARCHAR, CAST(@days AS MONEY), 1),'.00','') + ' Day(s) '

  SET @durr_str +=  REPLACE(STR(@hours,2),' ','0') + ':'
                  + REPLACE(STR(@minutes,2),' ','0') + ':'
                  + REPLACE(STR(@seconds,2),' ','0') + '.'
                  + REPLACE(STR(@milliseconds,4),' ','0')

  RETURN @durr_str
  
END
GO