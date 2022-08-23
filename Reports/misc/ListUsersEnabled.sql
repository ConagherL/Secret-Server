SELECT
	UserName AS [Username]
	,DisplayName AS [Name]
	,Created
FROM
	tbUser
WHERE
	Enabled = 1