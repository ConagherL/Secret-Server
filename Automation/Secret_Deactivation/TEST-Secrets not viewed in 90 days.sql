SELECT  
    s.secretid,
    s.secretname AS [Secret Name],
    STRING_AGG(username, ', ') AS [Usernames],
    STRING_AGG(u.EmailAddress, ', ') AS [EmailAddresses],
    CASE 
        WHEN (UPPER(f.FolderPath) LIKE '%NON-PROD%' OR UPPER(f.FolderPath) LIKE '%NONPROD%') THEN 'Non-Prod' 
        ELSE 'Prod' 
    END AS [Environment],
    ISNULL(f.FolderPath, N'No folder assigned') AS [Folder Path],
	st.SecretTypeName AS [Secret Template],
    CASE 
        WHEN s.LastHeartBeatStatus = 0 THEN 'Failed' 
        WHEN s.LastHeartBeatStatus = 4 THEN 'Unable To Connect' 
        WHEN s.LastHeartBeatStatus = 5 THEN 'Unknown Error' 
        WHEN s.LastHeartBeatStatus = 6 THEN 'Incompatible Host' 
        WHEN s.LastHeartBeatStatus = 7 THEN 'Account Lockedout' 
        WHEN s.LastHeartBeatStatus = 8 THEN 'DNS Mismatch' 
        WHEN s.LastHeartBeatStatus = 9 THEN 'Unable To Validate Server PublicKey' 
        WHEN s.LastHeartBeatStatus = 10 THEN 'Processing' 
        WHEN s.LastHeartBeatStatus = 11 THEN 'Argument Error' 
        WHEN s.LastHeartBeatStatus = 12 THEN 'Access Denied' 
        WHEN s.LastHeartBeatStatus in (1,2,3) THEN 'Success' 
        ELSE 'Unknown Status' 
    END AS [Last Heartbeat Status],
    CASE
        WHEN S.PasswordChangeFailed = 0 THEN 'Failed'
        ELSE 'Success'
    END AS [Last RPC Status],
    S.Created AS [Secret Created Date],
    MAX(a.latestdaterecorded) AS [Secret Last View Date],
    DATEDIFF(day, MAX(a.latestdaterecorded), GetDate()) as [Days Since Last View]
FROM vSecretUserPermission perm
JOIN tbsecret s ON s.secretid = perm.SecretID
JOIN tbuser u ON u.userid = perm.UserID
INNER JOIN tbSecretType st WITH (NOLOCK) ON st.SecretTypeId = s.SecretTypeId
LEFT JOIN tbFolder f WITH (NOLOCK) ON s.FolderId = f.FolderId
LEFT JOIN (    
    SELECT 
        audit.secretid,
        MAX(audit.daterecorded) AS 'latestdaterecorded'
    FROM tbauditsecret audit WITH (NOLOCK)
    WHERE UPPER(audit.Action) = 'VIEW'
    GROUP BY 
        audit.secretid
) a ON s.secretid = a.secretid 

WHERE
    s.secretid IN (8, 57, 48) ------UPDATE to ID's that you can delete and re activate
    AND perm.Permissions = 15 
    AND u.Enabled = 1
    AND s.Active = 1
    ---AND (a.latestdaterecorded IS NULL OR a.latestdaterecorded < DATEADD(day, -90, GetDate()))

GROUP BY 
    s.secretid,
    s.secretname,
    CASE 
        WHEN (UPPER(f.FolderPath) LIKE '%NON-PROD%' OR UPPER(f.FolderPath) LIKE '%NONPROD%') THEN 'Non-Prod' 
        ELSE 'Prod' 
    END,
    ISNULL(f.FolderPath, N'No folder assigned'),
    s.LastHeartBeatStatus,
    S.PasswordChangeFailed,
    S.Created,
	st.SecretTypeName
ORDER BY s.secretid ASC
