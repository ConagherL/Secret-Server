/*
.PURPOSE
Group Errors by count on unsuccessful scans, with filter for start and enddate
*/
SELECT
    csl.[Status]
    ,c.[ComputerName]
    ,COUNT(*) AS [ErrorCount]
FROM tbComputerScanLog AS csl
INNER JOIN tbComputer c ON csl.ComputerId = c.ComputerId
WHERE csl.[Success] = 0
    AND csl.[ScanDate] BETWEEN #STARTDATE AND #ENDDATE
GROUP BY c.[ComputerName], csl.[Status]