DECLARE @cmd NVARCHAR(500)
DECLARE @ident NVARCHAR(120)
DECLARE @secr VARCHAR(120) = @PASSWORD

/* Domain value in Secret Server can be domain.com but that is invalid for an identity. We need to strip the .com off the string */
SET @ident = CONCAT(LEFT(@DOMAIN, CHARINDEX('.', @DOMAIN) - 1),'\',@USERNAME)
SET @cmd = 'ALTER CREDENTIAL [test proxy cmd] WITH IDENTITY = ''' + @ident + ''', SECRET = ''' + @secr + ''''

EXEC sp_executesql @cmd
