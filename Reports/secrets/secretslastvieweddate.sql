SELECT 
a.latestdaterecorded AS [Latest Date Recorded],
u.displayname AS [User],
ISNULL(f.FolderPath, N'No folder assigned') AS [Folder Path],
s.secretname AS [Secret Name],
a.ipaddress AS [IP Address]
FROM ( 
SELECT 
audit.secretid,
audit.userid,
audit.ipaddress,
Max(audit.daterecorded) AS 'latestdaterecorded'
FROM tbauditsecret audit WITH (NOLOCK)
INNER JOIN tbUser WITH (NOLOCK)
ON audit.UserId = tbUser.UserID
AND tbUser.OrganizationId = 1
WHERE 
audit.DateRecorded >= #STARTDATE 
AND
audit.DateRecorded <= #ENDDATE and
tbuser.username <> 'ThycoticSystem' 
GROUP BY 
audit.userid,
audit.secretid,
audit.ipaddress) a
INNER JOIN vUserDisplayName u WITH (NOLOCK)
ON u.userid = a.userid
INNER JOIN tbsecret s WITH (NOLOCK)
ON s.secretid = a.secretid 
LEFT JOIN tbFolder f WITH (NOLOCK)
ON s.FolderId = f.FolderId
ORDER BY 
1 DESC, 2, 3, 4, 5


-