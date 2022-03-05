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


$tenantName = "y3qjt"
#  The string value for the host or the api path segment.
$applicationDisplayName = 'avdScalingRunAsPrincipal'
$keyId = (New-Guid).Guid

# Write-Verbose 'Create an Azure AD application' -Verbose
# $Application = New-AzADApplication -DisplayName $ApplicationDisplayName -HomePage ("http://" + $applicationDisplayName) -IdentifierUris ("http://" + $keyId) 

$app_uri = $("http://{0}.onmicrosoft.com/{1}" -f $tenantName, $applicationDisplayName )
echo $app_uri

Write-Verbose  ("http://" + $tenantName + ".onmicrosoft.com/" + $applicationDisplayName )  -Verbose

