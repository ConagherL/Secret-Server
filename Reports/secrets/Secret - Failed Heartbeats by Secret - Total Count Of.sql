SELECT 
    s.secretname AS [Secret Name],
    s.LastHeartBeatCheck AS [Last Heartbeat Check],
    ISNULL(f.FolderPath, N'No folder assigned') AS [Folder Path],
    st.SecretTypeName AS [Secret Template],
    (
        SELECT COUNT(*)
        FROM tbSecretLog sl2
        WHERE sl2.SecretId = s.SecretId
          AND sl2.Status <> 'Success'
          AND sl2.DateRecorded > COALESCE(
                (SELECT MAX(sl3.DateRecorded)
                 FROM tbSecretLog sl3
                 WHERE sl3.SecretId = s.SecretId
                   AND sl3.Status = 'Success'),
                '1900-01-01'
          )
    ) AS [Total Count of Failures]
FROM tbSecret s
LEFT JOIN tbFolder f 
    ON s.FolderId = f.FolderId
JOIN tbSecretType st 
    ON s.SecretTypeID = st.SecretTypeID
WHERE s.Active = 1
  AND st.EnableHeartBeat = 1
  AND EXISTS (
      SELECT 1
      FROM tbSecretLog sl2
      WHERE sl2.SecretId = s.SecretId
        AND sl2.Status <> 'Success'
        AND sl2.DateRecorded > COALESCE(
              (SELECT MAX(sl3.DateRecorded)
               FROM tbSecretLog sl3
               WHERE sl3.SecretId = s.SecretId
                 AND sl3.Status = 'Success'),
              '1900-01-01'
          )
  )
ORDER BY s.LastHeartBeatCheck DESC, [Folder Path], [Secret Name];
