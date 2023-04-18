Function Find {
    <#
    .SYNOPSIS
    Returns matching file and directory names or file content. 
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [Alias('d', 'f')]
        [ValidateScript({ Test-Path -Path $_})]
        [string] $Source,
        [Parameter(Mandatory = $true, HelpMessage = "Search pattern to find")]
        [Alias('p')]
        [string] $Pattern,
        [Parameter(Mandatory = $false, HelpMessage = "Search file content, not filenames. Default behavior if `$Source is a file")]
        [Alias('i')]
        [switch] $FileContent,
        [Parameter(Mandatory = $false, HelpMessage = "Recurcively search directory")]
        [Alias('r')]
        [switch] $Recurse

    )
    switch ((Get-Item $Source).GetType()) {
        [System.IO.DirectoryInfo]{
            if  ( $FileContent.IsPresent ){
                return Get-ChildItem -Path $Source -Recurse:$Recurse | ForEach-Object {Select-String -Path $_ -Pattern $Pattern}
            } else {
                return Get-ChildItem -Path $Source -Name $Pattern
            }
        }
        [System.IO.FileInfo] {
            if ( $Recurse.IsPresent ){
                Write-Error "Illegal parameter combination. Cannot recursively search a file."
            }
            return Select-String -Path $Source -Pattern $Pattern
        }
    }
}
