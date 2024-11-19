SELECT
	s.SecretName AS [Secret name]
	,st.SecretTypeName AS [Secret type]
	,s.Created AS [Date/Time created]
	,s.SecretID
FROM
	tbSecret s
JOIN
	tbSecretType st WITH (NOLOCK)
	ON
	s.SecretTypeId = st.SecretTypeId
WHERE
	s.Created >= (GETDATE() - 7)
ORDER BY 
	s.Created DESC