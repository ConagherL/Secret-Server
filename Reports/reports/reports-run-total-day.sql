/*
    .PURPOSE
    Total report executions per day
*/
SELECT
    FORMAT(CAST(ds.[RecordedDate] AS datetime2), 'MMMM') AS [RecordedMonth]
    , DAY(ds.[RecordedDate]) AS [Day]
    , SUM(ds.[Runs]) AS [Total Executions]
FROM (
    SELECT acr.[DateRecorded] AS [RecordedDate], 'Viewed' AS [Action], COUNT(*) AS [Runs]
    FROM tbCustomReport cr
    LEFT JOIN tbAuditCustomReport AS acr ON cr.[CustomReportId] = acr.[CustomReportId]
    WHERE acr.[DateRecorded] BETWEEN #STARTDATE AND #ENDDATE AND
        acr.[Action] IN ('VIEW','PREVIEW')
    GROUP BY acr.[DateRecorded]
    UNION ALL
    SELECT srh.[DateRun] AS [RecordedDate], 'Schedule' AS [Action], COUNT(*) AS [Runs]
    FROM tbCustomReport cr
    LEFT JOIN tbScheduledReport AS sr ON cr.[CustomReportId] = sr.[ReportId]
    LEFT JOIN tbScheduledReportHistory AS srh ON sr.[ScheduledReportId] = sr.[ScheduledReportId]
    WHERE srh.[DateRun] BETWEEN #STARTDATE AND #ENDDATE
    GROUP BY srh.[DateRun]
) AS ds
GROUP BY FORMAT(CAST(ds.[RecordedDate] AS datetime2), 'MMMM'), DAY(ds.[RecordedDate])
ORDER BY [RecordedMonth], [Day], [Total Executions]