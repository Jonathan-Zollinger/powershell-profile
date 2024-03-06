#!/usr/bin/env pwsh
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