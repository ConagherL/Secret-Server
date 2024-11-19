
SELECT DISTINCT f.FolderPath
,s.SecretName as 'Secret Name'
,l.Status as 'Status'
,l.Notes as 'Notes'
,MAX(DateRecorded) as 'Date Recorded'


FROM tbSecretLog l
	INNER JOIN tbSecret s
	ON l.SecretId = s.SecretID 
	INNER JOIN tbFolder f
	ON f.FolderID = s.FolderId

WHERE l.status <> 'Success' AND s.Active = 1 AND DateRecorded BETWEEN #STARTDATE AND #ENDDATE

GROUP BY f.FolderPath, s.SecretName,l.status, l.Notes   
ORDER BY f.FolderPath, s.SecretName,l.Status, l.Notes, [Date Recorded] ASC