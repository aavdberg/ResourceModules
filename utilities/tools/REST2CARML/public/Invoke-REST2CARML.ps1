﻿<#
.SYNOPSIS
Create/Update a CARML module based on the latest API information available

.DESCRIPTION
Create/Update a CARML module based on the latest API information available.
NOTE: As we query some data from Azure, you must be connected to an Azure Context to use this function

.PARAMETER ProviderNamespace
Mandatory. The provider namespace to query the data for

.PARAMETER ResourceType
Mandatory. The resource type to query the data for

.PARAMETER ExcludeChildren
Optional. Don't include child resource types in the result


.PARAMETER IncludePreview
Mandatory. Include preview API versions

.PARAMETER KeepArtifacts
Optional. Skip the removal of downloaded/cloned artifacts (e.g. the API-Specs repository). Useful if you want to run the function multiple times in a row.

.EXAMPLE
Invoke-REST2CARML -ProviderNamespace 'Microsoft.Keyvault' -ResourceType 'vaults'

Generate/Update a CARML module for [Microsoft.Keyvault/vaults]

.EXAMPLE
Invoke-REST2CARML -ProviderNamespace 'Microsoft.AVS' -ResourceType 'privateClouds' -Verbose -KeepArtifacts

Generate/Update a CARML module for [Microsoft.AVS/privateClouds] and do not delete any downloaded/cloned artifact.

.EXAMPLE
Invoke-REST2CARML -ProviderNamespace 'Microsoft.Keyvault' -ResourceType 'vaults' -KeepArtifacts

Generate/Update a CARML module for [Microsoft.Keyvault/vaults] and do not delete any downloaded/cloned artifact.

.EXAMPLE
Invoke-AzureApiCrawler -ProviderNamespace 'Microsoft.Storage' -ResourceType 'storageAccounts/blobServices/containers' -Verbose -KeepArtifacts

Generate/Update a CARML module for [Microsoft.Storage/storageAccounts/blobServices/containers] and do not delete any downloaded/cloned artifact.
#>
function Invoke-REST2CARML {

    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory = $true)]
        [string] $ProviderNamespace,

        [Parameter(Mandatory = $true)]
        [string] $ResourceType,

        [Parameter(Mandatory = $false)]
        [switch] $ExcludeChildren,

        [Parameter(Mandatory = $false)]
        [switch] $IncludePreview,

        [Parameter(Mandatory = $false)]
        [switch] $KeepArtifacts
    )

    begin {
        Write-Debug ('{0} entered' -f $MyInvocation.MyCommand)
        Write-Verbose ('Processing module [{0}/{1}]' -f $ProviderNamespace, $ResourceType) -Verbose
    }

    process {

        ############################################
        ##   Extract module data from API specs   ##
        ############################################

        $apiSpecsInputObject = @{
            ProviderNamespace = $ProviderNamespace
            ResourceType      = $ResourceType
            ExcludeChildren   = $ExcludeChildren
            IncludePreview    = $IncludePreview
            KeepArtifacts     = $KeepArtifacts
        }
        $moduleData = Get-AzureApiSpecsData @apiSpecsInputObject

        ###########################################
        ##   Generate initial module structure   ##
        ###########################################
        if ($PSCmdlet.ShouldProcess(('Module [{0}/{1}] structure' -f $ProviderNamespace, $ResourceType), 'Create/Update')) {
            # TODO: Consider child modules. BUT be aware that pipelines are only generated for the top-level resource
            Set-ModuleFileStructure -ProviderNamespace $ProviderNamespace -ResourceType $ResourceType
        }

        ############################
        ##   Set module content   ##
        ############################

        # TODO: Remove reduced reference as only temp. The logic is currently NOT capabale of handling child resources
        $moduleData = $moduleData | Where-Object { -not $_.metadata.parentUrlPath }

        $moduleTemplateInputObject = @{
            ProviderNamespace = $ProviderNamespace
            ResourceType      = $ResourceType
            JSONFilePath      = $moduleData.metadata.jsonFilePath
            UrlPath           = $moduleData.metadata.urlPath
            ModuleData        = $moduleData.data
        }
        if ($PSCmdlet.ShouldProcess(('Module [{0}/{1}] files' -f $ProviderNamespace, $ResourceType), 'Create/Update')) {
            Set-Module @moduleTemplateInputObject
        }
    }

    end {
        Write-Debug ('{0} exited' -f $MyInvocation.MyCommand)
    }
}