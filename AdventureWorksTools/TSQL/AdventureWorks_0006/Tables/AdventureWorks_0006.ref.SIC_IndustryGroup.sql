/*┌─────────────────────────────────────────────────────────────────────────────────────────────┐*\
  │ TITLE: Table DDL                                                                            │
  │   AdventureWorks_0006.ref.SIC_IndustryGroup
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤
  │ DESCRIPTION:                                                                                │
  │                                                                                             │
  │                                                                                             │
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤
  │ REVISION HISTORY:                                                                           │
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤
  │   DATE       AUTHOR          CHANGE DESCRIPTION                                             │
  │   ────────── ─────────────── ───────────────────────────────────────────────────────────────┤
      2018.12.19 bwarner         Initial Draft
\*└─────────────────────────────────────────────────────────────────────────────────────────────┘*/
USE AdventureWorks_0006
GO

IF EXISTS (SELECT *
           FROM sys.objects
           WHERE object_id = OBJECT_ID(N'ref.SIC_IndustryGroup')
                 AND type IN (N'U'))
    DROP TABLE 
      ref.SIC_IndustryGroup
GO

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

IF NOT EXISTS (SELECT *
               FROM sys.objects
               WHERE object_id = OBJECT_ID(N'ref.SIC_IndustryGroup')
                     AND type IN (N'U'))
  BEGIN
    CREATE TABLE
      ref.SIC_IndustryGroup
        (
            Division          CHAR(1) NOT NULL
                              CONSTRAINT
                                FK_ref_SIC_IndustryGroup_Division
                              FOREIGN KEY REFERENCES
                                ref.SIC_Division(Division)
          , MajorGroup        TINYINT NOT NULL
                              CONSTRAINT
                                FK_ref_SIC_IndustryGroup_MajorGroup
                              FOREIGN KEY REFERENCES
                                ref.SIC_MajorGroup(MajorGroup)
          , IndustryGroup     SMALLINT NOT NULL
                              CONSTRAINT 
                                PK_ref_SIC_IndustryGroup
                              PRIMARY KEY CLUSTERED
          , IndustryGroupDesc NVARCHAR(128) NOT NULL
                              CONSTRAINT 
                                UK_ref_SIC_IndustryGroup_IndustryGroupDesc
                              UNIQUE
        )
  END
GO


/*┌─────────────────────────────────────────────────────────────────────────────────────────────┐*\
  │ BULK LOAD CSV (only works with v 2k17)                                                      │
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤

    BULK INSERT
      ref.SIC_IndustryGroup
    FROM
      '\\SDW-BITOOLS-P01\FlatFileExtractImport\ReferenceData\sic4-list\industry-groups.csv'
    WITH 
      ( 
          FIELDTERMINATOR = ','
        , ROWTERMINATOR   = '\n'
        , FIRSTROW        = 2
        , FIELDQUOTE      = '"'
      )

    SELECT * FROM ref.SIC_IndustryGroup

  ├─────────────────────────────────────────────────────────────────────────────────────────────┤
  │ Load from manual import temp table I set up                                                 │
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤

    INSERT
      ref.SIC_IndustryGroup
        (
            Division
          , MajorGroup
          , IndustryGroup
          , IndustryGroupDesc
        )
    SELECT
        Division
      , Major_Group
      , Industry_Group
      , Description
    FROM
      dbo.SIC_IndustryGroups

  ├─────────────────────────────────────────────────────────────────────────────────────────────┤
  │ Load special values                                                                         │
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤

    INSERT
      ref.SIC_IndustryGroup
        (
            Division
          , MajorGroup
          , IndustryGroup
          , IndustryGroupDesc
        )
    VALUES
        ('*',   0,  0, 'ALL')
      , ('?', 254, -1, 'UNKNOWN')
      , ('#', 253, -2, 'OTHER')
      , ('!', 252, -3, 'NONE')

\*└─────────────────────────────────────────────────────────────────────────────────────────────┘*/






