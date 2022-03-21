# ---- Import My Scripts ----
Unblock-File $PSScriptRoot\General_Methods.ps1
import-Module $PSScriptRoot\General_Methods.ps1

# Shared Repos
$MarionetteToolbox_Directory = "C:\Projects\MarionetteToolbox"
$Computron_Directory = "C:\Projects\Computron"

# Create a temp file to hold all the .ps1 files we want to import.
Set-Variable -Scope script -Name 'Directories_To_Import' -Value $PSScriptRoot\Import_me
New-Item $Directories_To_Import -Force | Out-Null
$Import_Log = ("{0}\Imports_{1}.log" -f ($PSScriptRoot, (Get-Timestamp)))

# Create the log file. If it's already there, dont overwrite it. 
$Original_Logs = @(0, 0) #pass, fail
New-Item $Import_Log -ErrorAction SilentlyContinue | Out-Null
if(!$?){
    $Original_Logs[0] = ((Get-Content $Import_Log) -match "^\[Info\]").Count
    $Original_Logs[1] = ((Get-Content $Import_Log) -match "^\[Warning\]").Count
}
foreach ($Directory in $MarionetteToolbox_Directory, $Computron_Directory) {
    Get-All-Ps1 $Directory $Directories_To_Import
}
foreach ($ps1_File in (Get-Content $Directories_To_Import)) {
    try {
        Unblock-File $ps1_File
        import-Module $ps1_File
        Add-Content -Path $Import_Log -Value ("[Info][{1}] imported {0}." -f ($ps1_File, (Get-Timestamp -Full)))
    }
    catch {
        Add-Content -Path $Import_Log -Value ("[Warning][{1}] Failed to import {0}." -f ($File, (Get-Timestamp -Full)))
    }
}
Remove-Item $Directories_To_Import -Force
Write-Output ("Finished importing modules. Successfully imported {0} files, Failed to import {1} file(s). for details use the 'Get-Content `$Import_Log' cmdlet." `
    -f ((((Get-Content $Import_Log) -match "^\[Info\]").Count - $Original_Logs[0]),(((Get-Content $Import_Log) -match "^\[Warning\]").Count - $Original_Logs[1])))

# ---- Set VM & Other usefule  variables ----
Set-Variable -Name "ProfileDirectory" -Value $PROFILE.Substring(0, $PROFILE.LastIndexOf("\") + 1)

Import-Json-Inventory "$PSScriptRoot\My_VMs.json" | out-null
Set-Variable -Name "Cluster" -Value ($MyBoxes | Where-Object -Property Hostname -Match "vlab02420[0-3,5]$")
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Scope = 'Function', Target = '*')]
$MyBoxes = @(   $vlab024200, $vlab024201, $vlab024202, $vlab024203, $vlab024204, $vlab024205, $vlab024206, 
    $vlab024207, $vlab024208, $vlab024209, $vlab024210, $vlab024211, $vlab024212)


function Get-Full-History {
    code (Get-PSReadlineOption).HistorySavePath
}

function BuildIgDev {
    Set-Location "C:\Projects\develop\idgov\"
    ./run_all.ps1
}


function UpdatePowershell {
    Invoke-RestMethod https://aka.ms/install-powershell.ps1 | Out-File Update_Powershell.ps1
    .\Update_Powershell.ps1
    Remove-Item .\Update_Powershell.ps1 -ErrorAction Ignore
}

function Show-Progress {
    <#
    .SYNOPSIS
        Displays the completion status for a running task.
    .DESCRIPTION
        Show-Progress displays the progress of a long-running activity, task, 
        operation, etc. It is displayed as a progress bar, along with the 
        completed percentage of the task. It displays on a single line (where 
        the cursor is located). As opposed to Write-Progress, it doesn't hide 
        the upper block of text in the PowerShell console.
    .PARAMETER Activity
        A label you can assign to the current task. Normally, you'd put a relevant 
        description of what you're trying to accomplish (like "Restarting computers", 
        or "Downloading Updates").
    .PARAMETER PercentComplete
        Percentage to evaluate against the parameter total. It can be a number of 
        members processed from a collection, a partial download, the current number of 
        completed tasks, etc.
    .PARAMETER Total
        This is the number to evaluate against. It can be the number of users in a 
        group, total number of bytes to download, total number of tasks to execute, etc.
    .PARAMETER RefreshInterval
        Amount of time between two 'refreshes' of the percentage complete and update
        of the progress bar. The default refresh interval is 1 second.
    .EXAMPLE
        Show-Progress
        Without any arguments, Show-Progress displays a progress bar for 100 seconds.
        If no value is provided for the Activity parameter, it will simply say 
        "Current Task" and the completion percentage.
    .EXAMPLE
        Show-Progress -PercentComplete ($WsusServer.GetContentDownloadProgress()).DownloadedBytes -Total ($WsusServer.GetContentDownloadProgress()).TotalBytesToDownload -Activity "Downloading WSUS Updates"
        Displays a progress bar while WSUS downloads updates from an upstream source.
    .NOTES
        Author: Emanuel Halapciuc
        Last Updated: July 5th, 2021
        Source: https://bit.ly/3pdP30c
    #>
    
    # TODO: make the progress bar some ascii art that changes - like a paddle ball whose string will display new text with each "hit"

    Param(
        [Parameter()][string]$Activity = "Current Task",
        [Parameter()][ValidateScript({ $_ -gt 0 })][long]$PercentComplete = 1,
        [Parameter()][ValidateScript({ $_ -gt 0 })][long]$Total = 100,
        [Parameter()][ValidateRange(1, 60)][int]$RefreshInterval = 1
    )
    
    Process {        
        #Continue displaying progress on the same line/position
        $CurrentLine = $host.UI.RawUI.CursorPosition
    
        #Width of the progress bar
        if ($host.UI.RawUI.WindowSize.Width -gt 70) { $Width = 50 }
        else { $Width = ($host.UI.RawUI.WindowSize.Width) - 20 }
        if ($Width -lt 20) { "Window size is too small to display the progress bar"; break }
    
        $Percentage = ($PercentComplete / $Total) * 100
    
        #Write-Host -ForegroundColor Magenta "Percentage: $Percentage"
    
        for ($i = 0; $i -le 100; $i += $Percentage) {
            
            $Percentage = ($PercentComplete / $Total) * 100
            $ProgressBar = 0
    
            $host.UI.RawUI.CursorPosition = $CurrentLine
            
            Write-Host -NoNewline -ForegroundColor Cyan "["
    
            while ($ProgressBar -le $i * $Width / 100) {
                Write-Host -NoNewline "="
                $ProgressBar++
            }
    
            while (($ProgressBar -le $Width) -and ($ProgressBar -gt $i * $Width / 100)  ) {
                Write-Host -NoNewline " "
                $ProgressBar++
            }        
    
            #Write-Host -NoNewline $i
    
            Write-Host -NoNewline -ForegroundColor Cyan "] "
            Write-Host -NoNewline "$Activity`: "
            
            Write-Host -NoNewline "$([math]::round($i,2)) %, please wait"
            
            Start-Sleep -Seconds $RefreshInterval
            #Write-Host ""
    
        } #for
    
    
        #
        $host.UI.RawUI.CursorPosition = $CurrentLine
        
        Write-Host -NoNewline -ForegroundColor Cyan "["
        while ($end -le ($Width)) {
            Write-Host -NoNewline -ForegroundColor Green "="
            $end += 1
        }
    
        Write-Host -NoNewline -ForegroundColor Cyan "] "
        Write-Host -NoNewline "$Activity complete                    "
        #>
    } #Process
    
} #function
