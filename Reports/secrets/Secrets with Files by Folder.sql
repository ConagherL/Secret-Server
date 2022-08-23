SELECT fo.FolderPath,s.SecretName, i.FileAttachmentId, f.FileName
FROM tbSecret AS s
       INNER JOIN tbSecretItem AS i
       ON i.SecretID = s.SecretID
       INNER JOIN tbFileAttachment f
       ON i.FileAttachmentId = f.FileAttachmentId
	   INNER JOIN tbFolder fo
	   ON FO.FolderID = S.FolderId
WHERE i.FileAttachmentId IS NOT NULL AND s.Active =1
