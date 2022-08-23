SELECT
  CASE WHEN st.ExpirationFieldId IS NULL THEN
null
                ELSE
                    CASE s.IsCustomExpiration WHEN 1 THEN
                            DATEDIFF (minute, GETDATE(), DATEADD(day, s.CustomExpirationDays, s.ExpiredFieldChangedDate)) / 1440
                        ELSE
                            DATEDIFF (minute, GETDATE(), DATEADD(day, st.ExpirationDays, s.ExpiredFieldChangedDate)) / 1440
                    END
                END AS 
'ExpirationDays'  
FROM tbSecret s
INNER JOIN
	tbSecretType st
	ON
	s.SecretTypeID = st.SecretTypeID