DECLARE @GraceDays INT
SET @GraceDays = 3

SELECT 
tbUser.LastLogin AS lastlogin, tbUser.Created AS Date2, tbUser.PasswordLastChanged AS Date3
FROM 
tbUser WITH (NOLOCK)
WHERE
tbUser.LastLogin > GETDATE() + @GraceDays
OR
tbUser.Created > GETDATE() + @GraceDays
OR
tbUser.PasswordLastChanged > GETDATE() + @GraceDays
UNION SELECT
tbAuditSecret.DateRecorded AS Date1, NULL AS Date2, NULL AS Date3
FROM
tbAuditSecret WITH (NOLOCK)
WHERE
tbAuditSecret.DateRecorded > GETDATE() + @GraceDays
UNION SELECT
tbSecret.Created AS Date1, NULL AS Date2, NULL AS Date3
FROM
tbSecret WITH (NOLOCK)
WHERE
tbSecret.Created > GETDATE() + @GraceDays
UNION SELECT
tbSystemLog.LogDate AS Date1, NULL AS Date2, NULL AS Date3
FROM
tbSystemLog WITH
 (NOLOCK)
WHERE
	tbSystemLog.LogDate > GETDATE() + @GraceDays
UNION SELECT
	tbBackupLog.BackupTime AS Date1, NULL AS Date2, NULL AS Date3
FROM
	tbBackupLog WITH (NOLOCK)
WHERE
	tbBackupLog.BackupTime > GETDATE() + @GraceDays