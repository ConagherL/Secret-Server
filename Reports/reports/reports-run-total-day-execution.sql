/*
    .PURPOSE
    Total executions by day, by action (viewed or scheduled)
*/
SELECT
    FORMAT(CAST(ds.[RecordedDate] AS datetime2), 'MMMM') AS [RecordedMonth]
    , DAY(ds.[RecordedDate]) AS [Day]
    , COUNT(*) AS [Executions]
    , CASE
        WHEN ds.[Action] = 'PREVIEW' THEN 'Viewed'
        WHEN ds.[Action] = 'VIEW' THEN 'Viewed'
        WHEN ds.[Action] = 'Schedule' THEN 'Scheduled'
    END [ReportAction]
FROM (
    SELECT cr.[CustomReportId], cr.[Name] AS [ReportName], acr.[Action], acr.[DateRecorded] AS [RecordedDate]
    FROM tbCustomReport cr
    LEFT JOIN tbAuditCustomReport AS acr ON cr.[CustomReportId] = acr.[CustomReportId]
    WHERE acr.[DateRecorded] BETWEEN #STARTDATE AND #ENDDATE AND
        acr.[Action] IN ('VIEW','PREVIEW')
    UNION ALL
    SELECT cr.[CustomReportId], cr.[Name] AS [ReportName], 'Schedule' AS [Action], srh.[DateRun] AS [RecordedDate]
    FROM tbCustomReport cr
    LEFT JOIN tbScheduledReport AS sr ON cr.[CustomReportId] = sr.[ReportId]
    LEFT JOIN tbScheduledReportHistory AS srh ON sr.[ScheduledReportId] = sr.[ScheduledReportId]
    WHERE srh.[DateRun] BETWEEN #STARTDATE AND #ENDDATE
) AS ds
GROUP BY FORMAT(CAST(ds.[RecordedDate] AS datetime2), 'MMMM'), DAY(ds.[RecordedDate]), ds.[Action]
ORDER BY [RecordedMonth], [Day], [Executions]