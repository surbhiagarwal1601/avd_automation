#!/bin/bash

location=westus2
orchestrationPath=../WVD/Environments/template-orchestrated
rgFolder=WVD-Mgmt-TO-RG
template=$orchestrationPath/$rgFolder/deploy.json
parameters=$orchestrationPath/$rgFolder/Parameters/parameters.json

echo "template: $template"
echo "param: $parameters"

az deployment sub validate --location $location --template-file $template --parameters parameters 
# az deployment sub create --location $location --template-file $template --parameters parameters 