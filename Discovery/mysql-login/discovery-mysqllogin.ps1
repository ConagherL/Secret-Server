<#
    .SYNOPSIS

    Discovery script for finding MYSQL Logins that on the target machine

    .DESCRIPTION

    Find the MYSQL Logins on all instances.

    .NOTES

    Requires MySQL Connector Net module being installed on the Secret Server Web Node or the Distributed Engine
    Reference: https://dev.mysql.com/downloads/connector/net/
    Tested with version MySQL Connector Net 8.0.27 Build .Net 4.8

    logPath variable below used for troubleshooting if required, file is written to this path with errors.
    A file for each server will be created, and overwritten on each run.    
#>
# Connect to the libray MySQL.Data.dll
$mysqlpath = 'C:\Program Files (x86)\MySQL\MySQL Connector Net 8.0.27\Assemblies\v4.8\'

# Path to Logging Folder
$logPath = 'C:\temp\scripts'

Add-Type -Path $mysqlpath'MySql.Data.dll'

$params = $args

$mysqlhost = $params[0]
$mysqluser = $params[1]
$mysqlpass = $params[2]
$mysqldb = 'mysql'

if (-not (Test-Path $mysqlpath'MySql.Data.dll')) {
    if (Test-Path $logPath) {
        Write-Output "[$(Get-Date -Format yyyyMMdd)] The MySQL Connector Net is required on the Distributed Engine and/or Web Node." | Out-File "$logPath\$($mysqlhost)_mysql.txt" -Force
    } else {
        Write-Output "[$(Get-Date -Format yyyyMMdd)] The MySQL Connector Net is required on the Distributed Engine and/or Web Node."
    }
    continue
    throw "The MySQL Connector Net is required on the Distributed Engine and/or Web Node."
} 


try {
    $Connection = [MySql.Data.MySqlClient.MySqlConnection]@{ConnectionString="server=$mysqlhost;uid=$mysqluser;pwd=$mysqlpass;database=$mysqldb"}
    $Connection.Open()
 
    # Define a MySQL Command Object for a query.
    $sql = New-Object MySql.Data.MySqlClient.MySqlCommand
    $sql.Connection = $Connection
    $sql.CommandText = 'SELECT user FROM user WHERE user NOT IN ("mysql.infoschema","mysql.session","mysql.sys")'
    
    $myreader = $sql.ExecuteReader()
    
    While($myreader.Read()){ 
        $properties=@{
            Machine=$mysqlhost
            Username=$myreader.GetString("User")
        }
        New-Object psobject -Property $properties
        #Write-Debug $myreader.GetString("User")        
    }    
    
    $myreader.Close() 
    # Close the MySQL connection.
    $Connection.Close()
        
    } catch {
    if (Test-Path $logPath) {
        Write-Output "[$(Get-Date -Format yyyyMMdd)] Issue connecting to $mysqlhost - $($_.Exception.Message)" | Out-File "$logPath\$($mysqlhost)_mysql.txt" -Force
    } else {
        Write-Output "[$(Get-Date -Format yyyyMMdd)] Issue connecting to $mysqlhost - $($_.Exception.Message)"
    }
    continue
    
}
