select * from
 
(select s.SecretId, s.SecretName, rs.ResetSecretId as PrivilegAccountSecretID, 

(select secretname from tbSecret where SecretID = rs.ResetSecretId) as PrivilegeAccountSecretName

from tbSecret s 

inner join tbSecretResetSecrets rs 
on rs.SecretId = s.SecretID) s

where s.PrivilegeAccountSecretName = '<Privilege Account Secret Name>'