$startTime = [System.DateTime]$args[0]
$endTime = [System.DateTime]$args[1]
$timezone = $args[2]
if ($timezone -notin [System.TimeZoneInfo]::GetSystemTimeZones().Id) {
    throw "Timezone ID [$timezone] is not found!"
}
$calcTime = Get-Date
if ($timezone) {
    $currentTime =
    [System.TimeZoneInfo]::ConvertTimeBySystemTimeZoneId($calcTime,$timezone)
} else {
    $currentTime = $calcTime
}
if ( ($currentTime -ge $startTime) -and ($currentTime -le $endTime)) {
    $message = "This is accessible between [{0:hh}:{0:mm} {0:tt}] and [{1:hh}:{1:mm}
{1:tt}]!" -f $startTime, $endTime
    $message
} else {
    $message = "Current time [{0:hh}:{0:mm} {0:tt}] IS NOT within the alloted time
between [{1:hh}:{1:mm} {1:tt}] and [{2:hh}:{2:mm} {2:tt}]!" -f $currentTime, $startTime,
    $endTime
    throw $message
}