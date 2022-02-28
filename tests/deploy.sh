#!/bin/bash

location=westus2
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

az deployment sub validate --location $location --template-file $template --parameters parameters  resourcegroupname=$resourcegroupname componentStorageAccountId=$componentStorageAccountId componentsStorageContainerName=$storage_account_id
# az deployment sub create --location $location --template-file $template --parameters parameters 