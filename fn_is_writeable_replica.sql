USE [master]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[fn_is_writeable_replica] (@dbname sysname) 
RETURNS BIT 
WITH EXECUTE AS CALLER 
AS 

BEGIN 
	DECLARE @is_writeable BIT; 
	
	IF EXISTS(SELECT 1 FROM master.sys.databases WHERE [name] = @dbname) 
		BEGIN 
			IF(DATABASEPROPERTYEX(@dbname, 'Updateability') <> 'READ_WRITE') 
				SELECT @is_writeable = 0 
			ELSE 
				SELECT @is_writeable = 1 
		END 
	ELSE 
		BEGIN 
			SELECT @is_writeable = 0 
		END 
	RETURN(@is_writeable); 
END 
