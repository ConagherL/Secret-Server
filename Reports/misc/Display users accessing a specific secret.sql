select a.DateRecorded AS [Latetest Date Recorded], 
u.DisplayName AS [User] ,
a.Action AS [Type of Acess], 
a.Notes AS [Notes], 
a.IpAddress AS [IP Address]

From   tbAuditSecret a WITH (NOLOCK)
       join tbSecret s WITH (NOLOCK) ON a.SecretId = s.SecretId
       join tbUser u WITH (NOLOCK) On u.UserId = a.UserId

Where s.SecretName = 'INPUT_SECRETNAME_HERE'
		AND a.DateRecorded >= #STARTDATE
		AND	a.DateRecorded <= #ENDDATE
		AND a.Action = 'view' /*This will only show Secrets that have been viewed. To show all delete this line*/
		order by 1 DESC, 2, 3, 4, 5