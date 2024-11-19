SELECT
    auditNote.Notes
FROM
    tbAuditSecret auditNote
WHERE auditNote.AuditSecretId = (
SELECT
    MAX(aud.AuditSecretId)
FROM
    tbAuditSecret aud
    JOIN tbSecret s WITH (NOLOCK) ON aud.SecretId = s.SecretId
    INNER JOIN vUserDisplayName udn WITH (NOLOCK) ON aud.UserId =
udn.UserId
WHERE aud.Action = 'VIEW' AND aud.SecretId = #CUSTOMTEXT
)