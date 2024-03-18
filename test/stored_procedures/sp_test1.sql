CREATE PROCEDURE [dbo].[sp_test1]
AS
BEGIN
  SELECT * FROM sys.objects o JOIN sys.schemas s ON o.schema_id = s.schema_id
  WHERE type = 'P' AND o.name = 'sp_test1' AND s.name = 'dbo'
END
