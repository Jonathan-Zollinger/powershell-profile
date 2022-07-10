function Get-AllPs1 {
    <#
    .DESCRIPTION
    Recursively accumulates all the .ps1 files in a given directory and all subdirectories. The gathered .ps1 directories are added the provided imports_file. This is a useful resource when you have a respository of Powershell scripts and classes that are actively evolving and hosted with a VCS. By comparison, this ISN't a good resource when you've created a suite of Powershell scripts and classes that rarely change and aren't evolving, but act as a dependable resource for a community. In that case, a Powershell Module would be more suitable to host that resource. \end_rant

    .PARAMETER Directory
    The Directory provided which may contain .ps1 files and / or subdirectories

    .PARAMETER Imports_File
    File location where the list of gathered .ps1 files will be stored. 

    .EXAMPLE
    > New-Object -Path .\Temp_File
    > Get-All-Ps1 C:\Projects\Crime_Fighting\ .\Temp_File
    > foreach($File in (Get-Content .\Temp_File)){import-Module $File}
    > Remove-Item -Path .\Temp_File
    
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [String] $Directory,
        [Parameter(Mandatory = $true)]
        [String] $Imports_File
    )
    # Create the file. If it's already present, dont overwrite it. Suppress any error warnings. 
    New-Item -Path $Imports_File -ErrorAction SilentlyContinue | Out-Null
    
    foreach ($Sub_Directory in (Get-ChildItem -Path $Directory -Directory | Where-Object -Property Name -NotLike ".*")) {
        Get-AllPs1 $Sub_Directory $Imports_File
    }
    foreach ($File in ((Get-ChildItem -Path $Directory -File -Filter "*.ps1"))) {
        Add-Content $Imports_File $File.FullName
    }
}
# Shared Repos
$MarionetteToolbox_Directory = "$($HOME)\Documents\MarionetteToolbox"

# Create a temp file to hold all the .ps1 files we want to import.
Set-Variable -Scope script -Name 'Directories_To_Import' -Value $PSScriptRoot\Import_me
New-Item $Directories_To_Import -Force | Out-Null
$Import_Log = ("{0}\Imports_{1}.log" -f ($PSScriptRoot, (Get-Date -UFormat "%Y-%m-%d")))

# Create the log file. If it's already there, dont overwrite it. 
$Original_Logs = @(0, 0) #pass, fail
New-Item $Import_Log -ErrorAction SilentlyContinue | Out-Null
if (!$?) {
    $Original_Logs[0] = ((Get-Content $Import_Log) -match "^\[Info\]").Count
    $Original_Logs[1] = ((Get-Content $Import_Log) -match "^\[Warning\]").Count
}
Write-Output "Importing Modules..."
Get-AllPs1 $MarionetteToolbox_Directory $Directories_To_Import 
foreach ($ps1_File in (Get-Content $Directories_To_Import)) {
    try {
        Unblock-File $ps1_File
        import-Module $ps1_File
        Add-Content -Path $Import_Log -Value ("[Info][{1}] imported {0}." -f ($ps1_File, (Get-Date -UFormat "%Y-%m-%d")))
    }
    catch {
        Add-Content -Path $Import_Log -Value ("[Warning][{1}] Failed to import {0}." -f ($File, (Get-Date -UFormat "%Y-%m-%d")))
    }
}
Remove-Item $Directories_To_Import -Force
Write-Output ("Finished importing modules. Successfully imported {0} files, Failed to import {1} file(s). for details call 'Get-Content `$Import_Log'." `
        -f ((((Get-Content $Import_Log) -match "^\[Info\]").Count - $Original_Logs[0]), (((Get-Content $Import_Log) -match "^\[Warning\]").Count - $Original_Logs[1])))


