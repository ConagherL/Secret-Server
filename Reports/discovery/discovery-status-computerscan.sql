/*
.PURPOSE
Results show the start and end time for Computer Scans (e.g. local accounts, dependencies)

NOTE: This is only usable for Secret Server, this data is not stored in the database for Secret Server Cloud
*/
SELECT csStart.[Partition], csStart.ComputerScanStarted, csEnd.ComputerScanEnded, DATEDIFF(second, csStart.ComputerScanStarted, csEnd.ComputerScanEnded) AS DurationSeconds
FROM (
    SELECT [Partition], MAX(CreatedOn) AS ComputerScanStarted
    FROM tbStatusMessage
    WHERE [ThreadName] = 'ComputerScanConsumer'
    AND [Text] = 'Discovery computer scanning started'
    GROUP BY [Partition]
) AS csStart
LEFT JOIN (
    SELECT [Partition], MAX(CreatedOn) AS ComputerScanEnded
    FROM tbStatusMessage
    WHERE [ThreadName] = 'ComputerScanConsumer'
    AND [Text] = 'Discovery computer scanning finished / queued for engine.'
    GROUP BY [Partition]
) AS csEnd ON csStart.[Partition] = csEnd.[Partition]