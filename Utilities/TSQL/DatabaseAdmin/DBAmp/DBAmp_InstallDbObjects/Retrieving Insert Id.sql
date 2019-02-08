declare @lastid nchar(18)  -- Important, must be nchar (NOT char)

INSERT INTO SALESFORCE...Note
(Body, IsPrivate, ParentId, Title)
VALUES('Body of Note 5','false', '00130000005ZsG8AAK',NULL)

set @lastid = (select LastId from SALESFORCE...sys_sflastid)

select * from SALESFORCE...Note where Id=@lastid