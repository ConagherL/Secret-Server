/* Change date range as required. */

SELECT    S2.SecretID,
        R.[Action],
        S2.Active,
        S2.SecretName
 from tbSecret S2 LEFT JOIN (
SELECT [AuditSecretId]
      ,S.[SecretId]
      ,[DateRecorded]
      ,[Action]
  FROM [SecretServer].[dbo].[tbAuditSecret] as A INNER JOIN tbSecret as S on S.SecretID = A.SecretId WHERE A.[Action] = 'VIEW' AND  S.Active = 1 AND A.DateRecorded BETWEEN '2019/01/15' AND '2019/01/16'
  ) R on S2.SecretID = R.SecretID WHERE R.[Action] IS NULL AND S2.Active = 1 ORDER BY S2.SecretID ASC