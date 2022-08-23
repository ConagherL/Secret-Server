select 
		ts.Secretname AS 'Secret Name', 
		tf.FolderName AS 'Folder Name',
Case
	When 
			ts.AutoChangeOnExpiration = 0 then 'No'
	Else 
			'yes'
	End AS 
			'Auto Change Enabled'

from 
				tbSecret ts
		join 	tbFolder tf
On 
				ts.FolderId = tf.FolderID
where 
				ts.AutoChangeOnExpiration = 0
		and		tf.FolderName = 'Insert_foldername'