/*┌─────────────────────────────────────────────────────────────────────────────────────────────┐*\
  │ TITLE: Index DDL __DATABASE_NAME__.__SCHEMA_NAME__.__TABLE_NAME__.__FOREIGN_KEY_NAME__
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤
  │ DESCRIPTION:                                                                                │
      
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤
  │ REVISION HISTORY:                                                                           │
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤
  │   DATE       AUTHOR          CHANGE DESCRIPTION                                             │
  │   ────────── ─────────────── ────────────────────────────────────────────────────────────── │
      YYYY.MM.DD __AUTHOR_______ Initial Draft
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤
  │ INDEX NAMING CONVENTION:                                                                    │

    PREFIX DESIGNATIONS:

      CI = Primary Key Index (Clustered): A clustered index acting as a primary key
      NI = Non-Clustered, Non-Unique Index
      UI = Unique Non-Clulstered Index

    FORM:
      <PrefixDesignation>_<TableSchema>_<TableName>_<Descriptor>

      <PrefixDesignation> : Pick the appropriate Prefix Designations listed above
      <TableSchema>       : The name of the schema of the table this index is on (if not dbo)
      <TableName>         : The name of the table this index is on
      <Descriptor>        : If the index is on one or two columns, just put the column names
                            separated by and underscore, if the index name is too long doing 
                            this or there are more than a couple columns just put a brief 
                            description of the purpose of the index

\*└─────────────────────────────────────────────────────────────────────────────────────────────┘*/
USE __DATABASE_NAME__
GO

IF EXISTS (SELECT 1
                FROM 
                  sys.foreign_keys fk
                  JOIN
                  sys.tables t
                    ON t.[object_id] = fk.parent_object_id
                WHERE t.[object_id] = OBJECT_ID(N'__SCHEMA_NAME__.__TABLE_NAME__')
                  AND fk.[name]     = N'__FOREIGN_KEY_NAME__')
  ALTER TABLE 
    __SCHEMA_NAME__.__TABLE_NAME__     
  DROP CONSTRAINT 
    __FOREIGN_KEY_NAME__ 
GO

SET ANSI_PADDING ON
GO

IF NOT EXISTS ( SELECT 1
                FROM 
                  sys.foreign_keys fk
                  JOIN
                  sys.tables t
                    ON t.[object_id] = fk.parent_object_id
                WHERE t.[object_id] = OBJECT_ID(N'__SCHEMA_NAME__.__TABLE_NAME__')
                  AND fk.[name]     = N'__FOREIGN_KEY_NAME__' )
  ALTER TABLE 
    __SCHEMA_NAME__.__TABLE_NAME__     
  ADD CONSTRAINT 
    __FOREIGN_KEY_NAME__ 
  FOREIGN KEY 
    (__FOREIGN_KEY_COL_NAME__)     
  REFERENCES 
    __REF_TABLE_SCHEMA_NAME__.__REF_TABLE_TABLE_NAME__ 
      (__FOREIGN_KEY_REF_COL_NAME__)     
  --ON DELETE CASCADE    
  --ON UPDATE CASCADE  
