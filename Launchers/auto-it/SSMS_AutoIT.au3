; AutoIt script to auto login to SQL Server Management Studio 20 using SQL Authentication

; Set the path to SSMS executable
Local $ssmsPath = "C:\Program Files (x86)\Microsoft SQL Server Management Studio 20\Common7\IDE\ssms.exe"

; Set your login credentials
Local $serverName = "SQL"
Local $userName = "TestLocal"
Local $password = $response

$windowTitle = "Connect to Server"

; Get all visible text from the specified window
$windowText = WinGetText($windowTitle)

; Run SSMS
Run($ssmsPath)

; Wait for the SSMS window to appear
WinWaitActive("Connect to Server")

;check to see if Options Tab is clicked
If StringInStr($windowText, "Options >>") Then
    Send ("!O")
EndIf

; Enter the server name
ControlSetText("Connect to Server", "", "[CLASS:Edit; INSTANCE:1]", $serverName)
;Send("!S")
Sleep(500)

Send("!A")
Sleep(500)       ; Because send goes through within milliseconds, add a sleep so it doesnt act as fast.
Send("{S}") ; Sends an 'S' to select SQL Server Authentication

; Enter the username
ControlSetText("Connect to Server", "", "[CLASS:Edit; INSTANCE:2]", $userName)

Send("!P")

; Enter the password
;ControlSetText("Connect to Server", "", "[CLASS:Edit; NAME:password]", $password)
Send($password,1)

Send("!Y")
Sleep(500)
Send("O")
Sleep(500)
Send("!C")
;Send("{ENTER}")


; Your script ends here
