SELECT
a.DateRecorded AS [Date Recorded],
upn.displayname AS [Member],
ISNULL(f.FolderPath, N'No folder assigned') as [Folder Path],
s.secretname As [Secret Name],
a.Action,
a.Notes,
a.ipaddress AS [IP Address]
FROM tbauditsecret a WITH (NOLOCK)
INNER JOIN tbuser u WITH (NOLOCK)
ON u.userid = a.userid
AND u.OrganizationId = 1
INNER JOIN vUserDisplayName upn WITH (NOLOCK)
ON u.UserId = upn.UserId
INNER JOIN tbsecret s WITH (NOLOCK)
ON s.secretid = a.secretid
LEFT JOIN tbFolder f WITH (NOLOCK)
ON s.FolderId = f.FolderId
WHERE
a.Action like 'Password Displayed'
AND s.folderId IN (106,371,234,171,688) -- folderIDs
AND a.DateRecorded >= DATEADD(day, -30, GETUTCDATE())
ORDER BY
1 DESC,2, 3,4,5,6,7