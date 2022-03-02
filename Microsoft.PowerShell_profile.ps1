Get-ChildItem -Path C:\Projects\MarionetteToolbox -File -Filter "*.ps1" -Recurse | Import-Module
function callingPrvLabConnection {
    $time = 100
    $millisecond = $time   
    while ($millisecond -gt 0) {
        Write-Progress -id 0 -Status "Connecting to prv lab in $(($millisecond - ($millisecond % 100))/100 + 1) (hit ctrl+c to stop)..." -Activity "Permitting user to stop connection to PrvLab" -PercentComplete (($time - $millisecond) / $time * 100)
        Start-Sleep -Milliseconds 1 
        $millisecond = $millisecond - 1
    }
    Write-Progress -id 0 -PercentComplete 100 -Completed -Activity "Calling Script..."
    Connect_to_PrvLab
}
ImportJsonToLocalVariables "$PSScriptRoot\My_VMs.json" | out-null
function UpdatePowershell{
    Invoke-RestMethod https://aka.ms/install-powershell.ps1 | Out-File Update_Powershell.ps1
    .\Update_Powershell.ps1
    Remove-Item .\Update_Powershell.ps1 -ErrorAction Ignore
}
[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSUseDeclaredVarsMoreThanAssignments', '', Scope='Function', Target='*')]
$MyBoxes = @(   $vlab024200, $vlab024201, $vlab024202, $vlab024203, $vlab024204, $vlab024205, $vlab024206, 
                $vlab024207, $vlab024208, $vlab024209, $vlab024210, $vlab024211, $vlab024212)

Set-Variable -Name "Cluster" -Value ($MyBoxes | Where-Object -Property Hostname -Match "vlab02420[0-3,5]$")
function Get-Full-History {
    code (Get-PSReadlineOption).HistorySavePath
}

function Build_IG_Dev {
    Set-Location "C:\Projects\IG Development\idgov\"
    ./run_all.ps1
}
function Get-Timestamp {
    <#
    .DESCRIPTION
    returns a date string formatted with the intent to be used in a filename, ie BuildAllClean_2022-02-18_20.16.log is a log file for BuildAllClean. the timestamp shows it happened at 8:16 in the evening on Feb 18 2022
    
    .EXAMPLE
    1
    PS> .\WarmUpBatmobile.ps1 | Out-File (".\WarmUpBatmobile_{0}.log" -f (Get-Timestamp))
    #>
    $Date = (Get-date -Format o).Split("T")
    return ($Date[0], ($Date[1].Split(":")[0..1] -join ".")) -join "_"
}
$env:OPENSSL_CONF = "C:\Openssl\openssl.cnf"
Set-Variable -Name RedHatRegistrationCmdlet -Value "subscription-manager register --username jonathan.zollinger@microfocus.com --password 'imSOhungryIcouldD!*' --auto-attach"

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
     [Parameter()][string]$Activity="Current Task",
     [Parameter()][ValidateScript({$_ -gt 0})][long]$PercentComplete=1,
     [Parameter()][ValidateScript({$_ -gt 0})][long]$Total=100,
     [Parameter()][ValidateRange(1,60)][int]$RefreshInterval=1
     )
    
    Process {    
    
        #Continue displaying progress on the same line/position
        $CurrentLine = $host.UI.RawUI.CursorPosition
    
        #Width of the progress bar
        if ($host.UI.RawUI.WindowSize.Width -gt 70) { $Width = 50 }
        else { $Width = ($host.UI.RawUI.WindowSize.Width) -20 }
        if ($Width -lt 20) {"Window size is too small to display the progress bar";break}
    
        $Percentage = ($PercentComplete / $Total) * 100
    
        #Write-Host -ForegroundColor Magenta "Percentage: $Percentage"
    
        for ($i=0; $i -le 100; $i += $Percentage) {
            
            $Percentage = ($PercentComplete / $Total) * 100
            $ProgressBar = 0
    
            $host.UI.RawUI.CursorPosition = $CurrentLine
            
            Write-Host -NoNewline -ForegroundColor Cyan "["
    
            while ($ProgressBar -le $i*$Width/100) {
                Write-Host -NoNewline "="
                $ProgressBar++
                }
    
            while (($ProgressBar -le $Width) -and ($ProgressBar -gt $i*$Width/100)  ) {
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
