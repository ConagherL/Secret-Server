SELECT  SecretName, COUNT(SecretName) as [Total]
FROM tbSecret  
WHERE Active = 1
GROUP by SecretName
Having COUNT(SecretName) > 1
