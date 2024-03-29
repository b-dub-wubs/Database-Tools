/*┌─────────────────────────────────────────────────────────────────────────────────────────────┐*\
  │ TITLE: Table DDL                                                                            │
  │   AdventureWorks_0006.ref.GeoRegion
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
           WHERE object_id = OBJECT_ID(N'ref.GeoRegion')
                 AND type IN (N'U'))
    DROP TABLE 
      ref.GeoRegion
GO

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

IF NOT EXISTS (SELECT *
               FROM sys.objects
               WHERE object_id = OBJECT_ID(N'ref.GeoRegion')
                     AND type IN (N'U'))
  BEGIN
    CREATE TABLE
      ref.GeoRegion
        (
            GeoRegionID   TINYINT       NOT NULL
                          IDENTITY(1,1)
                          CONSTRAINT 
                            PK_ref_GeoRegion
                          PRIMARY KEY CLUSTERED
          , GeoRegionName VARCHAR(16)   NOT NULL
                          CONSTRAINT
                            UK_ref_GeoRegion_GeoRegionName
                          UNIQUE
          , GeoRegionDesc VARCHAR(512)  NULL
        )
  END
GO




/*┌─────────────────────────────────────────────────────────────────────────────────────────────┐*\
  │ Populate From Old Table                                                                     │
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤

    INSERT
      ref.GeoRegion
        (
            GeoRegionName
        )
    SELECT DISTINCT
        [region]
    FROM
      [AdventureWorks_0002].[OM].[state_to_region_xmap]
    ORDER BY
      1


SET IDENTITY_INSERT ref.GeoRegion ON

    INSERT
      ref.GeoRegion
        (
            GeoRegionID
          , GeoRegionName
        )
    VALUES
        (0, 'ALL')
      , (254, 'UNKNOWN')
      , (253, 'OTHER')
      , (252, 'NONE')

SET IDENTITY_INSERT ref.GeoRegion OFF

Division	MajorGroup	IndustryGroup	SIC	SIC_Desc
!	252	-3	-3	NONE
#	253	-2	-2	OTHER
?	254	-1	-1	UNKNOWN
*	0	0	0	ALL



    SELECT
        MAX(LEN([state_full_name]))
      , MAX(LEN([region]))

      --, [state_abbrev]
      --, [region]
    FROM
      [AdventureWorks_0002].[OM].[state_to_region_xmap]

\*└─────────────────────────────────────────────────────────────────────────────────────────────┘*/





