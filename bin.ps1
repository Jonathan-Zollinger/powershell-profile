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
      [String[]]
      $Paths
  )
  $Paths | ForEach-Object {
      if (! ($env:Path -like "*$_*")) {
          $env:Path = "$($env:Path);$_"
      }
  }
} 

function Start-DevTerminal {
  @("JAVA_HOME", "GRAALVM_HOME") | ForEach-Object { 
      [System.Environment]::SetEnvironmentVariable($_, "C:\Users\jonat\.jdks\graalvm-ce-17")
  }
  Add-ToPath $env:JAVA_HOME
  Import-Module "C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\Tools\Microsoft.VisualStudio.DevShell.dll"
  Enter-VsDevShell b48ab155 -SkipAutomaticLocation -DevCmdArguments "-arch=x64 -host_arch=x64"
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

# Import the Chocolatey Profile that contains the necessary code to enable
# tab-completions to function for `choco`.
# Be aware that if you are missing these lines from your profile, tab completion
# for `choco` will not function.
# See https://ch0.co/tab-completion for details.
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
    Import-Module "$ChocolateyProfile"
}