function Build-Module {
    <#
    .DESCRIPTION
    Compiles all .ps1 from a given directory and its subdirectories into a powershell module.
    
    .SYNOPSIS
    Recursively gathers all directory .ps1 content into a single .psm1 file and generates a psd1 file. The name of the root directory is used for the name of the module as well as the .psd1 and .psm1 files. A module manifest is created and populated with the author (pulled from the user's git configuration), Company (Micro Focus), Project URI (assuming the repo is hosted in GHE) and RootModule. If a module manifest is already present, it will be updated with current information. 

    .PARAMETER Directory
    Directory in which all the .ps1 files are found which will be compiled to create a powershell module. The name of the Directory is used as the name of the module (spaces are removed from the module name).

    .PARAMETER ClassFilePath
    Optional Parameter. Array of Filepath for custom classes to be made available in this powershell module. 

    .EXAMPLE
    # You've written a couple dozen scripts to use as a wrapper for vSphere's PowerCLI which you've called "Marionette Toolbox" and you want to compile into a module. 
    > $myModule = "$($HOME)\Documents\Marionette_Toolbox"
    > Build-Module -Directory $myModule -Class "$($myModule)\*.ps1" 
    # Validate $myModule is available to import as a module
    > (Get-Module).Name -Contains (Split-Path $myModule -Leaf)
    True

    #>
    [CmdletBinding()]
    param (
        [ValidateScript({ Test-Path -Path $_ -PathType Container })]
        [String] $Directory,
        
        [Parameter(Mandatory = $false)]
        [ValidateScript({ Test-Path -Path $_ -PathType leaf })]
        [String] $ClassFilePath
    )
    $RepoName = Split-Path $Directory -LeafBase
    Write-Debug "Repo Name generated from $($Directory) is $($RepoName)."

    # Place in user's Documents\Powershell\Modules directory, which is in $env:PSModulePath
    $NewModule= "$(Split-Path $PROFILE -Parent)\Modules\$($RepoName)\$($RepoName).psm1"
    if(-not (Test-Path $NewModule -PathType Leaf)){
        Write-Debug "Validated that $($NewModule) does not already exist."
        if(-not [System.IO.Directory]::Exists((Split-Path $NewModule -Parent))){
            Write-Debug "The Module's $((Split-Path $NewModule -Parent)) directory does not exist. Creating directory.."
            mkdir (Split-Path $NewModule -Parent)
        }
    }else{
        Write-Debug "a file '$($NewModule)' already exists. Creating a backup in $($Home)\Documents\.ModuleBackup\ before deleting."
        $BackupDirectory = "$($Home)\Documents\.ModuleBackup\"
        mkdir $BackupDirectory -ErrorAction SilentlyContinue | Out-Null # Suppress mkdir console output
        Backup -File $NewModule -DestinationDirectory $BackupDirectory
        Remove-Item $NewModule
    }
    Write-Debug "Compiling $($Directory)'s .ps1 content to $($NewModule)..."
    Get-Scripts $Directory | Out-File $NewModule
    Write-Verbose "Compiled $((Get-Content $NewModule).Length) lines of code into $($NewModule)."
    
    $FunctionsToExport = ((($(Get-Content $NewModule) -match '^Function.+{') -replace ("function ", "")) -replace ("{")).Trim()
    Add-Content -Value "Export-ModuleMember -Function $($FunctionsToExport -join ", ")" -Path $NewModule
    $NewModuleManifest = $NewModule.Replace("psm1", "psd1")
    $ModuleManifestArgs = @(
        Author = (git config user.name)
        FunctionsToExport = $FunctionsToExport
        Company = "Micro Focus"
        ProjectUri = "https://github.houston.softwaregrp.net/$((((git config --get remote.origin.url) -split (":"))[1]).Trim(".git")).com"
        Path = $NewModuleManifest
        RootModule = (Split-Path -path $NewModule -parent)
    )
    if ($PSBoundParameters.ContainsKey("ClassFilePath")){
        $ModuleManifestArgs["ScriptsToProcess"] = $ClassFilePath
    }
    if (-not(Test-Path -Path $NewModuleManifest)) {
        Write-Debug "Creating a new $($NewModuleManifest)."
        New-ModuleManifest @ModuleManifestArgs
        Write-Debug "Created a new $($NewModuleManifest)."
        return
    }
    Write-Debug "a $($NewModuleManifest) file already exists. Updating Manifest."
    Update-ModuleManifest @ModuleManifestArgs
    Write-Debug "Updated $($NewModuleManifest)."
}

function Get-Scripts {
    <#
    .DESCRIPTION
    Recursively accumulates all the .ps1 file content in a given directory and all subdirectories. Hidden directories are not included. The gathered content is returned as an array

    .PARAMETER Directory
    The root directory in which .ps1 files are found.

    .OUTPUTS
    Array of Strings which can be saved as a powershell module (.psm1) file.

    .EXAMPLE
    # You've written a couple dozen scripts to use as a wrapper for vSphere's PowerCLI which you've called "Marionette Toolbox" and you want to save all your scripts in a single .psm1 file
    > Get-Scripts "$($Home)\Documents\Marionette_Toolbox\" | Out-File "$(Split-Path $Profile -Parent)\Modules\Marionette_Toolbox.psm1"

    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateScript({ Test-Path -Path $_ -PathType Container })]
        [String] $Directory
    )
    $AllPs1Files = @()
    foreach ($Sub_Directory in (Get-ChildItem -Path $Directory -Directory | Where-Object -Property Name -NotLike ".*")) {
        $AllPs1Files += (Get-Scripts $Sub_Directory)
    }
    foreach ($File in ((Get-ChildItem -Path $Directory -File -Filter "*.ps1"))) {
        $AllPs1Files += (Get-Content $File)
    }
    return $AllPs1Files
}

function Backup {
    <#
    .DESCRIPTION
    Creates a copy of a given directory or file. The copy of the object will be either in $DestinationDirectory or in the User's Documents\Backups directory.

    .SYNOPSIS
    Copies a file or folder to a specified directory (or Documents\Backups). New objects will maintain the original name with a timestamp. Folders will be saved with a "." prepended to the name.

    .PARAMETER File
    Optional parameter (must provide Directory or File argument). File to be copied.

    .PARAMETER Directory
    Optional parameter (must provide Directory or File argument). Folder and folder content which is to be copied.

    .PARAMETER DestinationDirectory
    Optional parameter for the directory where the backup of the file or folder will be saved. Default value for this directory is the user's Documents\Backups directory.

    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, ParameterSetName = "File")]
        [ValidateScript({Test-Path -Path $_ -PathType Leaf})]
        [String] $File,

        [Parameter(Mandatory = $false, ParameterSetName = "Directory")]
        [ValidateScript({Test-Path -Path $_ -PathType Container})]
        [String] $Directory, 

        [Parameter(Mandatory = $false)]
        [ValidateScript({Test-Path -Path $_ -PathType Container})]
        [String] $DestinationDirectory = "$($HOME)\Documents\Backups")

    $Backup = Get-Date -UFormat "%F_%H.%M.%S"
    switch ($PSCmdlet.ParameterSetName) {
        "File" { 
            $Backup = "$($DestinationDirectory)\$(Split-Path -Path $File -Leaf)_$($Backup).$(Split-Path -Path $File -Extension)" 
            Copy-Item -Path $File -Destination $Backup
            Write-Verbose "Copied $($File) to $($Backup)."
        }
        "Directory" { 
            $Backup = "$($DestinationDirectory)\.$(Split-Path -Path $Directory -Leaf)_$($Backup)"
            Copy-Item -Path $Directory -Destination $Backup -Recurse
            Write-Verbose "Copied $($Directory) to $($Backup)."
        }
        Default { throw "No Folder or File was provided to backup to $($DestinationDirectory)."}
    }
}
