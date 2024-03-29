/*┌─────────────────────────────────────────────────────────────────────────────────────────────┐*\
  │ TITLE: Table DDL                                                                            │
  │   AdventureWorks_0006.imp.MenuUniverseExtract_T0_IFG_Unmatched
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤
  │ DESCRIPTION:                                                                                │
  │   InfoGroup Matched Template                                                                │
  │                                                                                             │
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤
  │ REVISION HISTORY:                                                                           │
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤
  │   DATE       AUTHOR          CHANGE DESCRIPTION                                             │
  │   ────────── ─────────────── ───────────────────────────────────────────────────────────────┤
      2018.10.18 bwarner         Initial Draft
\*└─────────────────────────────────────────────────────────────────────────────────────────────┘*/
USE AdventureWorks_0006
GO

IF EXISTS (SELECT *
           FROM sys.objects
           WHERE object_id = OBJECT_ID(N'imp.MenuUniverseExtract_T0_IFG_Unmatched')
                 AND type IN (N'U'))
    DROP TABLE 
      imp.MenuUniverseExtract_T0_IFG_Unmatched
GO

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

IF NOT EXISTS (SELECT *
               FROM sys.objects
               WHERE object_id = OBJECT_ID(N'imp.MenuUniverseExtract_T0_IFG_Unmatched')
                     AND type IN (N'U'))
  BEGIN
    CREATE TABLE 
      imp.MenuUniverseExtract_T0_IFG_Unmatched
        (
            MonthCount               TINYINT NOT NULL
          , [FIRST NAME OF DEBTOR]   VARCHAR(64) NULL
          , [MIDDLE NAME OF DEBTOR]  VARCHAR(64) NULL
          , [LAST NAME OF DEBTOR]    VARCHAR(64) NULL
          , [LAST NAME SUFFIX]       VARCHAR(3) NULL
          , [DEBTOR NAME]            VARCHAR(64) NULL
          , [DEBTOR ADDRESS]         VARCHAR(64) NULL
          , [DEBTOR CITY]            VARCHAR(64) NULL
          , [DEBTOR STATE]           CHAR(2) NULL
          , [DEBTOR ZIP]             INT NULL
          , [DEBTOR ZIP4]            SMALLINT NULL
          , [DCEBTOR CRCODE]         CHAR(4) NULL
          , [DEBTOR STATECD]         TINYINT NULL
          , [DEBTOR COUNTY CODE]     SMALLINT NULL
          , [DEBTOR COUNTY]          VARCHAR(32) NULL
          , [COLLATERAL TYPE]        CHAR(2) NULL
          , [COLLATERAL TYPE DESC]   VARCHAR(32) NULL
          , [CORP OR IND]            CHAR(1) NULL
          , [DAY ADDED TO UCC DB]    TINYINT NULL
          , [MONTH ADDED TO UCC DB]  TINYINT NULL
          , [YEAR ADDED TO UCC DB]   SMALLINT NULL
          , [RECEIVED DAY]           TINYINT NULL
          , [RECEIVED MONTH]         TINYINT NULL
          , [RECEIVED YEAR]          SMALLINT NULL
          , [DELIVERABILITY SCORE]   CHAR(2) NULL
          , [DELIVERY POINT BARCODE] SMALLINT NULL
          , [EXP DAY]                TINYINT NULL
          , [EXP MONTH]              TINYINT NULL
          , [EXP YEAR]               TINYINT NULL
          , [FILING DAY]             TINYINT NULL
          , [FILING MONTH]           TINYINT NULL
          , [FILING YEAR]            SMALLINT NULL
          , [FILING STATE]           CHAR(2) NULL
          --, [FILING STATUS]          VARCHAR(50) NULL
          , [FILING STATUS DESC]     CHAR(8) NULL
          , [FILING TYPE CODE]       CHAR(2) NULL
          , [FILING TYPE DESC]       VARCHAR(16) NULL
          , [ORIGINAL FILING ID]     VARCHAR(32) NULL
          , [PARTY TYPE CODE]        CHAR(1) NULL
          , [SOURCE FILING ID]       VARCHAR(32) NULL
          , [SEC PARTY NAME]         VARCHAR(64) NULL
          , [SECURED PARTY ADDRESS]  VARCHAR(64) NULL
          , [SECURED PARTY CITY]     VARCHAR(64) NULL
          , [SECURED PARTY STATE]    CHAR(2) NULL
          , [SECURED PARTY ZIP]      INT NULL
          , [SECURED PARTY ZIP4]     SMALLINT NULL
          , [Key Code 1]             VARCHAR(32) NULL
          , InfoId                   BIGINT NULL
          --, startDate                DATE NULL
          --, endDate                  DATE NULL
        )
  END
GO

/*
        , [FIRST NAME OF DEBTOR]    VARCHAR(64) NULL
        , [MIDDLE NAME OF DEBTOR]   VARCHAR(64) NULL
        , [LAST NAME OF DEBTOR]     VARCHAR(64) NULL
        , [LAST NAME SUFFIX]        VARCHAR(3) NULL
        , [DEBTOR NAME]             VARCHAR(64) NULL
        , [DEBTOR ADDRESS]          VARCHAR(64) NULL
        , [DEBTOR CITY]             VARCHAR(64) NULL
        , [DEBTOR STATE]            VARCHAR(2) NULL
        , [DEBTOR ZIP]              INT NULL
        , [DEBTOR ZIP4]             SMALLINT NULL
        , [DCEBTOR CRCODE]          VARCHAR(4) NULL
        , [DEBTOR STATECD]          TINYINT NULL
        , [DEBTOR COUNTY CODE]      SMALLINT NULL
        , [DEBTOR COUNTY]           VARCHAR(32) NULL
        , [COLLATERAL TYPE]         VARCHAR(2) NULL
        , [COLLATERAL TYPE DESC]    VARCHAR(32) NULL
        , [CORP OR IND]             VARCHAR(1) NULL
        , [DAY ADDED TO UCC DB]     TINYINT NULL
        , [MONTH ADDED TO UCC DB]   TINYINT NULL
        , [YEAR ADDED TO UCC DB]    SMALLINT NULL
        , [RECEIVED DAY]            TINYINT NULL
        , [RECEIVED MONTH]          TINYINT NULL
        , [RECEIVED YEAR]           SMALLINT NULL
        , [DELIVERABILITY SCORE]    VARCHAR(2) NULL
        , [DELIVERY POINT BARCODE]  SMALLINT NULL
        , [EXP DAY]                 TINYINT NULL
        , [EXP MONTH]               TINYINT NULL
        , [EXP YEAR]                TINYINT NULL
        , [FILING DAY]              TINYINT NULL
        , [FILING MONTH]            TINYINT NULL
        , [FILING YEAR]             SMALLINT NULL
        , [FILING STATE]            VARCHAR(2) NULL
        --, [FILING STATUS]           VARCHAR(50) NULL
        , [FILING STATUS DESC]      VARCHAR(8) NULL
        , [FILING TYPE CODE]        VARCHAR(2) NULL
        , [FILING TYPE DESC]        VARCHAR(16) NULL
        , [ORIGINAL FILING ID]      VARCHAR(32) NULL
        , [PARTY TYPE CODE]         VARCHAR(1) NULL
        , [SOURCE FILING ID]        VARCHAR(32) NULL
        , [SEC PARTY NAME]          VARCHAR(64) NULL
        , [SECURED PARTY ADDRESS]   VARCHAR(64) NULL
        , [SECURED PARTY CITY]      VARCHAR(64) NULL
        , [SECURED PARTY STATE]     VARCHAR(2) NULL
        , [SECURED PARTY ZIP]       INT NULL
        , [SECURED PARTY ZIP4]      SMALLINT NULL
        , [Key Code 1]              VARCHAR(15) NULL
        , InfoId                    INT NULL
        --, startDate                 DATE NOT NULL
        --, endDate                   DATE NOT NULL




        , [FIRST NAME OF DEBTOR]    VARCHAR(64) NOT NULL[dbo].[Lattice_NovemberScoring_PL SIC Target Retail & Services_FOX_*not scored*]
          , [MIDDLE NAME OF DEBTOR]   VARCHAR(64) NOT NULL
          , [LAST NAME OF DEBTOR]     VARCHAR(64) NOT NULL
          , [LAST NAME SUFFIX]        VARCHAR(3) NOT NULL
          , [DEBTOR NAME]             VARCHAR(64) NOT NULL
          , [DEBTOR ADDRESS]          VARCHAR(64) NOT NULL
          , [DEBTOR CITY]             VARCHAR(64) NOT NULL
          , [DEBTOR STATE]            VARCHAR(2) NOT NULL
          , [DEBTOR ZIP]              VARCHAR(5) NOT NULL
          , [DEBTOR ZIP4]             VARCHAR(4) NOT NULL
          , [DCEBTOR CRCODE]          VARCHAR(4) NOT NULL
          , [DEBTOR STATECD]          VARCHAR(2) NOT NULL
          , [DEBTOR COUNTY CODE]      VARCHAR(3) NOT NULL
          , [DEBTOR COUNTY]           VARCHAR(14) NOT NULL
          , [COLLATERAL TYPE]         VARCHAR(2) NOT NULL
          , [COLLATERAL TYPE DESC]    VARCHAR(32) NOT NULL
          , [CORP OR IND]             VARCHAR(1) NOT NULL
          , [DAY ADDED TO UCC DB]     VARCHAR(2) NOT NULL
          , [MONTH ADDED TO UCC DB]   VARCHAR(2) NOT NULL
          , [YEAR ADDED TO UCC DB]    VARCHAR(4) NOT NULL
          , [RECEIVED DAY]            VARCHAR(2) NOT NULL
          , [RECEIVED MONTH]          VARCHAR(2) NOT NULL
          , [RECEIVED YEAR]           VARCHAR(4) NOT NULL
          , [DELIVERABILITY SCORE]    VARCHAR(2) NOT NULL
          , [DELIVERY POINT BARCODE]  VARCHAR(3) NOT NULL
          , [EXP DAY]                 VARCHAR(2) NOT NULL
          , [EXP MONTH]               VARCHAR(2) NOT NULL
          , [EXP YEAR]                VARCHAR(4) NOT NULL
          , [FILING DAY]              VARCHAR(2) NOT NULL
          , [FILING MONTH]            VARCHAR(2) NOT NULL
          , [FILING YEAR]             VARCHAR(4) NOT NULL
          , [FILING STATE]            VARCHAR(2) NOT NULL
          --, [FILING STATUS]           VARCHAR(50) NULL
          , [FILING STATUS DESC]      VARCHAR(7) NOT NULL
          , [FILING TYPE CODE]        VARCHAR(2) NOT NULL
          , [FILING TYPE DESC]        VARCHAR(12) NOT NULL
          , [ORIGINAL FILING ID]      VARCHAR(32) NOT NULL
          , [PARTY TYPE CODE]         VARCHAR(1) NOT NULL
          , [SOURCE FILING ID]        VARCHAR(32) NOT NULL
          , [SEC PARTY NAME]          VARCHAR(64) NOT NULL
          , [SECURED PARTY ADDRESS]   VARCHAR(64) NOT NULL
          , [SECURED PARTY CITY]      VARCHAR(64) NOT NULL
          , [SECURED PARTY STATE]     VARCHAR(2) NOT NULL
          , [SECURED PARTY ZIP]       VARCHAR(5) NOT NULL
          , [SECURED PARTY ZIP4]      VARCHAR(4) NOT NULL
          , [Key Code 1]              VARCHAR(15) NOT NULL
          , InfoId                    BIGINT NOT NULL


          , [FIRST NAME OF DEBTOR]    VARCHAR(255) NULL
          , [MIDDLE NAME OF DEBTOR]   VARCHAR(255) NULL
          , [LAST NAME OF DEBTOR]     VARCHAR(255) NULL
          , [LAST NAME SUFFIX]        VARCHAR(255) NULL
          , [DEBTOR NAME]             VARCHAR(255) NULL
          , [DEBTOR ADDRESS]          VARCHAR(255) NULL
          , [DEBTOR CITY]             VARCHAR(255) NULL
          , [DEBTOR STATE]            VARCHAR(255) NULL
          , [DEBTOR ZIP]              VARCHAR(255) NULL
          , [DEBTOR ZIP4]             VARCHAR(255) NULL
          , [DCEBTOR CRCODE]          VARCHAR(255) NULL
          , [DEBTOR STATECD]          VARCHAR(255) NULL
          , [DEBTOR COUNTY CODE]      VARCHAR(255) NULL
          , [DEBTOR COUNTY]           VARCHAR(255) NULL
          , [COLLATERAL TYPE]         VARCHAR(255) NULL
          , [COLLATERAL TYPE DESC]    VARCHAR(255) NULL
          , [CORP OR IND]             VARCHAR(255) NULL
          , [DAY ADDED TO UCC DB]     VARCHAR(255) NULL
          , [MONTH ADDED TO UCC DB]   VARCHAR(255) NULL
          , [YEAR ADDED TO UCC DB]    VARCHAR(255) NULL
          , [RECEIVED DAY]            VARCHAR(255) NULL
          , [RECEIVED MONTH]          VARCHAR(255) NULL
          , [RECEIVED YEAR]           VARCHAR(255) NULL
          , [DELIVERABILITY SCORE]    VARCHAR(255) NULL
          , [DELIVERY POINT BARCODE]  VARCHAR(255) NULL
          , [EXP DAY]                 VARCHAR(255) NULL
          , [EXP MONTH]               VARCHAR(255) NULL
          , [EXP YEAR]                VARCHAR(255) NULL
          , [FILING DAY]              VARCHAR(255) NULL
          , [FILING MONTH]            VARCHAR(255) NULL
          , [FILING YEAR]             VARCHAR(255) NULL
          , [FILING STATE]            VARCHAR(255) NULL
          , [FILING STATUS]           VARCHAR(255) NULL
          , [FILING STATUS DESC]      VARCHAR(255) NULL
          , [FILING TYPE CODE]        VARCHAR(255) NULL
          , [FILING TYPE DESC]        VARCHAR(255) NULL
          , [ORIGINAL FILING ID]      VARCHAR(255) NULL
          , [PARTY TYPE CODE]         VARCHAR(255) NULL
          , [SOURCE FILING ID]        VARCHAR(255) NULL
          , [SEC PARTY NAME]          VARCHAR(255) NULL
          , [SECURED PARTY ADDRESS]   VARCHAR(255) NULL
          , [SECURED PARTY CITY]      VARCHAR(255) NULL
          , [SECURED PARTY STATE]     VARCHAR(255) NULL
          , [SECURED PARTY ZIP]       VARCHAR(255) NULL
          , [SECURED PARTY ZIP4]      VARCHAR(255) NULL
          , [Key Code 1]              VARCHAR(255) NULL
          , InfoId                    BIGINT NULL
          , startDate                        [DATE] NULL
          , endDate                          [DATE] NULL
*/



