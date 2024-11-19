/*Change your SecretTypeID(Secret template). You also need to 'Expose for Display' the field you are looking to see in the database, such as "notes"*/ 

select	
	fp.FolderPath as [Folder Path],
	s.SecretName as [Secret],
	sf.SecretFieldName as [Field Name],
	si.ItemValue as [Value],
	st.SecretTypeName as [Secret Template]
	from tbSecretItem si
join tbSecretField sf on si.SecretFieldID = sf.SecretFieldID
join tbsecret s on s.SecretID = si.SecretID
join tbSecretType st on s.SecretTypeID = st.SecretTypeID
full outer join vFolderPath fp on s.FolderID = fp.FolderID
where st.SecretTypeID = <X> and sf.MustEncrypt = 0 and s.Active = 1
order by [Folder Path], [Secret], [Field Name]