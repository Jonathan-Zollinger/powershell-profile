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

function Get-All-Ps1 {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [String] $Directory,
        [Parameter(Mandatory = $true)]
        [String] $Imports_File
    )
    if(-not(Test-Path -Path $Imports_File)){
        New-Item -Path $Imports_File | Out-Null
    }
    
    # simple recursion fails to import functions to be usable despite a -global flag. compiling a list of scripts to import is a workaround.
    foreach($Sub_Directory in (Get-ChildItem -Path $Directory -Directory | Where-Object -Property Name -NotLike ".*")){
        Get-All-Ps1 $Sub_Directory $Imports_File
    }
    $Files = ((Get-ChildItem -Path $Directory -File -Filter "*.ps1"))
    foreach ($File in $Files) {
        Add-Content $Imports_File $File.FullName
    }
}

function Get-Timestamp {
    <#
    .DESCRIPTION
    returns a date string formatted with the intent to be used in a filename, ie BuildAllClean_2022-02-18_20.16.log is a log file for BuildAllClean. the timestamp shows it happened at 8:16 in the evening on Feb 18 2022
    
    .EXAMPLE
    1
    PS> .\WarmUpBatmobile.ps1 | Out-File (".\WarmUpBatmobile_{0}.log" -f (Get-Timestamp -Full))
    .EXAMPLE
    2
    PS> "Stayed home to cry and watch Sandra Bullock's 'While You Were Sleeping'" | Out-File (".\CrimeFighting{0}.log" -f (Get-Timestamp))
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [switch]
        $Full
    )
    $Date = (Get-date -Format o).Split("T")
    if ($Full.IsPresent) {
        return ($Date[0], ($Date[1].Split(":")[0..1] -join ".")) -join "_"
    }
    return $Date[0]
}