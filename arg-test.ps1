write-host "Num Args: " $PSBoundParameters.Keys.Count
foreach ($key in $PSBoundParameters.keys) {
    $Script:args+= "`$$key=" + $PSBoundParameters["$key"] + "  "
}
write-host $Script:args
