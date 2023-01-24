#Requires -RunAsAdministrator
@('neovim', 'Arm.GnuArmEmbeddedToolchain', 'Kitware.CMake') | Foreach-Object {
    if ((winget list $_).Length -eq 3){
        winget install $_
    }else {
        Write-Verbose "The $($_) package is already installed. Skipping..."
    }
}

<<<<<<< HEAD
$nvimConfig = 'C:\Users\jonat\.config\nvim\' 
# C:\Users\Jonathan\Appdata\Local\nvim\init.lua
=======
$nvimConfig = '~\AppData\Local\nvim'
>>>>>>> df4c6b7c7d3f32febe3451b4b29ed79a76a224ba

if( -not ( Test-Path -PathType Container -Path $nvimConfig ) ){
    Write-Verbose "Creating $($nvimConfig)..."
    New-Item $nvimConfig -ItemType Directory
}else {
    Write-Verbose "nvim's config dir is already present "
}

$nvimConfigScript = 'https://raw.githubusercontent.com/Jonathan-Zollinger/dotfiles/main/nvim/windows-init.lua'

Invoke-WebRequest -URI $nvimConfigScript -OutFile "$($nvimConfig)init.lua"

