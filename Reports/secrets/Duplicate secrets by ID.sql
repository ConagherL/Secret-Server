--
---- Report finds all the duplicate secrets in a vault and drops the secrets with the lower ID #. Leaving the duplicates we want to delete in the report.

SELECT  
	s.SecretID as [SecretID]
	,f.folderpath as [Folder Path]
	,s.secretname as [Secret Name]

FROM tbsecret s 

JOIN (SELECT  SecretName, COUNT(SecretName) as [Total] 
	FROM tbsecret t
	WHERE t.active = 1
	GROUP BY SecretName 
	Having COUNT(SecretName) > 1)

t ON s.SecretName = t.SecretName

JOIN (SELECT  SecretName, MIN(SecretId) as [MinID] 
	FROM tbsecret m
	WHERE m.active = 1
	GROUP BY SecretName 
	Having COUNT(SecretName) > 1)

m ON s.SecretName = m.SecretName AND s.SecretID != m.MinID

LEFT JOIN tbfolder f ON s.folderid = f.folderid 

WHERE s.active = 1 

GROUP BY s.SecretName, f.FolderPath, s.SecretID