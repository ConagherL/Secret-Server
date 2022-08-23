SELECT
	si.SecretID AS [Secret ID]
	,s.SecretName AS [Secret Name]
	,sf.SecretFieldName AS [Secret Field]
	,si.ItemValue AS [Field Value]
FROM
	tbSecretItem si
INNER JOIN
	tbSecretField sf
ON
	si.SecretFieldID = sf.SecretFieldID
INNER JOIN
	tbSecret s
ON
	si.SecretID = s.SecretID
WHERE
	sf.IsPassword = '1'