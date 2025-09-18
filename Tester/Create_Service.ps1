# --- INPUTS ---
$ServiceName  = "FakeService"
$ServiceUser  = "DOMAIN\svc_test"
$ServicePass  = "P@ssw0rd!"
$BinaryPath   = "C:\Windows\System32\cmd.exe /c pause"

# --- CREATE SERVICE ---
sc.exe create $ServiceName binPath= "$BinaryPath" obj= "$ServiceUser" password= "$ServicePass" start= auto
