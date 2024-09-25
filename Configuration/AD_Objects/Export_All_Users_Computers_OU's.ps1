# Define variables
$SixMonthsAgo = (Get-Date).AddMonths(-6) # Date for filtering last logon
$ExportPath = "C:\Temp\UsersandComputers.csv" # Path to export the CSV file

# Get all enabled computers where the last logon is within the last 6 months
$computers = Get-ADComputer -Filter {(Enabled -eq $true) -and (lastLogonTimestamp -ge $SixMonthsAgo)} -Properties lastLogonTimestamp, DistinguishedName | 
    Select-Object @{Name='ObjectType';Expression={'Computer'}}, 
                  Name, 
                  @{Name='LastLogonDate';Expression={[datetime]::FromFileTime($_.lastLogonTimestamp)}}, 
                  @{Name='OU';Expression={(($_.DistinguishedName -split ',')[1..($_.DistinguishedName.Length)] -join ',').TrimEnd(',')}}

# Get all enabled users where the last logon is within the last 6 months
$users = Get-ADUser -Filter {(Enabled -eq $true) -and (lastLogonTimestamp -ge $SixMonthsAgo)} -Properties lastLogonTimestamp, DistinguishedName | 
    Select-Object @{Name='ObjectType';Expression={'User'}}, 
                  Name, 
                  @{Name='LastLogonDate';Expression={[datetime]::FromFileTime($_.lastLogonTimestamp)}}, 
                  @{Name='OU';Expression={(($_.DistinguishedName -split ',')[1..($_.DistinguishedName.Length)] -join ',').TrimEnd(',')}}

# Combine both results into a single collection
$combinedResults = $computers + $users

# Export the combined results to CSV with a semicolon delimiter
$combinedResults | Export-Csv -Path $ExportPath -Delimiter ';' -NoTypeInformation
