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
    $SideBanner = "-" * ((25 - $Comment.Length)/2)
    Write-Output ("{0} {1} {2} {1}" -f $Comment_Character, $SideBanner, $Comment ) | Set-Clipboard
}

function Write-OctaneStep(){
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [String] $Text,
        [Parameter(Mandatory = $false)]
        [String] $Subtext,
        [Parameter(Mandatory = $false)]
        [switch] $Bold,
        [Parameter(Mandatory = $false)]
        [switch] $Italic,
        [Parameter(Mandatory = $false)]
        [switch] $Underline,
        [Parameter(Mandatory = $false, ParameterSetName= "Color")]
        [switch] $Green,
        [Parameter(Mandatory = $false, ParameterSetName= "Color")]
        [switch] $Blue,
        [Parameter(Mandatory = $false, ParameterSetName= "Color")]
        [switch] $Red
    )
    if ($Subtext.IsPresent) {
        Write-Output ("**{0}**{1}" -f $Text, $Subtext) | Set-Clipboard 
        return
    }
    if ($Bold.IsPresent) {
        $Text = ("**{0}**" -f $Text)
    }
    if ($Italic.IsPresent) {
        $Text = ("*{0}*" -f $Text)
    }
    if ($Underline.IsPresent) {
        $Text = ("__{0}__" -f $Text)
    }
    if ($Green.IsPresent -or $Blue.IsPresent -or $Red.IsPresent) {
        switch ($PSCmdlet.ParameterSetName) {
            $Green  {$Text = ("`{{0}`}green" -f $Text)}
            $Blue   {$Text = ("`{{0}`}blue" -f $Text)}
            $Red    {$Text = ("`{{0}`}red" -f $Text)}
        }
    }
    Write-Output $Text | Set-Clipboard
    return $Text
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