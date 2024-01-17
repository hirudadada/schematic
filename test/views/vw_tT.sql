CREATE VIEW [dbo].[vw_tT]
AS
  SELECT o.name AS object_name, o.object_id, o.type, o.type_desc, create_date, s.name AS schema_nameee, s.schema_id 
  FROM sys.objects o JOIN sys.schemas s ON o.schema_id = s.schema_id
  WHERE type = 'V' AND o.name = 'vw_name' AND s.name = 'dbo'

