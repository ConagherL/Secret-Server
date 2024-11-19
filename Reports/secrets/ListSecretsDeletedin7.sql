SELECT
	s.SecretName AS [Secret name]
	,aud.DateRecorded AS [Date/Time of deletion]
	,aud.SecretId
FROM
	tbAuditSecret aud
JOIN
	tbSecret s WITH (NOLOCK)
	ON
	aud.SecretId = s.SecretId
WHERE
	aud.Action = 'DELETE'
	AND
	aud.DateRecorded >= (GETDATE() - 7)
ORDER BY
	aud.DateRecorded DESC