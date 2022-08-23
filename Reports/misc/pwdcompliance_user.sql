SELECT
	s.SecretID,
	s.SecretName,
	udn.DisplayName AS [Created By],
	[as].DateRecorded AS [Created On]
FROM
	tbSecret s
JOIN
	tbAuditSecret [as]
	ON	[as].SecretId = s.SecretID
JOIN
	vUserDisplayName udn
	ON	udn.UserId = [as].UserId
WHERE
	[as].[Action] = 'CREATE';