/*
.PURPOSE
View session details of user connections, provides IP of the connection and node they connected to
*/
SELECT
    u.[UserId]
    , u.[DisplayName]
    , us.[SessionKey]
    , us.[IpAddress]
    , us.[DateCreated]
    , us.[ConnectedNodeName]
FROM tbUser AS u
INNER JOIN tbUserSession AS us ON us.[UserId] = u.[UserId]
ORDER BY us.[DateCreated] DESC