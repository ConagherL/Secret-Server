--create using chart type
SELECT
    st.SecretTypeName
    ,COUNT(st.SecretTypeName) AS [TotalSecretTypeName]
FROM tbSecret tbs
INNER JOIN vFolderSecret fs ON fs.folderid = tbs.folderid
JOIN tbSecretType st WITH (NOLOCK) ON tbS.SecretTypeId = st.SecretTypeId
WHERE tbs.Active = 1
GROUP BY st.SecretTypeName