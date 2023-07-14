SELECT
  s.SecretName AS 'Secret Name',
  s.SecretId AS 'SecretId',
      CASE
        WHEN s.Active = 1 THEN 'Enabled'
        ELSE 'Not Enabled'
    END AS Status,
  s.EnableInheritSecretPolicy AS [Inheriting Policy],
  CASE
    WHEN sp.SecretPolicyId IS NULL THEN 'No Policy'
    ELSE sp.SecretPolicyName
  END AS 'Policy Name',
  s.AutoChangeOnExpiration AS 'Auto Change Status',
  (
    SELECT
      TOP 1 sa.DateRecorded
    FROM
      tbAuditSecret sa
    WHERE
      sa.Action IN ('CHANGE PASSWORD', 'Password Changed')
      AND sa.SecretId = s.SecretId
    ORDER BY
      sa.DateRecorded ASC
  ) AS [Initial PWD Change Date],
  s.LastRPCAttempt AS 'Last Password Change Time',
  s.RPCNextAttemptTime AS 'Next Password Change',
  s.LastSuccessfulPasswordChangeDate AS 'Last Successful Password Change',
  s.RPCAttemptCount AS 'Password Change Attempt Count',
  st.SecretTypeName AS 'Secret Template',
  CASE
    WHEN s.IsCustomExpiration = 1 THEN DATEADD(dd, s.CustomExpirationDays, s.ExpiredFieldChangedDate)
    ELSE DATEADD(dd, st.ExpirationDays, s.ExpiredFieldChangedDate)
  END AS 'Expiration Date',
  ISNULL(f.FolderPath, 'No Folder') AS 'Folder Path'
FROM
  tbSecret s WITH (NOLOCK)
  INNER JOIN tbSecretType st WITH (NOLOCK) ON st.SecretTypeId = s.SecretTypeId
  LEFT JOIN tbFolder f WITH (NOLOCK) ON s.FolderId = f.FolderId
  LEFT JOIN tbSecretPolicy sp WITH (NOLOCK) ON sp.SecretPolicyId = s.SecretPolicyId
WHERE
-----Remove the WHERE clause to grab every secret
	s.Active = 1
ORDER BY
  1, 2, 3, 4, 5, 6
