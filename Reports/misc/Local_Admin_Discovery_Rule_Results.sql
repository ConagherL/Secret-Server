SELECT
	c.ComputerName as [Computer],
	ca.AccountName as [Account],
	c.ComputerVersion as [OS],
	o.OrganizationUnitName as [Container],
	s.SecretName as [Secret],
	s.SecretID,
        s.Created as [Secret Created],
	a.Notes as [Rule Used],
	f.FolderPath as [Folder],
	c.LastPolledDate as [Last Scanned (UTC)]
FROM tbComputerAccount ca
	JOIN tbComputer c ON c.ComputerId = ca.ComputerId
	LEFT JOIN tbSecret s ON s.ComputerAccountId = ca.ComputerAccountId
	JOIN tbOrganizationUnit o ON o.OrganizationUnitId = c.OrganizationUnitId
	LEFT JOIN tbfolder f ON f.folderid = s.folderid
	LEFT JOIN tbAuditSecret a ON a.SecretId = s.SecretID 
WHERE
	a.Action = 'CREATE'
ORDER BY c.ComputerName