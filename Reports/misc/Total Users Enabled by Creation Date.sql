SELECT CONVERT(date, u.Created) AS 'Creation Date', count(u.UserId) as 'Total Users Created'

FROM tbUser u

WHERE u.Enabled = 1

GROUP BY CONVERT(date,u.Created)
ORDER By CONVERT(date,u.Created) ASC