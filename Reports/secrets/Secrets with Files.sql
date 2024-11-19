SELECT s.SecretName, i.FileAttachmentId, f.FileName
FROM tbSecret AS s
       INNER JOIN tbSecretItem AS i
       ON i.SecretID = s.SecretID
       INNER JOIN tbFileAttachment f
       ON i.FileAttachmentId = f.FileAttachmentId
WHERE i.FileAttachmentId IS NOT NULL  AND s.Active =1
