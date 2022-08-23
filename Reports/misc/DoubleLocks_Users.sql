SELECT
	 dl.Name AS [DoubleLock]
	,u.DisplayName AS [User]
	,dl.Created AS [Date Created]
FROM tbEncryptor en
JOIN tbUser u WITH (NOLOCK)
ON en.UserId = u.UserId
JOIN tbDoubleLock dl WITH (NOLOCK)
ON en.DoubleLockId = dl.DoubleLockId
WHERE dl.Active = 1