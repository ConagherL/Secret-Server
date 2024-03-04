SELECT
	ds.Name AS 'Discovery Source'
	,ca.AccountName AS 'Account Name'
	,ou.Path AS 'AD Path'
	,
CASE
    WHEN s.SecretID IS NOT NULL THEN 'Managed'
    WHEN s.SecretID IS NULL THEN 'NOT MANAGED'
    END as 'Managed'
	,s.SecretName
	,f.FolderPath AS 'Folder'
	,st.SecretTypeName AS 'Secret Type'
	,s.LastHeartBeatCheck
	,

CASE
    WHEN s.LastHeartBeatStatus = 0 THEN 'Failed'
	WHEN s.LastHeartBeatStatus = 1 THEN 'Success'
	WHEN s.LastHeartBeatStatus = 4 THEN 'UnableToConnect'
	WHEN s.LastHeartBeatStatus = 5 THEN 'UnknownError'
	WHEN s.LastHeartBeatStatus = 6 THEN 'IncompatibleHost'
	WHEN s.LastHeartBeatStatus = 7 THEN 'AccountLockedOut'
	WHEN s.LastHeartBeatStatus = 8 THEN 'DnsMismatch'
	WHEN s.LastHeartBeatStatus = 9 THEN 'UnableToValidateServerPublicKey'
	WHEN s.LastHeartBeatStatus = 10 THEN 'Processing'
	WHEN s.LastHeartBeatStatus = 11 THEN 'ArgumentError'
	WHEN s.LastHeartBeatStatus = 12 THEN 'AccessDenied'
	ELSE 'Failed Unknown'
	END as "HeartbeatStatus"

FROM tbComputerAccount ca
	INNER JOIN tbDiscoverySource ds on ca.DiscoverySourceId = ds.DiscoverySourceId
	LEFT JOIN tbDomain d ON d.DomainId = ds.DomainId
	LEFT JOIN tbOrganizationUnit ou ON ou.OrganizationUnitId = ca.OrganizationUnitId
	FULL JOIN tbSecret s ON s.ComputerAccountId = ca.ComputerAccountId
	LEFT JOIN tbSecretType st ON st.SecretTypeId = s.SecretTypeId
	FULL JOIN tbFolder f ON s.FolderId = f.FolderID
	 
WHERE ca.computerID is null AND (s.Active = 1 OR s.SecretID IS NULL)

GROUP BY ds.Name, ou.Path, ca.AccountName, s.SecretName, f.FolderPath, s.SecretID,s.LastHeartBeatCheck,s.LastHeartBeatStatus,st.SecretTypeName, ca.IsLocalAdministrator, ca.HasLocalAdminRights
	HAVING COUNT(ca.AccountName) > 0
ORDER BY
	1,2,3 ASC
