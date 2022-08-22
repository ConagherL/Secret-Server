SELECT DISTINCT
	a.DateRecorded as [Date],
	u.DisplayName as [Display Name],
	a.Action as [Event],
	st.SecretTypeName as [Template],
	a.ItemId as [Template ID]

FROM tbAudit a
INNER JOIN tbUser u on a.UserId = u.UserId
INNER JOIN tbSecretType st on a.ItemId = st.SecretTypeID

WHERE
st.Active = 1
AND
(a.AuditTypeID = 3 AND a.Action LIKE '%EATE')

ORDER BY Date DESC
