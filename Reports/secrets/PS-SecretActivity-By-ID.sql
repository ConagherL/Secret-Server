SELECT 
    a.DateRecorded AS [Date Recorded],
    upn.displayname AS [SSUser],
    ISNULL(f.FolderPath, N'No folder assigned') AS [Folder Path],
    s.secretname AS [Secret Name],
    a.Action,
    a.Notes,
    a.ipaddress AS [IP Address]
FROM tbauditsecret a WITH (NOLOCK)
INNER JOIN tbuser u WITH (NOLOCK)
    ON u.userid = a.userid
    AND u.OrganizationId = #Organization
INNER JOIN vUserDisplayName upn WITH (NOLOCK)
    ON u.UserId = upn.UserId
INNER JOIN tbsecret s WITH (NOLOCK)
    ON s.secretid = a.secretid 
LEFT JOIN tbFolder f WITH (NOLOCK)
    ON s.FolderId = f.FolderId
WHERE 
    a.DateRecorded >= #StartDate
    AND a.DateRecorded <= #EndDate
    AND a.SecretID IN (18, 55, 78) -- Replace with your list of SecretIDs
    AND s.active = 1
ORDER BY 
    a.DateRecorded DESC, upn.displayname, f.FolderPath, s.secretname, a.Action, a.Notes, a.ipaddress
