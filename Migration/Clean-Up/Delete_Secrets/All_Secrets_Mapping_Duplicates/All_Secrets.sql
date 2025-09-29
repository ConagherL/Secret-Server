SELECT 
    s.SecretID,
    s.SecretName,
    f.FolderPath,
    st.SecretTypeName AS TemplateName,
    s.Created AS CreatedDate,
    s.LastModifiedDate AS LastModifiedDate,
    CASE WHEN fa.SecretID IS NOT NULL THEN 'Yes' ELSE 'No' END AS HasFiles
FROM 
    tbSecret s
    LEFT JOIN tbFolder f ON s.FolderId = f.FolderId
    LEFT JOIN tbSecretType st ON s.SecretTypeID = st.SecretTypeID
    LEFT JOIN (
        SELECT DISTINCT i.SecretID
        FROM tbSecretItem i
        INNER JOIN tbFileAttachment a ON i.FileAttachmentId = a.FileAttachmentId
        WHERE i.FileAttachmentId IS NOT NULL
            AND a.IsDeleted = 0
    ) fa ON s.SecretID = fa.SecretID
WHERE 
    s.Active = 1