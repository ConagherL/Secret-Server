SELECT s.SecretID AS [SecretId]
	, s.SecretName AS [Secret Name]
	, s.SecretPolicyId As [PolicyID]
    , tbSecretPolicy.SecretPolicyName AS [Policy Name]
	,(CASE [s].[EnableInheritSecretPolicy]       
          WHEN 1 THEN 'Parent folder'
		  WHEN 0 THEN 'Secret'   
		  END) AS [Policy Inheritance type]
	, tbSecretType.SecretTypeName AS [Template]
	, f.FolderPath AS [Folder Path]
	, si.SiteName As [Distributed Engine Site]
FROM tbSecret AS s INNER JOIN
	tbFolder AS f ON s.FolderId = f.FolderID 
	INNER JOIN
		tbSecretType ON s.SecretTypeID = tbSecretType.SecretTypeID
	LEFT JOIN
		tbSecretPolicy ON s.SecretPolicyId = tbSecretPolicy.SecretPolicyId
	LEFT JOIN 
		tbSite si ON si.SiteId = s.SiteId
WHERE s.Active = 1 
	AND s.SecretPolicyId not like 'NULL'
	--AND f.FolderPath LIKE '%' + #CUSTOMTEXT + '%'
ORDER BY
        [SecretId]
