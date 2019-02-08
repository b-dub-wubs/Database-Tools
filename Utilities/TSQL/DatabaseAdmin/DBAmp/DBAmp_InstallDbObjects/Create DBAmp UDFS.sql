-- =============================================
-- Create User defined functions for the DBAmp system tables
--
-- IMPORTANT: Before executing this script, replace all instances of
--   SALESFORCE with your linked server name.
--
-- Run this script to create the following DBAmp user defined functions:
--	SF_PickLists()
--  SF_Fields()
--  SF_Objects()
-- This will allow you to do where clauses on these tables.
-- Example: Select * from SF_PickLists() where ObjectName='Account'
-- =============================================
-- *************************
-- SF_PickLists()
-- *************************
IF EXISTS (SELECT * 
	   FROM   sysobjects 
	   WHERE  name = N'SF_PickLists')
	DROP FUNCTION SF_PickLists
GO

CREATE FUNCTION SF_PickLists()
RETURNS @PickListTable TABLE 
	(ObjectName nvarchar(128), 
	 FieldName nvarchar(128),
	 PickListValue nvarchar(256),
	 PickListLabel nvarchar(256))
AS
BEGIN
	INSERT @PickListTable
	SELECT ObjectName, FieldName, PickListValue, PickListLabel
	FROM SALESFORCE...sys_sfpicklists
	RETURN 
END
GO
-- *************************
-- SF_Fields()
-- *************************
IF EXISTS (SELECT * 
	   FROM   sysobjects 
	   WHERE  name = N'SF_Fields')
	DROP FUNCTION SF_Fields
GO

CREATE FUNCTION SF_Fields()
RETURNS @FieldsTable TABLE (
	[ObjectName] [nvarchar](128) ,
	[Name] [nvarchar](128) ,
	[Type] [nvarchar](32) ,
	[Label] [nvarchar](128) ,
	[SQLDefinition] [nvarchar](128) ,
	[Calculated] [varchar](5) ,
	[Createable] [varchar](5) ,
	[DefaultedOnCreate] [varchar](5) ,
	[Filterable] [varchar](5) ,
	[NameField] [varchar](5) ,
	[Nillable] [varchar](5)  ,
	[Sortable] [varchar](5)  ,
	[Unique] [varchar](5)  ,
	[Updateable] [varchar](5)  ,
	[AutoNumber] [varchar](5)  ,
	[RestrictedPicklist] [varchar](5)  ,
	[ExternalID] [varchar](5)  ,
	[RelationshipName] [nvarchar](128)  
)
AS
BEGIN
	INSERT @FieldsTable
SELECT [ObjectName]
      ,[Name]
      ,[Type]
      ,[Label]
      ,[SQLDefinition]
      ,[Calculated]
      ,[Createable]
      ,[DefaultedOnCreate]
      ,[Filterable]
      ,[NameField]
      ,[Nillable]
      ,[Sortable]
      ,[Unique]
      ,[Updateable]
      ,[AutoNumber]
      ,[RestrictedPicklist]
      ,[ExternalID]
      ,[RelationshipName]
	FROM SALESFORCE...sys_sffields
	RETURN 
END
GO

-- *************************
-- SF_Objects()
-- *************************
IF EXISTS (SELECT * 
	   FROM   sysobjects 
	   WHERE  name = N'SF_Objects')
	DROP FUNCTION SF_Objects
GO

CREATE FUNCTION SF_Objects()
RETURNS @ObjectsTable TABLE (
	[Name] [nvarchar](128) ,
	[Createable] [varchar](5) ,
	[Deletable] [varchar](5) ,
	[Queryable] [varchar](5) ,
	[Replicateable] [varchar](5) ,
	[URLDetail] [nvarchar](2048) ,
	[URLEdit] [nvarchar](2048) ,
	[URLNew] [nvarchar](2048) 
)
AS
BEGIN
	INSERT @ObjectsTable
SELECT [Name]
      ,[Createable]
      ,[Deletable]
      ,[Queryable]
      ,[Replicateable]
      ,[URLDetail]
      ,[URLEdit]
      ,[URLNew]
	FROM SALESFORCE...sys_sfobjects
	RETURN 
END
GO
