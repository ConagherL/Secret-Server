SELECT f.FolderPath As [Folder Path], GroupName, u.UserName
  FROM tbUser as u
  INNER JOIN tbUserGroup ug
  ON u.UserId = ug.UserID
  INNER JOIN tbGroup g
  ON ug.GroupID = g.GroupID
  INNER JOIN tbFolderGroupPermission tfg
  ON g.GroupID = tfg.GroupId
  INNER JOIN tbFolder f
  ON tfg.FolderId = f.FolderID
  ORDER by f.folderpath, g.GroupName, u.UserName ASC
