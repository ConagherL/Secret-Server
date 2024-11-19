
		SELECT  IsNull(f.FolderPath, 'No Folder') AS 'Folder Path', s.SecretID, i.ItemValue as [Domain Name] ,s.SecretName, st.SecretTypeName AS [Secret Template], s.LastHeartBeatCheck, s.LastHeartBeatStatus, 
CASE
	WHEN s.LastHeartBeatStatus = 0 THEN 'Failed'
	WHEN s.LastHeartBeatStatus = 4 THEN 'UnableToConnect'
	WHEN s.LastHeartBeatStatus = 5 THEN 'UnknownError'
	WHEN s.LastHeartBeatStatus = 6 THEN 'IncompatibleHost'
	WHEN s.LastHeartBeatStatus = 7 THEN 'AccountLockedOut'
	WHEN s.LastHeartBeatStatus = 8 THEN 'DnsMismatch'
	WHEN s.LastHeartBeatStatus = 9 THEN 'UnableToValidateServerPublicKey'
	WHEN s.LastHeartBeatStatus = 10 THEN 'Processing'
	WHEN s.LastHeartBeatStatus = 11 THEN 'ArgumentError'
	WHEN s.LastHeartBeatStatus = 12 THEN 'AccessDenied'
	ELSE 'Failed Unknown' 
END as 'HeartbeatStatus'
FROM tbSecret s
	INNER JOIN tbSecretType st on s.SecretTypeID = st.SecretTypeID
	LEFT JOIN tbFolder f on s.FolderID = f.FolderID
	LEFT JOIN tbPasswordType pt ON st.PasswordTypeId = pt.PasswordTypeId
	LEFT JOIN tbPasswordTypeWebScript ptws ON s.PasswordTypeWebScriptId = ptws.PasswordTypeWebScriptId
	LEFT JOIN tbSecretItem i ON i.SecretID = s.SecretID
		WHERE st.EnableHeartBeat = 1 AND (LastHeartBeatStatus = 0 OR LastHeartBeatStatus > 3) AND s.Active = 1  AND st.SecretTypeName LIKE '%Active Directory%'
	AND (pt.IsWeb = 0 OR (pt.IsWeb = 1 AND s.PasswordTypeWebScriptId IS NOT NULL AND ptws.Active = 1)) AND LEN(i.ItemValue) <= 40  
ORDER BY s.LastHeartBeatCheck DESC