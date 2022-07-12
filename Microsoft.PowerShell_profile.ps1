# # ---- Import My Scripts ----
# $MyScripts = $(
#     "$PSScriptRoot\General_Methods.ps1",
#     "$PSScriptRoot\Import-inator.ps1"
# )
# foreach ($Script in $MyScripts) {
#     Unblock-File $Script 
#     import-Module $Script
# }

# # ---- Set VM & Other usefule  variables ----
# Set-Variable -Name "ProfileDirectory" -Value $PROFILE.Substring(0, $PROFILE.LastIndexOf("\") + 1)
# Import-JsonInventory "$PSScriptRoot\My_Inventory.json" -ShortName
# Set-Variable -Name "MyBoxes" -Scope Global -Value @($v00, $v01, $v02, $v03, $v04, $v05, $v06,  $v07, $v08, $v09, $v10, $v11, $v12)
# Set-Variable -Name "MarionetteLogFile" -Value ("{0}\Documents\PSscript_log_{1}.log" -f ($HOME, (Get-Date -UFormat "%Y-%m-%d"))) -Scope Global

function MavenCompile{
    mvn clean compile -D"ia.root"="C:\Program Files\InstallAnywhere 2021"
}

function MavenInstall{
    mvn clean install -D"ia.root"="C:\Program Files\InstallAnywhere 2021"
}

function CompileModule{
    [CmdletBinding()]
    param ([Parameter()][String]
    [ValidateScript({ Test-Path -Path $_ })] 
    $Directory)
    $RepoName = Split-Path $Directory -Leaf
    $Directories_To_Compile = "$($PSScriptRoot)\$($RepoName)_Directories_To_Compile_$($(Get-Date -UFormat "%Y-%m-%d")).txt"
    New-Item $Directories_To_Compile -Force
    # $Import_Log = ("{0}\Imports_{1}.log" -f ($PSScriptRoot, (Get-Date -UFormat "%Y-%m-%d")))
    Get-AllPs1 $Directory $Directories_To_Compile
    
    $NewModule = "$($(Split-Path $Profile))\$($RepoName))"
    if (Test-Path -Path $NewModule) {
        Write-Warning "Removing $($NewModule)..."
        Remove-Item $NewModule
    }
    New-Item -Path $NewModule
    foreach ($ps1_File in (Get-Content $Directories_To_Import)) {
        Add-Content -Path $NewModule -VAlue (Get-Content $ps1_File)
    }
}
function Get-FullHistory {
    code (Get-PSReadlineOption).HistorySavePath
}


function Checkup {
    Test-ServerConnection
    Get-Folder jzollinger | get-vm | Format-Table -AutoSize Name, PowerState, GuestId, Notes
}


function Build-Boxes {
    [CmdletBinding()]
    param ([Parameter()][Array[]] $Boxes)
    foreach($Box in $Boxes){
        Build-Box $MyBoxes[$Box] -UpdateNetworking -ReplaceBox
        Register-Box $MyBoxes[$Box]
    }
}

function Update-Powershell {
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
