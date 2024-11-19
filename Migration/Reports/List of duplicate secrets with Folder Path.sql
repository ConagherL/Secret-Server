SELECT  
	s.SecretID as [SecretID],
        f.folderpath as [Folder Path],
        s.secretname as [Secret Name]

FROM tbsecret s 

JOIN (SELECT  SecretName, COUNT(SecretName) as [Total] 
	FROM tbsecret t
	WHERE t.active = 1
	GROUP BY SecretName 
	Having COUNT(SecretName) > 1)

t ON s.SecretName = t.SecretName

INNER JOIN tbfolder f ON s.folderid = f.folderid 

WHERE	s.active = 1
GROUP BY s.SecretName, f.FolderPath, s.SecretID
