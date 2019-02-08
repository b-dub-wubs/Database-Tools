/*┌─────────────────────────────────────────────────────────────────────────────────────────────┐*.
  │ TITLE: Fix Orphaned Database Users (broken SID links)                                       │
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤
  │ DESCRIPTION:                                                                                │
      for use when restoring a database onto a different server where the login on the 
      destination server may have a different SID assosiated with a particular login
      This script fixes the "orpahaned" database users by fixing the SID assosiated with each 
      database user where the SID link is broken
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤
  │ REVISION HISTORY:                                                                           │
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤
  │   DATE       AUTHOR          CHANGE DESCRIPTION                                             │
  │   ────────── ─────────────── ────────────────────────────────────────────────────────────── │
      2018.11.14 bwarner         Initial Draft
\*└─────────────────────────────────────────────────────────────────────────────────────────────┘*/


SET NOCOUNT ON
USE Analytics_DWH
GO
DECLARE @loop INT
DECLARE @USER sysname
 
IF OBJECT_ID('tempdb..#Orphaned') IS NOT NULL 
 BEGIN
  DROP TABLE #orphaned
 END
 
CREATE TABLE #Orphaned (UserName sysname, UserSID VARBINARY(85),IDENT INT IDENTITY(1,1))
 
INSERT INTO #Orphaned
EXEC SP_CHANGE_USERS_LOGIN 'report';
 
IF(SELECT COUNT(*) FROM #Orphaned) > 0
BEGIN
 SET @loop = 1
 WHILE @loop <= (SELECT MAX(IDENT) FROM #Orphaned)
  BEGIN
    SET @USER = (SELECT UserName FROM #Orphaned WHERE IDENT = @loop)
    IF(SELECT COUNT(*) FROM sys.server_principals WHERE [Name] = @USER) <= 0
     BEGIN
        EXEC SP_ADDLOGIN @USER
     END
     
    EXEC SP_CHANGE_USERS_LOGIN 'update_one',@USER,@USER
    PRINT @USER + ' link to DB user reset';
    SET @loop = @loop + 1
  END
END
SET NOCOUNT OFF