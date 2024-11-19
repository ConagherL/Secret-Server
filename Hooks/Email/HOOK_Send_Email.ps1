$From = "mother-of-dragons@delinea.com"
$To = "jon-snow@delinea.com", "jorah-mormont@delinea.com”
$Cc = "tyrion-lannister@delinea.com"
$Attachment = "C:\Temp\Drogon.jpg"
$Subject = "Photos of Drogon"
$Body = "<h2>Guys, look at these pics of Drogon!</h2><br><br>"
$Body += “He is so cute!”
$SMTPServer = "smtp.mailtrap.io"
$SMTPPort = "587"
Send-MailMessage -From $From -to $To -Cc $Cc -Subject $Subject -Body $Body -BodyAsHtml -SmtpServer $SMTPServer -Port $SMTPPort -UseSsl -Credential (Get-Credential) -Attachments $Attachment