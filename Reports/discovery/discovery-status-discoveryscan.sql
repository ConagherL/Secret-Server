/*
.PURPOSE
Results show the start and end time for Discovery Scans

NOTE: This is only usable for Secret Server, this data is not stored in the database for Secret Server Cloud
*/
SELECT csStart.[Partition], csStart.DiscoveryScanStarted, csEnd.DiscoveryScanEnded, DATEDIFF(second, csStart.DiscoveryScanStarted, csEnd.DiscoveryScanEnded) AS DurationSeconds
FROM (
    SELECT [Partition], MAX(CreatedOn) AS DiscoveryScanStarted
    FROM tbStatusMessage
    WHERE [ThreadName] = 'DiscoveryConsumer'
    AND [Text] = 'Discovery started'
    GROUP BY [Partition]
) AS csStart
LEFT JOIN (
    SELECT [Partition], MAX(CreatedOn) AS DiscoveryScanEnded
    FROM tbStatusMessage
    WHERE [ThreadName] = 'DiscoveryConsumer'
    AND [Text] = 'Discovery queued to engine / local finished.'
    GROUP BY [Partition]
) AS csEnd ON csStart.[Partition] = csEnd.[Partition]