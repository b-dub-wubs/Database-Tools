/*┌─────────────────────────────────────────────────────────────────────────────────────────────┐*\
  │ TITLE: User Defined Function DDL                                                            │
  │   AdventureWorks_0006.config.udf_CheckRowValid_BusinessAgeSegment_Range
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

      SELECT TestResult = config.udf_CheckRowValid_BusinessAgeSegment_Range('Test_Param')

\*└─────────────────────────────────────────────────────────────────────────────────────────────┘*/
USE AdventureWorks_0006
GO

IF  EXISTS (SELECT * 
            FROM sys.objects 
            WHERE [object_id] = OBJECT_ID(N'config.udf_CheckRowValid_BusinessAgeSegment_Range')
            AND [type_desc] LIKE 'SQL%FUNCTION')
	DROP FUNCTION 
    config.udf_CheckRowValid_BusinessAgeSegment_Range
GO

CREATE FUNCTION 
  config.udf_CheckRowValid_BusinessAgeSegment_Range
    (
        @MailingOrgID         TINYINT
      , @MinAge               TINYINT 
      , @MaxAge               TINYINT
      , @BusinessAgeSegmentID SMALLINT
    )
RETURNS
  BIT
AS
BEGIN

  DECLARE 
      @IsValid  BIT = 1

  IF @BusinessAgeSegmentID > 0 -- Special Values are always valid
    BEGIN
      /*┌────────────────────────────────────────────────────────────────────┐*.
          Unbounded range case: No other valid segments for this org
      \*└────────────────────────────────────────────────────────────────────┘*/
      IF @MinAge IS NULL AND @MaxAge IS NULL
        IF EXISTS(  SELECT  
                      1 
                    FROM
                      config.BusinessAgeSegment 
                    WHERE 
                          ValidTo IS NULL
                      AND MailingOrgID = @MailingOrgID
                      AND BusinessAgeSegmentID > 0
                  )
          SET @IsValid = 0

      /*┌────────────────────────────────────────────────────────────────────┐*.
          Max age bounded only: No overlapping segments for this org
      \*└────────────────────────────────────────────────────────────────────┘*/
      ELSE IF  @MinAge IS NULL AND @MaxAge IS NOT NULL
        IF EXISTS(  SELECT  
                      1 
                    FROM
                      config.BusinessAgeSegment 
                    WHERE 
                          ValidTo IS NULL
                      AND 
                        (
                              MinAge <= @MaxAge
                          OR  MaxAge <= @MaxAge
                        )
                      AND MailingOrgID = @MailingOrgID
                      AND BusinessAgeSegmentID > 0
                  )
          SET @IsValid = 0

      /*┌────────────────────────────────────────────────────────────────────┐*.
          Min age bounded only: No overlapping segments for this org
      \*└────────────────────────────────────────────────────────────────────┘*/
      ELSE IF  @MinAge IS NOT NULL AND @MaxAge IS NULL
        IF EXISTS(  SELECT  
                      1 
                    FROM
                      config.BusinessAgeSegment 
                    WHERE 
                          ValidTo IS NULL
                      AND 
                        (
                              MinAge >= @MinAge
                          OR  MaxAge >= @MinAge
                        )
                      AND MailingOrgID = @MailingOrgID
                      AND BusinessAgeSegmentID > 0
                  )
          SET @IsValid = 0

      /*┌────────────────────────────────────────────────────────────────────┐*.
          min & max age bounded case: No overlapping segments for this org
      \*└────────────────────────────────────────────────────────────────────┘*/
      ELSE
        IF EXISTS(  SELECT  
                      1 
                    FROM
                      config.BusinessAgeSegment 
                    WHERE 
                          ValidTo IS NULL
                      AND
                        (
                              MinAge >= @MinAge
                          OR  MaxAge <= @MaxAge
                        )
                      AND MailingOrgID = @MailingOrgID
                      AND BusinessAgeSegmentID > 0
                  )
            OR @MinAge > @MaxAge
          SET @IsValid = 0
    END

  RETURN @IsValid
  
END
GO



