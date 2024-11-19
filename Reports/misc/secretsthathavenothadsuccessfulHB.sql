SELECT 
		s.LastHeartBeatCheck as [Last Heartbeat Check], 
		ISNULL(f.FolderPath, N'No folder assigned') as [Folder Path],
		s.secretname As [Secret Name],
		CASE 
			WHEN s.LastHeartBeatStatus = 0 THEN 'Failed' 
			WHEN s.LastHeartBeatStatus = 1 THEN 'Successful' 
			WHEN s.LastHeartBeatStatus = 2 THEN 'Heartbeat not enabled' 
			WHEN s.LastHeartBeatStatus = 3 THEN 'Heartbeat not enabled, has Check Out' 
			WHEN s.LastHeartBeatStatus = 4 THEN 'Unable To Connect' 
			WHEN s.LastHeartBeatStatus = 5 THEN 'Unknown Error' 
			WHEN s.LastHeartBeatStatus = 6 THEN 'Incompatible Host'
			WHEN s.LastHeartBeatStatus = 7 THEN 'Locked Out'
	END AS [Failure Reason]	
	FROM tbSecret s
	LEFT JOIN tbFolder f
		ON s.FolderId = f.FolderId
	WHERE s.Active = 1
	ORDER BY
		1 DESC,2,3,4