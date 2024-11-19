SELECT DISTINCT
	ISNULL(fp.FolderPath, N'No folder assigned') AS [Folder Path],
	tbSecret.SecretName AS [Secret Name],
	st.SecretTypeName AS [Secret Template],
	ISNULL(cpr.Name, pr.Name) AS [Password Requirement],
	CASE
		WHEN PasswordComplianceCode = 0 THEN 'Pending'
		WHEN PasswordComplianceCode = 1 THEN 'Yes'
		WHEN PasswordComplianceCode = 2 THEN 'No'
	END AS [Meets Compliance]
	,CASE gsp.[Inherit Permissions]
		WHEN 'No' THEN 'Secret'
		WHEN 'Yes' THEN	(CASE f.EnableInheritPermissions
			WHEN NULL THEN 'Folder'
			WHEN 1 THEN 'A Parent Folder'
			WHEN 0 THEN 'Folder'
		END)
	END AS [Permissions On],
	(select udn.DisplayName
		FROM tbSecret xx
		JOIN
			tbAuditSecret [as]
			ON [as].SecretId = xx.SecretID
		JOIN
			vUserDisplayName udn
			ON udn.UserId = [as].UserId
		WHERE
			[as].[Action] = 'CREATE'
			AND xx.SecretID = tbSecret.SecretID) AS 'Created By'
FROM
	tbSecret (NOLOCK)
INNER JOIN
	tbGroupSecretPermission sgp WITH (NOLOCK)
	ON tbSecret.SecretId = sgp.SecretId
	AND sgp.PermissionID = 3
INNER JOIN
	tbSecretType st
	ON tbSecret.SecretTypeId = st.SecretTypeId
INNER JOIN
	tbSecretField sf
	ON st.SecretTypeID = sf.SecretTypeID
INNER JOIN
	tbPasswordRequirement pr
	ON sf.PasswordRequirementId = pr.PasswordRequirementId
LEFT JOIN
	tbSecretItem si
	ON si.SecretFieldID = sf.SecretFieldID
	AND si.SecretID = tbsecret.secretid
LEFT JOIN
	tbPasswordRequirement cpr
	ON si.CustomPasswordRequirementId = cpr.PasswordRequirementId
LEFT JOIN
	vFolderPath fp WITH (NOLOCK)
	ON tbSecret.FolderId = fp.FolderId
LEFT JOIN
	tbFolder f WITH (NOLOCK)
	ON tbSecret.FolderId = f.FolderId
INNER JOIN
	vGroupSecretPermissions gsp
	ON sgp.GroupId = gsp.GroupId
	AND tbSecret.SecretID = gsp.SecretId
WHERE
	st.Organizationid = 1
	AND tbSecret.Active = 1
	AND sf.IsPassword = 1
	AND sf.Active = 1
ORDER BY 5