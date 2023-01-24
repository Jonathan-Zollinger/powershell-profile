#Requires -RunAsAdministrator

@('neovim', 'Arm.GnuArmEmbeddedToolchain', 'Kitware.CMake') | Foreach-Object {
    if ((winget list $_).Length -eq 3){
        winget install $_
    }else {
        Write-Verbose "The $($_) package is already installed. Skipping..."
    }
}

$nvimConfig = '~\AppData\Local\nvim'

if( -not ( Test-Path -PathType Container -Path $nvimConfig ) ){
    Write-Verbose "Creating $($nvimConfig)..."
    New-Item $nvimConfig -ItemType Directory
}else {
    Write-Verbose "nvim's config dir is already present "
}

