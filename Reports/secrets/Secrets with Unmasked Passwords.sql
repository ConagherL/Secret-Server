SELECT DISTINCT
a.DateRecorded AS 'Audit Date'
,a.SecretId AS 'Secret ID'
,s.SecretName AS 'Secret Name'
,t.SecretTypeName AS 'Secret Template'
,u.UserName AS 'UName'
,CASE
WHEN a.IpAddress IS NULL THEN 'Unknown'
ELSE a.IpAddress
END AS 'Host IP Address'
,a.Action AS 'Last Recorded Action'
,f.FolderPath AS 'Folder Path'
,a.EndPoint AS 'End-Point'


FROM tbAuditSecret a
JOIN tbSecret s ON s.SecretID = a.SecretId
JOIN tbFolder f ON f.FolderID = s.FolderId
JOIN tbUser u ON u.UserId = a.UserId
JOIN tbSecretType t ON t.SecretTypeID = s.SecretTypeID


WHERE a.DateRecorded=(
SELECT MAX(DateRecorded) FROM tbAuditSecret WHERE tbAuditSecret.SecretId = a.SecretId) AND a.EndPoint LIKE '%/fields/password%'

Order by a.DateRecorded DESC, a.SecretId ASC