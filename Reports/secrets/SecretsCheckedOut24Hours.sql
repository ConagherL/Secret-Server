SELECT DISTINCT
	s.SecretName
	,u.DisplayName AS 'User'
	,CASE s.RequireViewComment
		WHEN 1 THEN aud.Notes
		ELSE 'Comment not required' END AS 'Comment'
	,DATEDIFF(minute,s.CheckOutTime,GETUTCDATE())/60 AS 'Hours Elapsed' --avoid rounding to upper limit
	,CONVERT(VARCHAR(19),s.CheckOutTime) AS 'Checked Out'
	,CONVERT(VARCHAR(19),s.CheckOutEndTime) AS 'Check-In'
	,s.SecretId
FROM tbSecret s
JOIN tbUser u
ON s.CheckOutUserId = u.UserId
JOIN tbAuditSecret aud
ON s.SecretId = aud.SecretId
AND s.CheckOutUserId = aud.UserId
WHERE
	s.CheckOutEnabled = 1
	AND
	CAST(aud.DateRecorded AS smalldatetime) = CAST(s.CheckOutTime AS smalldatetime)
	AND
	aud.Action IN ('VIEW','WEBSERVICEVIEW')
	AND
	DATEDIFF(second,s.CheckOutEndTime,GETUTCDATE()) < 0 --Check Out period has not elapsed yet
	AND
	DATEDIFF(hour,s.CheckOutTime,GETUTCDATE()) >= 24 --True if number of hours checked out are eq to or exceed 24