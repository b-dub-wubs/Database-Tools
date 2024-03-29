/*┌─────────────────────────────────────────────────────────────────────────────────────────────┐*\
  │ TITLE: User Defined Function DDL                                                            │
  │   AdventureWorks_0006.config.udf_CheckRowValid_EmployeeSizeSegment_Range
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤
  │ DESCRIPTION:                                                                                │
      
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤
  │ REVISION HISTORY:                                                                           │
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤
  │   DATE       AUTHOR          CHANGE DESCRIPTION                                             │
  │   ────────── ─────────────── ────────────────────────────────────────────────────────────── │
      2018.12.26 bwarner         Initial Draft
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤
  │ UNIT TESTING SCRIPTS:                                                                       │

      SELECT TestResult = config.udf_CheckRowValid_EmployeeSizeSegment_Range('Test_Param')

\*└─────────────────────────────────────────────────────────────────────────────────────────────┘*/
USE AdventureWorks_0006
GO

IF  EXISTS (SELECT * 
            FROM sys.objects 
            WHERE [object_id] = OBJECT_ID(N'config.udf_CheckRowValid_EmployeeSizeSegment_Range')
            AND [type_desc] LIKE 'SQL%FUNCTION')
	DROP FUNCTION 
    config.udf_CheckRowValid_EmployeeSizeSegment_Range
GO

CREATE FUNCTION 
  config.udf_CheckRowValid_EmployeeSizeSegment_Range
    (
        @MailingOrgID           TINYINT
      , @MinEmpSize             INT 
      , @MaxEmpSize             INT
      , @EmployeeSizeSegmentID  SMALLINT
    )
RETURNS
  BIT
AS
BEGIN

  DECLARE 
      @IsValid  BIT = 1

  IF @EmployeeSizeSegmentID > 0 -- Special Values are always valid
    BEGIN
      /*┌────────────────────────────────────────────────────────────────────┐*.
          Unbounded range case: No other valid segments for this org
      \*└────────────────────────────────────────────────────────────────────┘*/
      IF @MinEmpSize IS NULL AND @MaxEmpSize IS NULL
        IF EXISTS(  SELECT  
                      1 
                    FROM
                      config.EmployeeSizeSegment 
                    WHERE 
                          ValidTo IS NULL
                      AND MailingOrgID = @MailingOrgID
                      AND EmployeeSizeSegmentID > 0
                  )
          SET @IsValid = 0

      /*┌────────────────────────────────────────────────────────────────────┐*.
          Max employee size bounded only: No overlapping segments for this org
      \*└────────────────────────────────────────────────────────────────────┘*/
      ELSE IF  @MinEmpSize IS NULL AND @MaxEmpSize IS NOT NULL
        IF EXISTS(  SELECT  
                      1 
                    FROM
                      config.EmployeeSizeSegment 
                    WHERE 
                          ValidTo IS NULL
                      AND 
                        (
                              MinEmpSize <= @MaxEmpSize
                          OR  MaxEmpSize <= @MaxEmpSize
                        )
                      AND MailingOrgID = @MailingOrgID
                      AND EmployeeSizeSegmentID > 0
                  )
          SET @IsValid = 0

      /*┌────────────────────────────────────────────────────────────────────┐*.
          Min employee size bounded only: No overlapping segments for this org
      \*└────────────────────────────────────────────────────────────────────┘*/
      ELSE IF  @MinEmpSize IS NOT NULL AND @MaxEmpSize IS NULL
        IF EXISTS(  SELECT  
                      1 
                    FROM
                      config.EmployeeSizeSegment 
                    WHERE 
                          ValidTo IS NULL
                      AND 
                        (
                              MinEmpSize >= @MinEmpSize
                          OR  MaxEmpSize >= @MinEmpSize
                        )
                      AND MailingOrgID = @MailingOrgID
                      AND EmployeeSizeSegmentID > 0
                  )
          SET @IsValid = 0

      /*┌────────────────────────────────────────────────────────────────────┐*.
          min & max employee size bounded case: No overlapping segments for this org
      \*└────────────────────────────────────────────────────────────────────┘*/
      ELSE
        IF EXISTS(  SELECT  
                      1 
                    FROM
                      config.EmployeeSizeSegment 
                    WHERE 
                          ValidTo IS NULL
                      AND
                        (
                              MinEmpSize >= @MinEmpSize
                          OR  MaxEmpSize <= @MaxEmpSize
                        )
                      AND MailingOrgID = @MailingOrgID
                      AND EmployeeSizeSegmentID > 0
                  )
            OR @MinEmpSize > @MaxEmpSize
          SET @IsValid = 0
    END

  RETURN @IsValid
  
END
GO



