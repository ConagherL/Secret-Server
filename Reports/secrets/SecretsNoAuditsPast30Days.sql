SELECT DISTINCT
	s.SecretName AS 'Secret Name'
	,MAX(aud.DateRecorded) OVER (PARTITION BY aud.SecretID) AS 'Last Activity'
	,s.SecretID
FROM tbSecret s
JOIN tbAuditSecret aud
ON s.SecretId = aud.SecretId
LEFT OUTER JOIN tbAuditSecret aud2
ON aud.DateRecorded = aud2.DateRecorded
AND aud2.DateRecorded >= (GETDATE() - 30)
WHERE aud2.DateRecorded IS NULL
ORDER BY 2 DESC