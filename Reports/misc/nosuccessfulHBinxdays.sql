SELECT

    [s].[SecretId],

    [s].[SecretName],

    [si].[ItemValue],

    (CASE [s].[LastHeartBeatStatus]

       WHEN 0 THEN 'Failed'

       WHEN 1 THEN 'Success'

       WHEN 2 THEN 'Pending'

       WHEN 3 THEN 'Disabled'

       WHEN 4 THEN 'UnableToConnect'

       WHEN 5 THEN 'UnknownError'

       WHEN 6 THEN 'IncompatibleHost'

       WHEN 7 THEN 'AccountLockedOut'

       WHEN 8 THEN 'DnsMismatch'

       WHEN 9 THEN 'UnableToValidateServerPublicKey'

       WHEN 10 THEN 'Processing'

    END) AS [Last Heartbeat Status],

    [s].[PasswordChangeFailed]

FROM [tbSecretItem] [si]

JOIN [tbSecretField] [sf] ON [si].[SecretFieldId] = [sf].[SecretFieldId]

JOIN [tbSecret] [s] ON [si].[SecretId] = [s].[SecretId]

WHERE

    (

        [sf].[SecretFieldName] = 'Domain'

        OR

        [sf].[SecretFieldName] = 'Server'

    )

    AND

    [si].[ItemValue] LIKE 'dev%'

    AND

    (

        [s].[LastHeartBeatStatus] <> 1

       OR

        [s].[PasswordChangeFailed] = 1

    )