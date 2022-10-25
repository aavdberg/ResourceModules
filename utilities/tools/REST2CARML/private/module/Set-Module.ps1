﻿<#
.SYNOPSIS
Update the module's files with the provided module data including added extension resources data.

.DESCRIPTION
Update the module's files with the provided module data including added extension resources data (i.e., RBAC, Diagnostic Settings, Private Endpoints, etc.).

.PARAMETER ProviderNamespace
Mandatory. The ProviderNamespace to update the template for.

.PARAMETER ResourceType
Mandatory. The ResourceType to update the template for.

.PARAMETER ModuleData
Mandatory. The module data (e.g. parameters) to add to the template.

.PARAMETER JSONFilePath
Mandatory. The service specification file to process.

.PARAMETER UrlPath
Mandatory. The API Path in the JSON specification file to process

.EXAMPLE
Set-Module -ProviderNamespace 'Microsoft.KeyVault' -ResourceType 'vaults' -ModuleData @{ parameters = @(...); resource = @(...); (...) } -JSONFilePath '(...)/resource-manager/Microsoft.KeyVault/stable/2022-07-01/keyvault.json' -UrlPath '/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.KeyVault/vaults/{vaultName}'

Update the module [Microsoft.KeyVault/vaults] with the provided module data.
#>
function Set-Module {

    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory = $true)]
        [string] $ProviderNamespace,

        [Parameter(Mandatory = $true)]
        [string] $ResourceType,

        [Parameter(Mandatory = $true)]
        [Hashtable] $ModuleData,

        [Parameter(Mandatory = $true)]
        [string] $JSONFilePath,

        [Parameter(Mandatory = $true)]
        [string] $UrlPath
    )

    begin {
        Write-Debug ('{0} entered' -f $MyInvocation.MyCommand)

        $moduleRootPath = Join-Path $script:repoRoot 'modules' $ProviderNamespace $ResourceType
        $templatePath = Join-Path $moduleRootPath 'deploy.bicep'

        # Load external functions
        . (Join-Path $script:repoRoot 'utilities' 'tools' 'Set-ModuleReadMe.ps1')
    }

    process {
        #############################
        ##   Update Support Files   #
        #############################
        foreach ($fileDefinition in $ModuleData.additionalFiles) {
            $supportFilePath = Join-Path $ModuleRootPath $fileDefinition.relativeFilePath
            if (-not (Test-Path $supportFilePath)) {
                if ($PSCmdlet.ShouldProcess(('File [{0}].' -f (Split-Path $supportFilePath -Leaf)), 'Create')) {
                    $null = New-Item -Path $supportFilePath -ItemType 'File' -Value $fileDefinition.fileContent
                }
            } else {
                if ($PSCmdlet.ShouldProcess(('File [{0}].' -f (Split-Path $supportFilePath -Leaf)), 'Update')) {
                    $null = Set-Content -Path $supportFilePath -Value $fileDefinition.fileContent
                }
            }
        }

        #############################
        ##   Update Template File   #
        #############################

        $moduleTemplateContentInputObject = @{
            ProviderNamespace = $ProviderNamespace
            ResourceType      = $ResourceType
            ModuleData        = $ModuleData
            JSONFilePath      = $JSONFilePath
            urlPath           = $UrlPath
        }
        Set-ModuleTemplate @moduleTemplateContentInputObject

        #############################
        ##   Update Module ReadMe   #
        #############################
        if ($PSCmdlet.ShouldProcess(('Module ReadMe [{0}]' -f (Join-Path (Split-Path $templatePath -Parent) 'readme.md')), 'Update')) {
            Set-ModuleReadMe -TemplateFilePath $templatePath
        }
    }

    end {
        Write-Debug ('{0} exited' -f $MyInvocation.MyCommand)
    }

}