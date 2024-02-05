SELECT 
    s.SecretId,  -- The unique identifier for each secret
    s.SecretName,  -- The name of the secret
    -- Checking for a null PrivilegAccountSecretID and replacing it with 'No Privilege Account' if null
    ISNULL(CAST(s.PrivilegAccountSecretID AS VARCHAR), 'No Privilege Account') AS PrivilegAccountSecretID, 
    -- Checking for a null PrivilegeAccountSecretName and replacing it with 'No Privilege Account' if null
    ISNULL(s.PrivilegeAccountSecretName, 'No Privilege Account') AS PrivilegeAccountSecretName,
    st.SecretTypeName -- The name of the template associated with the secret
FROM
    -- Subquery to fetch secrets and their corresponding privilege account details
    (SELECT 
        s.SecretId,  -- Secret ID
        s.SecretName,  -- Secret Name
        rs.ResetSecretId AS PrivilegAccountSecretID,  -- ID of the privilege account secret, if any
        -- Subquery to fetch the name of the privilege account secret
        (SELECT SecretName FROM tbSecret WHERE SecretID = rs.ResetSecretId) AS PrivilegeAccountSecretName,
        s.SecretTypeID  -- The type ID of the secret, used to join with the template table
    FROM 
        tbSecret s 
    LEFT JOIN  -- Left join to include secrets without a corresponding PrivilegeAccountSecretID
        tbSecretResetSecrets rs ON rs.SecretId = s.SecretID) s
LEFT JOIN  -- Left join to include secrets that might not have an associated template
    tbSecretType st ON s.SecretTypeID = st.SecretTypeID
WHERE 
    s.SecretName LIKE #CUSTOMTEXT + '%'  -- Filtering secrets that start with a specified custom text
