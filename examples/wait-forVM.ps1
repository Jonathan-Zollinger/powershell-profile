function wait-forVM(){
    [CmdletBinding()]
    param (
        [Parameter()]
        [String]
        $vmName
    )

    if (! (gum -v) ) {
        write-output "gum needs to be installed. exiting"
        exit
    } 
    gum spin --spinner='dot' --title "waiting for $vmName to respond to ping" -- pwsh -c "while(! (Test-Connection $vmName -Count 2)){}{return '$vmName is now pingable'}"
}