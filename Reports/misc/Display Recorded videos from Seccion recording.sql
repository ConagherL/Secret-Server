SELECT
	s.SecretName AS 'Secret Name', 
	aud.DateRecorded AS 'Time and Date' ,
	aud.SecretId AS 'Secret ID' ,
	aud.AuditSecretId AS 'Audit ID',
	aud.Notes AS 'Launcher Type' ,
	ls.Duration ,
	ls.FileSize AS 'Size',
Case 
	When 
		ls.ErrorMessage is NULL Then 'No errors where found'
	Else 
		ls.ErrorMessage
	end AS 
		'Error Message' ,
case 
	when 
		ls.IsArchived = 1 then 'Yes' 
	else 
		'No' 
	end AS 
		'Archived' ,
Case 
	When 
		ls.IsDeleted = 1 then 'Yes'
	Else 
		'No'
	End AS 
		'Deleted'


FROM
	tbAuditSecret aud
	JOIN tbLauncherSession ls
ON 
	aud.AuditSecretId = ls.AuditSecretId
	Join tbSecret s
on 
	s.SecretID = ls.SecretId