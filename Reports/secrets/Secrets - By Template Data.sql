SELECT
    tbs.SecretId
    ,tbs.SecretName
    ,st.SecretTypeName AS [SecretType]
    ,fs.foldername
    ,tbs.Created
FROM tbSecret tbs
INNER JOIN vFolderSecret fs ON fs.folderid =  tbs.folderid
JOIN tbSecretType st WITH (NOLOCK) ON tbS.SecretTypeId = st.SecretTypeId
WHERE tbs.Active = 1
ORDER BY tbs.secretname ASC