SELECT
    u.UserName, u.DisplayName, g.GroupName
FROM
    tbUser u 
    INNER JOIN tbUserGroup ug ON ug.UserID = u.UserId
    INNER JOIN tbGroup g ON ug.GroupID = g.GroupID
WHERE
    Enabled = 1