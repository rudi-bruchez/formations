-- Does database collation have influence over compression ?

CREATE DATABASE test_bin COLLATE French_BIN;
GO

USE test_bin;
GO

SELECT 
	message_id
INTO dbo.test
FROM sys.messages

exec sys.sp_estimate_data_compression_savings  'dbo','test',NULL,1,ROW
GO

USE Master;
GO

DROP DATABASE test_bin;
