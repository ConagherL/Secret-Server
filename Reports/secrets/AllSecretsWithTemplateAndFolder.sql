SELECT 
tbS.SecretId
,tbS.SecretName
,st.SecretTypeName AS [Secret type]
,fs.foldername
,tbs.Created
FROM tbSecret tbS
INNER JOIN vFolderSecret fs ON fs.folderid = 
tbs.folderid
JOIN
    tbSecretType st WITH (NOLOCK)
    ON
    tbS.SecretTypeId = st.SecretTypeId
WHERE tbs.Active = 1 
ORDER BY tbs.secretname ASC