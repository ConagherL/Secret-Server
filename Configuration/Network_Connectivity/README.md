About the scriptPermalink
With this Script you are able to specify server names and port numbers to check in a CSV File. The Script generates an CSV output file as a report. You can use this script for troubleshooting or engineering purposes to verify if TCP ports are opened.

Simply add the hostname and TCP port to the “CheckList.csv” and the script checks the specified servers and ports.

The script will generate an output file for the same path containing the suffix “Report_” with the test results.

CheckList.csv:
CheckList.csv

Report_CheckList.csv generated after script execution: Report_CheckList.csv

Executing the scriptPermalink
To execute the script simply add the “-Path” parameter to specifiy the path to the CheckList.csv template.

PS C:\techblog> &"Check-Ports.ps1" -Path "CheckList.csv"



#Important:

This script requires Power Shell version 5
