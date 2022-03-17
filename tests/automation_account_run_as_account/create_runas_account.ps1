Write-Verbose "################################" -Verbose
Write-Verbose "## 1 - Create Cert Password   ##" -Verbose
Write-Verbose "################################" -Verbose

$Guid = New-Guid

# $PasswordCredential = New-Object -TypeName Microsoft.Azure.Commands.ActiveDirectory.PSADPasswordCredential
# this is the same end-date which gets created when you manually create a key with "never expires" in the Azure portal
[datetime]$EndDate = "2299-12-31"
[datetime]$StartDate = Get-Date
Write-Output( $StartDate.toString() )
Write-Output( $EndDate.toString() )
Write-Output( $Guid )
$Password = ([System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes(($Guid)))) + "="
Write-Output($Password)


Write-Verbose "################################" -Verbose
Write-Verbose "## 2 - Create SelfSigned Cert ##" -Verbose
Write-Verbose "################################" -Verbose


$tempPath = "."
$RunAsConnectionSPName = "avd_scaling_run_as_sp"
$AutomationAccountName = "avd-scaling-autoaccount"
$CertifcateAssetName = "AzureRunAsCertificate"
$CertificateName = "{0}{1}" -f $AutomationAccountName, $CertifcateAssetName

$selfSignedCertPlainPassword = $Password
$selfSignedCertPassword = ConvertTo-SecureString $selfSignedCertPlainPassword -AsPlainText -Force
$PfxCertPathForRunAsAccount = Join-Path $tempPath ($CertificateName + ".pfx")
$CerCertPathForRunAsAccount = Join-Path $tempPath ($CertificateName + ".cer")

$certPath                           = $PfxCertPathForRunAsAccount 
$certPathCer                        = $CerCertPathForRunAsAccount 
$AutoAccountRunAsCertExpiryInMonths = 24

$certInputObject = @{
    DnsName           = $CertificateName 
    CertStoreLocation = 'cert:\LocalMachine\My'
    KeyExportPolicy   = 'Exportable' 
    Provider          = 'Microsoft Enhanced RSA and AES Cryptographic Provider'
    NotAfter          = (Get-Date).AddMonths($AutoAccountRunAsCertExpiryInMonths) 
    HashAlgorithm     = 'SHA256'
}
$Cert = New-SelfSignedCertificate @certInputObject

Export-PfxCertificate -Cert ("Cert:\localmachine\my\" + $Cert.Thumbprint) -FilePath $certPath -Password $selfSignedCertPassword -Force | Write-Verbose
Export-Certificate -Cert ("Cert:\localmachine\my\" + $Cert.Thumbprint) -FilePath $certPathCer -Type CERT | Write-Verbose


Write-Verbose "################################" -Verbose
Write-Verbose "## 3 - Update App Certificate ##" -Verbose
Write-Verbose "################################" -Verbose

$tenantName = "y3qjt"
$ApplicationDisplayName = $RunAsConnectionSPName
$servicePrincipal = Get-AzADServicePrincipal -DisplayName $applicationDisplayName

$PfxCertPathForRunAsAccount = Join-Path $pwd "avd-scaling-autoaccountAzureRunAsCertificate.pfx"
$PfxCert = New-Object -TypeName System.Security.Cryptography.X509Certificates.X509Certificate2 -ArgumentList @($PfxCertPathForRunAsAccount, $selfSignedCertPlainPassword)
$keyValue = [System.Convert]::ToBase64String($PfxCert.GetRawCertData())

if (-not $servicePrincipal) { 
    Write-Verbose ("Service principal '{0}' not existing. Creating new." -f $applicationDisplayName) -Verbose
 
    Write-Verbose 'Create an Azure AD application' -Verbose
    $Application = New-AzADApplication -DisplayName $ApplicationDisplayName -HomePage ("http://" + $tenantName + ".onmicrosoft.com/" + $applicationDisplayName) -IdentifierUris ("http://" + $tenantName + ".onmicrosoft.com/" + $applicationDisplayName) 
    Write-Verbose $Application -Verbose

    Write-Verbose 'Set app credential' -Verbose
    $null = New-AzADAppCredential -ApplicationId $Application.ApplicationId -CertValue $keyValue -StartDate $PfxCert.NotBefore -EndDate $PfxCert.NotAfter

    Write-Verbose 'Create SP' -Verbose
    $null = New-AzADServicePrincipal -ApplicationId $Application.ApplicationId  # -Scope "/subscriptions/$subscriptionId" -Role 'Contributor'

    $serviceprincipal = Get-AzADServicePrincipal -ApplicationId $Application.ApplicationId
}
else {
    Write-Verbose ("Service principal '{0}' already existing. Updating certifiate." -f $applicationDisplayName) -Verbose
     # Reset App credential
    $null = Remove-AzADAppCredential -ApplicationId $servicePrincipal.ApplicationId -Force
    $null = New-AzADAppCredential -ApplicationId $servicePrincipal.ApplicationId -CertValue $keyValue -StartDate $PfxCert.NotBefore -EndDate $PfxCert.NotAfter

}

$ApplicationId = $servicePrincipal.id


Write-Verbose "##################################" -Verbose
Write-Verbose "## 4 - Update Cert Secret to KV ##" -Verbose
Write-Verbose "##################################" -Verbose

$SelfSignedCertSecretName = "avdScalingRunAsPrincipalCert-Secret"
$KeyVaultName = "kvlov2dhy7sje6o"

Write-Verbose ("No cert secret '{0}' found in key vault '{1}'. Generating new." -f $SelfSignedCertSecretName, $KeyVaultName) -Verbose
$selfSignedCertPassword = ConvertTo-SecureString $selfSignedCertPlainPassword -AsPlainText -Force
Set-AzKeyVaultSecret -VaultName $KeyVaultName -Name $SelfSignedCertSecretName -SecretValue $selfSignedCertPassword


Write-Verbose "##################################" -Verbose
Write-Verbose "## 5 - Create Automation Cert   ##" -Verbose
Write-Verbose "##################################" -Verbose

$AutomationAccountRGName = "AVD-Mgmt-RG"
$AutomationAccountName = "avd-scaling-autoaccount"


$resourceGroup         = $AutomationAccountRGName 
$automationAccountName = $AutomationAccountName 
$certifcateAssetName   = $CertifcateAssetName 
$certPath              = $PfxCertPathForRunAsAccount 
$CertPassword          = $selfSignedCertPassword
$Exportable            = $true

Remove-AzAutomationCertificate -ResourceGroupName $resourceGroup -AutomationAccountName $automationAccountName -Name $certifcateAssetName -ErrorAction SilentlyContinue
New-AzAutomationCertificate -ResourceGroupName $resourceGroup -AutomationAccountName $automationAccountName -Path $certPath -Name $certifcateAssetName -Password $CertPassword -Exportable:$Exportable | write-verbose

Write-Verbose "########################################" -Verbose
Write-Verbose "## 6 - Create Automation Connection   ##" -Verbose
Write-Verbose "########################################" -Verbose

Write-Verbose "Create an Automation connection asset named AzureRunAsConnection in the Automation account. This connection uses the service principal." -Verbose

$CertifcateAssetName = "AzureRunAsCertificate"
$ConnectionTypeName = "AzureServicePrincipal"

$ctx = Get-AzContext  

$ConnectionFieldValues = @{
    ApplicationId         = $ApplicationId
    TenantId              = $ctx.Tenant.Id
    CertificateThumbprint = $PfxCert.Thumbprint
    SubscriptionId        = $ctx.Subscription.Id 
}

$ConnectionInputObject = @{
    ResourceGroupName     = $AutomationAccountRGName
    AutomationAccountName = $AutomationAccountName  
    Name                  = 'AzureRunAsConnection'
    ConnectionTypeName    = $ConnectionTypeName
    ConnectionFieldValues = $ConnectionFieldValues
}
New-AzAutomationConnection @ConnectionInputObject