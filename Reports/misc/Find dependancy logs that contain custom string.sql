SELECT TOP 50 u.DateRecorded as 'Date',u.SecretDependencyId as 'Dependancy ID', s.SecretId as 'Secret ID', x.SecretDependencyTypename as 'Dependancy Name', t.SecretName as 'Secret Name', s.MachineName as 'Machine', s.ServiceName as 'Service Name', u.LogMessage as 'Message log' FROM tbDependencyLog u
inner join tbSecretDependency s on s.SecretDependencyId = u.SecretDependencyId
inner join tbsecret t on t.secretID = s.SecretId
inner join tbSecretDependencytype x on x.SecretDependencyTypeId = s.SecretDependencyTypeId
WHERE  u.LogMessage like '%' + #CUSTOMTEXT + '%'
ORDER BY DateRecorded DESC