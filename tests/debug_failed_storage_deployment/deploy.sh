#!/bin/bash

resource_group=myAvdWorkFlowCall33334 

az deployment group create --resource-group $resource_group --template-file template.json --parameters parameters.json