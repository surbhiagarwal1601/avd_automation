# Delivery Guide Notes - GitHub Focused

These notes relate to porting the AVD solution from ADO to GitHub Actions. The goal is to capture the work needed to deploy the solution at a customer site.

These notes follow the structure of the Delivery Guide. 

* Prerequisites
* GitHub Enablement
* Solution Compenents
* Resource Deployment

# Prerequisites

## Shared Prerequisites

* Azure Environment
* Virtual Network
* Log Analytics
* Agent Deployment Policy

### Azure Environment

* Azure Active Directory - Follow instruction found in setting up an [Azure Sponsored subscription](https://microsoft-my.sharepoint.com/:w:/p/kuallamr/ETD6n6nQSA5DjgUTK7qu9O4Bdrl8AuVN12o1qub0ETMgKA?wdOrigin=TEAMS-ELECTRON.p2p.bim&wdExp=TEAMS-TREATMENT&wdhostclicktime=1645659949849)
* Azure Subscription - Follow instruction found in setting up an [Azure Sponsored subscription](https://microsoft-my.sharepoint.com/:w:/p/kuallamr/ETD6n6nQSA5DjgUTK7qu9O4Bdrl8AuVN12o1qub0ETMgKA?wdOrigin=TEAMS-ELECTRON.p2p.bim&wdExp=TEAMS-TREATMENT&wdhostclicktime=1645659949849)
* DesktopVirtualization resource provider

```bash
az provider show --namespace Microsoft.DesktopVirtualization

{
 "id": "/subscriptions/<SubID>/providers/Microsoft.DesktopVirtualization",
  "namespace": "Microsoft.DesktopVirtualization",
  "providerAuthorizationConsentState": null,
  "registrationPolicy": "RegistrationRequired",
  "registrationState": "Registered",
  ...
}

# Register if not registered
az provider register --namespace Microsoft.DesktopVirtualization
```

### Virtual Network 
```bash
# Resource Group
rg_region=westus2
rg_name=rg_connectivity_$rg_region

# Core VNet
vnet_core=vnet-core-$rg_region
vnet_core_prefix='10.0.0.0/16'
subnet_aad_ds=snet-add-ds # Core - Azure AD Domain Services subnet
subnet_aad_ds_prefix='10.0.255.0/27'
subnet_bastion=AzureBastionSubnet
subnet_bastion_prefix='10.0.255.64/27'
# subnet_gateway=gateway # Core - P2S Gateway Subnet Name created automatically
# subnet_gateway_prefix='10.0.255.32/27'

# AVD VNet 
vnet_avd=vnet-avd-$rg_region
vnet_avd_prefix='10.1.0.0/16'
subnet_avd=snet-avd-host-pool
subnet_avd_prefix='10.1.1.0/24'

# create resource group
az group create -n $rg_name -l $rg_region

# create core vnet
az network vnet create -g $rg_name -n $vnet_core --address-prefixes $vnet_core_prefix
az network vnet subnet create -g $rg_name -n $subnet_aad_ds --vnet-name $vnet_core  --address-prefixes $subnet_aad_ds_prefix
az network vnet subnet create -g $rg_name -n $subnet_bastion --vnet-name $vnet_core  --address-prefixes $subnet_bastion_prefix

# create avd vnet
az network vnet create -g $rg_name -n $vnet_avd --address-prefixes $vnet_avd_prefix
az network vnet subnet create -g $rg_name -n $subnet_avd --vnet-name $vnet_avd  --address-prefixes $subnet_avd_prefix



# Create NSG for subnets
nsg_avd=avd-nsg
az network nsg create --name $nsg_avd --resource-group $rg_name
az network vnet subnet update -g $rg_name -n $subnet_avd --vnet-name  $vnet_avd --network-security-group $nsg_avd


# Peer networks
# Get the id for myVirtualNetwork1.
vnet_core_id=$(az network vnet show \
  --resource-group $rg_name \
  --name $vnet_core \
  --query id --out tsv)

# Get the id for myVirtualNetwork2.
vnet_avd_id=$(az network vnet show \
  --resource-group $rg_name \
  --name $vnet_avd \
  --query id \
  --out tsv)

az network vnet peering create \
  --name $vnet_core-$vnet_avd \
  --resource-group $rg_name \
  --vnet-name $vnet_core \
  --remote-vnet $vnet_avd_id \
  --allow-vnet-access

az network vnet peering create \
  --name $vnet_avd-$vnet_core \
  --resource-group $rg_name \
  --vnet-name $vnet_avd \
  --remote-vnet $vnet_core_id \
  --allow-vnet-access

# Verify peering
az network vnet peering show \
  --name $vnet_core-$vnet_avd \
  --resource-group $rg_name \
  --vnet-name $vnet_core \
  --query peeringState


```
### Log Analytics Workspace 

Workspace needs to follow naming convensions. https://docs.microsoft.com/en-us/azure/azure-resource-manager/management/resource-name-rules#microsoftoperationalinsights


```bash
# Create Platform Management Shared Resource Group
rg_region=westus2
rg_name=rg_management_$rg_region
az group create --name $rg_name --location $rg_region

# Create Log Analytics Workspace
rnd_name=$(echo $RANDOM | md5sum | head -c 10; echo;)
workspace_name=log-analytics-${rnd_name}a 
az monitor log-analytics workspace create -g $rg_name -n $workspace_name
```

### Agent Deployment Policy (Post Host Pool RG Creation)

Enable the `Deploy - Configure Log Analytics` Policy on the Host Pool Resource Group `AVD-HostPool-RG` with effect `DeployIfNotExist`.

```bash

subscription_id=<replace with sub id>
host_pool_rg_name=<replace with rg name>
la_rg_name=<replace with log analytics resource group name>
la_workspace_name=<replace with log analtyics id>
principal_id=318b8561-106d-4665-be93-0fc35b68f1b7
principal_id=8dc827c9-0242-4238-aecd-1404cfe6f79f
location=westus2

# Get Resource Ids
host_pool_id=$(az group list --query "[].id" -o tsv | grep $host_pool_rg_name)
la_workspace_id=$(az monitor log-analytics workspace show -g $la_rg_name -n $la_workspace_name --query id -o tsv)
la_rg_id=$(az group list --query "[].id" -o tsv | grep $la_rg_name)


# Create Policy
# Deploy - Configure Log Analytics extension to be enabled on Windows virtual machines
policy_name=0868462e-646c-4fe3-9ced-a733534b6a2c
policy_display_name='Deploy - Configure Log Analytics extension to be enabled on Windows virtual machines'
az policy assignment create --name AVDDeployLogAnalytics --display-name "$policy_display_name"  --policy $policy_name --scope $host_pool_id --params "{ \"logAnalytics\": {\"value\": \"$la_workspace_id\"}, \"effect\": {\"value\": \"DeployIfNotExists\"}}" --mi-user-assigned $principal_id  --location $location

az policy assignment create --name AVDDeployLogAnalytics --policy $policy_name --scope $host_pool_id --params "{ \"logAnalytics\": {\"value\": \"$la_workspace_id\"}, \"effect\": {\"value\": \"DeployIfNotExists\"}}" --mi-system-assigned --location $location

# grant 'Log Analytics Contributor' permissions (or similar) to the policy assignment's principal ID

az role assignment create --assignee $principal_id --role 'Log Analytics Contributor' --scope $la_rg_id

```

## Identity solution prerequisites

This section installs a managed ADDS environment 

Create Resource Group for AADS

```bash
rg_region=westus2
rg_Name=rg_identity_$rg_region

```

This section installs a managed ADDS environment using PowerShell.

- Use PowerShell 5.1
- Install Azure PowerShell Module
- Install Azure Active Directory PowerSHell for Graph


```PowerShell
> $PSVersionTable

Name                           Value
----                           -----
PSVersion                      5.1.19041.1320
PSEdition                      Desktop
PSCompatibleVersions           {1.0, 2.0, 3.0, 4.0...}
BuildVersion                   10.0.19041.1320
CLRVersion                     4.0.30319.42000
WSManStackVersion              3.0
PSRemotingProtocolVersion      2.3
SerializationVersion           1.1.0.1

> Get-Module -ListAvailable PowerShellGet,PackageManagement

    Directory: C:\Program Files\WindowsPowerShell\Modules

ModuleType Version    Name                                ExportedCommands
---------- -------    ----                                ----------------
Script     1.4.7      PackageManagement                   {Find-Package, Get-Package, Get-PackageProvider, Get-Packa...
Binary     1.0.0.1    PackageManagement                   {Find-Package, Get-Package, Get-PackageProvider, Get-Packa...
Script     2.2.5      PowerShellGet                       {Find-Command, Find-DSCResource, Find-Module, Find-RoleCap...
Script     1.0.0.1    PowerShellGet                       {Install-Module, Find-Module, Save-Module, Update-Module...}

> Get-PackageProvider -ListAvailable

Name                     Version          DynamicOptions
----                     -------          --------------
msi                      3.0.0.0          AdditionalArguments
msu                      3.0.0.0
nuget                    2.8.5.208
NuGet                    3.0.0.1          Destination, ExcludeVersion, Scope, SkipDependencies, Headers, FilterOnTag...
PowerShellGet            2.2.5.0          PackageManagementProvider, Type, Scope, AllowClobber, SkipPublisherCheck, ...
PowerShellGet            1.0.0.1
Programs                 3.0.0.0          IncludeWindowsInstaller, IncludeSystemComponent


> Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
> Install-Module -Name PowerShellGet -Force
> Install-Module -Name Az -Scope CurrentUser -Repository PSGallery -Force
> Install-Module AzureAD
> Install-Module -Name Az.ADDomainServices
> $tenantId = <repalce with tenant id>
> Connect-AzAccount -Tenant $tenantId
> Connect-AzureAD-Tenant $tenantId

```

Create Resources

```PowerShell

# Create Service Principal in Domain Controller Services App
> New-AzureADServicePrincipal -AppId "2565bd9d-da50-47d4-8b85-4c97f669dc36"
# May throw Request_MultipleObjectsWithSameKeyValue becuase it's already created

# Get the AAD DC Administrators Group Id
> $GroupObjectId = Get-AzureADGroup  -Filter "DisplayName eq 'AAD DC Administrators'" |  Select-Object ObjectId

# Get User to add to AAD DC Administrators Group
> $UserObjectId = Get-AzureADUser -Filter "UserPrincipalName eq 'admin@contoso.onmicrosoft.com'" | Select-Object ObjectId

# Add the user to the 'AAD DC Administrators' group.
> Add-AzureADGroupMember -ObjectId $GroupObjectId.ObjectId -RefObjectId $UserObjectId.ObjectId

```

Create Network Resources

```PowerShell
> Register-AzResourceProvider -ProviderNamespace Microsoft.AAD

$VnetName = "vnet-core-westus2"

# Create the dedicated subnet for Azure AD Domain Services.
$addsSubnetName = "DomainServices"
$AaddsSubnet = New-AzVirtualNetworkSubnetConfig -Name $addsSubnetName -AddressPrefix 10.0.0.0/24

# Create an additional subnet for your own VM workloads
$workloadSubnetName = "Workloads"
$WorkloadSubnet = New-AzVirtualNetworkSubnetConfig -Name $workloadSubnetName -AddressPrefix 10.0.1.0/24

# Create the virtual network in which you will enable Azure AD Domain Services.
$Vnet= New-AzVirtualNetwork `
  -ResourceGroupName $ResourceGroupName `
  -Location westus2 `
  -Name $VnetName `
  -AddressPrefix 10.0.0.0/16 `
  -Subnet $AaddsSubnet,$WorkloadSubnet


```

Create a managed domain
```PowerShell
$AzureSubscriptionId = "YOUR_AZURE_SUBSCRIPTION_ID"
$ManagedDomainName = "aaddscontoso.com"

# Enable Azure AD Domain Services for the directory.
$replicaSetParams = @{
  Location = $AzureLocation
  SubnetId = "/subscriptions/$AzureSubscriptionId/resourceGroups/$ResourceGroupName/providers/Microsoft.Network/virtualNetworks/$VnetName/subnets/$addsSubnetName"
}
$replicaSet = New-AzADDomainServiceReplicaSet @replicaSetParams

$domainServiceParams = @{
  Name = $ManagedDomainName
  ResourceGroupName = $ResourceGroupName
  DomainName = $ManagedDomainName
  ReplicaSet = $replicaSet
}
New-AzADDomainService @domainServiceParams
```

Enable Password Synch

First configure self-service password reset


```bash
# Domain Joined Service Account: 
domain_join_sp_name=avd_domain_join_sp
az ad sp create-for-rbac --name $domain_join_sp_name  --sdk-auth

# Storage Joined Service Account: 
storage_join_sp_name=avd_storage_join_sp
az ad sp create-for-rbac --name $storage_join_sp_name  --sdk-auth

# Start on Connect Service Account: 
soc_sp_name=avd_start_on_connect_sp
az ad sp create-for-rbac --name $soc_sp_name  --sdk-auth

# Automation Run as Connection Service Account: 
scaling_sp_name=avd_scaling_run_as_sp
az ad sp create-for-rbac --name $scaling_sp_name  --sdk-auth

```

Add Domain Join User to AAD DC Administrators Group
```bash
# Get Group Id
aad_dc_admin_group_name="AAD DC Administrators"

# Get the objectId of the DomainJoinSp
avd_domain_join_sp_object_id=$(az ad sp list \
  --display-name $domain_join_sp_name \
  --query [].objectId \
  --out tsv)

az ad group member check --group "$aad_dc_admin_group_name" --member-id $avd_domain_join_sp_object_id
az ad group member add --group "$aad_dc_admin_group_name" --member-id $avd_domain_join_sp_object_id


```

Add users to AVD User Group
```bash
# Create Group
avd_user_group="AVD Users"
az ad group create --display-name "$avd_user_group" --mail-nickname "$avd_user_group"

# Get the objectId of the DomainJoinSp
avd_user_name="AVD User 001"
avd_user_object_id=$(az ad user list \
  --display-name "$avd_user_name" \
  --query [].objectId \
  --out tsv)

az ad group member check --group "$avd_user_group" --member-id $avd_user_object_id
az ad group member add --group "$avd_user_group" --member-id $avd_user_object_id
```
```PowerShell
# Get the AAD DC Administrators Group Id
> $GroupObjectId = Get-AzureADGroup  -Filter "DisplayName eq 'AVD Users'" |  Select-Object ObjectId

# Get User to add to AAD DC Administrators Group
> $UserObjectId = Get-AzureADUser -Filter "UserPrincipalName eq 'user001@y3qjt.onmicrosoft.com'" | Select-Object ObjectId

# Add the user to the 'AAD DC Administrators' group.
> Add-AzureADGroupMember -ObjectId $GroupObjectId.ObjectId -RefObjectId $UserObjectId.ObjectId
```

## Service Principal

These are the Service Principals used in the Solution

* Azure Virtual Desktop service principal (Has role for Start VM on Connect)
* DevOps Deployment Service Principal
* Automation RunAs Connection Service Principal. [See Create RunAs Connection](./tests/automation_account_run_as_account/create_runas_account.ps1)
    * Generate password called selfSignedCertPassword value of ToBase64String(New-Guid + '=')
    * Submit Request for New Identity
        * Request for Cert Authn using a certificate with the supplied secret
        * Request the ApplicationId and CertificateThumbprint


# DevOps Enablement (GitHub Actions)

This section describes what is required to deploy and manage the AVD environment using GitHub Actions.

## GitHub prerequisites

* GitHub environment (Prepared by customer)
* DevOps Deployment Service Principal
```bash

sp_name=github_cicd_service_principal
tenant=<tenant name>
sub_id=<sub id>

az login --tenant <tenant>
az ad sp create-for-rbac --name $sp_name --role contributor --scopes /subscriptions/$sub_id --sdk-auth

sp_client_id=$(az ad sp list --all --filter "displayname eq '$sp_name'" --query "[].appId" -o tsv)

az role assignment create --assignee $sp_client_id --role "User Access Administrator" --scope /subscriptions/$sub_id

# az role assignment create --assignee $sp_client_id --role "Application Developer" --scope /subscriptions/$sub_id
# Make this setting in Azure AAD Portal under Role Assignment

# ??? Azure Active Directory Graph: Application: Application.ReadWrite.OwnedBy

# ?? Microsoft Graph:- Application: Application.ReadWrite.OwnedBy - Application: Directory.Read.All
```

## Code Onboarding

* Create a new Git Repo in the Customer's GitHub project
* Add the solution Code (Download the Workloads/WVD folder)
* Add the module Code
* Onboard modules to Storage Account

## Set up the deployment pipelines

To register a pipeline in GitHub:

* Navigate to the `Actions` section of the GitHub repository
* Select 

TBD


## Storing secrets

TBD


