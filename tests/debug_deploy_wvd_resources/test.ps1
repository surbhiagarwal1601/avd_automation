

$templateFilePath = "../../WVD/Environments/template-orchestrated/WVD-HostPool-01-TO-RG/deploy.json"
$parameterFilePath = "../../WVD/Environments/template-orchestrated/WVD-HostPool-01-TO-RG/Parameters/parameters.json"
$templateUpdatedFilePath = "deploy.json"
$parameterUpdatedFilePath = "parameters.updated.json"

# Clean params
$paramsRaw = Get-Content $parameterFilePath -Raw
$paramsSanitized = $paramsRaw -replace '(?m)(?<=^([^"]|"[^"]*")*)//.*' -replace '(?ms)/\*.*?\*/'
$json = ConvertFrom-Json $paramsSanitized -AsHashTable

# Replace with Pipeline parameters
$json.parameters.componentStorageAccountId.value = '/subscriptions/cd3b4810-bb97-4f99-9eaa-20c547ee30cb/resourceGroups/avd_github/providers/Microsoft.Storage/storageAccounts/avdgithubsa'
$json.parameters.componentsStorageContainerName.value = "components"
$json.parameters.enableWvdResources.value = $true
$json.parameters.wvdLocation.value = "westus2"
$performRestart = "true"
if($performRestart -eq 'True') {
    $json.parameters.vmParameters.value.windowsScriptExtensionFileData += $json.parameters.vmParameters.value.windowsScriptRestartExtensionFileData
}
ConvertTo-Json $json -depth 10 | Out-File $parameterUpdatedFilePath
Write-Verbose 'Handling subscription level deployment' -Verbose


# Clean deploy.json
$templateRaw = Get-Content $templateFilePath -Raw
$templateSanitized = $templateRaw -replace '(?m)(?<=^([^"]|"[^"]*")*)//.*' -replace '(?ms)/\*.*?\*/'
$templateJson = ConvertFrom-Json $templateSanitized -AsHashTable
ConvertTo-Json $templateJson -depth 100 | Out-File $templateUpdatedFilePath


$ValidationErrors = $null
# az deployment sub validate --location "westus2" --template-file "deploy.json" --parameters "parameters.updated.json"
if ($ValidationErrors) {
    Write-Error "Template is not valid."
}           