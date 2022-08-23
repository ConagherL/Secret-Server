/*
.PURPOSE
Group Errors by count on unsuccessful scans, by Computer Name with filter on start and end date
*/
SELECT
    csl.[Status]
    ,csl.[ComputerName]
    ,COUNT(*) AS [ErrorCount]
FROM tbComputerScanLog AS csl
INNER JOIN tbComputer c ON csl.ComputerId = c.ComputerId
WHERE csl.[Success] = 0
    AND csl.[ScanDate] BETWEEN #STARTDATE AND #ENDDATE
GROUP BY csl.[ComputerName], csl.[Status]