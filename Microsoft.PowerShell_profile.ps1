#  ---------------- variables ----------------
#setting variables using set-variables removes warnings for unused variables.
Set-Variable -Name MyVariables -Scope Script -Value @{
    "BoxInventory"           = "$(Split-Path $PROFILE -Parent)\My_Inventory.json"
    "RedHatCredentialsFile"  = "$($Home)\Documents\redhat.cred"
    "vSphereCredentialsFile" = "$($Home)\Documents\vSphereLogin.cred"
    "HostsFile"              = "C:\Windows\System32\drivers\etc\hosts"
    "vSphere-Commons"        = "$($Home)\Documents\Repos\vSphere-Commons"
    "MyModules"              = @("$($Home)\Documents\Powershell\Modules\Build-Module\",
                                 "$($Home)\Documents\Powershell\Modules\vSphere-Commons\")
}

foreach($MyVariable in $MyVariables.Keys){
    Set-Variable -Scope Global -Name $MyVariable -Value $MyVariables[$MyVariable]
}
Remove-Variable -Name MyVariable, MyVariables


#  ---------------- functions ----------------

function PowerUpTheMainHyperdrive {
    Import-Module vSphere-Commons
    Import-Boxes $BoxInventory -KeepList -ShortName
}
function Update-Hosts {   
    $OriginalHosts = Get-Content $HostsFile 
    Write-Output $OriginalHosts[$Content.IndexOf($End)..$OriginalHosts.Count] | Out-File $HostsFile
    Write-Output $OriginalHosts[$Content.IndexOf($End)..$OriginalHosts.Count] | Out-File $HostsFile -Append
    Write-Output $NewContent | Out-File $HostsFile
    #TODO(Jonathan) add shortname as a Box property
    foreach($Box in $MyBoxes) { Write-Output "$($Box.ipv4)`t$($Box.FQDN)`t$($Box.shortname)" | Out-File $HostsFile -Append }
    Write-Output $OriginalHosts[$OriginalHosts.IndexOf($End)..$OriginalHosts.Count] | Out-File $HostsFile -Append
}
function Update-MyModule{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateScript({ Test-Path -Path $_ -PathType Directory })]
        [string] $Path = $PSScriptRoot
    )
    $PsmFile, $PsdFile = $null
    foreach ($FileType in "psm1", "psd1"){
        $TempObject = Get-ChildItem $Path | Where-Object -Property Name -Like "*.$($FileType)"
        if ($TempObject.Count -ne 1){
            throw "incompatible count of .psm1 files found. expected 1 and found $($TempObject.Count)."
            Exit
        }
        switch ($FileType) {
            "psm1" {$PsmFile = $TempObject ;break}
            "psd1" {$PsdFile = $TempObject ; break}
        }
    }
    $Module = Split-Path $PsmFile -LeafBase    
    #TODO(Jonathan Z) copy files over existing files in /Powershell/Modules/<module>/directory 
}

Function Find {
    <#
    .SYNOPSIS
    Recursively searches a directory for a string in directory names and file names. The search can be performed through file content instead using the -Content flag.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, Position = 1, ParameterSetName = "Directory")]
        [ValidateScript({ Test-Path -Path $_ -PathType Container })]
        [string] $Directory,
        [Parameter(Mandatory = $false, Position = 1, ParameterSetName = "File")]
        [ValidateScript({ Test-Path -Path $_ -PathType Leaf })]
        [string] $File,
        [Parameter(Mandatory = $false, Position = 2, ParameterSetName = "Name")]
        [switch] $Name,
        [Parameter(Mandatory = $false, Position = 2, ParameterSetName = "Content")]
        [switch] $Content,
        [string] $FindMe

    )
    if($Content.IsPresent){ 
        if($File.IsPresent){
            return Select-String -Path $File $FindMe
        }
        return Get-ChildItem $Directory -Recurse | Select-String $FindMe
    }
    return Get-ChildItem $Directory -Recurse $FindMe    #Default behavior is to search file and directory names
}

function Set-DebugPreference {
    [CmdletBinding()]
    param (
        [Parameter(ParameterSetName = "On", Mandatory = $false)]
        [switch] $On,
        [Parameter(ParameterSetName = "Off", Mandatory = $false)]
        [switch] $Off
    )
    $DebugValue = $null
    switch ($PSCmdlet.ParameterSetName) {
        Off { $DebugValue = "SilentlyContinue"; break}
        On { $DebugValue = "Continue"; break}
        Default { Throw "Provide either the -On or -Off flag for Set-Debug"}
    }
    Set-Variable -Scope Global -Name DebugPreference -Value $DebugValue
}


# function Get-Commits {
#     [CmdletBinding()]
#     param (
#         [Parameter()]
#         [String] $GitHead,
#         [Paramter(Mandatory = $false)]
#         [Switch] $Passthru
#     )
#     $Commits = (git log "$($GitHead)..HEAD" --oneline --reverse --no-notes)
#     $Summation = @()
#     foreach($Commit in $Commits){
#     }
# }

function Backup {
    [CmdletBinding()]param ([Parameter()]
        [String]
        [ValidateScript({ Test-Path -Path $_ })] 
        $Directory)

    $newDir = "$(Split-Path -Path $Directory -Parent)\.$(Split-Path -Path $Directory -Leaf)_$(Get-Date -UFormat "%Y-%m-%d")"

    Copy-Item -Path $Directory -Destination $newDir -Recurse
    Write-Output "Created $($newDir)"
}

function Get-FullHistory {
    code (Get-PSReadlineOption).HistorySavePath
}

function Checkup {
    Get-Folder jzollinger | get-vm | Format-Table -AutoSize Name, PowerState, Notes
}

function Build-Boxes {
    [CmdletBinding()]
    param ([Parameter()][Array[]] $Boxes)
    (Get-Variable | Select-Object -Property Name) -match "MyBoxes"
    if($Matches.count -eq 0){
        throw "`$MyBoxes isn't assigned. Cannot run this script without that global variable assigned."
    }
    foreach ($Box in $MyBoxes) {
        Build-Box $MyBoxes[$Box] -UpdateNetworking -ReplaceBox #TODO(Jonathan) update this to be more graceful when encountering a box that doesn't exist and thus doesn't need to be replaced.
        Register-Box $MyBoxes[$Box]
    }
}

function Update-Powershell {
    Invoke-RestMethod https://aka.ms/install-powershell.ps1 | Out-File Update_Powershell.ps1
    .\Update_Powershell.ps1
    Remove-Item .\Update_Powershell.ps1 -ErrorAction Ignore
}

function Write-Comment() {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)] [string] $Comment,
        [Parameter(Mandatory = $false)] [switch] $Java,
        [Parameter(Mandatory = $false)] [switch] $Python,
        [Parameter(Mandatory = $false)] [switch] $Powershell,
        [Parameter(Mandatory = $false)] [switch] $BashFunction,
        [Parameter(Mandatory = $false)] [switch] $Bash
    )
    if ($PSBoundParameters.Count -ne 2){
        throw "Write-Comment expected to receive 2 arguments, `
        recieved $($PSBoundParameters.Count)."
    }
    $CommentCharacter
    $DebugLog = "Using {0} style comment character"
    Write-Debug "Determining what escape character is used based on switch parameter passed."
    $Switch = $PSBoundParameters.Keys | Select-String -NotMatch "Comment"
    Write-Debug "The switch passed is the `"$($Switch)`" switch"
    switch -Regex ($PSBoundParameters.Keys) {
        "BashFunction" {
            $Header = "#" * 40
            $FunctionTags = @(
                "# Globals"
                "Arguments"
                "Outputs"
                "Returns"
                "Examples:`n#   `n#"
            )
            $Output = (@(
                "#! /bin/bash",
                "# $($Comment)`n"
                $Header, "# $($Comment)",
                ($FunctionTags -join ":`n#   `n#`n# "),
                "# Author: Jonathan Zollinger",
                "# Date:  $(Get-Date -UFormat ' %Y-%m-%d')",
                $Header) -join "`n")
            Write-Output $Output | Set-Clipboard
            Write-Debug "Copied to clipboard the following:`n$($Output)"
            return
        }
        "(Python)|(Powershell)|(Bash)" {
            Write-Debug ($DebugLog -f "Bash")
            $CommentCharacter = "# "
            break
        }        
        default     {
            Write-Debug ($DebugLog -f "Java")
            $CommentCharacter = "// "
        }
    }

    $SideBanner = "-" * ((40 - $Comment.Length) / 2)
    Write-Output ("{0} {1} {2} {1}" -f $CommentCharacter, $SideBanner, $Comment ) | Set-Clipboard
}

function Write-Header {
    param([string[]] $Header)
    $Header_Width = 0
    foreach ($Line in $Header) {
        if ($Line.Length -gt $Header_Width) {
            $Header_Width = $Line.Length
        }
    }    
    $Header_Width += 5
    Write-Output "$('#' * ($Header_Width))"
    foreach ($Line in $Header) {
        Write-Output "#  $($Line + ' ' * ($Header_Width - $Line.Length-4))#"
    }
    Write-Output "$('#' * ($Header_Width))"
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

function Show-Progress {
    <#
    .SYNOPSIS
        Displays the completion status for a running task.
    .DESCRIPTION
        Show-Progress displays the progress of a long-running activity, task, 
        operation, etc. It is displayed as a progress bar, along with the 
        completed percentage of the task. It displays on a single line (where 
        the cursor is located). As opposed to Write-Progress, it doesn't hide 
        the upper block of text in the PowerShell console.
    .PARAMETER Activity
        A label you can assign to the current task. Normally, you'd put a relevant 
        description of what you're trying to accomplish (like "Restarting computers", 
        or "Downloading Updates").
    .PARAMETER PercentComplete
        Percentage to evaluate against the parameter total. It can be a number of 
        members processed from a collection, a partial download, the current number of 
        completed tasks, etc.
    .PARAMETER Total
        This is the number to evaluate against. It can be the number of users in a 
        group, total number of bytes to download, total number of tasks to execute, etc.
    .PARAMETER RefreshInterval
        Amount of time between two 'refreshes' of the percentage complete and update
        of the progress bar. The default refresh interval is 1 second.
    .EXAMPLE
        Show-Progress
        Without any arguments, Show-Progress displays a progress bar for 100 seconds.
        If no value is provided for the Activity parameter, it will simply say 
        "Current Task" and the completion percentage.
    .EXAMPLE
        Show-Progress -PercentComplete ($WsusServer.GetContentDownloadProgress()).DownloadedBytes -Total ($WsusServer.GetContentDownloadProgress()).TotalBytesToDownload -Activity "Downloading WSUS Updates"
        Displays a progress bar while WSUS downloads updates from an upstream source.
    .NOTES
        Author: Emanuel Halapciuc
        Last Updated: July 5th, 2021
        Source: https://bit.ly/3pdP30c
    #>
    
    # TODO: make the progress bar some ascii art that changes - like a paddle ball whose string will display new text with each "hit"

    Param(
        [Parameter()][string]$Activity = "Current Task",
        [Parameter()][ValidateScript({ $_ -gt 0 })][long]$PercentComplete = 1,
        [Parameter()][ValidateScript({ $_ -gt 0 })][long]$Total = 100,
        [Parameter()][ValidateRange(1, 60)][int]$RefreshInterval = 1
    )
    
    Process {        
        #Continue displaying progress on the same line/position
        $CurrentLine = $host.UI.RawUI.CursorPosition
    
        #Width of the progress bar
        if ($host.UI.RawUI.WindowSize.Width -gt 70) { $Width = 50 }
        else { $Width = ($host.UI.RawUI.WindowSize.Width) - 20 }
        if ($Width -lt 20) { "Window size is too small to display the progress bar"; break }
    
        $Percentage = ($PercentComplete / $Total) * 100
    
        #Write-Host -ForegroundColor Magenta "Percentage: $Percentage"
    
        for ($i = 0; $i -le 100; $i += $Percentage) {
            
            $Percentage = ($PercentComplete / $Total) * 100
            $ProgressBar = 0
    
            $host.UI.RawUI.CursorPosition = $CurrentLine
            
            Write-Host -NoNewline -ForegroundColor Cyan "["
    
            while ($ProgressBar -le $i * $Width / 100) {
                Write-Host -NoNewline "="
                $ProgressBar++
            }
    
            while (($ProgressBar -le $Width) -and ($ProgressBar -gt $i * $Width / 100)  ) {
                Write-Host -NoNewline " "
                $ProgressBar++
            }        
    
            #Write-Host -NoNewline $i
    
            Write-Host -NoNewline -ForegroundColor Cyan "] "
            Write-Host -NoNewline "$Activity`: "
            
            Write-Host -NoNewline "$([math]::round($i,2)) %, please wait"
            
            Start-Sleep -Seconds $RefreshInterval
            #Write-Host ""
    
        } #for
    
    
        #
        $host.UI.RawUI.CursorPosition = $CurrentLine
        
        Write-Host -NoNewline -ForegroundColor Cyan "["
        while ($end -le ($Width)) {
            Write-Host -NoNewline -ForegroundColor Green "="
            $end += 1
        }
    
        Write-Host -NoNewline -ForegroundColor Cyan "] "
        Write-Host -NoNewline "$Activity complete                    "
        #>
    } #Process
    
} #function

function Maven {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [switch] $Passthru,
        [Parameter(Mandatory = $false)]
        [switch] $Compile,
        [Parameter(Mandatory = $false)]
        [switch] $Install,
        [Parameter(Mandatory = $false)]
        [switch] $Bash
    )
    #--- validate args ------
    $Errors = @(
        "Specify whether maven is to install or compile."
        "Too many arguments provided."
    )
    if ($PSBoundParameters.Keys -ne "Compile" -and
        $PSBoundParameters.Keys -ne "Install") {
        throw $Errors[0]
    }
    elseif ($PSBoundParameters.Keys -contains "Compile" -and 
        $PSBoundParameters.Keys -contains "Install") {
        throw "$($Errors[1])`n$($Errors[0])"
    }

    #---- compile args ------
    $MavenCommand = @("mvn")
    $ProfileFlag = "-Dia.root=/root/InstallAnywhere\ 2021"
    switch -Regex ($PSBoundParameters.Keys) {
        "Install" {
            $MavenCommand.add("install")
        }
        "Compile" {
            $MavenCommand.add("compile")
        }
        "Bash" {
            $ProfileFlag = "-D`"ia.root`"=`"C:\Program Files\InstallAnywhere 2021`""
        }
        "Passthru" {
            $MavenCommand.Add($ProfileFlag)
            Write-Output ($MavenCommand -join " ") | Set-Clipboard
            Write-Output "Copied!"
            break;
        }
        Default {
            $MavenCommand.Add($ProfileFlag)
            & ($MavenCommand -join " ")
        }
    }
}
