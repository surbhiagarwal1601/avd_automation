#!/bin/bash

az deployment sub validate --location "westus2" --template-file "vmonlytemplate.json" --parameters "parameters.updated.json"