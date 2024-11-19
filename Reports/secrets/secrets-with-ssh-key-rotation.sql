SELECT s.SecretId, s.SecretName, tp.SecretTypeName AS TemplateName
FROM tbSecret s
    INNER JOIN tbSecretType st ON st.SecretTypeID = s.SecretTypeID
    INNER JOIN tbSecretField sf ON st.SecretTypeID = sf.SecretTypeID
    INNER JOIN tbPasswordType pt ON pt.PasswordTypeId = st.PasswordTypeId
    INNER JOIN tbPasswordTypeField ptf ON pt.PasswordTypeId = ptf.PasswordTypeId AND sf.PasswordTypeFieldId = ptf.PasswordTypeFieldId
    INNER JOIN tbSecretType tp ON s.SecretTypeID = tp.SecretTypeID
WHERE st.PasswordTypeReady = 1
    AND s.Active = 1
    AND pt.TypeName = 'Thycotic.AppCore.Federator.UnixSshCustomAccountFederator'
    AND st.Active =  1
    AND st.PasswordTypeReady = 1
    AND ptf.Name = 'privatekey'
