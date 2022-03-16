# Local Setup

These are the instructions used to create the avd_automation repo

* Create new repo on GitHub (avd_automation)
* Clone to local computer
* Add solution code
    * Download the 'Workloads/WVD` folder hosted in the 'Solutions' repository from the [IaCS code base](https://dev.azure.com/servicescode/infra-as-code-source/_git/Solutions?path=/Workloads/WVD) as a zip file.
    * Expand the zip file to the customer's cloned repo
    * Check for all occurrences of the file path Workloads/WVD and replace it with the one matching your setup (Suggestion: Use Visual Studio Code with its search&replace feature). If you, for example, copy the WVD folder into the root of the cloned repository, the path Workloads/WVD has to be replaced with only WVD.
    * Commit the changes and push the code.
* Add the module code
    * Download the modules hosted in the 'Components' repository of the IaCS code base  as a zip file.
    * Select right modules
    * Commit the changes and push the code
* Onboard Modules
    * Create new Resource Group (rg_devops_iac_westus2)
    ```bash
    rg_region=westus2
    rg_name=rg_devops_iac_$rg_region
    az group create -n $rg_name -l $rg_region
    ```
    * Create a storage account (stdiacmodules)
    ```bash
    storage_name=stdiacmodules
    az storage account create --name $storage_name --resource-group $rg_name -l $rg_region
    ```
    * Create blob container (components)
    ```bash
    container_name=components
    account_key=$(az storage account keys renew -g $rg_name -n $storage_name --key primary --query "[0].value" --output tsv)
    az storage container create --name $container_name --account-name $storage_name --account-key $account_key
    ```
    * Add version folders
    * Upload the full 'Modules' folder to the 'Components' repository
    ```bash
    cd /path/to/project/
    end=`date -u -d "30 minutes" '+%Y-%m-%dT%H:%MZ'`
    sas=`az storage container generate-sas --name $container_name --account-name $storage_name --account-key $account_key --https-only --permissions dlrw --expiry $end -o tsv`
    storage_endpoint=$(az storage account show --name $storage_name --query "primaryEndpoints.blob" -o tsv)
    azcopy copy ./Modules "$storage_endpoint$container_name/?$sas" --recursive=true
    ```
* Prep Pipeline
    * Replace module version inWVD/Environment/.../..RG/Parameters/parameters.json 
* Set up the deployment Pipelines
    * Migrate ADO pipeline to Github Action
        * Copy WVD-Mgmt-TO-RG.yml to .github\workflows folder
        * Commit and push the code.
    * Create a DevOps service principal
    ```bash
    az login --tenant <tenant>
    az ad sp create-for-rbac --name "github_cicd_service_principal" --role contributor --scopes /subscriptions/{subscription-id} --sdk-auth
    # Set role assignment
    az role assignment create --assignee {service principal clientId} --role "User Access Administrator" --scope /subscriptions/{subscription-id}

    ```
    * On GitHub Navigate to the Settings -> Secrets page
        * Set the AZURE_CREDENTIALS value according to [this guidance](https://github.com/marketplace/actions/azure-login#configure-a-service-principal-with-a-secret) To login using Azure Service Principal with a secret
        * Set the COMPONENT_STORAGE_ACCOUNT_ID to the full id of the storage account
        ```bash
        storage_account_id=$(az storage account show --name $storage_name --query id -o tsv)
        echo $storage_account_id
        ```
    * On GitHub navigate to Action's Page
        Select New Work Flow
        Select the AVD Management deployment `AVD Management deployment`
* Add other items to get Management workflow to work
    * Create Start VM on Connect Service Principal
    ```bash
    tenant=<tenant>
    subscription_id=<sub id>
    az login --tenant $tenant
    az ad sp create-for-rbac --name "azure_virtual_desktop_service_principal"  --sdk-auth
    ```


## Migration Mapping

| Purpose | ADO Pipeline | GitHub Actions |
|---------|--------------|----------------|
| Pipeline parameters | /WVD/Environments/.../..._RG/variables.yml | .github/variables/...RG.yml |
| Pipeline | /WVD/Environments/.../..._RG/PipelineTemplates/template.yml | .github/workflows/...RG.yml |
| Master Template - Parameter File | /WVD/Environments/.../..._RG/Parameters/parameters.json | same |
| Master Template - TemplateFile | /WVD/Environments/.../..._RG/deploy.json | same | 
| Create date based rg name | "\$(resourcegroupname)-\$(Get-Date -Format yyyyMMddHHMMss)" | \${{ env.resourcegroupname }}-\$(date +'%Y%m%d%H%M%S') |

## Parameter Flow

This shows where parameters that need to be edited are stored in the Pipeline solution.

- 😣Poor design
- ❗ Variable redefined

**ADO Parameter Flow**


| Stage | Parameter Defined |
|-------|-------------------|
|Pipeline Input | <ul><li>Deploy Resources (Y/N)</li><li>Run Key Vault Post Deployment (Y/N)</li><li>Run Automation Account Post Deployment (Y/N)</li><li>Target Environment (SBX, TEST, PROD, ALL)</li></ul> |
| Global Pipeline variables | <ul><li>Path to master templates (orchestrationPath)</li><li>Path to deployment functions (orchestrationFunctionsPath)</li><li>Service Connection (serviceConnection-SBX, ...)</li><li>...</li></ul> | 
| Specific Pipeline variables | <ul><li>Path to pipeline folder (rgFolderPath)</li><li>location</li><li>Name of new Resource Group (resourcegroupname)</li><li>...</li></ul> | 
| Deploy Step | <ul><li>...</li></ul> |
| Master Template Parameters | <ul><li>Name of new Resource Group (rgParameters.resourceGroupName) ❗</li><li>Child Template Path (rgParameters.moduleName, rgParameters.version)</li><li>Enable Deploying Role Creation 😣</li><li>Enable Deploying Role Assignment 😣</li><li>...</li></ul> |
| Master Template | <ul><li>Storage Account ID (componentStorageAccountId) 😣</li><li>Storage Account Container Name (componentsStorageContainerName) 😣</li><li>...</li></ul> |


**GitHub Action Parameter Flow**


| Stage | Parameter Defined |
|-------|-------------------|
| Environments | Specify Target Subscription (Prod, Test, Sandbox) |
| Secrets (Environment Specific) | <ul><li>AZURE_CREDENTIALS</li><li>Storage Account Id (componentStorageAccountId)</li><li>...</li></ul> |
|Pipeline Input | <ul><li>Target Environment (sbx, test, prod)</li><li>Resource Group Name</li><li>...</li></ul> |
| Global Pipeline variables (env vars)| <ul><li>Path to arm templates</li><li>...</li></ul> | 
| Specific Pipeline variables | none |
| Deploy Step | <ul><li>Path to master templates (orchestrationPath)</li><li>Path to deployment functions (orchestrationFunctionsPath)</li><li>Path to Pipeline (rgFolder></li><li>location</li><li>Resource Group Name (resourcegroupname)</li><li>Storage account id (componentStorageAccountId)</li><li>Storage account Container Name (componentsStorageContainerName)</li><li>...</li></ul> |
| Master Template Parameters | <ul><li>Name of new Resource Group (rgParameters.resourceGroupName) ❗</li><li>Child Template Path (rgParameters.moduleName, rgParameters.version)</li><li>Enable Deploying Role Creation 😣</li><li>Enable Deploying Role Assignment 😣</li><li>...</li></ul> |
| Master Template | <ul><li>Storage Account ID (componentStorageAccountId) 😣</li><li>Storage Account Container Name (componentsStorageContainerName) 😣</li><li>...</li></ul> |


# Debugging Tips

* Look at Azure Activity Log at Failed Deployments

# Architecture Design

* Use GitHub Environments to store Secrets
* Use Pipeline Parameter to specify Target Environment to Deploy
* Pipeline should be complete
    * Design so an environment can be recreated completely to current state
    * Re-running pipeline recreates the environment
    * Pipeline should check if resources already exist
    * Recreate resources only if there is a change



# Resources

* ARM Template - Split array https://docs.microsoft.com/en-us/azure/azure-monitor/alerts/alerts-enable-template
* ARM Function - https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/template-functions-resource
* ARM Function - ListAccountSas https://docs.microsoft.com/en-us/rest/api/storagerp/storage-accounts/list-account-sas
* ARM Deploy GitHub Actions https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/deploy-github-actions
* GitHub - Migrate from Azure Pipelines https://docs.github.com/en/actions/migrating-to-github-actions/migrating-from-azure-pipelines-to-github-actions
* GitHub Action Arm Deploy https://github.com/Azure/arm-deploy
* GitHub Action Azure Login  https://github.com/marketplace/actions/azure-login#configure-a-service-principal-with-a-secret
* GitHub Actions Release Approval https://www.aaron-powell.com/posts/2020-03-23-approval-workflows-with-github-actions/
* GitHub Action Environments https://docs.github.com/en/actions/deployment/targeting-different-environments/using-environments-for-deployment
* Create Service Principal https://docs.microsoft.com/en-us/cli/azure/ad/sp?view=azure-cli-latest#az-ad-sp-create-for-rbac
* Create Service Principal Role Assignment https://docs.microsoft.com/en-us/cli/azure/role/assignment?view=azure-cli-latest#az-role-assignment-create
* CLI ARM Template Parameters https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/deploy-cli#inline-parameters
* CLI Manage Subscription https://docs.microsoft.com/en-us/cli/azure/manage-azure-subscriptions-azure-cli
* CLI deploy arm template https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/deploy-cli
* CLI variables https://docs.microsoft.com/en-us/cli/azure/azure-cli-variables
* WAF - Repeatable infrastructure https://docs.microsoft.com/en-us/azure/architecture/framework/devops/automation-infrastructure