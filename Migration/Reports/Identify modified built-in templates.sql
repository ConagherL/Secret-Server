SELECT
	a.DateRecorded as [Date],
	a.ItemId as [Template ID],
	a.Action as [Event],
	st.SecretTypeName as [Template],
	a.Notes as [Notes]

FROM tbAudit a
INNER JOIN tbUser u on a.UserId = u.UserId
INNER JOIN tbSecretType st on a.ItemId = st.SecretTypeID

WHERE 
(st.Active = 1 AND a.AuditTypeId = 3 AND a.Notes LIKE 'Field%')
AND
NOT EXISTS (
SELECT b.Action
FROM
	 tbAudit b
WHERE b.itemid = a.itemid AND b.Action LIKE '%EATE')

ORDER BY "Template ID" ASC
