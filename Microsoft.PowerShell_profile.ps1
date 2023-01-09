
#  --------------- Alias...i? ---------------

Set-Variable -Name MyVariables -Scope Script -Value @{
    "dc"       = docker-compose
    "inkscape" = "C:\Program Files\Inkscape\bin\inkscape.exe"
}
Set-Alias -Name "dc" -Value docker-compose
Set-Alias -Name "Reboot" -Value Restart-Computer
#  ---------------- variables ----------------

$ErrorActionPreference = 'Stop' # default to powershell scripts stopping at failures

# Setting variables using set-variables (like below) removes IDE warnings for unused variables.
Set-Variable -Name MyVariables -Scope Script -Value @{
    "mygit"	     = "git@github.com:Jonathan-Zollinger/"
    "HostsFile"      = "C:\Windows\System32\drivers\etc\hosts"
    "PowershellHome" = "$($Home)\Documents\Powershell"
<<<<<<< HEAD
    "Projects"       = @(
        "$($env:GOHOME)\src\github.com\Jonathan-Zollinger\Go-getajob",
        "$($Home)\Projects"
    )
=======
    "Projects"     = @(
    	"$($env:GOHOME)\src\github.com\Jonathan-Zollinger\Go-getajob",
    	"$($Home)\Projects"
	)
>>>>>>> 9bf967bb93bc847891fee02f89663e52a5a6b4c8
}

foreach ($MyVariable in $MyVariables.Keys) {
    Set-Variable -Scope Global -Name $MyVariable -Value $MyVariables[$MyVariable]
}
Remove-Variable -Name MyVariable, MyVariables # removes the literal vars "$MyVariable" and "$MyVariables"


#  ---------------- functions ----------------

function Sync-Branches {
    <#
    .SYNOPSIS
    Removes branches whose upstream branches aren't on remote

    .INPUTS
     - Remote repo configured for the local git repo. Get-NewBranch will throw errormessage "No git remote configured for this repo"

    .PARAMETER Force
    Force delete a branch with no matching remote branch. This is useful if PR's are merged via "Squash and Merge", as git will erroneously see the local branch as not fully merged

    .EXAMPLE
    ** does something amazing and commits it **
    > git push
    ** submits pull request in browser, PR is approved and branch deleted remotely **
    > Sync-Branches
    ** profites-en **

    .EXAMPLE
    > git checkout -b "Peter-Pan-is-a-good-person"
    ** regrets life decisions. **
    > git checkout main
    # you could force delete this branch, or you could force sync branches
    > Sync-Branches -Force


    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [Switch] $Force
    )

    try {
        #TODO(Jonathan) query remote branches, compare to local. change delete flag based on $Force
    }
    catch [ System.Management.Automation.RuntimeException ]
    { throw  "fatal: not a git repository (or any of the parent directories)" }
}

function Get-NewBranch {
    <#
    .SYNOPSIS
    Creates a new branch for the current git repo.

    .DESCRIPTION
    Creates a new branch using the provided name. Creates an upstream branch on the default remote repo. Sets the newly created remote repo as the upstream branch for the newly created local repo.

    .INPUTS
    - Remote repo configured for the local git repo. Get-NewBranch will throw errormessage "No git remote configured for this repo"
    - Unique name of branch to be named. If name is not unique, Get-NewBranch will throw errormessage "New Branch name is already used."
    
    .PARAMETER BranchName
    Name for the branch to be named. BranchName must comply with git documentation. see https://git-scm.com/docs/git-check-ref-format. BranchName must be unique from local and remote branches.

    .OUTPUTS
    Nothing on success, throws error messages on failures.

    .EXAMPLE
    git clone git@test/example/new-branch.git; cd new-branch
    Get-NewBranch 'My-Example'

    #>

    [CmdletBinding()]
    param (
        [String]
        [ValidateScript({ git check-ref-format --branch $_ })]
        $BranchName
    )
    
    try {
        if ( (git branch -a --list $BranchName).Length -ne 0 ) {
            throw "$($BranchName) is not a unique name"
        }
        if ( (git remote).Length -eq 0 ) {
            throw "No remote repo configured for this git repo"
        }
    }
    catch [ System.Management.Automation.RuntimeException ]
    { throw  "fatal: not a git repository (or any of the parent directories)" }

    git checkout -b $BranchName
    git push (git remote) $BranchName --set-upstream    

    #TODO(Jonathan) add pester tests
}

function Update-MyModule {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateScript({ Test-Path -Path $_ -PathType Directory })]
        [string] $Path = $PSScriptRoot
    )
    $PsmFile, $PsdFile = $null
    foreach ($FileType in "psm1", "psd1") {
        $TempObject = Get-ChildItem $Path | Where-Object -Property Name -Like "*.$($FileType)"
        if ($TempObject.Count -ne 1) {
            Write-Error "incompatible count of .psm1 files found. expected 1 and found $($TempObject.Count)."
            Exit
        }
        switch ($FileType) {
            "psm1" { $PsmFile = $TempObject ; break }
            "psd1" { $PsdFile = $TempObject ; break }
        }
    }
    # $Module = Split-Path $PsmFile -LeafBase    
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
    if ($Content.IsPresent) { 
        if ($File.IsPresent) {
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
        Off { $DebugValue = "SilentlyContinue"; break }
        On { $DebugValue = "Continue"; break }
        Default { Throw "Provide either the -On or -Off flag for Set-Debug" }
    }
    Set-Variable -Scope Global -Name DebugPreference -Value $DebugValue
}

function Get-FullHistory {
    code (Get-PSReadlineOption).HistorySavePath
}

#TODO(Jonathan) add this to peanutbutter before removing from profile
function Checkup {
    Get-Folder jzollinger | get-vm | Sort-Object Name | Format-Table @{N = "Box Name"; E = { $_.Name } }, 
    @{N = "Creation Date"; E = { $_.CreateDate.ToString("MM/d/yyyy") } },
    @{N = "Power State"; E = { $_.PowerState } },
    @{N = "Snap Count"; E = { $_.CustomFields['Snapshots'] } },
    @{N = "OS"; E = { $_.GuestId -Replace ("Guest", "") }; },
    @{N = "Role(s)"; E = { ($_.Notes -split "`n" | Select-Object -Skip 1) -join "`n" } } -Wrap -AutoSize
}

#TODO(Jonathan) add this to peanutbutter before removing from profile

function Build-Boxes {
    [CmdletBinding()]
    param ([Parameter()][Array[]] $Boxes)
    (Get-Variable | Select-Object -Property Name) -match "MyBoxes"
    if ($Matches.count -eq 0) {
        throw "`$MyBoxes isn't assigned. Cannot run this script without that global variable assigned."
    }
    foreach ($Box in $MyBoxes) {
        Build-Box $MyBoxes[$Box] -UpdateNetworking -ReplaceBox #TODO(Jonathan) update this to be more graceful when encountering a box that doesn't exist and thus doesn't need to be replaced.
        Register-Box $MyBoxes[$Box]
    }
}

function Update-Powershell {
    #TODO(Jonathan) Document this tool
    Invoke-RestMethod https://aka.ms/install-powershell.ps1 | Out-File Update_Powershell.ps1
    .\Update_Powershell.ps1
    Remove-Item .\Update_Powershell.ps1 -ErrorAction Ignore
}

function Write-Comment() {
    #TODO(Jonathan) Document this tool
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)] [string] $Comment,
        [Parameter(Mandatory = $false)] [switch] $Java,
        [Parameter(Mandatory = $false)] [switch] $Python,
        [Parameter(Mandatory = $false)] [switch] $Powershell,
        [Parameter(Mandatory = $false)] [switch] $BashFunction,
        [Parameter(Mandatory = $false)] [switch] $Bash
    )
    if ($PSBoundParameters.Count -ne 2) {
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
        default {
            Write-Debug ($DebugLog -f "Java")
            $CommentCharacter = "// "
        }
    }

    $SideBanner = "-" * ((40 - $Comment.Length) / 2)
    Write-Output ("{0} {1} {2} {1}" -f $CommentCharacter, $SideBanner, $Comment ) | Set-Clipboard
}

function Write-Header {
    #TODO(Jonathan) Document this tool
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

function Rename-Branch () {

    <#
    .SYNOPSIS
    provides the git cmdlet to rename the currently checked out branch. The cmdlet is made avaialble in the clipboard.  

    .PARAMETER BranchNames
    pair of strings, first is the current branch name, second is the name to be used. If one string is provided, it's assumed the current branch name is master. if no arguments are provided, it's assumed the current branch name is master and the new branch is to be named main.
    
    .PARAMETER Passthru
    Use the Passthru switch to employ the cmdlet immediately instead of placing the cmdlet in the clipboard.

    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [String[]] $BranchNames,
        [Parameter(Mandatory = $false)]
        [Switch] $Passthru
    )
    # $gitOptions = @(
    #     "-c credential.helper=",
    #     "-c core.quotepath=false", 
    #     "log.showSignature=false"
    # )


    if ( $Passthru.IsPresent ) {
        #TODO(Jonathan) #TODO all the things
    }

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
$ENV:STARSHIP_CONFIG = "$(Split-Path $PROFILE -Parent)/starship.toml"
Invoke-Expression (&starship init powershell)
