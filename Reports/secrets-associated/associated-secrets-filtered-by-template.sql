/*
    .PURPOSE
    Get list of Secrets and the associated secrets by Template
*/
SELECT *
FROM (
    SELECT s.SecretId
        ,s.SecretName
        ,s.SecretTypeID
        ,rs.ResetSecretId AS [AssociatedSecretId]
        ,privs.SecretName AS [AssociatedSecretName]
        ,rs.AssociatedSecretType
    FROM tbSecret s
    INNER JOIN tbSecretResetSecrets rs ON rs.SecretId = s.SecretID
    INNER JOIN tbSecret AS privs ON rs.SecretId = privs.SecretId
) AS s
WHERE s.SecretTypeID LIKE '%' + #CUSTOMTEXT + '%'