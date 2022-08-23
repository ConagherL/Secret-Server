DECLARE @cmd NVARCHAR(1200)
SET @cmd = 'DECLARE @var sql_variant = N''' + @PASSWORD + '''
EXEC [SSISDB].[catalog].[set_environment_variable_value]
	@variable_name = N''' + @VARIABLENAME + ''',
	@environment_name = N''' + @ENVNAME + ''',
	@folder_name = N''' + @FOLDERNAME + ''',
	@value = @var'
EXEC sp_executesql @cmd