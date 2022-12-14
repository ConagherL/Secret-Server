SELECT	a.SecretId, 
		s.SecretName, 
		u.UserName AS [Created By], 
		a.[Action], 
		a.Notes
FROM	tbAuditSecret AS a WITH (NOLOCK)
		INNER JOIN	(
						SELECT	SecretId, 
								MIN(DateRecorded) AS DateRecorded
						FROM	tbAuditSecret WITH (NOLOCK)
						WHERE	[Action] IN ('CREATE', 'SECRET COPIED FROM')
						GROUP BY SecretId
					) AS a_first ON a.SecretId = a_first.SecretId 
						AND a.DateRecorded = a_first.DateRecorded 
		INNER JOIN tbUser AS u WITH (NOLOCK) ON a.UserId = u.UserId 
		INNER JOIN tbSecret AS s WITH (NOLOCK) ON a.SecretId = s.SecretID
			AND u.OrganizationId = #Organization
ORDER BY 1,2,3,4


