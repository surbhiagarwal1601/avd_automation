# Debug Extension Deployment


# Call Stack

| Step | Caller | Callee | 
|------|--------|--------|
| 1    | `AVD Host Pool..` Pipeline `Deploy_VMExtensions` step |   Deployment `AVD-HostPool-RG-enableVmExtensions-20220322150342`  |
| 2 |  orchestration `/deploy.json` | Deployment `VirtualMachines-20220322155515Z` |
| 3 | Deployment `VirtualMachines/1.0.0/deploy.json` | Create availabilitySets `avd-avSet-westus-001` | 
| 4 | Deployment `VirtualMachines/1.0.0/deploy.json` | Deployment `bulkVMdeployment-0` | 
| 5 | Deployment `bulkVMdeployment-0` | Deployment `sessionhost001-vmLoop` |
| 6 | Deployment `sessionhost001-vmLoop` | Create Resources |


# Step 1 - Pipeline to Orchestration Template

This step calls the Orchestration Template.
- orchestration arm template `/deploy.json` 
- `parameters.updated.json` parameter file

## Parameters

Pipeline Secrets 

| Parameter |  Value | 
|-----------|-------|
| `COMPONENT_STORAGE_ACCOUNT_ID` | `/subscriptions/b0c05537-02c7-4099-b9af-ab0702d33d39/resourceGroups/rg_management_westus2/providers/Microsoft.Storage/storageAccounts/stdiacmodules`| 

Deployment Properties

| Parameter | Defined | Value | Set |
|-----------|---------|-------|-----|
| Deployment name | | `AVD-HostPool-RG-enableVmResources-20220322150326` | In Pipeline |
| componentStorageAccountId.value | 

Parameter Overrides

| Parameter |  Value | 
|-----------|-----|
| `$json.parameters.componentStorageAccountId.value` | `{{ secrets.COMPONENT_STORAGE_ACCOUNT_ID }}` | See Secrets | 
| `$json.parameters.componentsStorageContainerName.value` | components |
| `jsonParameterToEnable:` | `enableVmExtensions` |
| `$json.parameters.enableVmExtensions.value` | `$true` |
| `$performRestart` | `"true"` |

Parameters `parameters.json`

| Parameter |  Value | 
|-----------|-----|
|`enableWvdResources` | `false` |
| `vmParameters.enabled` | true |
| `vmParameters.moduleName` | VirtualMachines |
| `vmParameters.moduleVersion` | "1.0.0" |
| `vmParameters.availabilitySetName` | "avd-avSet-westus" |
| `hostPoolParameters.enabled` | true |
| `hostPoolParameters.moduleName` | WvdHostPools |

# Step 2 - Orchestration Template to Virtual Machines 

Arm Template Variables:

| Parameter | Defined | Value |
|-----------|---------|-------|
|componentsBaseUrl |  `"[concat('https://', split(parameters('componentStorageAccountId'), '/')[8], '.blob.core.windows.net/', parameters('componentsStorageContainerName'))]"`| `https://stdiacmodules.blob.core.windows.net/components` |
| modulesPath | `"[concat(variables('componentsBaseUrl'), '/Modules/ARM/')]"` | `https://stdiacmodules.blob.core.windows.net/components/Modules/ARM/`  | 


Virtual Machines (Session Hosts) Deployment Properties:

| Parameter | Defined | Value |
|-----------|---------|-------|
| name | `"[concat(parameters('vmParameters').moduleName, '-', variables('formattedTime'))]",` | `VirtualMachines-20220322154958Z` |  
| condition | `and( or( parameters('enableVmResources'), parameters('enableVmExtensions'), parameters('enableHostPoolJoin')), parameters('vmParameters').enabled)` | `and( or ( false, true, false), true)` | 
| dependsOn | `"[concat(parameters('hostPoolParameters').moduleName, '-', variables('formattedTime'))]"` | `WvdHostPools-20220322155515Z` See [Removed](#removed) |  
| TemplateLink | `"[concat(variables('modulesPath'), parameters('vmParameters').moduleName, '/', parameters('vmParameters').moduleVersion, '/deploy.json', if(parameters('componentsStorageContainerIsPrivate')...` |`https://stdiacmodules.blob.core.windows.net/components/Modules/ARM/VirtualMachines/1.0.0/deploy.json` | 

Arm Resource - Deployment - Properties:

| Parameter | Defined | Value |
|-----------|---------|-------|
| vmNamePrefix | `[parameters('vmParameters').vmNamePrefix]` | ... | 
| availabilitySetName | `[if(contains(parameters('vmParameters'), 'availabilitySetName') ,parameters('vmParameters').availabilitySetName, '')]` | avd-avSet-westus |
| ... | ... | ... |
| windowsScriptExtensionCommandToExecute | `"value": "[concat('powershell -ExecutionPolicy Unrestricted -Command \"& .\\scriptExtensionMasterInstaller.ps1 -Dynparameters @{FSLogixKeys = @([pscustomobject]@{StAName=''fslogixaaddst01'';StAKey=''', listKeys('/subscriptions/b0c05537-02c7-4099-b9af-ab0702d33d39/resourceGroups/AVD-AzFilesProfiles-RG/providers/Microsoft.Storage/storageAccounts/fslogixaaddst01', providers('Microsoft.Storage', 'storageAccounts').apiVersions[0]).keys[0].value, '''})}\"')]" // TODO Replace via pipeline` | same  |
| ... | ... | ... |

## Removed

When a conditional resource isn't deployed, Azure Resource Manager automatically removes it from the required dependencies. 

# Step 2 - Virtual Machines Deployment to Availability Set

# Step 4 Virtual Machines Deployment to bulkVMdeployment 

Virtual Machine `deploy.json` parameter default
| Parameter |  Value | 
|-----------|-----|
| proximityPlacementGroupName | "" |
| availabilitySetNames | | 
| avSetGeneratedNames | |

Virtual Machine `deploy.json` variables

| Parameter |  Defined | Value | 
|-----------|-----|---------|
| "avSetNames" | `"[if(and(empty( parameters('availabilitySetNames')), empty( parameters('availabilitySetName'))), json('[]'), if(empty( parameters('availabilitySetNames') ), variables('avSetGeneratedNames'), parameters('availabilitySetNames')))]"` | 

vmDepBulkVMdeployment Deployment Properties

| Parameter | Defined | Value |
|-----------|---------|-------|
| Deployment name | `[concat('bulkVMdeployment-', copyIndex('vmDepBulkVMdeployment'))]` |  `bulkVMdeployment-0` |
| dependsOn | avSetLoop |
| Template  |  In-line Template | See [Virtual Machine deploy.json line 1034](https://dev.azure.com/servicescode/infra-as-code-source/_git/Components?path=/Modules/ARM/VirtualMachines/deploy.json&version=GBmaster&line=1034&lineEnd=1035&lineStartColumn=1&lineEndColumn=1&lineStyle=plain&_a=contents) |  


# Step 5 bulkVMdeployment Deployment to -vmLoop Deployment

Getting Bad Request
`The template resource 'sessionhost001/WindowsCustomScriptExtension' at line '1' and column '49975' is not valid`

-vmLoop Template parameter default
| Parameter |  Value | 
|-----------|-----|
| windowsScriptExtensionFileData | None set |


Parameter passed the following:
```
"windowsScriptExtensionFileData": {
    "value": [
        {
            "storageAccountId": "/subscriptions/b0c05537-02c7-4099-b9af-ab0702d33d39/resourceGroups/AVD-Mgmt-RG/providers/Microsoft.Storage/storageAccounts/avdassetsstore",
            "uri": "https://avdassetsstore.blob.core.windows.net/hostpool1/scriptExtensionMasterInstaller.ps1"
        },
        {
            "storageAccountId": "/subscriptions/b0c05537-02c7-4099-b9af-ab0702d33d39/resourceGroups/AVD-Mgmt-RG/providers/Microsoft.Storage/storageAccounts/avdassetsstore",
            "uri": "https://avdassetsstore.blob.core.windows.net/hostpool1/001-FSLogix.zip"
        },
        null
    ]
},
```