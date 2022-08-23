/*
.PURPOSE
List unmanaged Dependencies computer details, with found and last poll date
*/
SELECT
    comp.[ComputerId]
    ,ca.[CreatedDate]
    ,ca.[AccountName]
    ,comp.[ComputerName]
    ,comp.[ComputerVersion]
    ,comp.[FoundDate]
    ,comp.[LastPolledDate]
    ,comp.[LastErrorMessage]
    ,comp.[DistinguishedName]
FROM tbComputerAccount AS ca
INNER JOIN tbComputer AS comp ON ca.[ComputerId] = comp.[ComputerId]
LEFT OUTER JOIN tbSecret AS sec ON ca.[ComputerAccountId] = sec.[ComputerAccountId]
WHERE sec.[SecretID] IS NULL