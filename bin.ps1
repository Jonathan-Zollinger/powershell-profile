function Add-ToPath {
    <#
  .SYNOPSIS
  Adds a set of paths to the PATH environment variable.

  .DESCRIPTION 
  Checks if a path is on the PATH variable. if it's not, it's added to the end of PATH.

  .PARAMETER Paths
  Array of paths to add to PATH. 

  .EXAMPLE
  Add-ToPath(@("C:\Program Files\dgraph", "C:\Program Files\MongoDB\Server\6.0\bin", "C:\Program Files\Goss", "C:\Program Files\timer"))
  #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateScript({$_ | ForEach-Object {Test-Path -Path $_ -PathType Container}})]
        [String[]]
        $Paths
    )
    $Paths | ForEach-Object {
        if (! ($env:Path -like "*$_*")) {
            $env:Path = "$($env:Path);$_"
        }
    }
} 


function Source {
    <#
    .SYNOPSIS
    Reads a properties file into the current shell's environment variables.

    .PARAMETER Path
    filepath for the properties file

    .EXAMPLE
    # reading in sensitive data for a java compilation
    source .env; mvn deploy

    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateScript({ Test-Path -Path $_ -PathType Leaf})]
        [String]
        $Path
    )
    Get-Content $Path | ForEach-Object { 
        if (!$_.Trim().StartsWith("#")) {
             [System.Environment]::SetEnvironmentVariable(
                $_.Split("=")[0], 
                $_.Split("=")[1]) 
            } 
    }
}

function Start-DevTerminal {
    <#
    .SYNOPSIS
    Configures shell to use a fully fledged java dev environment

    .DESCRIPTION
    Adds JAVA_HOME, GRAALVM_HOME and MAVEN_HOME variables and verifies they're each on system's PATH. 
    Imports VScode dev shell module and calls Enter-VsDevShell

    .PARAMETER Java
    Path to graalvm directory, defaults to ~\.jdks\graalvm-ce-17

    .PARAMETER Maven
    Path to maven directory, defaults to 'C:\Program Files\Apache Maven\'

    .EXAMPLE
    # Valid use could be as simple as calling with no args
    Start-DevTerminal

    #>
    [CmdletBinding()]
    param (
        [Parameter()]
        [String]
        [ValidateScript({ Test-Path -Path $_ -PathType Container })]
        $Java = "$($HOME)\.jdks\graalvm-ce-17",
        [Parameter()]
        [String]
        [ValidateScript({ Test-Path -Path $_ -PathType Container })]
        $Maven = "C:\Program Files\Apache Maven\"
    )
    @("JAVA_HOME", "GRAALVM_HOME") | ForEach-Object { 
        [System.Environment]::SetEnvironmentVariable($_, $Java)
    }
    [System.Environment]::SetEnvironmentVariable("MAVEN_HOME", "C:\Program Files\Apache Maven\")
    $devShellGeneratedName = "a33f35bb"
    Add-ToPath "$env:JAVA_HOME\bin"
    Add-ToPath "$env:MAVEN_HOME\bin"

    Import-Module "C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\Tools\Microsoft.VisualStudio.DevShell.dll"
    Enter-VsDevShell  $devShellGeneratedName -SkipAutomaticLocation -DevCmdArguments "-arch=x64 -host_arch=x64"
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


function Get-FullHistory {
    Get-Content (get-PSReadlineOption).HistorySavePath
}

# Import the Chocolatey Profile that contains the necessary code to enable
# tab-completions to function for `choco`.
# Be aware that if you are missing these lines from your profile, tab completion
# for `choco` will not function.
# See https://ch0.co/tab-completion for details.
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
    Import-Module "$ChocolateyProfile"
}
