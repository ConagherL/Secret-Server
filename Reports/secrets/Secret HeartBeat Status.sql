--Report is based of chart (doughnut)


SELECT 'Success' as 'HeartbeatStatus', count(1) as 'Total'
FROM tbSecret s
	INNER JOIN tbSecretType st on s.SecretTypeID = st.SecretTypeID
	LEFT JOIN tbPasswordType pt ON st.PasswordTypeId = pt.PasswordTypeId
	LEFT JOIN tbPasswordTypeWebScript ptws ON s.PasswordTypeWebScriptId = ptws.PasswordTypeWebScriptId
	WHERE st.EnableHeartBeat = 1 AND LastHeartBeatStatus = 1 AND s.Active = 1
	AND (pt.IsWeb = 0 OR (pt.IsWeb = 1 AND s.PasswordTypeWebScriptId IS NOT NULL AND ptws.Active = 1))

UNION 

SELECT 'Pending' as 'HeartbeatStatus', count(1) as 'Total'
FROM tbSecret s
	INNER JOIN tbSecretType st on s.SecretTypeID = st.SecretTypeID
	LEFT JOIN tbPasswordType pt ON st.PasswordTypeId = pt.PasswordTypeId
	LEFT JOIN tbPasswordTypeWebScript ptws ON s.PasswordTypeWebScriptId = ptws.PasswordTypeWebScriptId
	WHERE st.EnableHeartBeat = 1 AND LastHeartBeatStatus = 2 AND s.Active = 1
	AND (pt.IsWeb = 0 OR (pt.IsWeb = 1 AND s.PasswordTypeWebScriptId IS NOT NULL AND ptws.Active = 1))

UNION 

SELECT 'Failed' as 'HeartbeatStatus', count(1) as 'Total'
FROM tbSecret s
	INNER JOIN tbSecretType st on s.SecretTypeID = st.SecretTypeID
	LEFT JOIN tbPasswordType pt ON st.PasswordTypeId = pt.PasswordTypeId
	LEFT JOIN tbPasswordTypeWebScript ptws ON s.PasswordTypeWebScriptId = ptws.PasswordTypeWebScriptId
	WHERE st.EnableHeartBeat = 1 AND LastHeartBeatStatus = 0 AND s.Active = 1
	AND (pt.IsWeb = 0 OR (pt.IsWeb = 1 AND s.PasswordTypeWebScriptId IS NOT NULL AND ptws.Active = 1))


UNION 

SELECT 'Heartbeat not enabled, has Check Out' as 'HeartbeatStatus', count(1) as 'Total'
FROM tbSecret s
	INNER JOIN tbSecretType st on s.SecretTypeID = st.SecretTypeID
	LEFT JOIN tbPasswordType pt ON st.PasswordTypeId = pt.PasswordTypeId
	LEFT JOIN tbPasswordTypeWebScript ptws ON s.PasswordTypeWebScriptId = ptws.PasswordTypeWebScriptId
	WHERE st.EnableHeartBeat = 1 AND LastHeartBeatStatus = 3 AND s.Active = 1
	AND (pt.IsWeb = 0 OR (pt.IsWeb = 1 AND s.PasswordTypeWebScriptId IS NOT NULL AND ptws.Active = 1))

UNION 

SELECT 'Unable To Connect' as 'HeartbeatStatus', count(1) as 'Total'
FROM tbSecret s
	INNER JOIN tbSecretType st on s.SecretTypeID = st.SecretTypeID
	LEFT JOIN tbPasswordType pt ON st.PasswordTypeId = pt.PasswordTypeId
	LEFT JOIN tbPasswordTypeWebScript ptws ON s.PasswordTypeWebScriptId = ptws.PasswordTypeWebScriptId
	WHERE st.EnableHeartBeat = 1 AND LastHeartBeatStatus = 4 AND s.Active = 1
	AND (pt.IsWeb = 0 OR (pt.IsWeb = 1 AND s.PasswordTypeWebScriptId IS NOT NULL AND ptws.Active = 1))

UNION 

SELECT 'Unknown Error' as 'HeartbeatStatus', count(1) as 'Total'
FROM tbSecret s
	INNER JOIN tbSecretType st on s.SecretTypeID = st.SecretTypeID
	LEFT JOIN tbPasswordType pt ON st.PasswordTypeId = pt.PasswordTypeId
	LEFT JOIN tbPasswordTypeWebScript ptws ON s.PasswordTypeWebScriptId = ptws.PasswordTypeWebScriptId
	WHERE st.EnableHeartBeat = 1 AND LastHeartBeatStatus = 5 AND s.Active = 1
	AND (pt.IsWeb = 0 OR (pt.IsWeb = 1 AND s.PasswordTypeWebScriptId IS NOT NULL AND ptws.Active = 1))

UNION 

SELECT 'Incompatible Host' as 'HeartbeatStatus', count(1) as 'Total'
FROM tbSecret s
	INNER JOIN tbSecretType st on s.SecretTypeID = st.SecretTypeID
	LEFT JOIN tbPasswordType pt ON st.PasswordTypeId = pt.PasswordTypeId
	LEFT JOIN tbPasswordTypeWebScript ptws ON s.PasswordTypeWebScriptId = ptws.PasswordTypeWebScriptId
	WHERE st.EnableHeartBeat = 1 AND LastHeartBeatStatus = 6 AND s.Active = 1
	AND (pt.IsWeb = 0 OR (pt.IsWeb = 1 AND s.PasswordTypeWebScriptId IS NOT NULL AND ptws.Active = 1))

UNION 

SELECT 'Locked Out' as 'HeartbeatStatus', count(1) as 'Total'
FROM tbSecret s
	INNER JOIN tbSecretType st on s.SecretTypeID = st.SecretTypeID
	LEFT JOIN tbPasswordType pt ON st.PasswordTypeId = pt.PasswordTypeId
	LEFT JOIN tbPasswordTypeWebScript ptws ON s.PasswordTypeWebScriptId = ptws.PasswordTypeWebScriptId
	WHERE st.EnableHeartBeat = 1 AND LastHeartBeatStatus = 7 AND s.Active = 1
	AND (pt.IsWeb = 0 OR (pt.IsWeb = 1 AND s.PasswordTypeWebScriptId IS NOT NULL AND ptws.Active = 1))

UNION 

SELECT 'DNS Mismatch' as 'HeartbeatStatus', count(1) as 'Total'
FROM tbSecret s
	INNER JOIN tbSecretType st on s.SecretTypeID = st.SecretTypeID
	LEFT JOIN tbPasswordType pt ON st.PasswordTypeId = pt.PasswordTypeId
	LEFT JOIN tbPasswordTypeWebScript ptws ON s.PasswordTypeWebScriptId = ptws.PasswordTypeWebScriptId
	WHERE st.EnableHeartBeat = 1 AND LastHeartBeatStatus = 8 AND s.Active = 1
	AND (pt.IsWeb = 0 OR (pt.IsWeb = 1 AND s.PasswordTypeWebScriptId IS NOT NULL AND ptws.Active = 1))

UNION 

SELECT 'UnableToValidateServerPublicKey' as 'HeartbeatStatus', count(1) as 'Total'
FROM tbSecret s
	INNER JOIN tbSecretType st on s.SecretTypeID = st.SecretTypeID
	LEFT JOIN tbPasswordType pt ON st.PasswordTypeId = pt.PasswordTypeId
	LEFT JOIN tbPasswordTypeWebScript ptws ON s.PasswordTypeWebScriptId = ptws.PasswordTypeWebScriptId
	WHERE st.EnableHeartBeat = 1 AND LastHeartBeatStatus = 9 AND s.Active = 1
	AND (pt.IsWeb = 0 OR (pt.IsWeb = 1 AND s.PasswordTypeWebScriptId IS NOT NULL AND ptws.Active = 1))

UNION 

SELECT 'Processing' as 'HeartbeatStatus', count(1) as 'Total'
FROM tbSecret s
	INNER JOIN tbSecretType st on s.SecretTypeID = st.SecretTypeID
	LEFT JOIN tbPasswordType pt ON st.PasswordTypeId = pt.PasswordTypeId
	LEFT JOIN tbPasswordTypeWebScript ptws ON s.PasswordTypeWebScriptId = ptws.PasswordTypeWebScriptId
	WHERE st.EnableHeartBeat = 1 AND LastHeartBeatStatus = 10 AND s.Active = 1
	AND (pt.IsWeb = 0 OR (pt.IsWeb = 1 AND s.PasswordTypeWebScriptId IS NOT NULL AND ptws.Active = 1))

UNION 

SELECT 'ArgumentError' as 'HeartbeatStatus', count(1) as 'Total'
FROM tbSecret s
	INNER JOIN tbSecretType st on s.SecretTypeID = st.SecretTypeID
	LEFT JOIN tbPasswordType pt ON st.PasswordTypeId = pt.PasswordTypeId
	LEFT JOIN tbPasswordTypeWebScript ptws ON s.PasswordTypeWebScriptId = ptws.PasswordTypeWebScriptId
	WHERE st.EnableHeartBeat = 1 AND LastHeartBeatStatus = 11 AND s.Active = 1
	AND (pt.IsWeb = 0 OR (pt.IsWeb = 1 AND s.PasswordTypeWebScriptId IS NOT NULL AND ptws.Active = 1))

UNION 

SELECT 'AccessDenied' as 'HeartbeatStatus', count(1) as 'Total'
FROM tbSecret s
	INNER JOIN tbSecretType st on s.SecretTypeID = st.SecretTypeID
	LEFT JOIN tbPasswordType pt ON st.PasswordTypeId = pt.PasswordTypeId
	LEFT JOIN tbPasswordTypeWebScript ptws ON s.PasswordTypeWebScriptId = ptws.PasswordTypeWebScriptId
	WHERE st.EnableHeartBeat = 1 AND LastHeartBeatStatus = 12 AND s.Active = 1
	AND (pt.IsWeb = 0 OR (pt.IsWeb = 1 AND s.PasswordTypeWebScriptId IS NOT NULL AND ptws.Active = 1))

UNION 

SELECT 'Other' as 'HeartbeatStatus', count(1) as 'Total'
FROM tbSecret s
	INNER JOIN tbSecretType st on s.SecretTypeID = st.SecretTypeID
	LEFT JOIN tbPasswordType pt ON st.PasswordTypeId = pt.PasswordTypeId
	LEFT JOIN tbPasswordTypeWebScript ptws ON s.PasswordTypeWebScriptId = ptws.PasswordTypeWebScriptId
	WHERE st.EnableHeartBeat = 1 AND LastHeartBeatStatus > 12 AND s.Active = 1
	AND (pt.IsWeb = 0 OR (pt.IsWeb = 1 AND s.PasswordTypeWebScriptId IS NOT NULL AND ptws.Active = 1))
