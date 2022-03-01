function Write-Comment(){
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)] [string] $Comment,
        [Parameter(Mandatory = $false)] [switch] $Java,
        [Parameter(Mandatory = $false)] [switch] $Python,
        [Parameter(Mandatory = $false)] [switch] $Powershell
    )
    $Comment_Character
    if($Python.IsPresent -or $Powershell.IsPresent){
        $Comment_Character = "#"
    }else {
        #default to java comment
        $Comment_Character = "//"
    }
    $SideBanner = "-" * ((100 - $Comment.Length)/2)
    Write-Output ("{0} {1} {2} {1}" -f $Comment_Character, $SideBanner, $Comment ) | Set-Clipboard
}
function Write-Header{
    param([string[]] $Header)
    $Header_Width = 0
    foreach($Line in $Header){
        if ($Line.Length -gt $Header_Width) {
            $Header_Width = $Line.Length
        }
    }    
    $Header_Width += 5
    Write-Output "$('#' * ($Header_Width))"
    foreach ($Line in $Header){
        Write-Output "#  $($Line + ' ' * ($Header_Width - $Line.Length-4))#"
    }
    Write-Output "$('#' * ($Header_Width))"
}

function Open-History{
    code (Get-PSReadlineOption).HistorySavePath
}