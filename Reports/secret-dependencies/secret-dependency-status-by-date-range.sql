/*
.PURPOSE
Modified version of Secret Dependency Status report, adding date range filter
*/
SELECT *
FROM
(
    SELECT
        sdg.SecretDependencyGroupId as [PivotId]
        , se.SecretId
        , se.SecretName
        , sdg.Name as 'DependencyGroup'
        , s.SiteName
        , CASE
            WHEN SD.Active = 1 AND sd.SecretDependencyStatus = 1 THEN 'Success'
            WHEN SD.Active = 1 AND sd.SecretDependencyStatus = 0 THEN 'Failed'
            WHEN SD.Active = 1 AND sd.SecretDependencyStatus IS NULL THEN 'NotRun'
            ELSE 'NoDependencies'
        END status
    FROM tbSecretDependencyGroup sdg
    LEFT OUTER JOIN tbSite s ON  sdg.SiteId = s.SiteId
    LEFT OUTER JOIN tbSecretDependency sd ON sdg.SecretDependencyGroupId = sd.SecretDependencyGroupId
    LEFT JOIN tbDependencyLog AS dl ON sd.SecretDependencyId = dl.SecretDependencyId
    INNER JOIN tbSecret se on se.SecretId = sdg.SecretId
    WHERE dl.DateRecorded BETWEEN #STARTDATE AND #ENDDATE
        AND dl.Success IS NOT NULL
) groups
PIVOT
(
    COUNT(PivotId)
    FOR status IN ([Success], [Failed], [NotRun])
) as ds
WHERE Success > 0 OR Failed > 0 OR NotRun > 0
ORDER By SecretName