SELECT 
	cd.AccountName 'Account Name', 
	c.ComputerName AS 'Server Name', 
	cd.DependencyName AS 'Service Name', 
	sdt.SecretDependencyTypeName AS 'Service Type'
FROM 
		tbComputer c
	JOIN 	tbComputerDependency cd 

	ON 
		cd.ComputerID = c.ComputerId
	JOIN 	tbSecretDependencyType sdt

	on 
		sdt.SecretDependencyTypeId = cd.SecretDependencyTypeID

WHERE 
		cd.AccountName = 'insert_username'