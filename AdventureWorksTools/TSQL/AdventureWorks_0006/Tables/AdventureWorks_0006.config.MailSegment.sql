/*┌─────────────────────────────────────────────────────────────────────────────────────────────┐*\
  │ TITLE: Table DDL                                                                            │
  │   AdventureWorks_0006.config.MailSegment
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤
  │ DESCRIPTION:                                                                                │
  │                                                                                             │
  │                                                                                             │
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤
  │ REVISION HISTORY:                                                                           │
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤
  │   DATE       AUTHOR          CHANGE DESCRIPTION                                             │
  │   ────────── ─────────────── ───────────────────────────────────────────────────────────────┤
      2018.12.21 bwarner         Initial Draft
\*└─────────────────────────────────────────────────────────────────────────────────────────────┘*/
USE AdventureWorks_0006
GO

IF EXISTS (SELECT *
           FROM sys.objects
           WHERE object_id = OBJECT_ID(N'config.MailSegment')
                 AND type IN (N'U'))
    DROP TABLE 
      config.MailSegment
GO

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

IF NOT EXISTS (SELECT *
               FROM sys.objects
               WHERE object_id = OBJECT_ID(N'config.MailSegment')
                     AND type IN (N'U'))
  BEGIN
    CREATE TABLE
      config.MailSegment
        (
            MailSegmentID   SMALLINT NOT NULL
                            IDENTITY(1,1)
                            CONSTRAINT 
                              PK_config_MailSegment
                            PRIMARY KEY CLUSTERED
          , MailingOrgID    TINYINT       NOT NULL
                            CONSTRAINT
                              FK_config_MailSegment_MailingOrg
                            FOREIGN KEY REFERENCES
                              dbo.MailingOrg(MailingOrgID)
                            ON DELETE CASCADE
          , MailSegmentName VARCHAR(128)   NOT NULL
          , ValidFrom       DATETIME2      NOT NULL
                            CONSTRAINT
                              DF_config_MailSegment_ValidFrom
                            DEFAULT
                              GETDATE()
          , ValidTo         DATETIME2       NULL
          , IsCurrent       AS CAST(CASE WHEN ValidTo IS NULL AND ValidFrom < GETDATE() THEN 1 ELSE 0 END AS BIT)
          , CreatedDate       DATETIME        NOT NULL
                              CONSTRAINT
                                DF_config_MailSegment_CreatedDate
                              DEFAULT 
                                GETDATE()
          , CreatedBy         SYSNAME         NOT NULL
                              CONSTRAINT
                                DF_config_MailSegment_CreatedBy
                              DEFAULT 
                                SUSER_NAME()
          , ModifiedDate      DATETIME        NOT NULL
                              CONSTRAINT
                                DF_config_MailSegment_ModifiedDate
                              DEFAULT 
                                GETDATE()
          , ModifiedBy        SYSNAME         NOT NULL
                              CONSTRAINT
                                DF_config_MailSegment_ModifiedBy
                              DEFAULT 
                                SUSER_NAME()
          , CONSTRAINT
              UN_config_MailSegment_BisKey
            UNIQUE
              (
                  MailingOrgID    ASC
                , MailSegmentName ASC
                , ValidTo
              )
          , CONSTRAINT 
              CHK_config_MailSegment_ValidDateRange_Expire
            CHECK 
              (
                    ValidTo IS NULL
                OR  ValidTo > ValidFrom
              )
        )
  END
GO




/*┌─────────────────────────────────────────────────────────────────────────────────────────────┐*\
  │ Populate From Old Table                                                                     │
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤

    DECLARE 
        @MailingOrgID TINYINT
      , @TheBeginningOfDATETIME2  DATETIME2 = '0001-01-01 00:00:00'
      , @TheEndOfDATETIME2        DATETIME2 = '9999-12-31 23:59:59.9999999'

    SELECT
      @MailingOrgID = MailingOrgID
    FROM
      dbo.MailingOrg
    WHERE
      MailingOrgName = 'National Funding'

    INSERT
      config.MailSegment
        (
            MailingOrgID
          , MailSegmentName
          , ValidFrom
        )
    VALUES
        (
            @MailingOrgID
          , 'Growth'
          , @TheBeginningOfDATETIME2
        )
      , (
            @MailingOrgID
          , 'Unknown Growth'
          , @TheBeginningOfDATETIME2
        )
      , (
            @MailingOrgID
          , 'Mainstream'
          , @TheBeginningOfDATETIME2
        )
      , (
            @MailingOrgID
          , 'Vintage'
          , @TheBeginningOfDATETIME2
        )


    SET IDENTITY_INSERT config.MailSegment ON

    DECLARE 
        @MailingOrgID TINYINT
      , @TheBeginningOfDATETIME2  DATETIME2 = '0001-01-01 00:00:00'
      , @TheEndOfDATETIME2        DATETIME2 = '9999-12-31 23:59:59.9999999'

    SELECT
      @MailingOrgID = MailingOrgID
    FROM
      dbo.MailingOrg
    WHERE
      MailingOrgName = 'National Funding'


    INSERT
      config.MailSegment
        (
            MailingOrgID
          , MailSegmentName
          , ValidFrom
          , MailSegmentID
        )
    VALUES
        (
            @MailingOrgID
          , 'Other'
          , @TheBeginningOfDATETIME2
          , -2
        )

    SET IDENTITY_INSERT config.MailSegment OFF




    SELECT * FROM config.MailSegment

  ├─────────────────────────────────────────────────────────────────────────────────────────────┤

    SELECT DISTINCT
      MailSegmentName = '''' + RTRIM(REPLACE(REPLACE([Segments], LTRIM(STR([Empl_Segment])) + ' ' + LTRIM(STR([Has_Paydex_Flag])) + ' ' + [Region], ''), 'Unk 1 1 North', 'Unk')) + ''''
    FROM
      [AdventureWorks_0002].[OM].[list_segmentation_n1]
    WHERE
      RTRIM(REPLACE(REPLACE([Segments], LTRIM(STR([Empl_Segment])) + ' ' + LTRIM(STR([Has_Paydex_Flag])) + ' ' + [Region], ''), 'Unk 1 1 North', 'Unk'))
      NOT IN('Other','Unk')

'Growth'
'Mainstream I'
'Mainstream II'
'Millenial'
'Vintage'

\*└─────────────────────────────────────────────────────────────────────────────────────────────┘*/





