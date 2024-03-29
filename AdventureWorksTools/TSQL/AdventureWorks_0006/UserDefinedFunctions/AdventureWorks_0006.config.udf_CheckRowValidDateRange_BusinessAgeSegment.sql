/*┌─────────────────────────────────────────────────────────────────────────────────────────────┐*\
  │ TITLE: User Defined Function DDL                                                            │
  │   AdventureWorks_0006.config.udf_CheckRowValidDateRange_BusinessAgeSegment
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤
  │ DESCRIPTION:                                                                                │
      
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤
  │ REVISION HISTORY:                                                                           │
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤
  │   DATE       AUTHOR          CHANGE DESCRIPTION                                             │
  │   ────────── ─────────────── ────────────────────────────────────────────────────────────── │
      2018.12.21 bwarner         Initial Draft
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤
  │ UNIT TESTING SCRIPTS:                                                                       │

      SELECT TestResult = config.udf_CheckRowValidDateRange_BusinessAgeSegment('Test_Param')

\*└─────────────────────────────────────────────────────────────────────────────────────────────┘*/
USE AdventureWorks_0006
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE [object_id] = OBJECT_ID(N'config.udf_CheckRowValidDateRange_BusinessAgeSegment'))
	DROP FUNCTION 
    config.udf_CheckRowValidDateRange_BusinessAgeSegment
GO

CREATE FUNCTION 
  config.udf_CheckRowValidDateRange_BusinessAgeSegment
    (
        @ValidFrom              DATETIME2
      , @MailingOrgID           TINYINT
      , @BusinessAgeSegmentName VARCHAR(32)
    )
RETURNS
  BIT
AS
BEGIN
  DECLARE 
      @IsValid      BIT       = 0
    , @LastExpired  DATETIME2

  SELECT
    @LastExpired = MAX(ValidTo)
  FROM
    config.BusinessAgeSegment
  WHERE
        MailingOrgID            = @MailingOrgID
    AND BusinessAgeSegmentName  = @BusinessAgeSegmentName

  IF @LastExpired IS NULL OR @ValidFrom >= @LastExpired
    SET @IsValid = 1
  RETURN @IsValid
END
GO





