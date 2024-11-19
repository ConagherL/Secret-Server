SELECT    ISNULL(fp.FolderPath, 'No folder assigned') as [Folder Path]     
,s.SecretName AS [Secret Name]     
,st.SecretTypeName AS [Secret Template]     
,s.SecretId  
,sd.ServiceName
,sdt.SecretDependencyTypeName
,CASE sd.SecretDependencyStatus 
			WHEN 1 THEN 'Yes'
			WHEN 0 THEN 'No'
			END AS [Last Run Success]
,CASE sd.Active 
			WHEN 1 THEN 'Yes'
			WHEN 0 THEN 'No'
			END AS [Active]
 FROM tbSecret s WITH (NOLOCK)         
 INNER JOIN tbSecretType st WITH (NOLOCK)      
	ON s.SecretTypeId = st.SecretTypeId     
 LEFT JOIN vFolderPath fp WITH (NOLOCK)      
	ON s.FolderId = fp.FolderId     
 LEFT JOIN tbFolder f WITH (NOLOCK)      
	ON s.FolderId = f.FolderId     
JOIN tbSecretDependency sd WITH (NOLOCK)  
	ON sd.SecretId = s.SecretId
JOIN tbSecretDependencyType sdt WITH (NOLOCK)
	ON sdt.SecretDependencyTypeId = sd.SecretDependencyTypeId
 WHERE     
 s.Active = 1 
 AND (st.PasswordTypeReady = 1 OR st.EnableHeartBeat = 1) 
 AND st.OrganizationId = 1
 ORDER BY 1, 2, 3, 4