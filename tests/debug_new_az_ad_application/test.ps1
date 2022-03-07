# . \\wsl$\Ubuntu-18.04\home\brlamore\src\avd_automation\WVD\OrchestrationSources\SharedDeploymentFunctions\AutoAccount\Get-PasswordCredential.ps1


# Laptop Version
# PSVersion                      7.2.1
# PSEdition                      Core
# GitCommitId                    7.2.1
# OS                             Microsoft Windows 10.0.19044
# Platform                       Win32NT
# PSCompatibleVersions           {1.0, 2.0, 3.0, 4.0…}
# PSRemotingProtocolVersion      2.3
# SerializationVersion           1.1.0.1
# WSManStackVersion              3.0

# Script     1.6.0                 Az.Resources
#  New-AzADApplication                                1.6.0


# GitHub Runner
#  C:\Modules\az_7.1.0\Az.Resources\5.2.0\MSGraph.Autorest\custom\New-AzADApplication.ps1:702

# Get-Module Az* -ListAvailable

$AutomationAccountName='avd-scaling-autoaccount'
$tenantName = "y3qjt"
#  The string value for the host or the api path segment.
$applicationDisplayName = 'avdScalingRunAsPrincipal'
$CertifcateAssetName = "AzureRunAsCertificate"
$SelfSignedCertSecretName='avdScalingRunAsPrincipal-Secret'
$tempPath="C:/tmp/"
$ResourceGroupName='myAvdWorkFlowCall361752'

$keyId = (New-Guid).Guid

$CertificateName = "{0}{1}" -f $AutomationAccountName, $CertifcateAssetName
$PfxCertPathForRunAsAccount = Join-Path $tempPath ($CertificateName + ".pfx")
$CerCertPathForRunAsAccount = Join-Path $tempPath ($CertificateName + ".cer")

# Write-Verbose 'Create an Azure AD application' -Verbose
# $Application = New-AzADApplication -DisplayName $ApplicationDisplayName -HomePage ("http://" + $applicationDisplayName) -IdentifierUris ("http://" + $keyId) 

$app_uri = $("http://{0}.onmicrosoft.com/{1}" -f $tenantName, $applicationDisplayName )
echo $app_uri
Write-Verbose  ("http://" + $tenantName + ".onmicrosoft.com/" + $applicationDisplayName )  -Verbose

Write-Verbose 'New-AZADAPplication ...'
# $Application = New-AzADApplication -DisplayName $ApplicationDisplayName -HomePage ("http://" + $tenantName + ".onmicrosoft.com/" + $applicationDisplayName) -IdentifierUris ("http://" + $tenantName + ".onmicrosoft.com/" + $applicationDisplayName) 
$Application = Get-AzADApplication -ObjectId 'c071fc62-ca3e-4381-b4bf-961e140b5782'
$Application
# Write-Verbose $Application -Verbose
# Write-Verbose ($Application | Format-Table | Out-String) -Verbose

$KeyVault = Get-AzKeyVault -ResourceGroupName $ResourceGroupName
$KeyVaultName =$KeyVault.VaultName
Write-Host "KeyVaultName: $KeyVaultName"

$CertificateName = "{0}{1}" -f $AutomationAccountName, $CertifcateAssetName
Write-Host "Cert Name: $CertificateName"
Write-Host "PfxCertPathForRunAsAccount: $PfxCertPathForRunAsAccount"
Write-Host "SelfSignedCertSecretName $SelfSignedCertSecretName"

$SelfSignedCertSecret = Get-AzKeyVaultSecret -VaultName $KeyVaultName -Name $SelfSignedCertSecretName #-ErrorAction 'SilentlyContinue'
Write-Host "SelfSignedCertSecret $SelfSignedCertSecret" 

# $selfSignedCertPlainPassword = $SelfSignedCertSecret.SecretValueText
# Write-Host "selfSignedCertPlainPassword {0}" -f $selfSignedCertPlainPassword 

# $PfxCert = New-Object -TypeName System.Security.Cryptography.X509Certificates.X509Certificate2 -ArgumentList @($PfxCertPathForRunAsAccount, $selfSignedCertPlainPassword)
# $keyValue = [System.Convert]::ToBase64String($PfxCert.GetRawCertData())

# Write-Verbose 'Set app credential' -Verbose
# $null = New-AzADAppCredential -ObjectId  $Application.ObjectId -CertValue $keyValue -StartDate $PfxCert.NotBefore -EndDate $PfxCert.NotAfter
# Write-Verbose 'Create SP' -Verbose
# $null = New-AzADServicePrincipal -ObjectId  $Application.ObjectId # -Scope "/subscriptions/$subscriptionId" -Role 'Contributor'
# $serviceprincipal = Get-AzADServicePrincipal -ObjectId $Application.ObjectId

