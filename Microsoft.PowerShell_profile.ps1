$ErrorActionPreference = 'Stop' # default to powershell scripts stopping at failures
#  --------------- Alias...i? ---------------
Set-Alias grep Select-String
Set-Alias vi nvim
Set-Alias vim nvim
Set-Alias unzip Expand-Archive
Set-Alias dc docker-compose
Set-Alias Reboot Restart-Computer
Set-Alias make "C:\Program Files (x86)\GnuWin32\bin\make.exe" # winget install 'GnuWin32: Make'
Set-Alias vi 'nvim'
Set-Alias vim 'nvim'
#  ---------------- variables ----------------

# Setting variables using set-variables (like below) removes IDE warnings for unused variables.
Set-Variable -Name MyVariables -Scope Script -Value @{
    "StartupDir"     = "%AppData%\Roaming\Microsoft\Windows\Start Menu\Programs\Startup"
    "inkscape"       = "C:\Program Files\Inkscape\bin\inkscape.exe"
    "HostsFile"      = "C:\Windows\System32\drivers\etc\hosts"
    "PowershellHome" = "$($Home)\Documents\Powershell"
    "github"         = "$($env:GoPath)\src\github.com\Jonathan-Zollinger\"
    "NvimConfig"     = "$($Home)\Appdata\Local\nvim\init.lua"
    "GlazeWmConfig"  = "$($Home)\.glaze-wm\config.yaml"
    "trivir"         = "$($env:GoPath)\src\git.trivir.com\"
    "WTSettings"     = "$($Home)\AppData\Local\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
}
foreach ($MyVariable in $MyVariables.Keys) {
    Set-Variable -Scope Global -Name $MyVariable -Value $MyVariables[$MyVariable]
}
Remove-Variable -Name MyVariable, MyVariables # removes the literal vars "$MyVariable" and "$MyVariables"

$env:EDITOR='nvim'

#Edit PATH
@("C:\Program Files\Goss\", "C:\Program Files\timer", "C:\Program Files (x86)\VMware\VMware Workstation") | ForEach-Object {
    if (! ($env:Path -contains $_)) {
        $env:Path = "$($env:Path);$_"
    }
}
#  ---------------- functions ----------------
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
    Get-Content (get-PSReadlineOption).HistorySavePath
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

$ENV:STARSHIP_CONFIG = "$(Split-Path $PROFILE -Parent)/starship.toml"
Invoke-Expression (&starship init powershell)
