$ErrorActionPreference = 'Stop'
if (!(Test-Path -Path "$(Split-Path $PROFILE -Parent)\bin.ps1" -PathType Leaf)) {
    Write-Error "Can't find '$(Split-Path $PROFILE -Parent)\bin.ps1'."
}
Import-Module "$(Split-Path $PROFILE -Parent)\bin.ps1"
#  --------------- Alias...i? ---------------
Set-Alias grep Select-String
Set-Alias vi nvim
Set-Alias vim nvim
Set-Alias unzip Expand-Archive
Set-Alias dc docker-compose
Set-Alias Reboot Restart-Computer
Set-Alias make "C:\Program Files (x86)\GnuWin32\bin\make.exe" # winget install 'GnuWin32: Make'
#  ---------------- variables ----------------

# Setting variables using set-variables (like below) removes IDE warnings for unused variables.
Set-Variable -Name MyVariables -Scope Script -Value @{
    "StartupDir"     = "%AppData%\Roaming\Microsoft\Windows\Start Menu\Programs\Startup"
    "inkscape"       = "C:\Program Files\Inkscape\bin\inkscape.exe"
    "HostsFile"      = "C:\Windows\System32\drivers\etc\hosts"
    "PowershellHome" = "$($Home)\Documents\Powershell"
    "github"         = "$($env:GoPath)\src\github.com\Jonathan-Zollinger\"
    "NvimConfig"     = "$($Home)\Appdata\Local\nvim\init.lua"
    "hxConfig"       = "$($env:AppData)\helix\config.toml"
    "GlazeWmConfig"  = "$($Home)\.glaze-wm\config.yaml"
    "WTSettings"     = "$($Home)\AppData\Local\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
    "keyPirinhaConf" = "$($env:AppData)\Keypirinha\User\Keypirinha.ini"
}
foreach ($MyVariable in $MyVariables.Keys) {
    Set-Variable -Scope Global -Name $MyVariable -Value $MyVariables[$MyVariable]
}
Remove-Variable -Name MyVariable, MyVariables # removes the literal vars "$MyVariable" and "$MyVariables"

$env:EDITOR = 'nvim'

#Edit PATH
Add-ToPath(@(
        "C:\Program Files\MongoDB\Server\6.0\bin" 
        "$($Home)\Documents\ShareX\Tools\"
        "C:\Program Files\microfetch"
    ))
$ENV:STARSHIP_CONFIG = "$(Split-Path $PROFILE -Parent)/starship.toml"
Invoke-Expression (&starship init powershell)

# Import the Chocolatey Profile that contains the necessary code to enable
# tab-completions to function for `choco`.
# Be aware that if you are missing these lines from your profile, tab completion
# for `choco` will not function.
# See https://ch0.co/tab-completion for details.
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
    Import-Module "$ChocolateyProfile"
}
