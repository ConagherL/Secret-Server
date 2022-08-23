SELECT
g.GroupName AS [Group]
,CASE
WHEN g2.IsPersonal = 1 THEN u2.DisplayName
WHEN gop.GroupOwnerPermissionId IS NULL THEN 'GROUP ADMINS'
ELSE g2.GroupName
END AS [Group Owner]
,u.DisplayName AS [Group Member]
FROM
tbGroup g
LEFT JOIN tbGroupOwnerPermission gop WITH (NOLOCK)
ON g.GroupID = gop.OwnedGroupId
LEFT JOIN tbGroup g2 WITH (NOLOCK)
ON g2.GroupID = gop.GroupId
INNER JOIN tbUserGroup ug WITH (NOLOCK)
ON g.GroupId = ug.GroupId
INNER JOIN tbUser u WITH (NOLOCK)
ON ug.UserId = u.UserId
LEFT JOIN tbUserGroup ug2 WITH (NOLOCK)
ON g2.GroupID = ug2.GroupID AND g2.IsPersonal = 1
LEFT JOIN tbUser u2 WITH (NOLOCK)
ON ug2.UserID = u2.UserId
WHERE
g.IsPersonal = 0
AND
g.GroupName <> 'Everyone'