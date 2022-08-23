SELECT
	*
FROM
(
	SELECT
		s.SecretName,
		sf.SecretFieldName,
		si.ItemValue,
		CASE WHEN st.ExpirationFieldId IS NULL
		THEN
			null
			ELSE
				CASE s.IsCustomExpiration WHEN 1
				THEN
					DATEDIFF (minute, GETDATE(), DATEADD(day, s.CustomExpirationDays, s.ExpiredFieldChangedDate)) / 1440
                ELSE
					DATEDIFF (minute, GETDATE(), DATEADD(day, st.ExpirationDays, s.ExpiredFieldChangedDate)) / 1440
            END
        END AS 'ExpirationDays'
	FROM
		tbSecret s
	JOIN
		tbSecretItem si
		ON	si.SecretID = s.SecretID
	JOIN
		tbSecretField sf
		ON	sf.SecretFieldID = si.SecretFieldID
	JOIN
		tbSecretType st
		ON	s.SecretTypeID = st.SecretTypeID
	WHERE
		s.SecretTypeID = 6043
) secrets
PIVOT (
	MAX(ItemValue) FOR SecretFieldName IN ([Status], [Could be used on CCA listed device], [Notes])
 )
 a
 WHERE [ExpirationDays] < 30