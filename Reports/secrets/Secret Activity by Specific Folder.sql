Secret Activity by Specific Folder Report:
a.	Locate the targeted FolderID:
SELECT FolderID, FolderName
FROM tbFolder
b.	Locate the OrganizationID:
SELECT USERNAME, OrganizationId
FROM tbUser
c.	Update the following statement with the Targeted ‘FolderID’ and ‘OrganizationID’
SELECT 
          a.DateRecorded AS [Date Recorded],
          upn.displayname AS [User],
          ISNULL(f.FolderPath, N'No folder assigned') as [Folder Path],
          s.secretname As [Secret Name],
          a.Action,
          a.Notes,
          a.ipaddress AS [IP Address]
   FROM tbauditsecret a WITH (NOLOCK)
   INNER JOIN tbuser u WITH (NOLOCK)
          ON u.userid = a.userid
          AND u.OrganizationId = 1
   INNER JOIN vUserDisplayName upn WITH (NOLOCK)
          ON u.UserId = upn.UserId
   INNER JOIN tbsecret s WITH (NOLOCK)
          ON s.secretid = a.secretid 
   LEFT JOIN tbFolder f WITH (NOLOCK)
          ON s.FolderId = f.FolderId
   WHERE 
          s.FolderId = 3
          AND
          a.DateRecorded >= #StartDate
          AND
          a.DateRecorded <= #EndDate 
   ORDER BY 
          1 DESC,2, 3,4,5,6,7
d.	Add the SQL Query to the saved report.