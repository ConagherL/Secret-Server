$computer = $args[0]

try {
    Restart-Computer -ComputerName $computer  -ErrorAction Stop
} catch {
    $connections = Invoke-Command -ComputerName $computer  -ScriptBlock { quser }
    $cList = ($connections)[1..($connections.count - 1)] | ForEach-Object { ($_ -split " +")[-6] }
    foreach ($session in $cList){
        Invoke-RDUserLogoff -HostServer $computer -UnifiedSessionID $session -Force
        Start-Sleep -Milliseconds 250
    }
}
try {
    Restart-Computer -ComputerName $computer  -ErrorAction Stop
} catch {
    Restart-Computer -ComputerName $computer  -Force
}