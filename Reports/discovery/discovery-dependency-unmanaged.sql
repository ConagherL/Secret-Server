/*
.PURPOSE
Get list of dependencies found during discovery scanning that are not managed
*/
SELECT
    comp.ComputerId
    ,cd.AccountName
    ,cd.DependencyName
    ,comp.ComputerName
    ,comp.ComputerId
    ,comp.LastErrorMessage
    ,comp.DistinguishedName
FROM tbComputer comp
JOIN tbComputerDependency cd ON comp.ComputerId = cd.ComputerId
WHERE comp.LastErrorMessage is NULL AND cd.SecretId is NULL