SELECT	f.FolderPath, s.*
FROM	tbSecret AS s 
		INNER JOIN tbFolder AS f ON s.FolderId = f.FolderID 
		INNER JOIN (
						SELECT FolderPath
						FROM   tbFolder AS f0
						WHERE  FolderID = 16
					) AS f0 ON f.FolderPath LIKE f0.FolderPath + '%'
