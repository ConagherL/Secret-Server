select s.SecretID, s.SecretName, sf.SecretFieldDisplayName, f.FileName
from tbSecretItem si
inner join tbSecret s on si.SecretID = s.SecretID
inner join tbSecretField sf on si.SecretFieldID = sf.SecretFieldID
inner join tbFileAttachment f on f.FileAttachmentId = si.FileAttachmentId
where si.FileAttachmentId is not null