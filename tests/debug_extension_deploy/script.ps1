$templateFilePath = "deploy.json"
$parameterUpdatedFilePath = "parameters.json"

$DeploymentInputs = @{
    # DeploymentName        = "${{ inputs.resourceGroupName  }}-${{ inputs.jsonParameterToEnable }}-$(Get-Date -Format yyyyMMddHHMMss)"
    DeploymentName        = "blxtestAVD-HostPool-RG-enableVmExtensions-$(Get-Date -Format yyyyMMddHHMMss)"
    TemplateFile          = $templateFilePath
    TemplateParameterFile = $parameterUpdatedFilePath
    Verbose               = $true
    OutVariable           = "ValidationErrors"
    ErrorAction           = "Stop"
    Location              = 'westus2'
}

Write-Verbose "Invoke task with" -Verbose
$DeploymentInputs.Keys | ForEach-Object { Write-Verbose ("PARAMETER: `t'{0}' with value '{1}'" -f $_, $DeploymentInputs[$_]) -Verbose }

Write-Verbose 'Handling subscription level deployment' -Verbose
$ValidationErrors = $null
New-AzSubscriptionDeployment @DeploymentInputs

if ($ValidationErrors) {
    Write-Error "Template is not valid."
}
