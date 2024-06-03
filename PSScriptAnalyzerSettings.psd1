#!/usr/bin/env pwsh

@{
    'Rules' = @{
        'PSAvoidUsingCmdletAliases' = @{
            'allowlist' = @('cd', '%', 'ls', 'echo')
        }
    }
}