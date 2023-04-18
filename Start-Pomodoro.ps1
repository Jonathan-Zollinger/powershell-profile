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
        [ValidateScript({[int]::TryParse($_) && $_ -gt 0})]
        $time = 30,

        [Parameter(Mandatory=$false,
                   HelpMessage="Path to one or more locations.")]
        [ValidateScript({Test-Path -Path $_ -PathType Leaf})]
        [string]
        $TimeEntryPath = "${HOME}\Documents\TimeEntry_$(Get-Date -UFormat `"%m-%d-%y`").log",

        [Parameter(Mandatory = $false)]
        [ValidateScript({
               if(!( timer -v | Out-Null && gum -v | Out-Null )){
                    throw "charm's gum and carloos' timer executables need to be on PATH"
               }
            })
        ]
        [switch] 
        $NeedToInstallDependencies = $false
    )
    Add-Type -AssemblyName System.Speech
    $SpeechSynthesizer = New-Object -TypeName System.Speech.Synthesis.SpeechSynthesizer

    $StartTime = $(Get-Date -UFormat "%R")
    Write-Output "[${Project}] ${StartTime} | ${Task}" | Tee-Object -Append -FilePath $TimeEntryPath
    timer ($time * 60) -n $Task
    $TotalTimespan = New-Timespan -Start $StartTime -end (Get-Date)
    Write-Output "[${Project}] ${TotalTimespan}h ${TotalTimespan}m | ${Task}" | Tee-Object -Append -FilePath $TimeEntryPath 
    $SpeechSynthesizer.Speak("Finished ${Task}'s ${time} minute timer")
   
 
}