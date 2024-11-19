/*
    .PURPOSE
    Report runs by date range.
        Previewed   = Chart and SQL Editor used to run query from UI
        Viewed      = Basic Report run from UI
        Scheduled   = Scheduled Report execution
*/
SELECT *
FROM
(
    SELECT ds.[CustomReportId] AS [PivotId]
        ,ds.[ReportName]
        , CASE
            WHEN ds.[Action] = 'PREVIEW' THEN 'Previewed'
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
) reports
PIVOT
(
    COUNT(PivotId)
    FOR [ReportAction] IN ([Previewed], [Viewed], [Scheduled])
) AS [ds]
WHERE Previewed > 0 OR Viewed > 0 OR Scheduled > 0
ORDER By ReportName