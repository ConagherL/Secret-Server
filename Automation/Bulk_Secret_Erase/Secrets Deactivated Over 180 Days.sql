SELECT
    aud.SecretId,
    s.SecretName AS [Secret name],
    f.FolderName AS [Folder name],
    f.FolderPath AS [Folder path],
    aud.DateRecorded AS [Date/Time of deactivation]
FROM
    tbAuditSecret aud
JOIN
    tbSecret s WITH (NOLOCK)
    ON aud.SecretId = s.SecretId
JOIN
    tbFolder f WITH (NOLOCK)
    ON s.FolderID = f.FolderID
WHERE
    aud.Action = 'DEACTIVATE'
    AND aud.DateRecorded <= DATEADD(DAY, -180, GETDATE())
ORDER BY
    aud.DateRecorded DESC
