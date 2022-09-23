function Set-LockModuleData {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string] $JSONKeyPath,

        [Parameter(Mandatory = $true)]
        [string] $ResourceType,

        [Parameter(Mandatory = $true)]
        [Hashtable] $ModuleData
    )

    begin {
        Write-Debug ('{0} entered' -f $MyInvocation.MyCommand)
        # Load used functions
        . (Join-Path $PSScriptRoot 'Get-SupportsLock.ps1')
    }

    process {

        if (-not (Get-SupportsLock -JSONKeyPath $JSONKeyPath)) {
            return
        }

        $ModuleData.additionalParameters += @(
            @{
                name          = 'lock'
                type          = 'string'
                description   = 'Specify the type of lock.'
                required      = $false
                default       = ''
                allowedValues = @(
                    ''
                    'CanNotDelete'
                    'ReadOnly'
                )
            }
        )

        $ModuleData.resources += @(
            "resource keyVault_lock 'Microsoft.Authorization/locks@2017-04-01' = if (!empty(lock)) {"
            "  name: '`${$ResourceType.name}-`${lock}-lock'"
            '  properties: {'
            '    level: any(lock)'
            "    notes: lock == 'CanNotDelete' ? 'Cannot delete resource or child resources.' : 'Cannot modify the resource or child resources.'"
            '  }'
            '  scope: {0}' -f $ResourceType
            '}'
        )
    }

    end {
        Write-Debug ('{0} exited' -f $MyInvocation.MyCommand)
    }
}

