SELECT DISTINCT
 a.DateRecorded AS 'Most Recent Activity Recorded Date'
,a.SecretId AS 'SecretID'
,s.SecretName AS 'Secret Name'
,t.SecretTypeName AS 'Secret Template'
,u.UserName AS 'UName' 
,CASE 
	WHEN a.IpAddress IS NULL THEN 'Unknown'
	ELSE a.IpAddress
	END AS 'User/System IP Address'
,a.Action AS 'Last Recorded Action'
,a.Notes AS 'Audit Notes'
,t.SecretTypeName AS 'Secret Template'
,f.FolderPath AS 'Folder Path'
,v.[Inherit Permissions] AS 'Inherit Permissions'
,gdn.DisplayName AS 'Group/User Name'
,v.Permissions AS 'Permissions'


FROM tbAuditSecret a
JOIN tbSecret s ON s.SecretID = a.SecretId
JOIN tbFolder f ON f.FolderID = s.FolderId
JOIN tbUser u ON u.UserId = a.UserId
JOIN tbSecretType t ON t.SecretTypeID = s.SecretTypeID
JOIN vGroupFolderPermissions v ON v.FolderId = f.FolderID
INNER JOIN vGroupDisplayName gdn ON gdn.GroupId = v.GroupId


WHERE a.DateRecorded=(
SELECT MAX(DateRecorded) FROM tbAuditSecret WHERE tbAuditSecret.SecretId = a.SecretId) AND v.OwnerPermission = 1

Order by a.DateRecorded DESC, a.SecretId ASC