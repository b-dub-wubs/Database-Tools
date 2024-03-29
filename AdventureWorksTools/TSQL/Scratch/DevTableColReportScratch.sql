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



SELECT
  

    TABLE_SCHEMA
  , TABLE_NAME
  , COLUMN_NAME

  , DataTypeDef = CASE
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
FROM
  AdventureWorks_0006.INFORMATION_SCHEMA.COLUMNS
WHERE 
  TABLE_NAME LIKE 'menu%'


