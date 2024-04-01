while ($true) {
    (New-Object -ComObject "WScript.Shell").SendKeys("{PRTSC}")
    Write-Output ("Simulated key press at {0:yyyy-MM-dd HH:mm:ss}" -f (Get-Date) )
    Start-Sleep -Seconds 540
}