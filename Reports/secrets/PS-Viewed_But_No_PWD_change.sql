SELECT 
    sa1.DateRecorded AS [Date Recorded],
    u.DisplayName AS [SS_User],
    s.SecretName AS [Secret Name],
    sa1.Action AS [Action]
FROM tbAuditSecret sa1
JOIN tbSecret s ON sa1.SecretId = s.SecretId
JOIN tbUser u ON sa1.UserId = u.UserId
LEFT JOIN (
    -- Query to find the most recent "CHANGE PASSWORD" action per Secret if found
    SELECT SecretId, MAX(DateRecorded) AS LastPasswordChangeTime
    FROM tbAuditSecret
    WHERE Action = 'CHANGE PASSWORD'
    GROUP BY SecretId
) sa2 ON sa1.SecretId = sa2.SecretId
WHERE 
    s.SecretTypeId IN (
        SELECT SecretTypeId FROM tbSecretType WHERE SecretTypeName = 'Manual-Change'
    ) 
    AND u.DisplayName NOT LIKE 'YOUREXAMPLE%' -- Exclude service accounts
    AND sa1.Action = 'PASSWORD DISPLAYED' -- Track only password display actions
    AND (sa2.LastPasswordChangeTime IS NULL OR sa1.DateRecorded > sa2.LastPasswordChangeTime) -- Exclude if a password change happened after this date
ORDER BY sa1.DateRecorded DESC
