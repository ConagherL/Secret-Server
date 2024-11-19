SELECT f.FolderName 
,DATEPART(month, s.Created) AS 'Month'
,DATEPART(year, s.Created) AS 'Year'
,Count(s.SecretID) AS 'Total Secrets'
from tbSecret S
INNER JOIN tbFolder f
ON F.FolderID = S.FolderId
GROUP BY f.FolderName, DATEPART(month, s.Created), DATEPART(year, s.Created)
Order by 'Month', 'Year', f.FolderName ASC