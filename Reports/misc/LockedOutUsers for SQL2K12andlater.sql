Select s.username[User Name], s.displayname[Display Name], s.lastlogin[Last Login Time], q.DateRecorded[Last Login Attempt],
 
IIF(s.IsLockedOut=1,'Yes','No')[Locked Out?] 
 
From tbUser as s
 
Inner Join tbAuditUser as q
 
on s.UserId = q.UserId
 
Where s.IsLockedOut = '1'