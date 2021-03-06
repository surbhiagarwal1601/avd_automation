<#
.NOTES
===========================================================================
Created on:   	09/2019
Created by:   	Mark Warneke & Alexander Sehr
Organization: 	Microsoft
Reference:      https://github.com/MarkWarneke
===========================================================================
#>

# Dot source this script in any Pester test script that requires the module to be imported.

$ModuleBase = Split-Path -Parent $MyInvocation.MyCommand.Path

# For tests in .\Tests subdirectory
if ((Split-Path $ModuleBase -Leaf) -eq 'lib') {
    $ModuleBase = Split-Path -Path (Split-Path $ModuleBase -Parent) -Parent
}

# Handles modules in version directories
$leaf = Split-Path $ModuleBase -Leaf
$parent = Split-Path $ModuleBase -Parent
$parsedVersion = $null
if ([System.Version]::TryParse($leaf, [ref]$parsedVersion)) {
    $ModuleName = Split-Path $parent -Leaf
}
# for VSTS build agent
elseif ($leaf -eq 's') {
    $ModuleName = $Env:Build_Repository_Name
}
else {
    $ModuleName = $leaf
}

# Removes all versions of the module from the session before importing
Get-Module $ModuleName | Remove-Module

# Because ModuleBase includes version number, this imports the required version of the module
$ModuleManifestPath = Join-Path  $ModuleBase "$ModuleName.psd1"

# Load and install dependencies
$bootstrap = Join-Path $PSScriptRoot "bootstrap.ps1"
# Load and install dependencies
if (-not $env:BOOTSTAP_EXECUTED) {
    $null = & $bootstrap -Test -Verbose
    $env:BOOTSTAP_EXECUTED = $true
}
else {
    Write-Verbose "Bootstrap ran already in context. Skipping"
}

$Module = Import-Module $ModuleManifestPath -PassThru -ErrorAction Stop
Write-Verbose "Imported $Module"

if (!$SuppressImportModule) {
    Import-Module $ModuleManifestPath -Scope Global
}
