#!/bin/bash

location=westus2
module_path=../Modules/ARM
orchestrationPath=../WVD/Environments/template-orchestrated
rgFolder=WVD-Mgmt-TO-RG
template=$orchestrationPath/$rgFolder/deploy.json
parameters=$orchestrationPath/$rgFolder/Parameters/parameters.json

echo "template: $template"
echo "param: $parameters"

storage_name=stdiacmodules
storage_account_id=$(az storage account show --name $storage_name --query id -o tsv)
resourcegroupname=myAvdFromBash
componentsStorageContainerName=components

# Master Template
az deployment sub create --location $location --template-file $template --parameters $parameters  resourcegroupname=$resourcegroupname componentStorageAccountId=$storage_account_id componentsStorageContainerName=$componentsStorageContainerName

# # Master Template - Local Param file
# az deployment sub create --location $location --template-file $template --parameters $parameters  resourcegroupname=$resourcegroupname componentStorageAccountId=$storage_account_id componentsStorageContainerName=$componentsStorageContainerName


# Child Template
# storage_endpoint=$(az storage account show --name $storage_name --query "primaryEndpoints.blob" -o tsv)
# modules_path=$storage_endpoint$componentsStorageContainerName/Modules/ARM/

# template_file=../Modules/ARM/RoleDefinitions/1.0.0/deploy.json

# az deployment sub create --location westus2 --template-file ../Modules/ARM/RoleDefinitions/1.0.0/deploy.json   --parameters '@parameters.json' 

# Role Assignment
template=$module_path/RoleAssignments/1.0.0/deploy.json
parameters=$module_path/RoleAssignments/1.0.0/Parameters/parameters.json
az deployment sub create --location westus2 --template-file ../Modules/ARM/RoleAssignments/1.0.0/deploy.json   --parameters '@parameters.json' 
