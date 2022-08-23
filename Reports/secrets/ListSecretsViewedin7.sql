SELECT
	s.SecretName AS [Secret name]
	,aud.DateRecorded AS [Date/Time viewed]
	,aud.SecretId
FROM
	tbAuditSecret aud
JOIN
	tbSecret s WITH (NOLOCK)
	ON
	aud.SecretId = s.SecretId
WHERE
	aud.Action = 'VIEW'
	AND
	aud.DateRecorded >= (GETDATE() - 7)
ORDER BY
	aud.DateRecorded DESC