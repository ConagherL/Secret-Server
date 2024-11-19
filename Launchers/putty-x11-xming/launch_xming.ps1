param( $machine, $username, $password )

echo "
 _____ _                     _   _
|_   _| |__  _   _  ___ ___ | |_(_) ___
  | | | '_ \| | | |/ __/ _ \| __| |/ __|
  | | | | | | |_| | (_| (_) | |_| | (__
  |_| |_| |_|\__, |\___\___/ \__|_|\___|
             |___/
"

echo "Calculating next screen available for XMing"

$first_port = 6000
$list = netstat -an |Select-String 'TCP(.*)0\.0\.0\.0\:60[0-9]{2}(.*)LISTENING' |ConvertFrom-String |select p3
if($list.count -eq 0){
    $next_screen = 0
}
else{

    $list = $list | ForEach {($_.p3 -split(':'))[1]-$first_port}

    $next_screen = -1
    for ($i=0; $i -lt $list.count; $i++){
        if($i -lt $list[$i]){
            $next_screen = $i
            break
        }
    }
    if($next_screen -eq -1){
        $next_screen = $list.count
    }
}

echo "Next Screen: $next_screen"
    
$env:DISPLAY = ":$next_screen"

echo "Launching XMing"
& 'C:\Program Files (x86)\Xming\Xming.exe' :$next_screen -multiwindow -clipboard

echo "Launching Putty"
& 'C:\tools\putty.exe' -X -ssh $machine -l $username -pw $password