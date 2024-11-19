SELECT g.GroupName, u.UserName
  FROM tbUser as u
  INNER JOIN tbUserGroup ug
  ON u.UserId = ug.UserID
  INNER JOIN tbGroup g
  ON ug.GroupID = g.GroupID
  ORDER by g.GroupName, u.UserName ASC
