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
    <#
    .DESCRIPTION
    Recursively accumulates all the .ps1 files in a given directory and all subdirectories. The gathered .ps1 directories are added the provided imports_file. This is a useful resource when you have a respository of Powershell scripts and classes that are actively evolving and hosted with a VCS. By comparison, this ISN't a good resource when you've created a suite of Powershell scripts and classes that rarely change and aren't evolving, but act as a dependable resource for a community. In that case, a Powershell Module would be more suitable to host that resource. \end_rant

    .PARAMETER Directory
    The Directory provided which may contain .ps1 files and / or subdirectories

    .PARAMETER Imports_File
    File location where the list of gathered .ps1 files will be stored. 

    .EXAMPLE
    PS> New-Object -Path .\Temp_File
    PS> Get-All-Ps1 C:\Projects\Crime_Fighting\ .\Temp_File
    PS> foreach($File in (Get-Content .\Temp_File)){import-Module $File}
    PS> Remove-Item -Path .\Temp_File
    
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [String] $Directory,
        [Parameter(Mandatory = $true)]
        [String] $Imports_File
    )
    # Create the file. If it's already present, dont overwrite it. Suppress any error warnings. 
    New-Item -Path $Imports_File -ErrorAction SilentlyContinue | Out-Null
    
    foreach($Sub_Directory in (Get-ChildItem -Path $Directory -Directory | Where-Object -Property Name -NotLike ".*")){
        Get-All-Ps1 $Sub_Directory $Imports_File
    }
    foreach ($File in ((Get-ChildItem -Path $Directory -File -Filter "*.ps1"))) {
        Add-Content $Imports_File $File.FullName
    }
}

function Get-Timestamp {
    <#
    .DESCRIPTION
    Returns a date string with the month, day and year.

    .PARAMETER Full
    Optional flag which changes the returned date string to include the hour and minute. The default date provided includes only month, day and year.
    
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