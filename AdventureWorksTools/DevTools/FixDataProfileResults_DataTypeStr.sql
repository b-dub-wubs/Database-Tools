/*┌─────────────────────────────────────────────────────────────────────────────────────────────┐*\
  │ TITLE:                                                                                      │
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤
  │ DESCRIPTION:                                                                                │

  ├─────────────────────────────────────────────────────────────────────────────────────────────┤
  │ REVISION HISTORY:                                                                           │
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤
  │   DATE       AUTHOR          CHANGE DESCRIPTION                                             │
  │   ────────── ─────────────── ────────────────────────────────────────────────────────────── │
      YYYY.MM.DD _AUTHOR_        Initial Draft
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤
  │ UNIT TESTING SCRIPTS:                                                                       │

\*└─────────────────────────────────────────────────────────────────────────────────────────────┘*/



USE AdventureWorks_0007
GO


;WITH
     base_set AS
      (
        SELECT 
            dpr.[TableName]
          --, dpr.[OrdinalPos]
          , dpr.[ColName]
          , dpr.[MaxLen]
          , dpr.[MinLen]
          , MaxVal = REPLACE(dpr.[MaxVal],',',' ')
          , MinVal = REPLACE(dpr.[MinVal],',',' ')
          , dpr.[DistinctValCnt]
          , dpr.[IsNumeric]
          , dpr.[IsInteger]
          , dpr.[IntegerRowCnt]
          , dpr.[NumericRowCnt]
          , dpr.[BlankOrNullCount]
          , dpr.[BlankOrNullPct]
          , dpr.[UnicodeCnt]
          , dpr.[UnicodePct]
        FROM
          data_prof.DataProfileRpt_00 dpr
      )
    , SmallestSquareLen_OrdPos_Calc AS
        (
          SELECT
              OrdinalPos                    = isc.ORDINAL_POSITION
            , SmallestSquareLen             = CASE                                                
                                                WHEN MaxLen < 16
                                                  THEN LTRIM(RTRIM(STR(MaxLen)))
                                                WHEN MaxLen < 24
                                                  THEN '32'
                                                WHEN MaxLen < 48
                                                  THEN '64'
                                                WHEN MaxLen < 96
                                                  THEN '128'
                                                WHEN MaxLen < 192
                                                  THEN '256'
                                                WHEN MaxLen < 384
                                                  THEN '512'
                                                WHEN MaxLen < 768
                                                  THEN '1024'
                                                WHEN MaxLen < 1536
                                                  THEN '2048'
                                                WHEN MaxLen < 1536
                                                  THEN '2048'
                                                WHEN MaxLen < 3072
                                                  THEN '4096'
                                                WHEN MaxLen < 6144
                                                  THEN '8192'
                                                WHEN MaxLen IS NULL
                                                  THEN NULL
                                                ELSE 'MAX'
                                              END
            , [DATA_TYPE]                   = UPPER(isc.[DATA_TYPE])
            , isc.[CHARACTER_MAXIMUM_LENGTH]
            , isc.[IS_NULLABLE]
            , isc.[NUMERIC_PRECISION]
            , isc.[NUMERIC_SCALE]
            , isc.[DATETIME_PRECISION]
            , piv.*            
          FROM
            base_set piv            
            LEFT JOIN AdventureWorks_0007.INFORMATION_SCHEMA.COLUMNS isc            
              ON piv.ColName = isc.COLUMN_NAME
              AND piv.TableName = isc.TABLE_NAME    
        )
    , CharTypeDefStr_Calc AS
        (
          SELECT
              calc.*
            , CharTypeDefStr  = CASE
                                  WHEN 
                                    IsInteger = 'Yes' 
                                    OR 
                                      (
                                            ISNUMERIC(CAST(MaxVal AS NVARCHAR(MAX)) + '.0e0') = 1
                                        AND ISNUMERIC(CAST(MinVal AS NVARCHAR(MAX)) + '.0e0') = 1
                                      )
                                    THEN
                                      CASE
                                        WHEN CAST(ISNULL(MinVal,0) AS BIGINT) >= 0 AND CAST(ISNULL(MaxVal,0) AS BIGINT) < 204 
                                          THEN 'TINYINT'
                                        WHEN CAST(ISNULL(MinVal,0) AS BIGINT) >= -32768 AND CAST(ISNULL(MaxVal,0) AS BIGINT) < 26213
                                          THEN 'SMALLINT'
                                        WHEN CAST(ISNULL(MinVal,0) AS BIGINT) >= -2147483648 AND CAST(ISNULL(MaxVal,0) AS BIGINT) < 1717986917
                                          THEN 'INT'
                                        ELSE 'BIGINT'
                                      END
                                  ELSE
                                    CASE 
                                      WHEN CAST(UnicodePct AS FLOAT) = 0.0 OR UnicodePct IS NULL
                                        THEN
                                          CASE 
                                            WHEN MaxLen = MinLen 
                                              THEN 'CHAR(' + LTRIM(RTRIM(STR(MaxLen))) + ')'  
                                            ELSE 'VARCHAR(' + ISNULL(SmallestSquareLen, CHARACTER_MAXIMUM_LENGTH) + ')'
                                          END
                                      ELSE
                                        CASE 
                                          WHEN MaxLen = MaxLen 
                                            THEN 'NCHAR(' + LTRIM(RTRIM(STR(MaxLen))) + ')'  
                                          ELSE 'NVARCHAR(' + ISNULL(SmallestSquareLen, CHARACTER_MAXIMUM_LENGTH) + ')'
                                        END
                                    END
                                END
          FROM
            SmallestSquareLen_OrdPos_Calc calc  
        )     

    , Nullability_Calc AS
        (
          SELECT
              calc.*
            , DataTypeStrNative = CASE
                                    WHEN [DATA_TYPE] IN(
                                                            'datetime'
                                                          , 'date'
                                                          , 'time'
                                                          , 'text'
                                                          , 'ntext'
                                                          , 'xml'
                                                          , 'money'
                                                          , 'bigint'
                                                          , 'bit'
                                                          , 'int'
                                                          , 'smallint'
                                                          , 'tinyint'
                                                          , 'real'
                                                        )
                                      THEN [DATA_TYPE]
                                    WHEN [DATA_TYPE] LIKE '%char' OR [DATA_TYPE] LIKE '%binary'  
                                      THEN [DATA_TYPE] + '(' + REPLACE(LTRIM(RTRIM(STR([CHARACTER_MAXIMUM_LENGTH]))),'-1','MAX') + ')'
                                    WHEN [DATA_TYPE] = 'datetime2' 
                                      THEN [DATA_TYPE] + '(' + LTRIM(RTRIM(STR([DATETIME_PRECISION]))) + ')'
                                    WHEN [DATA_TYPE] = 'float' 
                                      THEN [DATA_TYPE] + '(' + LTRIM(RTRIM(STR([NUMERIC_PRECISION]))) + ')'              
                                    WHEN [DATA_TYPE] IN('decimal', 'numeric')
                                      THEN [DATA_TYPE] + '(' + LTRIM(RTRIM(STR([NUMERIC_PRECISION]))) + ',' + LTRIM(RTRIM(STR([NUMERIC_SCALE])))  + ')'
                                  END 
                                + CASE 
                                    WHEN IS_NULLABLE = '1' 
                                      THEN ' NULL' 
                                    ELSE ' NOT NULL' 
                                  END
            , Nullability       = CASE 
                                    WHEN CAST(BlankOrNullPct AS FLOAT) = 100.0 
                                      THEN ' NULL'
                                    ELSE ' NOT NULL'
                                  END
          FROM
            CharTypeDefStr_Calc calc
        )             
  SELECT
      [TableName]      = CAST(calc.[TableName] AS SYSNAME)
    , ColName          = CAST(calc.ColName AS SYSNAME)
    , OrdinalPos       = CAST(calc.OrdinalPos AS INT)
    , MaxLen           = CAST(calc.MaxLen AS BIGINT)
    , MinLen           = CAST(calc.MinLen AS BIGINT)  
    , MaxVal           = CAST(calc.MaxVal AS NVARCHAR(MAX))
    , MinVal           = CAST(calc.MinVal AS NVARCHAR(MAX))
    , [IsNumeric]      = CAST(CASE calc.[IsNumeric] WHEN 'Yes' THEN 1 ELSE 0 END AS BIT)
    , IsInteger        = CAST(CASE calc.IsInteger WHEN 'Yes' THEN 1 ELSE 0 END AS BIT)
    , IntegerRowCnt    = CAST(calc.IntegerRowCnt AS BIGINT)    
    , DistinctValCnt   = CAST(calc.DistinctValCnt AS BIGINT)    
    , NumericRowCnt    = CAST(calc.NumericRowCnt AS BIGINT)
    , BlankOrNullCount = CAST(calc.BlankOrNullCount AS BIGINT)    
    , UnicodeCnt       = CAST(calc.UnicodeCnt AS BIGINT)
    , BlankOrNullPct   = CAST(calc.BlankOrNullPct AS FLOAT)
    , TypeDef          = CASE 
                          WHEN DATA_TYPE LIKE '%char' OR DATA_TYPE LIKE '%int'
                            THEN CAST(', [' + ColName + '] ' + CharTypeDefStr + Nullability AS VARCHAR(256))
                          ELSE CAST(', [' + ColName + '] ' + DataTypeStrNative AS VARCHAR(256))
                        END
    , TypeDefNative    = CAST(', [' + ColName + '] ' + DataTypeStrNative AS VARCHAR(256))
  FROM
    Nullability_Calc calc
  where
    CAST(calc.[TableName] AS SYSNAME) = 'InfoUsaUnmatched_Archive'--'InfoUsaMatched_Archive'

-- INT max 2,147,483,647	2,147,483,647	1717986917
-- SMALLINT max 32767	32767	26213
-- TINYINT 255	255	204







