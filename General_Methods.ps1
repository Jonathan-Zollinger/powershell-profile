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

Set-Variable -Name LillyLog -Value ("{0}\OneDrive\Home\Family\Lilly-isms.log" -f $HOME) -Scope Global
function Write-LillyLog {
    <#
    .NOTES
    Author:  Jonathan Zollinger
    Creation Date:  Mar 24 2022

    .DESCRIPTION
    Appends a given log entry to a log file. The log file is located in the <repo-root>/logs directory. Logs are grouped by the date of the log entry. 

    .PARAMETER Message
    Single String value for a log entry. 


    .PARAMETER LogFile
    Optionally designate where the log file is to be saved. the Default location is the user's Documents folder.
    
    .EXAMPLE
    pipe output from another script to a log file.
    > .\WarmUpBatmobile.ps1 | Write-Log -Info
    
    .EXAMPLE
    Bruce Wayne's commitment to log entries can become too personal.
    > Write-Log "Stayed home to cry and watch Sandra Bullock's 'While You Were Sleeping'" -Warning
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $Message,
        [Parameter(Mandatory = $false)]
        [ValidateScript({ Test-Path -Path $_ })]
        [String] $LogFile = ("{0}\OneDrive\Home\Family\Lilly-isms.log" -f $HOME)
    )

    New-Item $LogFile -ErrorAction SilentlyContinue
    if (-not (Get-Content $LogFile).Count) {
        # Add a header if this is a new file.
        $Lines = "-" * 40
        Add-Content -Path $LogFile -Value $Lines
        Add-Content -Path $LogFile -Value ("[{0}] {1}" -f ("TIMESTAMP", "Log Message"))
        Add-Content -Path $LogFile -Value $Lines
    }
    $Message = ("[{0}] {1}" -f ((Get-Date -UFormat "%H:%M:%S"), $Message)) 
    Add-Content -Path $LogFile
}