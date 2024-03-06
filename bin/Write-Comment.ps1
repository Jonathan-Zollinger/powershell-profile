#!/usr/bin/env pwsh
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