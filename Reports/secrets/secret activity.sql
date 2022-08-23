
-- just greater than 30 days
select s.SecretID, SecretName
from tbsecret s
join (
		select SecretId, DATEDIFF(day, Max(daterecorded),GETUTCDATE()) DayCount 
		from tbAuditSecret
		where [Action] = 'VIEW'
		group by SecretId
     ) as latest on s.SecretID = latest.SecretId
where latest.DayCount >= 30 


-- original
select s.SecretID, SecretName, 
       case when latest.DayCount < 30 then 'with in past 30 days'
            when latest.DayCount >= 30 and latest.DayCount < 60 then 'Last 60' 
            when latest.DayCount >= 60 and latest.DayCount < 90 then 'Last 90' 
            when latest.DayCount >= 90 then 'Greater Than 90' 
       end as [Days Since Last Activity]
from tbsecret s
join (
		select SecretId, DATEDIFF(day, Max(daterecorded),GETUTCDATE()) DayCount 
		from tbAuditSecret
		where [Action] = 'VIEW'
		group by SecretId
     ) as latest on s.SecretID = latest.SecretId



