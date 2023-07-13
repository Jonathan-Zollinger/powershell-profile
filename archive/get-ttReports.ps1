
$report = ""
ForEach-Object (27..31){
    $report = $report + $(tt -p "mar$_" report)
}
