#!/usr/bin/env pwsh
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
            $splitIndex = $_.IndexOf("=")
             [System.Environment]::SetEnvironmentVariable(
                $_.Substring(0, $splitIndex), 
                $_.Substring($splitIndex + 1)
                ) 
            } 
    }
}
