#!/usr/bin/env pwsh
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