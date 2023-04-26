function Start-Pomodoro {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [String] 
        $Task = $(Read-Host "what task are you working on?"), # "$(gum input --placeholder="Submitting Timesheet")",

        [Parameter(Mandatory = $false)]
        [Alias('p')]
        [String]
        $Project= $(Read-Host "what project is '${Task}' for?"), #"$(gum choose 'FCPS' 'IDM-Unit')",

        [Parameter(Mandatory = $false)]
        [Alias('t')]
        [ValidateScript({ if ( ( $_ -gt 0) ) {$true} else {Write-Error "$_ must be greater than 0"} }) ]
        [double]
        $time = 30,

        [Parameter(Mandatory=$false,
            HelpMessage="Path to one or more locations.")]
        [ValidateScript({Test-Path -Path $_ -PathType Leaf})]
        [string]
        $TimeEntryPath = "${HOME}\Documents\TimeEntry_$(Get-Date -UFormat `"%m-%d-%y`").log",

        [Parameter(Mandatory = $false)]
        [ValidateScript({timer -v && gum -v })]
        [switch] 
        $NeedToInstallDependencies = $false
    )

    $ErrorActionPreference = 'Stop'
    try{
        timer -v && gum -v
    }catch{
        $Error[0].Exception.Message
        $Error[0].Exception.StackTrace
        Write-Host "`tgum and timer need to be available to use in this module.`n`t are these executables on PATH?"
    }

    Add-Type -AssemblyName System.Speech
    $SpeechSynthesizer = New-Object -TypeName System.Speech.Synthesis.SpeechSynthesizer

    $SpeechSynthesizer.Speak("Starting ${Task}'s ${time} minute timer")
    $StartTime = $(Get-Date -UFormat "%R")
    Write-Output "[${Project}] ${StartTime} | ${Task}" | Tee-Object -Append -FilePath $TimeEntryPath
    timer ($time * 60) -n $Task
    $TotalTimespan = New-Timespan -Start $StartTime -end (Get-Date)
    Write-Output "[${Project}] ${TotalTimespan}h ${TotalTimespan}m | ${Task}" | Tee-Object -Append -FilePath $TimeEntryPath 
    $SpeechSynthesizer.Speak("Finished ${Task}'s ${time} minute timer")
}
Set-Alias pomo Start-Pomodoro
