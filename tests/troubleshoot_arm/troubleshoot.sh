#!/bin/bash

resource_group=myAvdWorkFlowCall33204

az deployment group create --resource-group $resource_group --template-file debug_storage.json --parameters params.json